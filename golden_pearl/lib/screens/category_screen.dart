import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../models/product.dart';
import '../main.dart';
import '../widgets/product_card.dart';
import '../widgets/category_icons.dart';
import '../utils/arabic_digits.dart';

class CategoryScreen extends StatefulWidget {
  final String slug;
  const CategoryScreen({super.key, required this.slug});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  List<Product> _products = [];
  bool _loading = true;
  String _sortBy = 'newest';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  String _categoryTitle(AppLocalizations l10n) {
    switch (widget.slug) {
      case 'dresses': return l10n.dresses;
      case 'jalabiyas': return l10n.jalabiyas;
      case 'kids': return l10n.kids;
      case 'gifts': return l10n.gifts;
      default: return widget.slug;
    }
  }

  Widget _categoryIconWidget({double size = 20}) {
    switch (widget.slug) {
      case 'dresses': return DressIcon(size: size, color: kGoldPrimary);
      case 'jalabiyas': return KaftanIcon(size: size, color: kGoldPrimary);
      case 'kids': return RibbonBowIcon(size: size, color: kGoldPrimary);
      case 'gifts': return GiftBoxIcon(size: size, color: kGoldPrimary);
      default: return Icon(Icons.category, size: size, color: kGoldPrimary);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() => _loading = true);
    try {
      List<Product> products;
      if (_searchQuery.isNotEmpty) {
        final all = await apiService.getProducts(search: _searchQuery);
        products = all.where((p) => p.category == widget.slug).toList();
      } else {
        products = await apiService.getProducts(category: widget.slug);
      }
      _sortProducts(products);
      if (mounted) setState(() { _products = products; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _sortProducts(List<Product> products) {
    switch (_sortBy) {
      case 'priceLow':
        products.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'priceHigh':
        products.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'bestsellers':
        products.sort((a, b) => b.reviewCount.compareTo(a.reviewCount));
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lang = Provider.of<LanguageProvider>(context).languageCode;
    final title = _categoryTitle(l10n);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _categoryIconWidget(size: 20),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocus,
              decoration: InputDecoration(
                hintText: '${l10n.searchProducts}',
                prefixIcon: const Icon(Icons.search, color: kGoldPrimary),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          _searchFocus.unfocus();
                          setState(() => _searchQuery = '');
                          _loadProducts();
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onSubmitted: (value) {
                setState(() => _searchQuery = value);
                _loadProducts();
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _loading ? '' : l10n.itemCount(_products.length),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                PopupMenuButton<String>(
                  initialValue: _sortBy,
                  onSelected: (value) {
                    setState(() => _sortBy = value);
                    _sortProducts(_products);
                    setState(() {});
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(value: 'newest', child: Text(l10n.newest)),
                    PopupMenuItem(value: 'priceLow', child: Text(l10n.priceLowHigh)),
                    PopupMenuItem(value: 'priceHigh', child: Text(l10n.priceHighLow)),
                    PopupMenuItem(value: 'bestsellers', child: Text(l10n.bestSellers)),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: kDivider),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.sort, size: 16, color: kGoldPrimary),
                        const SizedBox(width: 6),
                        Text(l10n.sortBy, style: const TextStyle(fontSize: 13, color: kGoldPrimary, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: kGoldPrimary))
                : _products.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _categoryIconWidget(size: 64),
                            const SizedBox(height: 16),
                            Text(l10n.noProducts, style: Theme.of(context).textTheme.bodyLarge),
                            if (_searchQuery.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                  _loadProducts();
                                },
                                child: Text(l10n.clearFilters, style: const TextStyle(color: kGoldPrimary)),
                              ),
                            ],
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        color: kGoldPrimary,
                        onRefresh: _loadProducts,
                        child: GridView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.52,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                          ),
                          itemCount: _products.length,
                          itemBuilder: (context, index) => ProductCard(product: _products[index], locale: lang),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
