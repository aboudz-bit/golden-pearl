import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../models/product.dart';
import '../main.dart';
import '../widgets/product_card.dart';

class ShopScreen extends StatefulWidget {
  final String? initialCategory;
  const ShopScreen({super.key, this.initialCategory});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  List<Product> _products = [];
  bool _loading = true;
  String _selectedCategory = 'all';
  String _sortBy = 'newest';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialCategory != null) _selectedCategory = widget.initialCategory!;
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _loading = true);
    try {
      List<Product> products;
      if (_searchQuery.isNotEmpty) {
        products = await apiService.getProducts(search: _searchQuery);
      } else if (_selectedCategory != 'all') {
        products = await apiService.getProducts(category: _selectedCategory);
      } else {
        products = await apiService.getProducts();
      }
      _sortProducts(products);
      if (mounted) setState(() { _products = products; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _sortProducts(List<Product> products) {
    switch (_sortBy) {
      case 'priceLow': products.sort((a, b) => a.price.compareTo(b.price));
      case 'priceHigh': products.sort((a, b) => b.price.compareTo(a.price));
      case 'bestsellers': products.sort((a, b) => b.reviewCount.compareTo(a.reviewCount));
      default: break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lang = Provider.of<LanguageProvider>(context).languageCode;
    final categories = [
      {'key': 'all', 'label': l10n.all},
      {'key': 'dresses', 'label': l10n.dresses},
      {'key': 'jalabiyas', 'label': l10n.jalabiyas},
      {'key': 'kids', 'label': l10n.kids},
      {'key': 'gifts', 'label': l10n.gifts},
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.shop)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l10n.searchProducts,
                prefixIcon: const Icon(Icons.search, color: kGoldPrimary),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear), onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                        _loadProducts();
                      })
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
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                final isSelected = _selectedCategory == cat['key'];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      if (_selectedCategory != cat['key']) {
                        setState(() { _selectedCategory = cat['key']!; _searchQuery = ''; _searchController.clear(); });
                        _loadProducts();
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? kGoldPrimary : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isSelected ? kGoldPrimary : kDivider),
                      ),
                      child: Text(
                        cat['label']!,
                        style: TextStyle(
                          fontSize: 13,
                          color: isSelected ? Colors.white : const Color(0xFF4A4A4A),
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${_products.length}', style: Theme.of(context).textTheme.bodySmall),
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
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.sort, size: 18, color: kGoldPrimary),
                      const SizedBox(width: 4),
                      Text(l10n.sortBy, style: const TextStyle(color: kGoldPrimary, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: kGoldPrimary))
                : _products.isEmpty
                    ? Center(child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.shopping_bag_outlined, size: 64, color: kDivider),
                          const SizedBox(height: 16),
                          Text(l10n.noProducts, style: Theme.of(context).textTheme.bodyLarge),
                        ],
                      ))
                    : RefreshIndicator(
                        color: kGoldPrimary,
                        onRefresh: _loadProducts,
                        child: GridView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.all(16),
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
