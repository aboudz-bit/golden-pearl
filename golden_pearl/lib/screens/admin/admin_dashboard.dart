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
import 'admin_settings.dart';
import 'admin_analytics.dart';

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
    final pages = [
      _buildOverview(l10n),
      const AdminProductsScreen(),
      const AdminOrdersScreen(),
      const AdminSettingsScreen(),
      const AdminAnalyticsScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.adminPanel, style: playfairDisplay(fontSize: 20, fontWeight: FontWeight.w700, color: kCharcoal)),
        backgroundColor: kCreamBg,
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: kGoldPrimary,
        unselectedItemColor: kSecondaryText,
        backgroundColor: kCardBg,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.dashboard_outlined), activeIcon: const Icon(Icons.dashboard), label: l10n.dashboard),
          BottomNavigationBarItem(icon: const Icon(Icons.inventory_2_outlined), activeIcon: const Icon(Icons.inventory_2), label: l10n.products),
          BottomNavigationBarItem(icon: const Icon(Icons.receipt_long_outlined), activeIcon: const Icon(Icons.receipt_long), label: l10n.orders),
          BottomNavigationBarItem(icon: const Icon(Icons.settings_outlined), activeIcon: const Icon(Icons.settings), label: l10n.adminSettings),
          BottomNavigationBarItem(icon: const Icon(Icons.analytics_outlined), activeIcon: const Icon(Icons.analytics), label: l10n.analytics),
        ],
      ),
    );
  }

  Widget _buildOverview(AppLocalizations l10n) {
    final lang = Provider.of<LanguageProvider>(context).languageCode;
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: kGoldPrimary));
    }

    return RefreshIndicator(
      onRefresh: _loadDashboard,
      color: kGoldPrimary,
      child: ListView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.all(20),
        children: [
          Text(l10n.dashboard, style: playfairDisplay(fontSize: 24, fontWeight: FontWeight.w700, color: kCharcoal)),
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
          Text(l10n.quickActions, style: playfairDisplay(fontSize: 18, fontWeight: FontWeight.w600, color: kCharcoal)),
          const SizedBox(height: 12),
          _actionTile(Icons.add_box_outlined, l10n.addProduct, () => setState(() => _selectedIndex = 1)),
          _actionTile(Icons.receipt_long_outlined, l10n.manageOrders, () => setState(() => _selectedIndex = 2)),
          _actionTile(Icons.image_outlined, l10n.manageBanners, () => setState(() => _selectedIndex = 3)),
          _actionTile(Icons.analytics_outlined, l10n.viewAnalytics, () => setState(() => _selectedIndex = 4)),
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
