import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../main.dart';
import '../../models/product.dart';
import '../../services/api_service.dart';
import '../../utils/money_formatter.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  List<Product> _products = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final products = await apiService.getProducts();
      if (mounted) setState(() { _products = products; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
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

  Color _stockColor(int stock) {
    if (stock <= 0) return Colors.red;
    if (stock <= 10) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lang = Provider.of<LanguageProvider>(context).languageCode;

    if (_loading) return const Center(child: CircularProgressIndicator(color: kGoldPrimary));

    return RefreshIndicator(
      onRefresh: _loadProducts,
      color: kGoldPrimary,
      child: ListView.builder(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.all(16),
        itemCount: _products.length,
        itemBuilder: (context, index) {
          final p = _products[index];
          final name = lang == 'ar' ? p.nameAr : p.nameEn;

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: kCardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kDivider),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 50,
                  height: 50,
                  child: p.images.isNotEmpty
                      ? Image.network(
                          p.images.first.startsWith('http') ? p.images.first : '${ApiService.baseUrl}${p.images.first}',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(color: kCreamBg, child: const Icon(Icons.image, color: kSecondaryText)),
                        )
                      : Container(color: kCreamBg, child: const Icon(Icons.image, color: kSecondaryText)),
                ),
              ),
              title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, color: kCharcoal, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Row(
                children: [
                  Text(MoneyFormatter.format(p.price, lang), style: const TextStyle(fontSize: 12, color: kGoldPrimary, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _stockColor(p.stock).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${l10n.stock}: ${p.stock}',
                      style: TextStyle(fontSize: 10, color: _stockColor(p.stock), fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (p.featured) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.star, color: kGoldPrimary, size: 14),
                  ],
                ],
              ),
              trailing: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: kSecondaryText),
                onSelected: (action) {
                  if (action == 'stock') _updateStock(p);
                  if (action == 'delete') _deleteProduct(p.id);
                },
                itemBuilder: (ctx) => [
                  PopupMenuItem(value: 'stock', child: Row(children: [const Icon(Icons.inventory, size: 18), const SizedBox(width: 8), Text(l10n.updateStock)])),
                  PopupMenuItem(value: 'delete', child: Row(children: [const Icon(Icons.delete, size: 18, color: Colors.red), const SizedBox(width: 8), Text(l10n.remove, style: const TextStyle(color: Colors.red))])),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
