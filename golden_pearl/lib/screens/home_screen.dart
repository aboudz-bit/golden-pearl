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

  @override
  void initState() {
    super.initState();
    _loadFeatured();
    _loadBanners();
    _loadCategories();
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lang = Provider.of<LanguageProvider>(context).languageCode;
    final size = MediaQuery.of(context).size;
    final hasBanners = _banners.isNotEmpty;

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
              background: hasBanners ? _buildBannerCarousel(size, l10n, topPadding) : _buildDefaultHero(size, l10n, topPadding),
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

  Widget _buildHeroOverlay(AppLocalizations l10n, double topPadding, {bool showDots = false}) {
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
        Positioned(
          bottom: 90,
          left: 24,
          right: 24,
          child: SafeArea(
            top: true,
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  l10n.heroTitle,
                  style: playfairDisplay(fontSize: 30, fontWeight: FontWeight.w700, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(l10n.heroSubtitle, style: const TextStyle(fontSize: 14, color: Colors.white70, height: 1.4), textAlign: TextAlign.center),
              ],
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
              child: Text(l10n.shopNow),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBannerCarousel(Size size, AppLocalizations l10n, double topPadding) {
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
        _buildHeroOverlay(l10n, topPadding, showDots: true),
      ],
    );
  }

  Widget _buildDefaultHero(Size size, AppLocalizations l10n, double topPadding) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const HeroVideoBackground(),
        _buildHeroOverlay(l10n, topPadding),
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
