import 'package:flutter/material.dart';
import 'dart:ui';
import '../l10n/generated/app_localizations.dart';
import '../main.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../services/api_service.dart';
import '../models/product.dart';
import '../widgets/product_card.dart';
import '../widgets/hero_video_background.dart';
import 'shop_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Product> _featured = [];
  bool _loading = true;
  List<Map<String, dynamic>> _banners = [];
  List<Map<String, dynamic>> _categories = [];
  int _currentBanner = 0;
  final PageController _bannerController = PageController();
  Map<String, dynamic>? _heroOverlay;

  @override
  void initState() {
    super.initState();
    _loadFeatured();
    _loadBanners();
    _loadCategories();
    _loadHeroOverlay();
  }

  @override
  void dispose() {
    _bannerController.dispose();
    super.dispose();
  }

  Future<void> _loadFeatured() async {
    try {
      final products = await apiService.getProducts(featured: true);
      if (mounted) setState(() { _featured = products; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadBanners() async {
    try {
      final banners = await apiService.getPublicBanners();
      if (mounted) setState(() => _banners = banners);
    } catch (_) {}
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await apiService.getPublicCategories();
      if (mounted) setState(() => _categories = categories);
    } catch (_) {}
  }

  Future<void> _loadHeroOverlay() async {
    try {
      final overlay = await apiService.getHeroOverlay();
      if (mounted && overlay != null) setState(() => _heroOverlay = overlay);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lang = Provider.of<LanguageProvider>(context).languageCode;
    final size = MediaQuery.of(context).size;
    final hasBanners = _banners.isNotEmpty;
    final overlayLang = _heroOverlay?[lang] as Map<String, dynamic>?;

    final heroHeight = size.width > 800
        ? (size.height * 0.65).clamp(520.0, 650.0)
        : (size.height * 0.5).clamp(size.height * 0.45, size.height * 0.55);
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: heroHeight,
            pinned: true,
            stretch: true,
            backgroundColor: kCreamBg,
            title: Text(l10n.appName, style: playfairDisplay(fontWeight: FontWeight.w700, color: kCharcoal)),
            actions: const [],
            flexibleSpace: FlexibleSpaceBar(
              background: hasBanners
                  ? _buildBannerCarousel(size, l10n, topPadding, overlayLang)
                  : _buildDefaultHero(size, l10n, topPadding, overlayLang),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Text(l10n.categories, style: playfairDisplay(fontSize: 20, fontWeight: FontWeight.w600, color: kCharcoal)),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 140,
              child: _buildCategoryList(l10n, lang),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l10n.featuredPieces, style: playfairDisplay(fontSize: 20, fontWeight: FontWeight.w600, color: kCharcoal)),
                  TextButton(
                    onPressed: () => Navigator.push(context, PageRouteBuilder(
                      pageBuilder: (_, __, ___) => const ShopScreen(),
                      transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
                      transitionDuration: const Duration(milliseconds: 280),
                    )),
                    child: Text(l10n.viewAll, style: TextStyle(color: kSecondaryText, fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
            ),
          ),
          if (_loading)
            const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: kGoldPrimary))))
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.52,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => ProductCard(product: _featured[index], locale: lang),
                  childCount: _featured.length,
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: kCardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kDivider),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                children: [
                  Image.asset('assets/images/logo.png', height: 72),
                  const SizedBox(height: 16),
                  Text(l10n.appName, style: playfairDisplay(fontSize: 22, fontWeight: FontWeight.w700, color: kCharcoal)),
                  const SizedBox(height: 8),
                  Text(l10n.aboutBrand, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _ServiceBadge(icon: Icons.local_shipping_outlined, label: l10n.shippingInfo),
                      _ServiceBadge(icon: Icons.replay, label: l10n.returnPolicy),
                      _ServiceBadge(icon: Icons.lock_outline, label: l10n.securePayment),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
        ],
      ),
    );
  }

  Widget _buildContainedNetworkImage(String fullUrl) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRect(
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.3),
                BlendMode.darken,
              ),
              child: Image.network(fullUrl, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
            ),
          ),
        ),
        Center(
          child: Image.network(
            fullUrl,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Container(
              color: kCharcoal,
              child: const Center(child: Icon(Icons.image, color: Colors.white30, size: 48)),
            ),
          ),
        ),
      ],
    );
  }

  Color _hexToColor(String hex, {double opacity = 1.0}) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    final c = Color(int.parse(hex, radix: 16));
    return c.withOpacity(opacity);
  }

  TextStyle _heroTextStyle(Map<String, dynamic>? style, double baseSize, {bool isHeadline = true}) {
    if (style == null) {
      return isHeadline
          ? playfairDisplay(fontSize: baseSize, fontWeight: FontWeight.w700, color: Colors.white)
          : TextStyle(fontSize: baseSize, color: Colors.white70, height: 1.4);
    }

    final screenW = MediaQuery.of(context).size.width;
    final scaleFactor = (screenW / 400).clamp(0.7, 1.3);
    final size = (baseSize * scaleFactor).clamp(isHeadline ? 22.0 : 12.0, isHeadline ? 44.0 : 22.0);
    final color = _hexToColor(style['color'] as String? ?? '#FFFFFF');
    final weight = FontWeight.values[((style['fontWeight'] as num? ?? 700) ~/ 100).clamp(1, 8)];
    final spacing = (style['letterSpacing'] as num?)?.toDouble() ?? 0;
    final fontFamily = style['fontFamily'] as String? ?? 'Playfair';

    List<Shadow>? shadows;
    final shadowMap = style['shadow'] as Map<String, dynamic>?;
    if (shadowMap != null && shadowMap['enabled'] == true) {
      final sColor = _hexToColor(
        shadowMap['color'] as String? ?? '#000000',
        opacity: (shadowMap['opacity'] as num?)?.toDouble() ?? 0.5,
      );
      shadows = [
        Shadow(
          color: sColor,
          blurRadius: (shadowMap['blur'] as num?)?.toDouble() ?? 8,
          offset: Offset(
            (shadowMap['offsetX'] as num?)?.toDouble() ?? 0,
            (shadowMap['offsetY'] as num?)?.toDouble() ?? 2,
          ),
        ),
      ];
    }

    if (fontFamily == 'Playfair') {
      return playfairDisplay(fontSize: size, fontWeight: weight, color: color).copyWith(
        letterSpacing: spacing,
        shadows: shadows,
      );
    }

    return TextStyle(
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: spacing,
      shadows: shadows,
      height: isHeadline ? null : 1.4,
    );
  }

  Alignment _presetToAlignment(String preset, double xOff, double yOff) {
    double x = 0, y = 0;
    switch (preset) {
      case 'TopLeft':       x = -1; y = -1; break;
      case 'TopCenter':     x = 0;  y = -1; break;
      case 'TopRight':      x = 1;  y = -1; break;
      case 'CenterLeft':    x = -1; y = 0;  break;
      case 'Center':        x = 0;  y = 0;  break;
      case 'CenterRight':   x = 1;  y = 0;  break;
      case 'BottomLeft':    x = -1; y = 1;  break;
      case 'BottomCenter':  x = 0;  y = 1;  break;
      case 'BottomRight':   x = 1;  y = 1;  break;
    }
    return Alignment(
      (x + xOff / 50).clamp(-1.0, 1.0),
      (y + yOff / 50).clamp(-1.0, 1.0),
    );
  }

  TextAlign _parseAlign(String? align) {
    switch (align) {
      case 'left': return TextAlign.left;
      case 'right': return TextAlign.right;
      default: return TextAlign.center;
    }
  }

  CrossAxisAlignment _parseCross(String? align) {
    switch (align) {
      case 'left': return CrossAxisAlignment.start;
      case 'right': return CrossAxisAlignment.end;
      default: return CrossAxisAlignment.center;
    }
  }

  Widget _buildHeroOverlay(AppLocalizations l10n, double topPadding, Map<String, dynamic>? overlayLang, {bool showDots = false}) {
    final headline = overlayLang?['headline'] as String? ?? l10n.heroTitle;
    final subheadline = overlayLang?['subheadline'] as String? ?? l10n.heroSubtitle;
    final cta = overlayLang?['cta'] as String?;
    final ctaText = (cta != null && cta.isNotEmpty) ? cta : l10n.shopNow;
    final style = overlayLang?['style'] as Map<String, dynamic>?;
    final textAlign = _parseAlign(style?['align'] as String?);
    final crossAlign = _parseCross(style?['align'] as String?);

    final preset = style?['positionPreset'] as String? ?? 'BottomCenter';
    final xOff = (style?['offsetXPercent'] as num?)?.toDouble() ?? 0;
    final yOff = (style?['offsetYPercent'] as num?)?.toDouble() ?? 0;
    final alignment = _presetToAlignment(preset, xOff, yOff);

    final headlineSize = (style?['headlineSize'] as num?)?.toDouble() ?? 30;
    final subSize = (style?['subheadlineSize'] as num?)?.toDouble() ?? 14;

    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              stops: const [0.0, 0.45],
              colors: [Colors.black.withOpacity(0.65), Colors.transparent],
            ),
          ),
        ),
        SafeArea(
          child: Align(
            alignment: alignment,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: crossAlign,
                children: [
                  Text(
                    headline,
                    style: _heroTextStyle(style, headlineSize, isHeadline: true),
                    textAlign: textAlign,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subheadline,
                    style: _heroTextStyle(style, subSize, isHeadline: false),
                    textAlign: textAlign,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (showDots && _banners.length > 1)
          Positioned(
            bottom: 66,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_banners.length, (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _currentBanner ? 20 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: i == _currentBanner ? kGoldPrimary : Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(3),
                ),
              )),
            ),
          ),
        Positioned(
          bottom: 20,
          left: 0,
          right: 0,
          child: Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(context, PageRouteBuilder(
                  pageBuilder: (_, __, ___) => const ShopScreen(),
                  transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
                  transitionDuration: const Duration(milliseconds: 280),
                ));
              },
              child: Text(ctaText),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBannerCarousel(Size size, AppLocalizations l10n, double topPadding, Map<String, dynamic>? overlayLang) {
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          controller: _bannerController,
          itemCount: _banners.length,
          onPageChanged: (i) => setState(() => _currentBanner = i),
          itemBuilder: (context, index) {
            final banner = _banners[index];
            final url = banner['url'] as String? ?? '';
            final type = banner['type'] as String? ?? 'image';
            final fullUrl = url.startsWith('http') ? url : '${ApiService.baseUrl}$url';

            if (type == 'video') {
              return HeroVideoBackground(videoUrl: fullUrl);
            }

            return _buildContainedNetworkImage(fullUrl);
          },
        ),
        _buildHeroOverlay(l10n, topPadding, overlayLang, showDots: true),
      ],
    );
  }

  Widget _buildDefaultHero(Size size, AppLocalizations l10n, double topPadding, Map<String, dynamic>? overlayLang) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const HeroVideoBackground(),
        _buildHeroOverlay(l10n, topPadding, overlayLang),
      ],
    );
  }

  Widget _buildCategoryList(AppLocalizations l10n, String lang) {
    if (_categories.isNotEmpty) {
      return ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: _categories.map((cat) {
          final slug = cat['slug'] as String? ?? '';
          final name = lang == 'ar' ? (cat['nameAr'] ?? slug) : (cat['nameEn'] ?? slug);
          final imageUrl = cat['imageUrl'] as String?;
          String? fullImgUrl;
          if (imageUrl != null && imageUrl.isNotEmpty) {
            fullImgUrl = imageUrl.startsWith('http') ? imageUrl : '${ApiService.baseUrl}$imageUrl';
          }
          return _CategoryCircle(label: name.toString(), imageUrl: fullImgUrl, category: slug);
        }).toList(),
      );
    }

    return ListView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      children: [
        _CategoryCircle(label: l10n.dresses, category: 'dresses'),
        _CategoryCircle(label: l10n.jalabiyas, category: 'jalabiyas'),
        _CategoryCircle(label: l10n.kids, category: 'kids'),
        _CategoryCircle(label: l10n.gifts, category: 'gifts'),
      ],
    );
  }
}

