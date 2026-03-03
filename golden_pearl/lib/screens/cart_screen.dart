import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../main.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/favorites_provider.dart';
import '../services/api_service.dart';
import '../utils/money_formatter.dart';
import '../utils/arabic_digits.dart';
import '../models/product.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CartProvider>(context, listen: false).loadCart();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lang = Provider.of<LanguageProvider>(context).languageCode;
    final cart = Provider.of<CartProvider>(context);
    final favs = Provider.of<FavoritesProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.yourBag),
        actions: _tabController.index == 0 && cart.items.isNotEmpty
            ? [
                TextButton(
                  onPressed: () => cart.clearCart(),
                  child: Text(l10n.clearAll, style: const TextStyle(color: kGoldPrimary)),
                ),
              ]
            : null,
        bottom: TabBar(
          controller: _tabController,
          onTap: (_) => setState(() {}),
          labelColor: kGoldPrimary,
          unselectedLabelColor: kSecondaryText,
          indicatorColor: kGoldPrimary,
          indicatorWeight: 2.5,
          labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 14),
          tabs: [
            Tab(text: '${l10n.cart} (${ArabicDigits.convert(cart.itemCount, lang)})'),
            Tab(text: '${l10n.wishlist} (${ArabicDigits.convert(favs.favoriteIds.length, lang)})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCartTab(context, l10n, lang, cart),
          _buildFavoritesTab(context, l10n, lang, favs),
        ],
      ),
    );
  }

  Widget _buildCartTab(BuildContext context, AppLocalizations l10n, String lang, CartProvider cart) {
    final shippingThreshold = 15000;
    final shippingFee = 1500;
    final shipping = cart.subtotal >= shippingThreshold ? 0 : shippingFee;
    final total = cart.subtotal + shipping;

    if (cart.loading) {
      return const Center(child: CircularProgressIndicator(color: kGoldPrimary));
    }

    if (cart.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shopping_cart_outlined, size: 80, color: kDivider),
            const SizedBox(height: 16),
            Text(l10n.emptyBag, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(l10n.continueShopping, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: cart.items.length,
            itemBuilder: (context, index) {
              final item = cart.items[index];
              final product = item.product;
              if (product == null) return const SizedBox();

              final imgUrl = product.images.isNotEmpty
                  ? (product.images[0].startsWith('http') ? product.images[0] : '${ApiService.baseUrl}${product.images[0]}')
                  : '';

              return Dismissible(
                key: Key('cart-${item.id}'),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: cart.items.length,
                        itemBuilder: (context, index) {
                          final item = cart.items[index];
                          final product = item.product;
                          if (product == null) return const SizedBox();

                          final imgUrl = product.images.isNotEmpty
                              ? (product.images[0].startsWith('http') ? product.images[0] : '${ApiService.baseUrl}${product.images[0]}')
                              : '';

                          return Dismissible(
                            key: Key('cart-${item.id}'),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.delete_outline, color: Colors.red.shade400),
                            ),
                            onDismissed: (_) => cart.removeItem(item.id),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
                              ),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: imgUrl.isNotEmpty
                                        ? Image.network(imgUrl, width: 80, height: 100, fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => Container(width: 80, height: 100, color: kCreamBg))
                                        : Container(width: 80, height: 100, color: kCreamBg),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(product.name(lang), style: playfairDisplay(fontSize: 14, fontWeight: FontWeight.w600, color: kCharcoal), maxLines: 2, overflow: TextOverflow.ellipsis),
                                        const SizedBox(height: 4),
                                        Text('${item.size} · ${item.color}', style: const TextStyle(fontSize: 12, color: kSecondaryText)),
                                        const SizedBox(height: 10),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Container(
                                              decoration: BoxDecoration(
                                                border: Border.all(color: kDivider),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  InkWell(
                                                    onTap: () {
                                                      if (item.quantity <= 1) {
                                                        cart.removeItem(item.id);
                                                      } else {
                                                        cart.updateQuantity(item.id, item.quantity - 1);
                                                      }
                                                    },
                                                    child: const Padding(padding: EdgeInsets.all(6), child: Icon(Icons.remove, size: 16)),
                                                  ),
                                                  Padding(
                                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                                    child: Text(ArabicDigits.convert(item.quantity, lang), style: const TextStyle(fontWeight: FontWeight.w600)),
                                                  ),
                                                  InkWell(
                                                    onTap: () => cart.updateQuantity(item.id, item.quantity + 1),
                                                    child: const Padding(padding: EdgeInsets.all(6), child: Icon(Icons.add, size: 16)),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Text(
                                              MoneyFormatter.format(product.price * item.quantity, lang),
                                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kGoldPrimary),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(context).padding.bottom),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        boxShadow: [BoxShadow(color: Color(0x0F000000), blurRadius: 12, offset: Offset(0, -2))],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(l10n.subtotal, style: Theme.of(context).textTheme.bodyLarge),
                              Text(MoneyFormatter.format(cart.subtotal, lang), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(l10n.shipping, style: Theme.of(context).textTheme.bodyLarge),
                              Text(
                                shipping == 0 ? l10n.freeShipping : MoneyFormatter.format(shipping, lang),
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: shipping == 0 ? Colors.green : null),
                              ),
                            ],
                          ),
                          Divider(height: 24, color: kDivider),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(l10n.total, style: playfairDisplay(fontSize: 18, fontWeight: FontWeight.w700, color: kCharcoal)),
                              Text(MoneyFormatter.format(total, lang), style: playfairDisplay(fontSize: 20, fontWeight: FontWeight.w700, color: kGoldPrimary)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: () => Navigator.pushNamed(context, '/checkout'),
                              child: Text(l10n.proceedToCheckout),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Color(0x0F000000), blurRadius: 12, offset: Offset(0, -2))],
          ),
          child: SafeArea(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(l10n.subtotal, style: Theme.of(context).textTheme.bodyLarge),
                    Text(MoneyFormatter.format(cart.subtotal, lang), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(l10n.shipping, style: Theme.of(context).textTheme.bodyLarge),
                    Text(
                      shipping == 0 ? l10n.freeShipping : MoneyFormatter.format(shipping, lang),
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: shipping == 0 ? Colors.green : null),
                    ),
                  ],
                ),
                Divider(height: 24, color: kDivider),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(l10n.total, style: playfairDisplay(fontSize: 18, fontWeight: FontWeight.w700, color: kCharcoal)),
                    Text(MoneyFormatter.format(total, lang), style: playfairDisplay(fontSize: 20, fontWeight: FontWeight.w700, color: kGoldPrimary)),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/checkout'),
                    child: Text(l10n.proceedToCheckout),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFavoritesTab(BuildContext context, AppLocalizations l10n, String lang, FavoritesProvider favs) {
    if (favs.favoriteProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.favorite_border, size: 80, color: kDivider),
            const SizedBox(height: 16),
            Text(l10n.noFavorites, style: Theme.of(context).textTheme.headlineMedium),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: favs.favoriteProducts.length,
      itemBuilder: (context, index) {
        final product = favs.favoriteProducts[index];
        final imgUrl = product.images.isNotEmpty
            ? (product.images[0].startsWith('http') ? product.images[0] : '${ApiService.baseUrl}${product.images[0]}')
            : '';

        return GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/product/${product.id}'),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: imgUrl.isNotEmpty
                      ? Image.network(imgUrl, width: 80, height: 100, fit: BoxFit.cover, alignment: Alignment.topCenter,
                          errorBuilder: (_, __, ___) => Container(width: 80, height: 100, color: kCreamBg))
                      : Container(width: 80, height: 100, color: kCreamBg),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product.name(lang), style: playfairDisplay(fontSize: 14, fontWeight: FontWeight.w600, color: kCharcoal), maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 6),
                      Text(MoneyFormatter.format(product.price, lang), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kGoldPrimary)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 36,
                              child: ElevatedButton.icon(
                                onPressed: () => _addFavToCart(product),
                                icon: const Icon(Icons.add_shopping_cart, size: 16),
                                label: Text(l10n.addToBag, style: const TextStyle(fontSize: 12)),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            height: 36,
                            width: 36,
                            child: IconButton(
                              onPressed: () => favs.toggleFavorite(product.id),
                              icon: const Icon(Icons.close, size: 18),
                              style: IconButton.styleFrom(
                                backgroundColor: kCreamBg,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _addFavToCart(Product product) {
    if (product.sizes.length <= 1 && product.colors.length <= 1) {
      _addProductDirectly(
        product,
        product.sizes.isNotEmpty ? product.sizes[0] : 'One Size',
        product.colors.isNotEmpty ? product.colors[0] : 'Default',
      );
    } else {
      _showFavQuickSelect(product);
    }
  }

  void _addProductDirectly(Product product, String size, String color) async {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;
    final success = await cart.addToCart(product.id, size, color);
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

  void _showFavQuickSelect(Product product) {
    final lang = Provider.of<LanguageProvider>(context, listen: false).languageCode;
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
                Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: kDivider, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 16),
                Text(product.name(lang), style: playfairDisplay(fontSize: 16, fontWeight: FontWeight.w600, color: kCharcoal)),
                const SizedBox(height: 16),
                if (product.sizes.length > 1) ...[
                  Text(l10n.size, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kCharcoal)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: product.sizes.map((size) {
                      final isSel = selectedSize == size;
                      return GestureDetector(
                        onTap: () => setSheetState(() => selectedSize = size),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(color: isSel ? kCharcoal : Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: isSel ? kCharcoal : kDivider)),
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
                    spacing: 8, runSpacing: 8,
                    children: product.colors.map((color) {
                      final isSel = selectedColor == color;
                      return GestureDetector(
                        onTap: () => setSheetState(() => selectedColor = color),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(color: isSel ? kGoldPrimary.withOpacity(0.12) : Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: isSel ? kGoldPrimary : kDivider, width: isSel ? 2 : 1)),
                          child: Text(color, style: TextStyle(fontSize: 13, color: isSel ? kGoldDark : const Color(0xFF4A4A4A), fontWeight: isSel ? FontWeight.w600 : FontWeight.normal)),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],
                SizedBox(
                  width: double.infinity, height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () { Navigator.pop(ctx); _addProductDirectly(product, selectedSize, selectedColor); },
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
}
