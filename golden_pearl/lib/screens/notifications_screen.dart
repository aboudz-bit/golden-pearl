import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../providers/language_provider.dart';
import '../models/order.dart';
import '../services/api_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<AppNotification> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final notifs = await apiService.getNotifications();
      if (mounted) setState(() { _notifications = notifs; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markRead(AppNotification notif) async {
    if (!notif.read) {
      await apiService.markNotificationRead(notif.id);
      _loadNotifications();
    }
    if (notif.orderId != null && mounted) {
      Navigator.pushNamed(context, '/orders');
    }
  }

  String _timeAgo(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final diff = DateTime.now().difference(date);
      if (diff.inMinutes < 1) return 'now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m';
      if (diff.inHours < 24) return '${diff.inHours}h';
      return '${diff.inDays}d';
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.notifications)),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kGoldPrimary))
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_none, size: 80, color: kDivider),
                      const SizedBox(height: 16),
                      Text(l10n.noNotifications, style: Theme.of(context).textTheme.headlineMedium),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: kGoldPrimary,
                  onRefresh: _loadNotifications,
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notif = _notifications[index];
                      return GestureDetector(
                        onTap: () => _markRead(notif),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: notif.read ? kCardBg : kGoldPrimary.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: notif.read ? kDivider : kGoldPrimary.withOpacity(0.2)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: notif.read ? kDivider : kGoldPrimary.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.notifications,
                                  size: 20,
                                  color: notif.read ? kSecondaryText : kGoldPrimary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            notif.title,
                                            style: TextStyle(
                                              fontWeight: notif.read ? FontWeight.w500 : FontWeight.w700,
                                              fontSize: 14,
                                              color: kCharcoal,
                                            ),
                                          ),
                                        ),
                                        if (!notif.read)
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: const BoxDecoration(
                                              color: kGoldPrimary,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      notif.message,
                                      style: TextStyle(fontSize: 13, color: kSecondaryText),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _timeAgo(notif.createdAt),
                                      style: TextStyle(fontSize: 11, color: kSecondaryText.withOpacity(0.7)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
