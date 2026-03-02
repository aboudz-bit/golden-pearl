import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../main.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../providers/cart_provider.dart';
import '../services/api_service.dart';
import '../utils/money_formatter.dart';
import '../utils/arabic_digits.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CartProvider>(context, listen: false).loadCart();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lang = Provider.of<LanguageProvider>(context).languageCode;
    final cart = Provider.of<CartProvider>(context);
    final shippingThreshold = 15000;
    final shippingFee = 1500;
    final shipping = cart.subtotal >= shippingThreshold ? 0 : shippingFee;
    final total = cart.subtotal + shipping;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.yourBag),
        actions: cart.items.isNotEmpty
            ? [
                TextButton(
                  onPressed: () => cart.clearCart(),
                  child: Text(l10n.clearAll, style: const TextStyle(color: kGoldPrimary)),
                ),
              ]
            : null,
      ),
      body: cart.loading
          ? const Center(child: CircularProgressIndicator(color: kGoldPrimary))
          : cart.items.isEmpty
              ? Center(
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
                                        Text('${item.size} · ${item.color}', style: const TextStyle(fontSize: 12, color: Color(0xFF8A8A8A))),
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
                ),
    );
  }
}
