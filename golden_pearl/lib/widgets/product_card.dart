import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../main.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../utils/money_formatter.dart';
import '../utils/arabic_digits.dart';
import '../providers/favorites_provider.dart';
import '../providers/cart_provider.dart';
import 'shimmer_placeholder.dart';

class ProductCard extends StatefulWidget {
  final Product product;
  final String locale;

  const ProductCard({super.key, required this.product, required this.locale});

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> with SingleTickerProviderStateMixin {
  double _scale = 1.0;
  bool _imageLoaded = false;
  double _heartScale = 1.0;

  String get _imageUrl {
    if (widget.product.images.isNotEmpty) {
      final img = widget.product.images[0];
      if (img.startsWith('http')) return img;
      return '${ApiService.baseUrl}$img';
    }
    return '';
  }

  void _onFavoriteTap() {
    final favs = Provider.of<FavoritesProvider>(context, listen: false);
    favs.toggleFavorite(widget.product.id);
    setState(() => _heartScale = 1.3);
    Future.delayed(const Duration(milliseconds: 180), () {
      if (mounted) setState(() => _heartScale = 1.0);
    });
  }

  void _onQuickAdd() {
    final product = widget.product;
    if (product.sizes.length <= 1 && product.colors.length <= 1) {
      _addDirectly(
        product.sizes.isNotEmpty ? product.sizes[0] : 'One Size',
        product.colors.isNotEmpty ? product.colors[0] : 'Default',
      );
    } else {
      _showQuickSelectSheet();
    }
  }

  void _addDirectly(String size, String color) async {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;
    final success = await cart.addToCart(widget.product.id, size, color);
    if (mounted && success) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.addedToBag),
          backgroundColor: kGoldPrimary,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 1500),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _showQuickSelectSheet() {
    final product = widget.product;
    String selectedSize = product.sizes.isNotEmpty ? product.sizes[0] : 'One Size';
    String selectedColor = product.colors.isNotEmpty ? product.colors[0] : 'Default';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSheetState) {
          final l10n = AppLocalizations.of(ctx)!;
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(width: 36, height: 4, decoration: BoxDecoration(color: kDivider, borderRadius: BorderRadius.circular(2))),
                ),
                const SizedBox(height: 16),
                Text(product.name(widget.locale), style: playfairDisplay(fontSize: 16, fontWeight: FontWeight.w600, color: kCharcoal)),
                const SizedBox(height: 16),
                if (product.sizes.length > 1) ...[
                  Text(l10n.size, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kCharcoal)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: product.sizes.map((size) {
                      final isSel = selectedSize == size;
                      return GestureDetector(
                        onTap: () => setSheetState(() => selectedSize = size),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSel ? kCharcoal : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: isSel ? kCharcoal : kDivider),
                          ),
                          child: Text(size, style: TextStyle(fontSize: 13, color: isSel ? Colors.white : const Color(0xFF4A4A4A), fontWeight: isSel ? FontWeight.w600 : FontWeight.normal)),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],
                if (product.colors.length > 1) ...[
                  Text(l10n.color, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kCharcoal)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: product.colors.map((color) {
                      final isSel = selectedColor == color;
                      return GestureDetector(
                        onTap: () => setSheetState(() => selectedColor = color),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSel ? kGoldPrimary.withOpacity(0.12) : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: isSel ? kGoldPrimary : kDivider, width: isSel ? 2 : 1),
                          ),
                          child: Text(color, style: TextStyle(fontSize: 13, color: isSel ? kGoldDark : const Color(0xFF4A4A4A), fontWeight: isSel ? FontWeight.w600 : FontWeight.normal)),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _addDirectly(selectedSize, selectedColor);
                    },
                    icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                    label: Text(l10n.addToBag),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final locale = widget.locale;
    final hasDiscount = product.originalPrice != null && product.originalPrice! > product.price;
    final favs = Provider.of<FavoritesProvider>(context);
    final isFav = favs.isFavorite(product.id);

    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.97),
      onTapUp: (_) {
        setState(() => _scale = 1.0);
        Navigator.pushNamed(context, '/product/${product.id}');
      },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: Container(
          decoration: BoxDecoration(
            color: kCardBg,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 4 / 5,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      child: _imageUrl.isNotEmpty
                          ? AnimatedOpacity(
                              opacity: _imageLoaded ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 300),
                              child: Image.network(
                                _imageUrl,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                                alignment: Alignment.topCenter,
                                frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                                  if (wasSynchronouslyLoaded || frame != null) {
                                    WidgetsBinding.instance.addPostFrameCallback((_) {
                                      if (mounted && !_imageLoaded) setState(() => _imageLoaded = true);
                                    });
                                    return child;
                                  }
                                  return const SizedBox();
                                },
                                errorBuilder: (_, __, ___) => _placeholder(),
                              ),
                            )
                          : _placeholder(),
                    ),
                    if (!_imageLoaded && _imageUrl.isNotEmpty)
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          child: ShimmerPlaceholder(borderRadius: BorderRadius.zero),
                        ),
                      ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: _onFavoriteTap,
                        behavior: HitTestBehavior.opaque,
                        child: AnimatedScale(
                          scale: _heartScale,
                          duration: const Duration(milliseconds: 180),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.85),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isFav ? Icons.favorite : Icons.favorite_border,
                              size: 17,
                              color: isFav ? kGoldPrimary : kSecondaryText,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: GestureDetector(
                        onTap: _onQuickAdd,
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.85),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add_shopping_cart, size: 16, color: kCharcoal),
                        ),
                      ),
                    ),
                    if (product.videoUrl != null && product.videoUrl!.isNotEmpty)
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.55),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.play_arrow, color: Colors.white, size: 18),
                        ),
                      ),
                    if (product.badge != null)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: kGoldPrimary.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            product.badge!,
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name(locale),
                      style: playfairDisplay(fontSize: 13, fontWeight: FontWeight.w600, color: kCharcoal),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          MoneyFormatter.format(product.price, locale),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kGoldPrimary),
                        ),
                        if (hasDiscount) ...[
                          const SizedBox(width: 6),
                          Text(
                            MoneyFormatter.format(product.originalPrice!, locale),
                            style: const TextStyle(fontSize: 11, decoration: TextDecoration.lineThrough, color: Color(0xFF999999)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 13, color: kGoldPrimary),
                        const SizedBox(width: 3),
                        Text(ArabicDigits.convert(product.rating, locale), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: kCharcoal)),
                        Text(' (${ArabicDigits.convert(product.reviewCount, locale)})', style: const TextStyle(fontSize: 11, color: Color(0xFF999999))),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: kCreamBg,
      child: Center(child: Icon(Icons.image_outlined, size: 40, color: kDivider)),
    );
  }
}
