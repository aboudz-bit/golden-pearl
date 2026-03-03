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

  Future<void> _updateStatus(Order order) async {
    final l10n = AppLocalizations.of(context)!;
    final statuses = order.deliveryMethod == 'pickup'
        ? ['pending', 'confirmed', 'ready_for_pickup', 'picked_up', 'cancelled']
        : ['pending', 'confirmed', 'processing', 'shipped', 'delivered', 'cancelled'];

    final statusLabels = {
      'pending': l10n.pending,
      'confirmed': l10n.confirmed,
      'processing': l10n.processing,
      'shipped': l10n.shipped,
      'delivered': l10n.delivered,
      'ready_for_pickup': l10n.readyForPickup,
      'picked_up': l10n.pickedUp,
      'cancelled': l10n.cancelled,
    };

    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l10n.updateStatus),
        children: statuses.map((s) => SimpleDialogOption(
          onPressed: () => Navigator.pop(ctx, s),
          child: Row(
            children: [
              Icon(
                s == order.status ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: s == order.status ? kGoldPrimary : kSecondaryText,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(statusLabels[s] ?? s, style: TextStyle(
                fontWeight: s == order.status ? FontWeight.w700 : FontWeight.w400,
                color: s == order.status ? kGoldPrimary : kCharcoal,
              )),
            ],
          ),
        )).toList(),
      ),
    );

    if (selected != null && selected != order.status) {
      try {
        await apiService.updateOrderStatus(order.id, selected);
        await _loadOrders();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.error), backgroundColor: Colors.red.shade400, behavior: SnackBarBehavior.floating),
          );
        }
      }
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
                  itemBuilder: (context, index) {
                    final order = filtered[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: kCardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: kDivider),
                      ),
                      child: InkWell(
                        onTap: () => _showOrderDetail(order, l10n, lang),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('#${order.id}', style: playfairDisplay(fontSize: 16, fontWeight: FontWeight.w700, color: kCharcoal)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _statusColor(order.status).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _statusLabel(order.status, l10n),
                                      style: TextStyle(fontSize: 11, color: _statusColor(order.status), fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(order.customerName, style: const TextStyle(fontSize: 13, color: kSecondaryText)),
                                  Text(MoneyFormatter.format(order.total, lang), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kGoldPrimary)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(
                                    order.deliveryMethod == 'pickup' ? Icons.store : Icons.local_shipping,
                                    size: 14,
                                    color: kSecondaryText,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    order.deliveryMethod == 'pickup' ? l10n.storePickup : l10n.delivery,
                                    style: const TextStyle(fontSize: 11, color: kSecondaryText),
                                  ),
                                  const Spacer(),
                                  OutlinedButton(
                                    onPressed: () => _updateStatus(order),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: kGoldPrimary,
                                      side: const BorderSide(color: kGoldPrimary),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                      minimumSize: Size.zero,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    child: Text(l10n.updateStatus, style: const TextStyle(fontSize: 11)),
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
            }),
          ),
        ),
      ],
    );
  }

  void _showOrderDetail(Order order, AppLocalizations l10n, String lang) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kCreamBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (ctx, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: kDivider, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text(l10n.orderNumber(order.id.toString()), style: playfairDisplay(fontSize: 20, fontWeight: FontWeight.w700, color: kCharcoal)),
            const SizedBox(height: 16),
            _detailRow(l10n.fullName, order.customerName),
            _detailRow(l10n.email, order.customerEmail ?? '-'),
            _detailRow(l10n.phone, order.customerPhone),
            _detailRow(l10n.address, order.shippingAddress),
            _detailRow(l10n.city, order.shippingCity),
            _detailRow(l10n.deliveryMethod, order.deliveryMethod == 'pickup' ? l10n.storePickup : l10n.delivery),
            if (order.notes != null) _detailRow(l10n.notes, order.notes!),
            const Divider(height: 24),
            Text(l10n.subtotal, style: const TextStyle(fontWeight: FontWeight.w600, color: kCharcoal)),
            Text(MoneyFormatter.format(order.subtotal, lang), style: const TextStyle(color: kGoldPrimary, fontWeight: FontWeight.w600)),
            if (order.discount > 0) ...[
              const SizedBox(height: 4),
              Text('${l10n.discount}: -${MoneyFormatter.format(order.discount, lang)}', style: const TextStyle(color: Colors.green)),
            ],
            const SizedBox(height: 4),
            Text('${l10n.total}: ${MoneyFormatter.format(order.total, lang)}', style: playfairDisplay(fontSize: 18, fontWeight: FontWeight.w700, color: kGoldPrimary)),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(fontSize: 13, color: kSecondaryText))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, color: kCharcoal, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}
