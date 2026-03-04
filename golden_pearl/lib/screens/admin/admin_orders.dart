import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../main.dart';
import '../../models/order.dart';
import '../../services/api_service.dart';
import '../../utils/money_formatter.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> with SingleTickerProviderStateMixin {
  List<Order> _orders = [];
  bool _loading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    try {
      final orders = await apiService.getAllOrders();
      if (mounted) setState(() { _orders = orders; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Order> _filterOrders(int tabIndex) {
    switch (tabIndex) {
      case 1: return _orders.where((o) => o.deliveryMethod == 'delivery').toList();
      case 2: return _orders.where((o) => o.deliveryMethod == 'pickup').toList();
      default: return _orders;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'confirmed': return Colors.blue;
      case 'processing': return Colors.indigo;
      case 'shipped': return Colors.teal;
      case 'delivered': case 'picked_up': return Colors.green;
      case 'ready_for_pickup': return kGoldPrimary;
      case 'cancelled': return Colors.red;
      default: return kSecondaryText;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'pending': return Icons.schedule;
      case 'confirmed': return Icons.check_circle_outline;
      case 'processing': return Icons.autorenew;
      case 'shipped': return Icons.local_shipping_outlined;
      case 'delivered': return Icons.done_all;
      case 'ready_for_pickup': return Icons.store_outlined;
      case 'picked_up': return Icons.check_circle;
      case 'cancelled': return Icons.cancel_outlined;
      default: return Icons.circle_outlined;
    }
  }

  String _statusLabel(String status, AppLocalizations l10n) {
    final map = {
      'pending': l10n.pending,
      'confirmed': l10n.confirmed,
      'processing': l10n.processing,
      'shipped': l10n.shipped,
      'delivered': l10n.delivered,
      'ready_for_pickup': l10n.readyForPickup,
      'picked_up': l10n.pickedUp,
      'cancelled': l10n.cancelled,
    };
    return map[status] ?? status;
  }

  List<Map<String, dynamic>> _orderItems(Order order) {
    if (order.items is List) return List<Map<String, dynamic>>.from(order.items);
    return [];
  }

  String? _firstImage(Map<String, dynamic> item) {
    final images = item['images'];
    if (images is List && images.isNotEmpty) return images.first?.toString();
    final image = item['image'];
    if (image is String && image.isNotEmpty) return image;
    return null;
  }

  Widget _productThumb(String? img, {double size = 44}) {
    if (img == null) {
      return Container(
        width: size, height: size,
        decoration: BoxDecoration(color: kCreamBg, borderRadius: BorderRadius.circular(6), border: Border.all(color: kDivider)),
        child: Icon(Icons.image_outlined, size: size * 0.4, color: kSecondaryText),
      );
    }
    final url = img.startsWith('http') ? img : '${ApiService.baseUrl}$img';
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), border: Border.all(color: kDivider)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: Image.network(
          url,
          fit: BoxFit.cover,
          loadingBuilder: (_, child, progress) {
            if (progress == null) return child;
            return Container(color: kCreamBg, child: Center(child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 1.5, color: kGoldPrimary, value: progress.expectedTotalBytes != null ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes! : null))));
          },
          errorBuilder: (_, error, ___) {
            debugPrint('Image load failed: $url — $error');
            return Container(color: kCreamBg, child: Icon(Icons.broken_image_outlined, size: size * 0.4, color: kSecondaryText));
          },
        ),
      ),
    );
  }

  Future<void> _showUpdateStatusDialog(Order order) async {
    final l10n = AppLocalizations.of(context)!;
    final lang = Provider.of<LanguageProvider>(context, listen: false).languageCode;
    final statuses = order.deliveryMethod == 'pickup'
        ? ['pending', 'confirmed', 'ready_for_pickup', 'picked_up', 'cancelled']
        : ['pending', 'confirmed', 'processing', 'shipped', 'delivered', 'cancelled'];

    String? selected;
    bool saving = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return Dialog(
            backgroundColor: kCardBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(color: kGoldPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.sync_alt, color: kGoldPrimary, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l10n.updateStatus, style: playfairDisplay(fontSize: 16, fontWeight: FontWeight.w700, color: kCharcoal)),
                              Text(l10n.orderNumber(order.id.toString()), style: const TextStyle(fontSize: 12, color: kSecondaryText)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _statusColor(order.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_statusIcon(order.status), size: 14, color: _statusColor(order.status)),
                          const SizedBox(width: 6),
                          Text(
                            '${l10n.currentStatus}: ${_statusLabel(order.status, l10n)}',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _statusColor(order.status)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: statuses.map((s) {
                        final isCurrentStatus = s == order.status;
                        final isSelected = s == selected;
                        final color = _statusColor(s);
                        return ChoiceChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_statusIcon(s), size: 14, color: isSelected ? Colors.white : (isCurrentStatus ? color.withOpacity(0.5) : color)),
                              const SizedBox(width: 6),
                              Text(_statusLabel(s, l10n)),
                            ],
                          ),
                          selected: isSelected,
                          selectedColor: color,
                          backgroundColor: isCurrentStatus ? color.withOpacity(0.05) : kCreamBg,
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : (isCurrentStatus ? color.withOpacity(0.5) : kCharcoal),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: isSelected ? color : (isCurrentStatus ? color.withOpacity(0.2) : kDivider)),
                          ),
                          onSelected: isCurrentStatus ? null : (val) {
                            setDialogState(() => selected = val ? s : null);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: saving ? null : () => Navigator.pop(ctx),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: kSecondaryText,
                              side: BorderSide(color: kDivider),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: Text(l10n.cancel),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: (selected == null || saving) ? null : () async {
                              setDialogState(() => saving = true);
                              try {
                                await apiService.updateOrderStatus(order.id, selected!);
                                if (ctx.mounted) Navigator.pop(ctx, selected);
                              } catch (e) {
                                setDialogState(() => saving = false);
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(
                                      content: Text(l10n.error),
                                      backgroundColor: Colors.red.shade700,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  );
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kGoldPrimary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 0,
                            ),
                            child: saving
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : Text(l10n.confirm, style: const TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );

    if (selected != null && mounted) {
      final l10n2 = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n2.orderNumber(order.id.toString())} → ${_statusLabel(selected!, l10n2)}'),
          backgroundColor: kGoldPrimary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      await _loadOrders();
    }
  }

  void _showOrderDetail(Order order, AppLocalizations l10n, String lang) {
    final items = _orderItems(order);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kCreamBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        expand: false,
        builder: (ctx, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          children: [
            Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: kDivider, borderRadius: BorderRadius.circular(2)))),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: kCardBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: kDivider)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.orderNumber(order.id.toString()), style: playfairDisplay(fontSize: 20, fontWeight: FontWeight.w700, color: kCharcoal)),
                          const SizedBox(height: 4),
                          Text(_formatDate(order.createdAt), style: const TextStyle(fontSize: 12, color: kSecondaryText)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _statusColor(order.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_statusIcon(order.status), size: 14, color: _statusColor(order.status)),
                            const SizedBox(width: 4),
                            Text(_statusLabel(order.status, l10n), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _statusColor(order.status))),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(l10n.total, style: const TextStyle(fontSize: 14, color: kSecondaryText)),
                      Text(MoneyFormatter.format(order.total, lang), style: playfairDisplay(fontSize: 20, fontWeight: FontWeight.w700, color: kGoldPrimary)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            _sectionCard(
              icon: Icons.person_outline,
              title: l10n.customerInfo,
              children: [
                _infoRow(l10n.fullName, order.customerName),
                _infoRow(l10n.phone, order.customerPhone),
                if (order.customerEmail != null && order.customerEmail!.isNotEmpty)
                  _infoRow(l10n.email, order.customerEmail!),
              ],
            ),

            const SizedBox(height: 12),
            _sectionCard(
              icon: order.deliveryMethod == 'pickup' ? Icons.store_outlined : Icons.local_shipping_outlined,
              title: l10n.fulfillment,
              children: [
                _infoRow(l10n.deliveryMethod, order.deliveryMethod == 'pickup' ? l10n.storePickup : l10n.delivery),
                if (order.deliveryMethod == 'delivery') ...[
                  _infoRow(l10n.address, order.shippingAddress),
                  _infoRow(l10n.city, order.shippingCity),
                ],
                if (order.trackingNumber != null && order.trackingNumber!.isNotEmpty)
                  _infoRow(l10n.trackingNumber, order.trackingNumber!),
                if (order.notes != null && order.notes!.isNotEmpty)
                  _infoRow(l10n.notes, order.notes!),
              ],
            ),

            if (items.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: kCardBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: kDivider)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.shopping_bag_outlined, size: 18, color: kGoldPrimary),
                        const SizedBox(width: 8),
                        Text('${l10n.items} (${items.length})', style: playfairDisplay(fontSize: 15, fontWeight: FontWeight.w600, color: kCharcoal)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...items.asMap().entries.map((entry) {
                      final i = entry.key;
                      final item = entry.value;
                      final img = _firstImage(item);
                      final name = item['name'] ?? item['nameEn'] ?? '';
                      final qty = item['quantity'] ?? 1;
                      final size = item['size'] ?? '';
                      final color = item['color'] ?? '';
                      final price = item['price'] ?? 0;
                      final lineTotal = (price as num) * (qty as num);
                      return Column(
                        children: [
                          if (i > 0) Divider(height: 16, color: kDivider),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _productThumb(img, size: 56),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(name.toString(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kCharcoal), maxLines: 2, overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 4),
                                    if (size.toString().isNotEmpty || color.toString().isNotEmpty)
                                      Text(
                                        [if (size.toString().isNotEmpty) '${l10n.size}: $size', if (color.toString().isNotEmpty) '${l10n.color}: $color'].join('  •  '),
                                        style: const TextStyle(fontSize: 11, color: kSecondaryText),
                                      ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('${MoneyFormatter.format(price.toInt(), lang)} × $qty', style: const TextStyle(fontSize: 12, color: kSecondaryText)),
                                        Text(MoneyFormatter.format(lineTotal.toInt(), lang), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kCharcoal)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: kCardBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: kDivider)),
              child: Column(
                children: [
                  _summaryRow(l10n.subtotal, MoneyFormatter.format(order.subtotal, lang)),
                  const SizedBox(height: 8),
                  _summaryRow(l10n.deliveryFee, order.shipping > 0 ? MoneyFormatter.format(order.shipping, lang) : l10n.freeShipping),
                  if (order.discount > 0) ...[
                    const SizedBox(height: 8),
                    _summaryRow(l10n.discount, '-${MoneyFormatter.format(order.discount, lang)}', valueColor: Colors.green),
                  ],
                  if (order.discountCode != null && order.discountCode!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const SizedBox(width: 4),
                        Icon(Icons.local_offer_outlined, size: 12, color: Colors.green.shade700),
                        const SizedBox(width: 4),
                        Text(order.discountCode!, style: TextStyle(fontSize: 11, color: Colors.green.shade700, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ],
                  Divider(height: 20, color: kDivider),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(l10n.total, style: playfairDisplay(fontSize: 16, fontWeight: FontWeight.w700, color: kCharcoal)),
                      Text(MoneyFormatter.format(order.total, lang), style: playfairDisplay(fontSize: 18, fontWeight: FontWeight.w700, color: kGoldPrimary)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _showUpdateStatusDialog(order);
                },
                icon: const Icon(Icons.sync_alt, size: 18),
                label: Text(l10n.updateStatus),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kGoldPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                  textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({required IconData icon, required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: kCardBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: kDivider)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: kGoldPrimary),
              const SizedBox(width: 8),
              Text(title, style: playfairDisplay(fontSize: 15, fontWeight: FontWeight.w600, color: kCharcoal)),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text(label, style: const TextStyle(fontSize: 12, color: kSecondaryText))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, color: kCharcoal, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: kSecondaryText)),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: valueColor ?? kCharcoal)),
      ],
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final dt = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inHours < 1) return '${diff.inMinutes}m ago';
      if (diff.inDays < 1) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return dateStr ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lang = Provider.of<LanguageProvider>(context).languageCode;

    if (_loading) return const Center(child: CircularProgressIndicator(color: kGoldPrimary));

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          onTap: (_) => setState(() {}),
          labelColor: kGoldPrimary,
          unselectedLabelColor: kSecondaryText,
          indicatorColor: kGoldPrimary,
          tabs: [
            Tab(text: l10n.all),
            Tab(text: l10n.delivery),
            Tab(text: l10n.storePickup),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: List.generate(3, (tabIndex) {
              final filtered = _filterOrders(tabIndex);
              if (filtered.isEmpty) {
                return Center(child: Text(l10n.noOrders, style: const TextStyle(color: kSecondaryText)));
              }
              return RefreshIndicator(
                onRefresh: _loadOrders,
                color: kGoldPrimary,
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) => _buildOrderCard(filtered[index], l10n, lang),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderCard(Order order, AppLocalizations l10n, String lang) {
    final items = _orderItems(order);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kDivider),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: InkWell(
        onTap: () => _showOrderDetail(order, l10n, lang),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text('#${order.id}', style: playfairDisplay(fontSize: 16, fontWeight: FontWeight.w700, color: kCharcoal)),
                      const SizedBox(width: 8),
                      Text(_formatDate(order.createdAt), style: const TextStyle(fontSize: 11, color: kSecondaryText)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor(order.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_statusIcon(order.status), size: 12, color: _statusColor(order.status)),
                        const SizedBox(width: 4),
                        Text(_statusLabel(order.status, l10n), style: TextStyle(fontSize: 11, color: _statusColor(order.status), fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(order.customerName, style: const TextStyle(fontSize: 13, color: kSecondaryText), overflow: TextOverflow.ellipsis)),
                  Text(MoneyFormatter.format(order.total, lang), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kGoldPrimary)),
                ],
              ),
              if (items.isNotEmpty) ...[
                const SizedBox(height: 10),
                SizedBox(
                  height: 44,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: items.length > 5 ? 6 : items.length,
                    itemBuilder: (ctx, i) {
                      if (i == 5) {
                        return Container(
                          width: 44, height: 44,
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(color: kCreamBg, borderRadius: BorderRadius.circular(6), border: Border.all(color: kDivider)),
                          child: Center(child: Text('+${items.length - 5}', style: const TextStyle(fontSize: 11, color: kSecondaryText, fontWeight: FontWeight.w600))),
                        );
                      }
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: _productThumb(_firstImage(items[i])),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(order.deliveryMethod == 'pickup' ? Icons.store : Icons.local_shipping, size: 14, color: kSecondaryText),
                  const SizedBox(width: 4),
                  Text(order.deliveryMethod == 'pickup' ? l10n.storePickup : l10n.delivery, style: const TextStyle(fontSize: 11, color: kSecondaryText)),
                  if (items.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Text('${items.length} ${l10n.items}', style: const TextStyle(fontSize: 11, color: kSecondaryText)),
                  ],
                  const Spacer(),
                  OutlinedButton.icon(
                    onPressed: () => _showUpdateStatusDialog(order),
                    icon: const Icon(Icons.sync_alt, size: 14),
                    label: Text(l10n.updateStatus, style: const TextStyle(fontSize: 11)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kGoldPrimary,
                      side: const BorderSide(color: kGoldPrimary),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
