import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../main.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../providers/cart_provider.dart';
import '../utils/money_formatter.dart';
import 'package:url_launcher/url_launcher.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _countryController = TextEditingController();
  final _discountController = TextEditingController();
  bool _submitting = false;
  int _discountAmount = 0;
  String? _discountError;
  bool _discountApplied = false;
  String _deliveryMethod = 'delivery';

  static const _shippingThreshold = 15000;
  static const _shippingFee = 1500;

  bool get _isPickup => _deliveryMethod == 'pickup';

  Future<void> _applyDiscount() async {
    final code = _discountController.text.trim();
    if (code.isEmpty) return;

    final result = await apiService.validateDiscount(code);
    final cart = Provider.of<CartProvider>(context, listen: false);
    final lang = Provider.of<LanguageProvider>(context, listen: false).languageCode;

    if (result != null) {
      final type = result['type'] as String;
      final value = (result['value'] as num).toInt();
      final minOrder = (result['minOrder'] as num?)?.toInt() ?? 0;

      if (cart.subtotal < minOrder) {
        setState(() {
          _discountError = '${AppLocalizations.of(context)!.subtotal}: ${MoneyFormatter.format(minOrder, lang)}';
          _discountApplied = false;
        });
        return;
      }

      int discount = type == 'percentage' ? (cart.subtotal * value / 100).round() : value;
      setState(() { _discountAmount = discount; _discountError = null; _discountApplied = true; });
    } else {
      setState(() { _discountError = AppLocalizations.of(context)!.invalidCode; _discountApplied = false; _discountAmount = 0; });
    }
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    final cart = Provider.of<CartProvider>(context, listen: false);
    final shipping = _isPickup ? 0 : (cart.subtotal >= _shippingThreshold ? 0 : _shippingFee);
    final total = cart.subtotal + shipping - _discountAmount;

    try {
      final items = cart.items.map((item) => {
        'productId': item.productId,
        'quantity': item.quantity,
        'size': item.size,
        'color': item.color,
        'price': item.product?.price ?? 0,
        'name': item.product?.nameEn ?? '',
      }).toList();

      final l10n = AppLocalizations.of(context)!;

      final order = await apiService.createOrder({
        'items': items,
        'subtotal': cart.subtotal,
        'shipping': shipping,
        'discount': _discountAmount,
        'total': total,
        'deliveryMethod': _deliveryMethod,
        'customerName': _nameController.text,
        'customerEmail': _emailController.text,
        'customerPhone': _phoneController.text,
        'shippingAddress': _isPickup ? l10n.storeAddress : _addressController.text,
        'shippingCity': _isPickup ? l10n.storeCity : _cityController.text,
        'shippingCountry': _isPickup ? 'Saudi Arabia' : _countryController.text,
        'discountCode': _discountApplied ? _discountController.text : null,
      });

      await cart.clearCart();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/order-confirmation', arguments: order);
      }
    } catch (e) {
      setState(() => _submitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.networkError),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lang = Provider.of<LanguageProvider>(context).languageCode;
    final cart = Provider.of<CartProvider>(context);
    final shipping = _isPickup ? 0 : (cart.subtotal >= _shippingThreshold ? 0 : _shippingFee);
    final total = cart.subtotal + shipping - _discountAmount;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.checkout)),
      body: Form(
        key: _formKey,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            Text(l10n.deliveryMethod, style: playfairDisplay(fontSize: 20, fontWeight: FontWeight.w700, color: kCharcoal)),
            const SizedBox(height: 12),
            _buildDeliveryToggle(l10n),
            const SizedBox(height: 24),

            if (_isPickup) ...[
              _buildStoreInfoCard(l10n),
              const SizedBox(height: 24),
            ],

            Text(
              _isPickup ? l10n.fullName : l10n.shippingAddress,
              style: playfairDisplay(fontSize: 20, fontWeight: FontWeight.w700, color: kCharcoal),
            ),
            const SizedBox(height: 16),
            _buildField(l10n.fullName, _nameController, l10n.required),
            _buildField(l10n.email, _emailController, l10n.invalidEmail, keyboard: TextInputType.emailAddress),
            _buildField(l10n.phone, _phoneController, l10n.invalidPhone, keyboard: TextInputType.phone),

            if (!_isPickup) ...[
              _buildField(l10n.address, _addressController, l10n.required),
              Row(
                children: [
                  Expanded(child: _buildField(l10n.city, _cityController, l10n.required)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildField(l10n.country, _countryController, l10n.required)),
                ],
              ),
            ],

            const SizedBox(height: 24),
            Text(l10n.discountCode, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _discountController,
                    decoration: InputDecoration(
                      hintText: 'WELCOME10',
                      filled: true,
                      fillColor: kCardBg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kDivider)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kDivider)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kGoldPrimary)),
                      errorText: _discountError,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _discountApplied ? null : _applyDiscount,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _discountApplied ? Colors.green : kGoldPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                  child: Text(_discountApplied ? '✓' : l10n.apply),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kCardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kDivider),
              ),
              child: Column(
                children: [
                  _summaryRow(l10n.subtotal, MoneyFormatter.format(cart.subtotal, lang)),
                  const SizedBox(height: 8),
                  _summaryRow(l10n.shipping, shipping == 0 ? l10n.freeShipping : MoneyFormatter.format(shipping, lang)),
                  if (_discountAmount > 0) ...[
                    const SizedBox(height: 8),
                    _summaryRow(l10n.discount, '-${MoneyFormatter.format(_discountAmount, lang)}', color: Colors.green),
                  ],
                  Divider(height: 24, color: kDivider),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(l10n.total, style: playfairDisplay(fontSize: 18, fontWeight: FontWeight.w700, color: kCharcoal)),
                      Text(MoneyFormatter.format(total, lang), style: playfairDisplay(fontSize: 20, fontWeight: FontWeight.w700, color: kGoldPrimary)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _submitting ? null : _placeOrder,
                child: _submitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(l10n.placeOrder),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryToggle(AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kDivider),
      ),
      child: Column(
        children: [
          _deliveryOption(
            icon: Icons.local_shipping_outlined,
            title: l10n.deliverToAddress,
            value: 'delivery',
            l10n: l10n,
          ),
          Divider(height: 0, color: kDivider),
          _deliveryOption(
            icon: Icons.store_outlined,
            title: l10n.storePickup,
            value: 'pickup',
            l10n: l10n,
          ),
        ],
      ),
    );
  }

  Widget _deliveryOption({
    required IconData icon,
    required String title,
    required String value,
    required AppLocalizations l10n,
  }) {
    final selected = _deliveryMethod == value;
    return InkWell(
      onTap: () => setState(() => _deliveryMethod = value),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: selected ? kGoldPrimary : kSecondaryText, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? kCharcoal : kSecondaryText,
                ),
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: selected ? kGoldPrimary : kDivider, width: 2),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: kGoldPrimary),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  static const _mapsUrl = 'https://maps.app.goo.gl/ZHro6TSLAqysY6MfA?g_st=ic';
  static const _storePhoneRaw = '0555012942';

  Future<void> _openMaps() async {
    final l10n = AppLocalizations.of(context)!;
    final url = Uri.parse(_mapsUrl);
    try {
      final launched = await launchUrl(url, mode: LaunchMode.platformDefault);
      if (!launched) {
        _showMapsFallback(l10n);
      }
    } catch (_) {
      _showMapsFallback(l10n);
    }
  }

  void _showMapsFallback(AppLocalizations l10n) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.mapOpenFailed),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: SnackBarAction(
          label: l10n.copyLink,
          textColor: Colors.white,
          onPressed: () {
            Clipboard.setData(const ClipboardData(text: _mapsUrl));
          },
        ),
      ),
    );
  }

  Future<void> _callStore() async {
    final telUrl = Uri.parse('tel:$_storePhoneRaw');
    try {
      final launched = await launchUrl(telUrl);
      if (!launched) {
        Clipboard.setData(const ClipboardData(text: '055 501 2942'));
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('055 501 2942'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    } catch (_) {
      Clipboard.setData(const ClipboardData(text: '055 501 2942'));
    }
  }

  Widget _buildStoreInfoCard(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kGoldPrimary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.store, color: kGoldPrimary, size: 22),
              const SizedBox(width: 8),
              Text(l10n.storeInfo, style: playfairDisplay(fontSize: 16, fontWeight: FontWeight.w600, color: kCharcoal)),
            ],
          ),
          const SizedBox(height: 14),
          _storeInfoRow(Icons.storefront, l10n.storeName),
          _storeInfoRow(Icons.location_on_outlined, l10n.storeAddress),
          _storeInfoRow(Icons.location_city, l10n.storeCity),
          _storeInfoRow(Icons.access_time, l10n.storeHours),
          GestureDetector(
            onTap: _callStore,
            child: _storeInfoRow(Icons.phone_outlined, l10n.storePhone, tappable: true),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _openMaps,
              icon: const Icon(Icons.map_outlined, size: 18),
              label: Text(l10n.openInMaps),
            ),
          ),
        ],
      ),
    );
  }

  Widget _storeInfoRow(IconData icon, String text, {bool tappable = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: tappable ? kGoldPrimary : kSecondaryText),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(fontSize: 13, color: tappable ? kGoldPrimary : kCharcoal, height: 1.4, decoration: tappable ? TextDecoration.underline : null))),
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, String errorMsg, {TextInputType? keyboard}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        validator: (v) => (v == null || v.isEmpty) ? errorMsg : null,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: kCardBg,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kDivider)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kDivider)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kGoldPrimary)),
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        Text(value, style: TextStyle(fontWeight: FontWeight.w600, color: color)),
      ],
    );
  }
}
