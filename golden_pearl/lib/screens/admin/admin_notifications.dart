import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../main.dart';

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  State<AdminNotificationsScreen> createState() => _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final _productIdController = TextEditingController();
  bool _sending = false;
  bool _loading = true;
  List<Map<String, dynamic>> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    _productIdController.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    setState(() => _loading = true);
    try {
      final notifications = await apiService.getAdminNotifications();
      if (mounted) {
        setState(() {
          _notifications = notifications;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendNotification() async {
    final title = _titleController.text.trim();
    final message = _messageController.text.trim();
    final productIdText = _productIdController.text.trim();

    if (title.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Title and message are required'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    int? productId;
    if (productIdText.isNotEmpty) {
      productId = int.tryParse(productIdText);
      if (productId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Product ID must be a valid number'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        return;
      }
    }

    setState(() => _sending = true);
    try {
      await apiService.sendNotification(title, message, productId: productId);
      if (mounted) {
        _titleController.clear();
        _messageController.clear();
        _productIdController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Notification sent to all users'),
            backgroundColor: kGoldPrimary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        _loadNotifications();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _deleteNotification(Map<String, dynamic> notif) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kCardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.delete_outline, color: Colors.red.shade600, size: 22),
            const SizedBox(width: 8),
            const Expanded(child: Text('Delete Notification', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: kCharcoal))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Delete "${notif['title']}" for all users?', style: const TextStyle(fontSize: 14, color: kCharcoal)),
            const SizedBox(height: 6),
            Text('${notif['count'] ?? 1} notification(s) will be removed.', style: const TextStyle(fontSize: 12, color: kSecondaryText)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: kSecondaryText)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await apiService.deleteNotificationGroup(notif['title'] ?? '', notif['message'] ?? '');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Notification deleted'),
            backgroundColor: kGoldPrimary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        _loadNotifications();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Delete failed: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  InputDecoration _inputDecoration(String label, {String? hint, IconData? icon}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: kSecondaryText, fontSize: 14),
      hintStyle: TextStyle(color: kSecondaryText.withOpacity(0.5), fontSize: 14),
      prefixIcon: icon != null ? Icon(icon, color: kGoldPrimary, size: 20) : null,
      filled: true,
      fillColor: kCreamBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: kDivider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: kDivider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kGoldPrimary, width: 1.5),
      ),
    );
  }

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return '';
    try {
      final dt = DateTime.parse(timestamp);
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inHours < 1) return '${diff.inMinutes}m ago';
      if (diff.inDays < 1) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return timestamp ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kCreamBg,
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: playfairDisplay(fontSize: 20, fontWeight: FontWeight.w700, color: kCharcoal),
        ),
        backgroundColor: kCreamBg,
        elevation: 0,
        centerTitle: true,
      ),
      body: RefreshIndicator(
        color: kGoldPrimary,
        onRefresh: _loadNotifications,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              decoration: BoxDecoration(
                color: kCardBg,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: kGoldPrimary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.campaign_outlined, color: kGoldPrimary, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Compose Notification',
                        style: playfairDisplay(fontSize: 18, fontWeight: FontWeight.w600, color: kCharcoal),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _titleController,
                    decoration: _inputDecoration('Title', hint: 'Notification title', icon: Icons.title),
                    style: const TextStyle(color: kCharcoal, fontSize: 14),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _messageController,
                    decoration: _inputDecoration('Message', hint: 'Write your message...', icon: Icons.message_outlined),
                    style: const TextStyle(color: kCharcoal, fontSize: 14),
                    maxLines: 4,
                    minLines: 3,
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _productIdController,
                    decoration: _inputDecoration('Product ID (optional)', hint: 'e.g. 12', icon: Icons.inventory_2_outlined),
                    style: const TextStyle(color: kCharcoal, fontSize: 14),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _sending ? null : _sendNotification,
                      icon: _sending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.send_rounded, size: 18),
                      label: Text(_sending ? 'Sending...' : 'Send to All Users'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kGoldPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Text(
                  'Sent Notifications',
                  style: playfairDisplay(fontSize: 18, fontWeight: FontWeight.w600, color: kCharcoal),
                ),
                const Spacer(),
                if (!_loading)
                  Text(
                    '${_notifications.length} total',
                    style: const TextStyle(color: kSecondaryText, fontSize: 13),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            if (_loading)
              ..._buildLoadingShimmers()
            else if (_notifications.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 48),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    Icon(Icons.notifications_none_rounded, size: 48, color: kSecondaryText.withOpacity(0.4)),
                    const SizedBox(height: 12),
                    Text(
                      'No notifications sent yet',
                      style: TextStyle(color: kSecondaryText.withOpacity(0.6), fontSize: 15),
                    ),
                  ],
                ),
              )
            else
              ...List.generate(_notifications.length, (index) {
                final notif = _notifications[index];
                final count = notif['count'] ?? 1;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: kCardBg,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    leading: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: kGoldPrimary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.notifications_active_outlined, color: kGoldPrimary, size: 20),
                    ),
                    title: Text(
                      notif['title'] ?? '',
                      style: const TextStyle(
                        color: kCharcoal,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          notif['message'] ?? '',
                          style: const TextStyle(color: kSecondaryText, fontSize: 13),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text(
                              _formatTimestamp(notif['createdAt']?.toString()),
                              style: TextStyle(color: kSecondaryText.withOpacity(0.6), fontSize: 11),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: kGoldPrimary.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '$count recipient${count > 1 ? 's' : ''}',
                                style: const TextStyle(fontSize: 10, color: kGoldPrimary, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.delete_outline, color: Colors.red.shade400, size: 20),
                      onPressed: () => _deleteNotification(notif),
                      tooltip: 'Delete notification',
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildLoadingShimmers() {
    return List.generate(3, (index) {
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        height: 90,
        decoration: BoxDecoration(
          color: kCardBg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: kGoldPrimary, strokeWidth: 2),
        ),
      );
    });
  }
}
