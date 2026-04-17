import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
import 'admin_customers.dart';
import 'admin_staff.dart';

class _NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final Widget page;
  final String? permission;
  final bool adminOnly;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.page,
    this.permission,
    this.adminOnly = false,
  });
}

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

  List<_NavItem> _buildNavItems(AppLocalizations l10n) {
    return [
      _NavItem(label: l10n.dashboard, icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, page: _buildOverviewPlaceholder(), permission: 'dashboard.view'),
      _NavItem(label: l10n.products, icon: Icons.inventory_2_outlined, activeIcon: Icons.inventory_2, page: const AdminProductsScreen(), permission: 'products.view'),
      _NavItem(label: l10n.orders, icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long, page: const AdminOrdersScreen(), permission: 'orders.view'),
      _NavItem(label: l10n.manageBanners, icon: Icons.photo_library_outlined, activeIcon: Icons.photo_library, page: const AdminHeroPage(), permission: 'banners.view'),
      _NavItem(label: l10n.categories, icon: Icons.category_outlined, activeIcon: Icons.category, page: const AdminCategoriesScreen(), permission: 'categories.view'),
      _NavItem(label: 'Promos', icon: Icons.local_offer_outlined, activeIcon: Icons.local_offer, page: const AdminPromotions(), permission: 'discountCodes.view'),
      _NavItem(label: l10n.notifications, icon: Icons.notifications_outlined, activeIcon: Icons.notifications, page: const AdminNotificationsScreen(), permission: 'notifications.view'),
      _NavItem(label: l10n.customers, icon: Icons.people_outlined, activeIcon: Icons.people, page: const AdminCustomersScreen(), permission: 'customers.view'),
      _NavItem(label: 'Staff', icon: Icons.badge_outlined, activeIcon: Icons.badge, page: const AdminStaffScreen(), adminOnly: true),
    ];
  }

  List<_NavItem> _getVisibleItems(AuthProvider auth, AppLocalizations l10n) {
    final allItems = _buildNavItems(l10n);
    if (auth.isAdmin) return allItems;

    return allItems.where((item) {
      if (item.adminOnly) return false;
      if (item.permission == null) return true;
      return auth.hasPermission(item.permission!);
    }).toList();
  }

  Widget _buildOverviewPlaceholder() {
    return const SizedBox.shrink();
  }

  Future<void> _loadDashboard() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final hasDashboard = auth.hasPermission('dashboard.view');
    if (!hasDashboard) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    Map<String, dynamic>? analytics;
    int productsCount = 0;
    int ordersCount = 0;

    // Each call is isolated so a failure in one (e.g. orders permission) does
    // NOT zero out the others — the dashboard count must always reflect the
    // real product table count when the analytics call succeeds.
    try {
      analytics = await apiService.getAnalytics();
      productsCount = (analytics['totalProducts'] as num?)?.toInt() ?? 0;
      ordersCount = (analytics['totalOrders'] as num?)?.toInt() ?? 0;
    } catch (_) {}

    // Fallback: if the analytics endpoint did not return totalProducts (older
    // server build), fetch the same list the products page uses and count it.
    if (productsCount == 0) {
      try {
        final products = await apiService.getProducts();
        productsCount = products.length;
      } catch (_) {}
    }

    if (ordersCount == 0 && auth.hasPermission('orders.view')) {
      try {
        final orders = await apiService.getAllOrders();
        ordersCount = orders.length;
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _analytics = analytics;
        _totalProducts = productsCount;
        _totalOrders = ordersCount;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lang = Provider.of<LanguageProvider>(context).languageCode;
    final auth = Provider.of<AuthProvider>(context);

    final visibleItems = _getVisibleItems(auth, l10n);

    if (visibleItems.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.adminPanel, style: playfairDisplay(fontSize: 20, fontWeight: FontWeight.w700, color: kCharcoal)),
          backgroundColor: kCreamBg,
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 48, color: kSecondaryText),
              const SizedBox(height: 16),
              Text('Access Denied', style: playfairDisplay(fontSize: 20, fontWeight: FontWeight.w600, color: kCharcoal)),
              const SizedBox(height: 8),
              const Text('No permissions assigned. Contact your administrator.', style: TextStyle(color: kSecondaryText, fontSize: 13)),
            ],
          ),
        ),
      );
    }

    final safeIndex = _selectedIndex.clamp(0, visibleItems.length - 1);

    final pages = visibleItems.map((item) {
      if (item.permission == 'dashboard.view') {
        return _buildOverview(l10n, lang, auth);
      }
      return item.page;
    }).toList();

    final bottomItems = visibleItems.take(5).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.adminPanel, style: playfairDisplay(fontSize: 20, fontWeight: FontWeight.w700, color: kCharcoal)),
        backgroundColor: kCreamBg,
        actions: [
          if (visibleItems[safeIndex].permission == 'products.view' && auth.hasPermission('products.create'))
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
      body: pages[safeIndex],
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
                      child: Icon(auth.isAdmin ? Icons.admin_panel_settings : Icons.badge, color: kGoldPrimary, size: 26),
                    ),
                    const SizedBox(height: 12),
                    Text(auth.userName, style: playfairDisplay(fontSize: 18, fontWeight: FontWeight.w700, color: kCharcoal)),
                    const SizedBox(height: 2),
                    Text(
                      auth.isAdmin ? 'Administrator' : 'Staff',
                      style: TextStyle(fontSize: 12, color: kSecondaryText),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: List.generate(visibleItems.length, (i) {
                    final selected = safeIndex == i;
                    final item = visibleItems[i];
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                      decoration: BoxDecoration(
                        color: selected ? kGoldPrimary.withOpacity(0.08) : null,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        leading: Icon(selected ? item.activeIcon : item.icon, color: selected ? kGoldPrimary : kSecondaryText, size: 22),
                        title: Text(item.label, style: TextStyle(
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
              const Divider(height: 1, color: kDivider),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red, size: 22),
                  title: Text(l10n.logout, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.red)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  onTap: () => _confirmLogout(context, auth, l10n),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: bottomItems.length >= 2 ? BottomNavigationBar(
        currentIndex: safeIndex < bottomItems.length ? safeIndex : 0,
        onTap: (i) => setState(() => _selectedIndex = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: kGoldPrimary,
        unselectedItemColor: kSecondaryText,
        backgroundColor: kCardBg,
        selectedFontSize: 10,
        unselectedFontSize: 10,
        items: bottomItems.map((item) => BottomNavigationBarItem(
          icon: Icon(item.icon),
          activeIcon: Icon(item.activeIcon),
          label: item.label,
        )).toList(),
      ) : null,
    );
  }

  Future<void> _confirmLogout(BuildContext context, AuthProvider auth, AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kCardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.confirmLogout, style: playfairDisplay(fontSize: 18, fontWeight: FontWeight.w600, color: kCharcoal)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel, style: const TextStyle(color: kSecondaryText)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.logout),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    Navigator.pop(context);
    await auth.logout();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('currentUserId');
    await prefs.remove('currentRole');
    await prefs.remove('authToken');

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.logoutSuccess),
          backgroundColor: kGoldPrimary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  Widget _buildOverview(AppLocalizations l10n, String lang, AuthProvider auth) {
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
          Text('Welcome, ${auth.userName}', style: playfairDisplay(fontSize: 24, fontWeight: FontWeight.w700, color: kCharcoal)),
          if (auth.isStaff) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: kGoldPrimary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('Staff Account', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kGoldPrimary)),
            ),
          ],
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
          if (auth.hasPermission('products.create'))
            _actionTile(Icons.add_box_outlined, l10n.addProduct, () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminProductFormScreen()));
              _loadDashboard();
            }),
          if (auth.hasPermission('orders.view'))
            _actionTile(Icons.receipt_long_outlined, l10n.manageOrders, () {
              final items = _getVisibleItems(auth, l10n);
              final ordersIdx = items.indexWhere((i) => i.permission == 'orders.view');
              if (ordersIdx >= 0) setState(() => _selectedIndex = ordersIdx);
            }),
          if (auth.hasPermission('banners.view'))
            _actionTile(Icons.photo_library_outlined, l10n.manageBanners, () {
              final items = _getVisibleItems(auth, l10n);
              final idx = items.indexWhere((i) => i.permission == 'banners.view');
              if (idx >= 0) setState(() => _selectedIndex = idx);
            }),
          if (auth.hasPermission('categories.view'))
            _actionTile(Icons.category_outlined, l10n.categories, () {
              final items = _getVisibleItems(auth, l10n);
              final idx = items.indexWhere((i) => i.permission == 'categories.view');
              if (idx >= 0) setState(() => _selectedIndex = idx);
            }),
          if (auth.hasPermission('discountCodes.view'))
            _actionTile(Icons.local_offer_outlined, 'Promotions', () {
              final items = _getVisibleItems(auth, l10n);
              final idx = items.indexWhere((i) => i.permission == 'discountCodes.view');
              if (idx >= 0) setState(() => _selectedIndex = idx);
            }),
          if (auth.hasPermission('notifications.send'))
            _actionTile(Icons.campaign_outlined, 'Send Notification', () {
              final items = _getVisibleItems(auth, l10n);
              final idx = items.indexWhere((i) => i.permission == 'notifications.view');
              if (idx >= 0) setState(() => _selectedIndex = idx);
            }),
          if (auth.hasPermission('customers.view'))
            _actionTile(Icons.people_outlined, l10n.customers, () {
              final items = _getVisibleItems(auth, l10n);
              final idx = items.indexWhere((i) => i.permission == 'customers.view');
              if (idx >= 0) setState(() => _selectedIndex = idx);
            }),
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
