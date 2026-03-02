import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../main.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../providers/cart_provider.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../utils/money_formatter.dart';
import '../utils/arabic_digits.dart';

class ProductDetailScreen extends StatefulWidget {
  final int productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  Product? _product;
  bool _loading = true;
  String? _selectedSize;
  String? _selectedColor;
  int _quantity = 1;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    try {
      final product = await apiService.getProduct(widget.productId);
      if (mounted) {
        setState(() {
          _product = product;
          _selectedSize = product.sizes.isNotEmpty ? product.sizes[0] : null;
          _selectedColor = product.colors.isNotEmpty ? product.colors[0] : null;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _addToBag() async {
    if (_product == null || _selectedSize == null || _selectedColor == null) return;
    final cart = Provider.of<CartProvider>(context, listen: false);
    final success = await cart.addToCart(_product!.id, _selectedSize!, _selectedColor!, quantity: _quantity);
    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.addedToBag),
          backgroundColor: kGoldPrimary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lang = Provider.of<LanguageProvider>(context).languageCode;

    if (_loading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator(color: kGoldPrimary)),
      );
    }

    if (_product == null) {
      return Scaffold(appBar: AppBar(), body: Center(child: Text(l10n.error)));
    }

    final p = _product!;
    final hasDiscount = p.originalPrice != null && p.originalPrice! > p.price;

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: MediaQuery.of(context).size.height * 0.5,
            pinned: true,
            backgroundColor: kCreamBg,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  PageView.builder(
                    itemCount: p.images.length,
                    onPageChanged: (i) => setState(() => _currentImageIndex = i),
                    itemBuilder: (context, index) {
                      final img = p.images[index];
                      final url = img.startsWith('http') ? img : '${ApiService.baseUrl}$img';
                      return Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: kCreamBg));
                    },
                  ),
                  if (p.images.length > 1)
                    Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(p.images.length, (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 280),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: _currentImageIndex == i ? 20 : 6,
                          height: 3,
                          decoration: BoxDecoration(
                            color: _currentImageIndex == i ? kGoldPrimary : Colors.white54,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        )),
                      ),
                    ),
                  if (p.badge != null)
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 56,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: kGoldPrimary.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(p.badge!, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                    ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: Text(p.name(lang), style: playfairDisplay(fontSize: 24, fontWeight: FontWeight.w700, color: kCharcoal))),
                      IconButton(icon: const Icon(Icons.favorite_border, color: kGoldPrimary), onPressed: () {}),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        MoneyFormatter.format(p.price, lang),
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: kGoldPrimary),
                      ),
                      if (hasDiscount) ...[
                        const SizedBox(width: 12),
                        Text(
                          MoneyFormatter.format(p.originalPrice!, lang),
                          style: const TextStyle(fontSize: 15, decoration: TextDecoration.lineThrough, color: Color(0xFF999999)),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: kGoldPrimary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '-${ArabicDigits.convert(((1 - p.price / p.originalPrice!) * 100).round(), lang)}%',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kGoldPrimary),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ...List.generate(5, (i) => Icon(
                        i < p.rating.floor() ? Icons.star : (i < p.rating ? Icons.star_half : Icons.star_border),
                        size: 18,
                        color: kGoldPrimary,
                      )),
                      const SizedBox(width: 8),
                      Text(l10n.reviews(p.reviewCount), style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Text(l10n.size, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: p.sizes.map((size) {
                      final isSelected = _selectedSize == size;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedSize = size),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? kCharcoal : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isSelected ? kCharcoal : kDivider),
                          ),
                          child: Text(size, style: TextStyle(
                            color: isSelected ? Colors.white : const Color(0xFF4A4A4A),
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          )),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  Text(l10n.color, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: p.colors.map((color) {
                      final isSelected = _selectedColor == color;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedColor = color),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? kGoldPrimary.withOpacity(0.12) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isSelected ? kGoldPrimary : kDivider, width: isSelected ? 2 : 1),
                          ),
                          child: Text(color, style: TextStyle(
                            fontSize: 13,
                            color: isSelected ? kGoldDark : const Color(0xFF4A4A4A),
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          )),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  Text(l10n.quantity, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: kDivider),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.remove, size: 18), onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null),
                        SizedBox(width: 40, child: Text(ArabicDigits.convert(_quantity, lang), textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
                        IconButton(icon: const Icon(Icons.add, size: 18), onPressed: () => setState(() => _quantity++)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(l10n.description, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 10),
                  Text(p.description(lang), style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.6)),
                  if (p.fabric(lang) != null) ...[
                    const SizedBox(height: 24),
                    Text(l10n.fabricCare, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.texture, size: 18, color: kGoldPrimary),
                        const SizedBox(width: 8),
                        Expanded(child: Text(p.fabric(lang)!, style: Theme.of(context).textTheme.bodyMedium)),
                      ],
                    ),
                  ],
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Color(0x0F000000), blurRadius: 12, offset: Offset(0, -2))],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _addToBag,
              icon: const Icon(Icons.shopping_bag_outlined, size: 20),
              label: Text('${l10n.addToBag}  ·  ${MoneyFormatter.format(p.price * _quantity, lang)}'),
            ),
          ),
        ),
      ),
    );
  }
}
