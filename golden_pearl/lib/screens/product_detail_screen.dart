import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:video_player/video_player.dart';
import '../main.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../providers/cart_provider.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../utils/money_formatter.dart';
import '../utils/arabic_digits.dart';
import '../widgets/luxury_video_player.dart';

class ProductDetailScreen extends StatefulWidget {
  final int productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  Product? _product;
  bool _loading = true;
  bool _adding = false;
  String? _selectedSize;
  String? _selectedColor;
  int _quantity = 1;
  int _currentSlideIndex = 0;
  late PageController _pageController;

  List<_MediaSlide> _mediaSlides = [];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadProduct();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _buildMediaSlides(Product p) {
    _mediaSlides = [];
    if (p.videoUrl != null && p.videoUrl!.isNotEmpty) {
      final vUrl = p.videoUrl!.startsWith('http') ? p.videoUrl! : '${ApiService.baseUrl}${p.videoUrl!}';
      _mediaSlides.add(_MediaSlide(type: _MediaType.video, url: vUrl));
    }
    for (final img in p.images) {
      final url = img.startsWith('http') ? img : '${ApiService.baseUrl}$img';
      _mediaSlides.add(_MediaSlide(type: _MediaType.image, url: url));
    }
  }

  Future<void> _loadProduct() async {
    try {
      final product = await apiService.getProduct(widget.productId);
      if (mounted) {
        _buildMediaSlides(product);
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

  void _addToCart() async {
    if (_product == null || _selectedSize == null || _selectedColor == null || _adding) return;
    setState(() => _adding = true);
    final cart = Provider.of<CartProvider>(context, listen: false);
    final success = await cart.addToCart(_product!.id, _selectedSize!, _selectedColor!, quantity: _quantity);
    if (mounted && success) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.addedToBag),
          backgroundColor: kGoldPrimary,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 1800),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) Navigator.pop(context);
    } else {
      if (mounted) setState(() => _adding = false);
    }
  }

  void _openImageViewer(String imageUrl) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        barrierDismissible: true,
        pageBuilder: (context, animation, secondaryAnimation) {
          return _FullscreenImageViewer(imageUrl: imageUrl);
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 250),
      ),
    );
  }

  void _jumpToSlide(int index) {
    _pageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
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
    final hasVideo = p.videoUrl != null && p.videoUrl!.isNotEmpty;
    final totalSlides = p.images.length + (hasVideo ? 1 : 0);

    return Scaffold(
      body: CustomScrollView(
        physics: const ClampingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: MediaQuery.of(context).size.width * (5 / 4),
            pinned: true,
            backgroundColor: kCreamBg,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  PageView.builder(
                    itemCount: totalSlides,
                    onPageChanged: (i) => setState(() => _currentImageIndex = i),
                    itemBuilder: (context, index) {
                      // Video slide (last position)
                      if (hasVideo && index == totalSlides - 1) {
                        final videoSrc = p.videoUrl!.startsWith('http')
                            ? p.videoUrl!
                            : '${ApiService.baseUrl}${p.videoUrl!}';
                        final thumbUrl = p.images.isNotEmpty
                            ? (p.images[0].startsWith('http')
                                ? p.images[0]
                                : '${ApiService.baseUrl}${p.images[0]}')
                            : null;
                        return AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          child: LuxuryVideoPlayer(
                            key: ValueKey(videoSrc),
                            videoUrl: videoSrc,
                            thumbnailUrl: thumbUrl,
                          ),
                        );
                      }
                      // Image slides
                      final img = p.images[index];
                      final url = img.startsWith('http') ? img : '${ApiService.baseUrl}$img';
                      return Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: kCreamBg));
                    },
                  ),
                  if (totalSlides > 1)
                    Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(totalSlides, (i) {
                          final isVideo = hasVideo && i == totalSlides - 1;
                          final isActive = _currentImageIndex == i;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 280),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: isActive ? 20 : 6,
                            height: 3,
                            decoration: BoxDecoration(
                              color: isActive ? kGoldPrimary : Colors.white54,
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: isVideo && !isActive
                                ? Center(
                                    child: Container(
                                      width: 6,
                                      height: 3,
                                      decoration: BoxDecoration(
                                        color: Colors.white54,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  )
                                : null,
                          );
                        }),
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
          if (_mediaSlides.length > 1)
            SliverToBoxAdapter(
              child: Container(
                height: 72,
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _mediaSlides.length,
                  itemBuilder: (context, index) {
                    final slide = _mediaSlides[index];
                    final isSelected = _currentSlideIndex == index;
                    return GestureDetector(
                      onTap: () => _jumpToSlide(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 52,
                        height: 52,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? kGoldPrimary : kDivider,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(7),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              if (slide.type == _MediaType.image)
                                Image.network(slide.url, fit: BoxFit.cover, alignment: Alignment.topCenter, errorBuilder: (_, __, ___) => Container(color: kCreamBg))
                              else ...[
                                Container(color: const Color(0xFF2A2A2A)),
                                const Center(child: Icon(Icons.play_circle_fill, color: Colors.white70, size: 22)),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
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
                          style: const TextStyle(fontSize: 15, decoration: TextDecoration.lineThrough, color: kSecondaryText),
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
                            color: isSelected ? Colors.white : kSecondaryText,
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
                            color: isSelected ? kGoldDark : kSecondaryText,
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
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).padding.bottom),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Color(0x0F000000), blurRadius: 12, offset: Offset(0, -2))],
        ),
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
    );
  }
}