class _CategoryCircle extends StatefulWidget {
  final String label;
  final String? imageUrl;
  final String category;

  const _CategoryCircle({required this.label, this.imageUrl, required this.category});

  @override
  State<_CategoryCircle> createState() => _CategoryCircleState();
}

class _CategoryCircleState extends State<_CategoryCircle> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.95),
      onTapUp: (_) {
        setState(() => _scale = 1.0);
        Navigator.pushNamed(context, '/category/${widget.category}');
      },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        child: Container(
          width: 100,
          margin: const EdgeInsets.only(right: 16),
          child: Column(
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: kCreamBg,
                  border: Border.all(color: kGoldPrimary.withOpacity(0.3), width: 2),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2)),
                  ],
                ),
                child: ClipOval(
                  child: widget.imageUrl != null
                      ? Image.network(
                          widget.imageUrl!,
                          width: 96,
                          height: 96,
                          fit: BoxFit.cover,
                          alignment: Alignment.topCenter,
                          errorBuilder: (_, __, ___) => _fallback(),
                        )
                      : _fallback(),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.label,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: kCharcoal),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fallback() {
    return Container(
      width: 96,
      height: 96,
      color: kCreamBg,
      child: Icon(Icons.category, color: kGoldPrimary.withOpacity(0.4), size: 32),
    );
  }
}

class _ServiceBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ServiceBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 22, color: kSecondaryText),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(fontSize: 10, color: kSecondaryText), textAlign: TextAlign.center, maxLines: 2),
        ],
      ),
    );
  }
}
