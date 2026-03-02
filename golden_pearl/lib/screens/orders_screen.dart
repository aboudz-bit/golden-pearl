import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../main.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../models/order.dart';
import '../utils/money_formatter.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<Order> _orders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      final orders = await apiService.getOrders();
      if (mounted) setState(() { _orders = orders; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'processing': return const Color(0xFFE8A830);
      case 'confirmed': return const Color(0xFF5B8DEF);
      case 'shipped': return Colors.blue;
      case 'delivered': return Colors.green;
      case 'ready_for_pickup': return const Color(0xFF8B5CF6);
      case 'picked_up': return Colors.green;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _statusLabel(String status, AppLocalizations l10n) {
    switch (status) {
      case 'processing': return l10n.processing;
      case 'confirmed': return l10n.confirmed;
      case 'shipped': return l10n.shipped;
      case 'delivered': return l10n.delivered;
      case 'ready_for_pickup': return l10n.readyForPickup;
      case 'picked_up': return l10n.pickedUp;
      case 'cancelled': return l10n.cancelled;
      default: return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lang = Provider.of<LanguageProvider>(context).languageCode;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.orderHistory)),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kGoldPrimary))
          : _orders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.receipt_long_outlined, size: 80, color: kDivider),
                      const SizedBox(height: 16),
                      Text(l10n.noOrders, style: Theme.of(context).textTheme.headlineMedium),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: kGoldPrimary,
                  onRefresh: _loadOrders,
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: _orders.length,
                    itemBuilder: (context, index) {
                      final order = _orders[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  l10n.orderNumber('${order.id}'),
                                  style: playfairDisplay(fontSize: 16, fontWeight: FontWeight.w600, color: kCharcoal),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _statusColor(order.status).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _statusLabel(order.status, l10n),
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _statusColor(order.status)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Fulfillment type badge
                            Row(
                              children: [
                                Icon(
                                  order.isPickup ? Icons.store_outlined : Icons.local_shipping_outlined,
                                  size: 14,
                                  color: const Color(0xFF8A8A8A),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  order.isPickup ? l10n.storePickup : l10n.delivery,
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF8A8A8A)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(order.customerName, style: const TextStyle(color: Color(0xFF8A8A8A))),
                                Text(
                                  MoneyFormatter.format(order.total, lang),
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: kGoldPrimary),
                                ),
                              ],
                            ),
                            // Pickup store info
                            if (order.isPickup && order.pickupStoreName != null) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: kGoldPrimary.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.store, size: 16, color: kGoldPrimary),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            order.pickupStoreName!,
                                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kCharcoal),
                                          ),
                                          if (order.pickupAddress != null)
                                            Text(
                                              order.pickupAddress!,
                                              style: const TextStyle(fontSize: 11, color: Color(0xFF8A8A8A)),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            if (order.trackingNumber != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.local_shipping_outlined, size: 16, color: kGoldPrimary),
                                  const SizedBox(width: 6),
                                  Text(order.trackingNumber!, style: const TextStyle(fontSize: 13, color: Color(0xFF4A4A4A))),
                                ],
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