enum _MediaType { image, video }

class _MediaSlide {
  final _MediaType type;
  final String url;
  const _MediaSlide({required this.type, required this.url});
}

class _VideoSlideWidget extends StatefulWidget {
  final String videoUrl;
  const _VideoSlideWidget({required this.videoUrl});

  @override
  State<_VideoSlideWidget> createState() => _VideoSlideWidgetState();
}

class _VideoSlideWidgetState extends State<_VideoSlideWidget> {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _error = false;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      await _controller!.initialize();
      _controller!.addListener(() {
        if (mounted) setState(() {});
      });
      if (mounted) setState(() => _initialized = true);
    } catch (e) {
      if (mounted) setState(() => _error = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_controller == null || !_initialized) return;
    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
        _showControls = true;
      } else {
        _controller!.play();
        _showControls = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_error) {
      return Container(
        color: const Color(0xFF1C1C1C),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.videocam_off, color: Colors.white38, size: 48),
              SizedBox(height: 12),
              Text('تعذر تشغيل الفيديو', style: TextStyle(color: Colors.white54, fontSize: 14)),
            ],
          ),
        ),
      );
    }

    if (!_initialized) {
      return Container(
        color: const Color(0xFF1C1C1C),
        child: const Center(child: CircularProgressIndicator(color: kGoldPrimary)),
      );
    }

    return GestureDetector(
      onTap: () => setState(() => _showControls = !_showControls),
      child: Container(
        color: Colors.black,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: VideoPlayer(_controller!),
              ),
            ),
            if (_showControls || !_controller!.value.isPlaying)
              GestureDetector(
                onTap: _togglePlayPause,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _controller!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ),
            if (_initialized)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: VideoProgressIndicator(
                  _controller!,
                  allowScrubbing: true,
                  colors: const VideoProgressColors(
                    playedColor: kGoldPrimary,
                    bufferedColor: Colors.white24,
                    backgroundColor: Colors.white12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FullscreenImageViewer extends StatefulWidget {
  final String imageUrl;
  const _FullscreenImageViewer({required this.imageUrl});

  @override
  State<_FullscreenImageViewer> createState() => _FullscreenImageViewerState();
}

class _FullscreenImageViewerState extends State<_FullscreenImageViewer> {
  final TransformationController _controller = TransformationController();
  TapDownDetails? _doubleTapDetails;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    if (_controller.value != Matrix4.identity()) {
      _controller.value = Matrix4.identity();
    } else {
      final position = _doubleTapDetails?.localPosition ?? Offset.zero;
      _controller.value = Matrix4.identity()
        ..translate(-position.dx * 1.5, -position.dy * 1.5)
        ..scale(2.5);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          GestureDetector(
            onDoubleTapDown: (details) => _doubleTapDetails = details,
            onDoubleTap: _handleDoubleTap,
            onVerticalDragEnd: (details) {
              if (details.primaryVelocity != null && details.primaryVelocity!.abs() > 300) {
                Navigator.pop(context);
              }
            },
            child: Center(
              child: InteractiveViewer(
                transformationController: _controller,
                minScale: 0.5,
                maxScale: 5.0,
                child: Image.network(
                  widget.imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white54, size: 64),
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 8,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
              style: IconButton.styleFrom(backgroundColor: Colors.black45),
            ),
          ),
        ],
      ),
    );
  }
}
