import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../main.dart';
import '../../models/product.dart';
import '../../services/api_service.dart';
import '../../utils/money_formatter.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';
import 'admin_product_form.dart';

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> with SingleTickerProviderStateMixin {
  List<Product> _products = [];
  bool _loading = true;
  late TabController _tabController;

  final _tabs = ['All', 'Dresses', 'Jalabiyas', 'Kids', 'Gifts'];
  final _slugs = ['all', 'dresses', 'jalabiyas', 'kids', 'gifts'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _loadProducts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    try {
      final products = await apiService.getProducts();
      if (mounted) setState(() { _products = products; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Product> _filteredProducts(int tabIndex) {
    if (tabIndex == 0) return _products;
    return _products.where((p) => p.category == _slugs[tabIndex]).toList();
  }

  Future<void> _deleteProduct(int id) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.confirmRemove),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.yes, style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      await apiService.deleteProduct(id);
      _loadProducts();
    }
  }

  Future<void> _updateStock(Product product) async {
    final controller = TextEditingController(text: '${product.stock}');
    final l10n = AppLocalizations.of(context)!;
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.updateStock),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: l10n.stock,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, int.tryParse(controller.text)),
            child: Text(l10n.save, style: const TextStyle(color: kGoldPrimary)),
          ),
        ],
      ),
    );
    if (result != null) {
      await apiService.updateProductStock(product.id, result);
      _loadProducts();
    }
  }

  Future<void> _duplicateProduct(Product p) async {
    final data = {
      'nameEn': '${p.nameEn} (Copy)',
      'nameAr': '${p.nameAr} (نسخة)',
      'descriptionEn': p.descriptionEn,
      'descriptionAr': p.descriptionAr,
      'price': p.price,
      'originalPrice': p.originalPrice,
      'category': p.category,
      'images': p.images,
      'sizes': p.sizes,
      'colors': p.colors,
      'fabricEn': p.fabricEn,
      'fabricAr': p.fabricAr,
      'inStock': p.inStock,
      'featured': p.featured,
      'stock': p.stock,
    };
    await apiService.createProduct(data);
    _loadProducts();
  }

  Future<void> _manageDiscount(Product product) async {
    final lang = Provider.of<LanguageProvider>(context, listen: false).languageCode;

    if (product.hasActiveDiscount && product.activeDiscount != null) {
      final l10n = AppLocalizations.of(context)!;
      final ad = product.activeDiscount!;
      final action = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Active Discount'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Type: ${ad.type == 'percent' ? 'Percentage' : 'Fixed Amount'}'),
              Text('Value: ${ad.type == 'percent' ? '${ad.value}%' : MoneyFormatter.format(ad.value, lang)}'),
              Text('Ends: ${ad.endsAt.toLocal().toString().substring(0, 16)}'),
              const SizedBox(height: 8),
              Text('Final price: ${MoneyFormatter.format(product.effectivePrice, lang)}',
                  style: const TextStyle(fontWeight: FontWeight.w600, color: kGoldPrimary)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'remove'),
              child: const Text('Remove Discount', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
      if (action == 'remove') {
        try {
          await apiService.removeProductDiscount(product.id);
          _loadProducts();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Discount removed')));
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
          }
        }
      }
      return;
    }

    final typeController = ValueNotifier<String>('percent');
    final valueController = TextEditingController();
    final labelController = TextEditingController();
    DateTime startsAt = DateTime.now();
    DateTime endsAt = DateTime.now().add(const Duration(days: 7));

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Discount'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ValueListenableBuilder<String>(
                  valueListenable: typeController,
                  builder: (_, type, __) => DropdownButtonFormField<String>(
                    value: type,
                    decoration: InputDecoration(
                      labelText: 'Discount Type',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'percent', child: Text('Percentage (%)')),
                      DropdownMenuItem(value: 'fixed', child: Text('Fixed Amount (SAR)')),
                    ],
                    onChanged: (v) => typeController.value = v ?? 'percent',
                  ),
                ),
                const SizedBox(height: 12),
                ValueListenableBuilder<String>(
                  valueListenable: typeController,
                  builder: (_, type, __) => TextField(
                    controller: valueController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: type == 'percent' ? 'Discount % (1-95)' : 'Amount in SAR',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: labelController,
                  decoration: InputDecoration(
                    labelText: 'Label (optional)',
                    hintText: 'e.g. Flash Sale',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Starts', style: TextStyle(fontSize: 13)),
                  subtitle: Text(startsAt.toString().substring(0, 16)),
                  trailing: const Icon(Icons.calendar_today, size: 18),
                  onTap: () async {
                    final date = await showDatePicker(context: ctx, initialDate: startsAt, firstDate: DateTime(2024), lastDate: DateTime(2030));
                    if (date != null) {
                      final time = await showTimePicker(context: ctx, initialTime: TimeOfDay.fromDateTime(startsAt));
                      setDialogState(() {
                        startsAt = DateTime(date.year, date.month, date.day, time?.hour ?? 0, time?.minute ?? 0);
                      });
                    }
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Ends', style: TextStyle(fontSize: 13)),
                  subtitle: Text(endsAt.toString().substring(0, 16)),
                  trailing: const Icon(Icons.calendar_today, size: 18),
                  onTap: () async {
                    final date = await showDatePicker(context: ctx, initialDate: endsAt, firstDate: DateTime(2024), lastDate: DateTime(2030));
                    if (date != null) {
                      final time = await showTimePicker(context: ctx, initialTime: TimeOfDay.fromDateTime(endsAt));
                      setDialogState(() {
                        endsAt = DateTime(date.year, date.month, date.day, time?.hour ?? 0, time?.minute ?? 0);
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final type = typeController.value;
                final rawValue = double.tryParse(valueController.text);
                if (rawValue == null || rawValue <= 0) return;
                int value;
                if (type == 'percent') {
                  value = rawValue.round();
                  if (value < 1 || value > 95) return;
                } else {
                  value = (rawValue * 100).round();
                  if (value >= product.price) return;
                }
                Navigator.pop(ctx, {
                  'type': type,
                  'value': value,
                  'startsAt': startsAt.toUtc().toIso8601String(),
                  'endsAt': endsAt.toUtc().toIso8601String(),
                  'label': labelController.text,
                });
              },
              style: ElevatedButton.styleFrom(backgroundColor: kGoldPrimary),
              child: const Text('Create', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      try {
        await apiService.createProductDiscount(
          productId: product.id,
          type: result['type'],
          value: result['value'],
          startsAt: result['startsAt'],
          endsAt: result['endsAt'],
          label: result['label'],
        );
        _loadProducts();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Discount created')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  Color _stockColor(int stock) {
    if (stock <= 0) return Colors.red;
    if (stock <= 10) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lang = Provider.of<LanguageProvider>(context).languageCode;

    return Column(
      children: [
        Container(
          color: kCardBg,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: kGoldPrimary,
            unselectedLabelColor: kSecondaryText,
            indicatorColor: kGoldPrimary,
            indicatorWeight: 3,
            tabs: _tabs.map((t) => Tab(text: t)).toList(),
            onTap: (_) => setState(() {}),
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: kGoldPrimary))
              : AnimatedBuilder(
                  animation: _tabController,
                  builder: (context, _) {
                    final filtered = _filteredProducts(_tabController.index);
                    if (filtered.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 64, color: kSecondaryText.withOpacity(0.5)),
                            const SizedBox(height: 12),
                            Text(l10n.products, style: TextStyle(color: kSecondaryText, fontSize: 16)),
                          ],
                        ),
                      );
                    }
                    return RefreshIndicator(
                      onRefresh: _loadProducts,
                      color: kGoldPrimary,
                      child: ListView.builder(
                        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                        padding: const EdgeInsets.all(12),
                        itemCount: filtered.length + 1,
                        itemBuilder: (context, index) {
                          if (index == filtered.length) return const SizedBox(height: 80);
                          final p = filtered[index];
                          final name = lang == 'ar' ? p.nameAr : p.nameEn;
                          final imageUrl = p.images.isNotEmpty ? p.images.first : null;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: kCardBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: kDivider),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: SizedBox(
                                      width: 56,
                                      height: 70,
                                      child: imageUrl != null
                                          ? Image.network(
                                              imageUrl.startsWith('http') ? imageUrl : '${ApiService.baseUrl}$imageUrl',
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => Container(color: kCreamBg, child: const Icon(Icons.image, color: kSecondaryText)),
                                            )
                                          : Container(color: kCreamBg, child: const Icon(Icons.image, color: kSecondaryText)),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(name, style: const TextStyle(fontWeight: FontWeight.w600, color: kCharcoal, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Text(MoneyFormatter.format(p.effectivePrice, lang), style: const TextStyle(fontSize: 12, color: kGoldPrimary, fontWeight: FontWeight.w600)),
                                            if (p.hasActiveDiscount) ...[
                                              const SizedBox(width: 4),
                                              Text(MoneyFormatter.format(p.price, lang), style: const TextStyle(fontSize: 10, decoration: TextDecoration.lineThrough, color: Color(0xFF999999))),
                                              const SizedBox(width: 4),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(4)),
                                                child: Text(p.discountBadgeText ?? '', style: TextStyle(fontSize: 9, color: Colors.red.shade600, fontWeight: FontWeight.w600)),
                                              ),
                                            ],
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(color: _stockColor(p.stock).withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                                              child: Text('${l10n.stock}: ${p.stock}', style: TextStyle(fontSize: 10, color: _stockColor(p.stock), fontWeight: FontWeight.w600)),
                                            ),
                                            if (p.featured) ...[
                                              const SizedBox(width: 6),
                                              const Icon(Icons.star, color: kGoldPrimary, size: 14),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                          decoration: BoxDecoration(color: kCreamBg, borderRadius: BorderRadius.circular(4)),
                                          child: Text(p.category, style: const TextStyle(fontSize: 10, color: kSecondaryText)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert, color: kSecondaryText),
                                    onSelected: (action) async {
                                      if (action == 'edit') {
                                        await Navigator.push(context, MaterialPageRoute(builder: (_) => AdminProductFormScreen(product: p)));
                                        _loadProducts();
                                      } else if (action == 'duplicate') {
                                        _duplicateProduct(p);
                                      } else if (action == 'stock') {
                                        _updateStock(p);
                                      } else if (action == 'discount') {
                                        _manageDiscount(p);
                                      } else if (action == 'delete') {
                                        _deleteProduct(p.id);
                                      }
                                    },
                                    itemBuilder: (ctx) => [
                                      PopupMenuItem(value: 'edit', child: Row(children: [const Icon(Icons.edit, size: 18), const SizedBox(width: 8), Text(l10n.edit)])),
                                      const PopupMenuItem(value: 'duplicate', child: Row(children: [Icon(Icons.copy, size: 18), SizedBox(width: 8), Text('Duplicate')])),
                                      PopupMenuItem(value: 'stock', child: Row(children: [const Icon(Icons.inventory, size: 18), const SizedBox(width: 8), Text(l10n.updateStock)])),
                                      PopupMenuItem(
                                        value: 'discount',
                                        child: Row(children: [
                                          Icon(p.hasActiveDiscount ? Icons.discount : Icons.discount_outlined, size: 18, color: p.hasActiveDiscount ? Colors.red : null),
                                          const SizedBox(width: 8),
                                          Text(p.hasActiveDiscount ? 'Manage Discount' : 'Add Discount'),
                                        ]),
                                      ),
                                      PopupMenuItem(value: 'delete', child: Row(children: [const Icon(Icons.delete, size: 18, color: Colors.red), const SizedBox(width: 8), Text(l10n.remove, style: const TextStyle(color: Colors.red))])),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
