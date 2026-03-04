import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../main.dart';
import '../../services/api_service.dart';
import '../../utils/money_formatter.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/auth_provider.dart';
import 'admin_products.dart';
import 'admin_orders.dart';
import 'admin_hero_page.dart';
import 'admin_categories.dart';
import 'admin_promotions.dart';
import 'admin_notifications.dart';
import 'admin_product_form.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;
  Map<String, dynamic>? _analytics;
  int _totalProducts = 0;
  int _totalOrders = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    try {
      final analytics = await apiService.getAnalytics();
      final products = await apiService.getProducts();
      final orders = await apiService.getAllOrders();
      if (mounted) {
        setState(() {
          _analytics = analytics;
          _totalProducts = products.length;
          _totalOrders = orders.length;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lang = Provider.of<LanguageProvider>(context).languageCode;

    final pages = [
      _buildOverview(l10n, lang),
      const AdminProductsScreen(),
      const AdminOrdersScreen(),
      const AdminHeroPage(),
      const AdminCategoriesScreen(),
      const AdminPromotions(),
      const AdminNotificationsScreen(),
    ];

    final labels = [
      l10n.dashboard,
      l10n.products,
      l10n.orders,
      'Hero',
      l10n.categories,
      'Promos',
      l10n.notifications,
    ];

    final icons = [
      Icons.dashboard_outlined,
      Icons.inventory_2_outlined,
      Icons.receipt_long_outlined,
      Icons.slideshow_outlined,
      Icons.category_outlined,
      Icons.local_offer_outlined,
      Icons.notifications_outlined,
    ];

    final activeIcons = [
      Icons.dashboard,
      Icons.inventory_2,
      Icons.receipt_long,
      Icons.slideshow,
      Icons.category,
      Icons.local_offer,
      Icons.notifications,
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.adminPanel, style: playfairDisplay(fontSize: 20, fontWeight: FontWeight.w700, color: kCharcoal)),
        backgroundColor: kCreamBg,
        actions: [
          if (_selectedIndex == 1)
            IconButton(
              icon: const Icon(Icons.add, color: kGoldPrimary),
              onPressed: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminProductFormScreen()));
                setState(() {});
              },
              tooltip: 'Add Product',
            ),
        ],
      ),
      body: pages[_selectedIndex],
      drawer: Drawer(
        backgroundColor: kCardBg,
        child: SafeArea(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: kGoldPrimary.withOpacity(0.06),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: kGoldPrimary.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.admin_panel_settings, color: kGoldPrimary, size: 26),
                    ),
                    const SizedBox(height: 12),
                    Text('Zainab Hussain', style: playfairDisplay(fontSize: 18, fontWeight: FontWeight.w700, color: kCharcoal)),
                    const SizedBox(height: 2),
                    Text('Golden Pearl CMS', style: TextStyle(fontSize: 12, color: kSecondaryText)),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: List.generate(labels.length, (i) {
                    final selected = _selectedIndex == i;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                      decoration: BoxDecoration(
                        color: selected ? kGoldPrimary.withOpacity(0.08) : null,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        leading: Icon(selected ? activeIcons[i] : icons[i], color: selected ? kGoldPrimary : kSecondaryText, size: 22),
                        title: Text(labels[i], style: TextStyle(
                          fontSize: 14,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                          color: selected ? kGoldPrimary : kCharcoal,
                        )),
                        selected: selected,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        onTap: () {
                          setState(() => _selectedIndex = i);
                          Navigator.pop(context);
                        },
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex < 5 ? _selectedIndex : 0,
        onTap: (i) => setState(() => _selectedIndex = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: kGoldPrimary,
        unselectedItemColor: kSecondaryText,
        backgroundColor: kCardBg,
        selectedFontSize: 10,
        unselectedFontSize: 10,
        items: [
          BottomNavigationBarItem(icon: Icon(icons[0]), activeIcon: Icon(activeIcons[0]), label: labels[0]),
          BottomNavigationBarItem(icon: Icon(icons[1]), activeIcon: Icon(activeIcons[1]), label: labels[1]),
          BottomNavigationBarItem(icon: Icon(icons[2]), activeIcon: Icon(activeIcons[2]), label: labels[2]),
          BottomNavigationBarItem(icon: Icon(icons[3]), activeIcon: Icon(activeIcons[3]), label: labels[3]),
          BottomNavigationBarItem(icon: Icon(icons[4]), activeIcon: Icon(activeIcons[4]), label: labels[4]),
        ],
      ),
    );
  }

  Widget _buildOverview(AppLocalizations l10n, String lang) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: kGoldPrimary));
    }

    final topProducts = (_analytics?['topProducts'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return RefreshIndicator(
      onRefresh: _loadDashboard,
      color: kGoldPrimary,
      child: ListView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.all(20),
        children: [
          Text('Welcome, Zainab', style: playfairDisplay(fontSize: 24, fontWeight: FontWeight.w700, color: kCharcoal)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _statCard(Icons.inventory_2, l10n.products, '$_totalProducts', kGoldPrimary)),
              const SizedBox(width: 12),
              Expanded(child: _statCard(Icons.receipt_long, l10n.orders, '$_totalOrders', Colors.blue)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _statCard(Icons.visibility, l10n.totalVisits, '${_analytics?['totalViews'] ?? 0}', Colors.green)),
              const SizedBox(width: 12),
              Expanded(child: _statCard(Icons.people, l10n.uniqueSessions, '${_analytics?['uniqueSessions'] ?? 0}', Colors.purple)),
            ],
          ),
          const SizedBox(height: 24),
          Text(l10n.topProducts, style: playfairDisplay(fontSize: 18, fontWeight: FontWeight.w600, color: kCharcoal)),
          const SizedBox(height: 12),
          if (topProducts.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: kCardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: kDivider)),
              child: Center(child: Text(l10n.noProducts, style: const TextStyle(color: kSecondaryText))),
            )
          else
            ...topProducts.take(5).toList().asMap().entries.map((entry) {
              final idx = entry.key;
              final item = entry.value;
              final product = item['product'] as Map<String, dynamic>?;
              final views = item['views'] ?? 0;
              final name = product != null
                  ? (lang == 'ar' ? product['nameAr'] : product['nameEn']) ?? 'Product #${item['productId']}'
                  : 'Product #${item['productId']}';
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(color: kCardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: kDivider)),
                child: Row(
                  children: [
                    Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(color: kGoldPrimary.withOpacity(0.1), shape: BoxShape.circle),
                      child: Center(child: Text('${idx + 1}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kGoldPrimary))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: kCharcoal), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    Text('$views ${l10n.views}', style: const TextStyle(fontSize: 12, color: kSecondaryText)),
                  ],
                ),
              );
            }),
          const SizedBox(height: 24),
          Text(l10n.quickActions, style: playfairDisplay(fontSize: 18, fontWeight: FontWeight.w600, color: kCharcoal)),
          const SizedBox(height: 12),
          _actionTile(Icons.add_box_outlined, l10n.addProduct, () async {
            await Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminProductFormScreen()));
            _loadDashboard();
          }),
          _actionTile(Icons.receipt_long_outlined, l10n.manageOrders, () => setState(() => _selectedIndex = 2)),
          _actionTile(Icons.slideshow_outlined, 'Manage Hero', () => setState(() => _selectedIndex = 3)),
          _actionTile(Icons.category_outlined, l10n.categories, () => setState(() => _selectedIndex = 4)),
          _actionTile(Icons.local_offer_outlined, 'Promotions', () => setState(() => _selectedIndex = 5)),
          _actionTile(Icons.campaign_outlined, 'Send Notification', () => setState(() => _selectedIndex = 6)),
        ],
      ),
    );
  }

  Widget _statCard(IconData icon, String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kDivider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(value, style: playfairDisplay(fontSize: 24, fontWeight: FontWeight.w700, color: kCharcoal)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontSize: 12, color: kSecondaryText)),
        ],
      ),
    );
  }

  Widget _actionTile(IconData icon, String label, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kDivider),
      ),
      child: ListTile(
        leading: Icon(icon, color: kGoldPrimary),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w500, color: kCharcoal)),
        trailing: const Icon(Icons.chevron_right, color: kSecondaryText),
        onTap: onTap,
      ),
    );
  }
}
