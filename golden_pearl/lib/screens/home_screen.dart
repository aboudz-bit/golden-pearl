import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../main.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../services/api_service.dart';
import '../models/product.dart';
import '../widgets/product_card.dart';
import 'shop_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Product> _featured = [];
  Map<String, String> _categoryImages = {};
  bool _loading = true;
  final PageController _heroController = PageController();
  int _currentHeroPage = 0;

  // Category product images cache
  Map<String, String> _categoryImages = {};

  @override
  void initState() {
    super.initState();
    _loadFeatured();
    _loadCategoryImages();
    _startHeroAutoScroll();
  }

  Future<void> _loadCategoryImages() async {
    try {
      final products = await apiService.getProducts();
      final Map<String, String> images = {};
      for (final cat in ['dresses', 'jalabiyas', 'kids', 'gifts']) {
        final catProducts = products.where((p) => p.category == cat).toList();
        if (catProducts.isNotEmpty && catProducts[0].images.isNotEmpty) {
          final img = catProducts[0].images[0];
          images[cat] = img.startsWith('http') ? img : '${ApiService.baseUrl}$img';
        }
      }
      if (mounted) setState(() => _categoryImages = images);
    } catch (e) {}
  }

  void _startHeroAutoScroll() {
    Future.delayed(const Duration(seconds: 5), () {
      if (!mounted) return;
      final nextPage = (_currentHeroPage + 1) % 3;
      _heroController.animateToPage(nextPage, duration: const Duration(milliseconds: 600), curve: Curves.easeInOut);
      _startHeroAutoScroll();
    });
  }

  Future<void> _loadFeatured() async {
    try {
      final products = await apiService.getProducts(featured: true);
      if (mounted) setState(() { _featured = products; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadCategoryImages() async {
    try {
      final allProducts = await apiService.getProducts();
      final images = <String, String>{};
      for (final cat in ['dresses', 'jalabiyas', 'kids', 'gifts']) {
        final match = allProducts.where((p) => p.category == cat && p.images.isNotEmpty).toList();
        if (match.isNotEmpty) {
          final img = match.first.images.first;
          images[cat] = img.startsWith('http') ? img : '${ApiService.baseUrl}$img';
        }
      }
      if (mounted) setState(() => _categoryImages = images);
    } catch (_) {}
  }

  @override
  void dispose() {
    _heroController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lang = Provider.of<LanguageProvider>(context).languageCode;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: size.height * 0.55,
            pinned: true,
            stretch: true,
            backgroundColor: kCreamBg,
            title: Text(l10n.appName, style: playfairDisplay(fontWeight: FontWeight.w700, color: kCharcoal)),
            actions: [
              IconButton(
                icon: Icon(Icons.language, color: kSecondaryText),
                onPressed: () => Provider.of<LanguageProvider>(context, listen: false).toggleLanguage(),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  PageView(
                    controller: _heroController,
                    onPageChanged: (i) => setState(() => _currentHeroPage = i),
                    children: [
                      _HeroSlide(image: 'assets/images/hero1.png', title: l10n.heroTitle, subtitle: l10n.heroSubtitle),
                      _HeroSlide(image: 'assets/images/hero2.png', title: l10n.eidCollection, subtitle: l10n.heroSubtitle),
                      _HeroSlide(image: 'assets/images/hero3.png', title: l10n.newDrop, subtitle: l10n.exploreCollection),
                    ],
                  ),
                  Positioned(
                    bottom: 72,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 280),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentHeroPage == i ? 24 : 8,
                        height: 3,
                        decoration: BoxDecoration(
                          color: _currentHeroPage == i ? Colors.white : Colors.white54,
                          borderRadius: BorderRadius.circular(2),
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
              ),
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
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                children: [
                  _CategoryCircle(label: l10n.dresses, imageUrl: _categoryImages['dresses'], category: 'dresses'),
                  _CategoryCircle(label: l10n.jalabiyas, imageUrl: _categoryImages['jalabiyas'], category: 'jalabiyas'),
                  _CategoryCircle(label: l10n.kids, imageUrl: _categoryImages['kids'], category: 'kids'),
                  _CategoryCircle(label: l10n.gifts, imageUrl: _categoryImages['gifts'], category: 'gifts'),
                ],
              ),
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
}

class _HeroSlide extends StatelessWidget {
  final String image;
  final String title;
  final String subtitle;

  const _HeroSlide({required this.image, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(image, fit: BoxFit.cover),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Colors.black.withOpacity(0.6), Colors.black.withOpacity(0.05)],
            ),
          ),
        ),
        Positioned(
          bottom: 110,
          left: 24,
          right: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                title,
                style: playfairDisplay(fontSize: 30, fontWeight: FontWeight.w700, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(subtitle, style: const TextStyle(fontSize: 14, color: Colors.white70, height: 1.4), textAlign: TextAlign.center),
            ],
          ),
        ),
      ],
    );
  }
}

/// Large circular category with real product image (96-110px).
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
    final isSelected = false; // No selection state on home
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
                  border: isSelected
                      ? Border.all(color: kGoldPrimary, width: 2)
                      : null,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 2)),
                  ],
                ),
                child: ClipOval(
                  child: widget.imageUrl != null
                      ? Image.network(
                          widget.imageUrl!,
                          width: 96,
                          height: 96,
                          fit: BoxFit.cover,
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
      color: kDivider,
      child: Icon(Icons.category_outlined, color: kSecondaryText, size: 32),
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
