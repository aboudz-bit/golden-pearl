import 'package:flutter/material.dart';
import '../main.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../utils/money_formatter.dart';
import '../utils/arabic_digits.dart';
import 'shimmer_placeholder.dart';

class ProductCard extends StatefulWidget {
  final Product product;
  final String locale;

  const ProductCard({super.key, required this.product, required this.locale});

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  double _scale = 1.0;
  bool _imageLoaded = false;

  String get _imageUrl {
    if (widget.product.images.isNotEmpty) {
      final img = widget.product.images[0];
      if (img.startsWith('http')) return img;
      return '${ApiService.baseUrl}$img';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final locale = widget.locale;
    final hasDiscount = product.originalPrice != null && product.originalPrice! > product.price;

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
            color: kCreamBg,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
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
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      child: _imageUrl.isNotEmpty
                          ? AnimatedOpacity(
                              opacity: _imageLoaded ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 300),
                              child: Image.network(
                                _imageUrl,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
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
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                          child: ShimmerPlaceholder(borderRadius: BorderRadius.zero),
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
      child: const Center(child: Icon(Icons.image_outlined, size: 40, color: Color(0xFFCCCCCC))),
    );
  }
}
