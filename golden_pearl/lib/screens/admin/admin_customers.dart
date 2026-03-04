import 'package:flutter/material.dart';
import 'dart:html' as html;
import '../../l10n/generated/app_localizations.dart';
import '../../main.dart';
import '../../services/api_service.dart';
import '../../utils/money_formatter.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';
import 'admin_customer_detail.dart';

class AdminCustomersScreen extends StatefulWidget {
  const AdminCustomersScreen({super.key});

  @override
  State<AdminCustomersScreen> createState() => _AdminCustomersScreenState();
}

class _AdminCustomersScreenState extends State<AdminCustomersScreen> {
  List<Map<String, dynamic>> _customers = [];
  int _totalCount = 0;
  int _page = 1;
  bool _loading = true;
  String _search = '';
  String _sort = 'newest';
  String? _hasOrders;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final result = await apiService.getCustomers(
        search: _search.isNotEmpty ? _search : null,
        sort: _sort,
        hasOrders: _hasOrders,
        page: _page,
        limit: 20,
      );
      if (mounted) {
        setState(() {
          _customers = (result['data'] as List).cast<Map<String, dynamic>>();
          _totalCount = result['totalCount'] as int? ?? 0;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onSearch(String val) {
    _search = val;
    _page = 1;
    _load();
  }

  void _exportList() {
    final url = apiService.getCustomersExportUrl(
      search: _search.isNotEmpty ? _search : null,
      sort: _sort,
      hasOrders: _hasOrders,
    );
    html.window.open(url, '_blank');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lang = Provider.of<LanguageProvider>(context).languageCode;
    final totalPages = (_totalCount / 20).ceil();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: l10n.searchCustomers,
              hintStyle: const TextStyle(color: kSecondaryText, fontSize: 13),
              prefixIcon: const Icon(Icons.search, color: kSecondaryText, size: 20),
              filled: true,
              fillColor: kCardBg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kDivider)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kDivider)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kGoldPrimary)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              suffixIcon: _search.isNotEmpty
                  ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () { _searchCtrl.clear(); _onSearch(''); })
                  : null,
            ),
            onSubmitted: _onSearch,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(
            children: [
              _filterChip(l10n.allCustomers, _hasOrders == null, () { setState(() { _hasOrders = null; _page = 1; }); _load(); }),
              const SizedBox(width: 6),
              _filterChip(l10n.hasOrders, _hasOrders == 'true', () { setState(() { _hasOrders = 'true'; _page = 1; }); _load(); }),
              const SizedBox(width: 6),
              _filterChip(l10n.noOrders, _hasOrders == 'false', () { setState(() { _hasOrders = 'false'; _page = 1; }); _load(); }),
              const Spacer(),
              PopupMenuButton<String>(
                icon: const Icon(Icons.sort, color: kSecondaryText, size: 20),
                tooltip: l10n.sortBy,
                onSelected: (v) { setState(() { _sort = v; _page = 1; }); _load(); },
                itemBuilder: (_) => [
                  PopupMenuItem(value: 'newest', child: Text(l10n.newestFirst)),
                  PopupMenuItem(value: 'highest_spent', child: Text(l10n.highestSpent)),
                  PopupMenuItem(value: 'most_orders', child: Text(l10n.mostOrders)),
                  PopupMenuItem(value: 'last_order', child: Text(l10n.lastOrderDate)),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.download_outlined, color: kGoldPrimary, size: 20),
                tooltip: l10n.exportList,
                onPressed: _exportList,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text('$_totalCount ${l10n.customers}', style: const TextStyle(fontSize: 12, color: kSecondaryText)),
              const Spacer(),
              Text('${l10n.sortBy}: ${_sortLabel(l10n)}', style: const TextStyle(fontSize: 11, color: kSecondaryText)),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: kGoldPrimary))
              : _customers.isEmpty
                  ? Center(child: Text(l10n.noOrdersYet, style: const TextStyle(color: kSecondaryText)))
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: kGoldPrimary,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        itemCount: _customers.length,
                        itemBuilder: (ctx, i) => _customerCard(_customers[i], l10n, lang),
                      ),
                    ),
        ),
        if (totalPages > 1)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _page > 1 ? () { setState(() => _page--); _load(); } : null,
                ),
                Text('$_page / $totalPages', style: const TextStyle(fontSize: 13, color: kCharcoal)),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _page < totalPages ? () { setState(() => _page++); _load(); } : null,
                ),
              ],
            ),
          ),
      ],
    );
  }

  String _sortLabel(AppLocalizations l10n) {
    switch (_sort) {
      case 'highest_spent': return l10n.highestSpent;
      case 'most_orders': return l10n.mostOrders;
      case 'last_order': return l10n.lastOrderDate;
      default: return l10n.newestFirst;
    }
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? kGoldPrimary.withOpacity(0.12) : kCardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? kGoldPrimary : kDivider),
        ),
        child: Text(label, style: TextStyle(fontSize: 11, fontWeight: selected ? FontWeight.w600 : FontWeight.w400, color: selected ? kGoldPrimary : kSecondaryText)),
      ),
    );
  }

  Widget _customerCard(Map<String, dynamic> c, AppLocalizations l10n, String lang) {
    final name = c['name'] ?? '';
    final email = c['email'] ?? '';
    final phone = c['phone'] ?? '';
    final totalOrders = c['totalOrders'] ?? 0;
    final totalSpent = c['totalSpent'] ?? 0;
    final createdAt = c['createdAt'];
    final id = c['id'] as int;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kDivider),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminCustomerDetailScreen(customerId: id))),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: kGoldPrimary.withOpacity(0.1), shape: BoxShape.circle),
                child: Center(child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: kGoldPrimary))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kCharcoal), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(email, style: const TextStyle(fontSize: 12, color: kSecondaryText), maxLines: 1, overflow: TextOverflow.ellipsis),
                    if (phone.isNotEmpty) Text(phone, style: const TextStyle(fontSize: 11, color: kSecondaryText)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('$totalOrders ${l10n.orders}', style: const TextStyle(fontSize: 11, color: kSecondaryText)),
                  const SizedBox(height: 2),
                  Text(MoneyFormatter.format(totalSpent, lang), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kGoldPrimary)),
                  if (createdAt != null) ...[
                    const SizedBox(height: 2),
                    Text(_formatDate(createdAt), style: const TextStyle(fontSize: 10, color: kSecondaryText)),
                  ],
                ],
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: kSecondaryText, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(dynamic d) {
    if (d == null) return '';
    final dt = DateTime.tryParse(d.toString());
    if (dt == null) return '';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}
