import 'package:flutter/material.dart';
import 'dart:html' as html;
import '../../l10n/generated/app_localizations.dart';
import '../../main.dart';
import '../../services/api_service.dart';
import '../../utils/money_formatter.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';

class AdminCustomerDetailScreen extends StatefulWidget {
  final int customerId;
  const AdminCustomerDetailScreen({super.key, required this.customerId});

  @override
  State<AdminCustomerDetailScreen> createState() => _AdminCustomerDetailScreenState();
}

class _AdminCustomerDetailScreenState extends State<AdminCustomerDetailScreen> {
  Map<String, dynamic>? _customer;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final result = await apiService.getCustomerDetail(widget.customerId);
      if (mounted) setState(() { _customer = result['data'] as Map<String, dynamic>?; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _exportCustomer() {
    final url = apiService.getCustomerExportUrl(widget.customerId);
    html.window.open(url, '_blank');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lang = Provider.of<LanguageProvider>(context).languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.customerDetails, style: playfairDisplay(fontSize: 18, fontWeight: FontWeight.w700, color: kCharcoal)),
        backgroundColor: kCreamBg,
        actions: [
          IconButton(
            icon: const Icon(Icons.download_outlined, color: kGoldPrimary),
            tooltip: l10n.exportCustomer,
            onPressed: _exportCustomer,
          ),
        ],
      ),
      backgroundColor: kCreamBg,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kGoldPrimary))
          : _customer == null
              ? const Center(child: Text('Customer not found'))
              : RefreshIndicator(
                  onRefresh: _load,
                  color: kGoldPrimary,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildInfoCard(l10n, lang),
                      const SizedBox(height: 16),
                      _buildOrdersSection(l10n, lang),
                      const SizedBox(height: 16),
                      _buildCartSection(l10n, lang),
                    ],
                  ),
                ),
    );
  }

  Widget _buildInfoCard(AppLocalizations l10n, String lang) {
    final c = _customer!;
    final name = c['name'] ?? '';
    final email = c['email'] ?? '';
    final phone = c['phone'] ?? '';
    final totalOrders = c['totalOrders'] ?? 0;
    final totalSpent = c['totalSpent'] ?? 0;
    final createdAt = c['createdAt'];
    final lastOrder = c['lastOrderDate'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: kCardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: kDivider)),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(color: kGoldPrimary.withOpacity(0.1), shape: BoxShape.circle),
            child: Center(child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: kGoldPrimary))),
          ),
          const SizedBox(height: 10),
          Text(name, style: playfairDisplay(fontSize: 18, fontWeight: FontWeight.w700, color: kCharcoal), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(email, style: const TextStyle(fontSize: 13, color: kSecondaryText), maxLines: 1, overflow: TextOverflow.ellipsis),
          if (phone.isNotEmpty) ...[const SizedBox(height: 2), Text(phone, style: const TextStyle(fontSize: 13, color: kSecondaryText))],
          const SizedBox(height: 4),
          Text('ID: ${c['id']}', style: const TextStyle(fontSize: 11, color: kSecondaryText)),
          const Divider(height: 24, color: kDivider),
          Row(
            children: [
              Expanded(child: _infoItem(l10n.orders, '$totalOrders')),
              Expanded(child: _infoItem(l10n.totalSpent, MoneyFormatter.format(totalSpent, lang))),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _infoItem(l10n.registered, _formatDate(createdAt))),
              Expanded(child: _infoItem(l10n.lastOrder, lastOrder != null ? _formatDate(lastOrder) : '-')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kCharcoal)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: kSecondaryText)),
      ],
    );
  }

  Widget _buildOrdersSection(AppLocalizations l10n, String lang) {
    final ordersList = (_customer!['orders'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: kCardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: kDivider)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long, color: kGoldPrimary, size: 20),
              const SizedBox(width: 8),
              Text(l10n.orderHistory, style: playfairDisplay(fontSize: 16, fontWeight: FontWeight.w600, color: kCharcoal)),
              const Spacer(),
              Text('${ordersList.length}', style: const TextStyle(fontSize: 13, color: kSecondaryText)),
            ],
          ),
          const Divider(height: 20, color: kDivider),
          if (ordersList.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(child: Text(l10n.noOrdersYet, style: const TextStyle(color: kSecondaryText, fontSize: 13))),
            )
          else
            ...ordersList.map((o) => _orderTile(o, l10n, lang)),
        ],
      ),
    );
  }

  Widget _orderTile(Map<String, dynamic> o, AppLocalizations l10n, String lang) {
    final status = o['status'] ?? 'pending';
    final itemsArr = o['items'] is List ? (o['items'] as List) : [];
    final total = o['total'] ?? 0;
    final delivery = o['deliveryMethod'] ?? 'delivery';
    final createdAt = o['createdAt'];

    Color statusColor;
    switch (status) {
      case 'delivered':
      case 'picked_up':
        statusColor = Colors.green;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        break;
      case 'processing':
      case 'ready':
        statusColor = Colors.orange;
        break;
      default:
        statusColor = Colors.blue;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kCreamBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('#${o['id']}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kCharcoal)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: statusColor)),
              ),
              const Spacer(),
              Text(MoneyFormatter.format(total, lang), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kGoldPrimary)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(delivery == 'pickup' ? Icons.store : Icons.local_shipping, size: 14, color: kSecondaryText),
              const SizedBox(width: 4),
              Text(delivery == 'pickup' ? 'Store Pickup' : 'Delivery', style: const TextStyle(fontSize: 11, color: kSecondaryText)),
              const SizedBox(width: 12),
              Text('${itemsArr.length} ${l10n.itemsCount}', style: const TextStyle(fontSize: 11, color: kSecondaryText)),
              const Spacer(),
              Text(_formatDate(createdAt), style: const TextStyle(fontSize: 10, color: kSecondaryText)),
            ],
          ),
          if (itemsArr.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: itemsArr.length > 5 ? 5 : itemsArr.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (_, i) {
                  final item = itemsArr[i] is Map ? itemsArr[i] as Map<String, dynamic> : {};
                  final images = item['images'] is List ? item['images'] as List : [];
                  final img = images.isNotEmpty ? images[0].toString() : null;
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: img != null
                        ? Image.network('${ApiService.baseUrl}$img', width: 40, height: 40, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _placeholderThumb())
                        : _placeholderThumb(),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCartSection(AppLocalizations l10n, String lang) {
    final cartList = (_customer!['cart'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: kCardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: kDivider)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shopping_cart_outlined, color: kGoldPrimary, size: 20),
              const SizedBox(width: 8),
              Text(l10n.currentCart, style: playfairDisplay(fontSize: 16, fontWeight: FontWeight.w600, color: kCharcoal)),
              const Spacer(),
              Text('${cartList.length} ${l10n.itemsCount}', style: const TextStyle(fontSize: 13, color: kSecondaryText)),
            ],
          ),
          const Divider(height: 20, color: kDivider),
          if (cartList.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(child: Text(l10n.cartEmpty, style: const TextStyle(color: kSecondaryText, fontSize: 13))),
            )
          else
            ...cartList.map((item) => _cartItemTile(item, lang)),
        ],
      ),
    );
  }

  Widget _cartItemTile(Map<String, dynamic> item, String lang) {
    final productName = lang == 'ar' ? (item['productNameAr'] ?? item['productNameEn'] ?? '') : (item['productNameEn'] ?? '');
    final qty = item['quantity'] ?? 1;
    final price = item['productPrice'] ?? 0;
    final images = item['productImages'] is List ? item['productImages'] as List : [];
    final img = images.isNotEmpty ? images[0].toString() : null;
    final size = item['size'] ?? '';
    final color = item['color'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: kCreamBg, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: img != null
                ? Image.network('${ApiService.baseUrl}$img', width: 44, height: 44, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _placeholderThumb())
                : _placeholderThumb(),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(productName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: kCharcoal), maxLines: 1, overflow: TextOverflow.ellipsis),
                if (size.isNotEmpty || color.isNotEmpty)
                  Text('${size.isNotEmpty ? size : ''} ${color.isNotEmpty ? '• $color' : ''}'.trim(), style: const TextStyle(fontSize: 11, color: kSecondaryText)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('×$qty', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kCharcoal)),
              Text(MoneyFormatter.format(price * qty, lang), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kGoldPrimary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _placeholderThumb() {
    return Container(width: 40, height: 40, color: kDivider, child: const Icon(Icons.image, size: 18, color: kSecondaryText));
  }

  String _formatDate(dynamic d) {
    if (d == null) return '-';
    final dt = DateTime.tryParse(d.toString());
    if (dt == null) return '-';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}
