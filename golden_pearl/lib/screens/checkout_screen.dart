import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../main.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../providers/cart_provider.dart';
import '../utils/money_formatter.dart';

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

  static const _shippingThreshold = 15000;
  static const _shippingFee = 1500;

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
    final shipping = cart.subtotal >= _shippingThreshold ? 0 : _shippingFee;
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

      final order = await apiService.createOrder({
        'items': items,
        'subtotal': cart.subtotal,
        'shipping': shipping,
        'discount': _discountAmount,
        'total': total,
        'customerName': _nameController.text,
        'customerEmail': _emailController.text,
        'customerPhone': _phoneController.text,
        'shippingAddress': _addressController.text,
        'shippingCity': _cityController.text,
        'shippingCountry': _countryController.text,
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
    final shipping = cart.subtotal >= _shippingThreshold ? 0 : _shippingFee;
    final total = cart.subtotal + shipping - _discountAmount;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.checkout)),
      body: Form(
        key: _formKey,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            Text(l10n.shippingAddress, style: playfairDisplay(fontSize: 20, fontWeight: FontWeight.w700, color: kCharcoal)),
            const SizedBox(height: 16),
            _buildField(l10n.fullName, _nameController, l10n.required),
            _buildField(l10n.email, _emailController, l10n.invalidEmail, keyboard: TextInputType.emailAddress),
            _buildField(l10n.phone, _phoneController, l10n.invalidPhone, keyboard: TextInputType.phone),
            _buildField(l10n.address, _addressController, l10n.required),
            Row(
              children: [
                Expanded(child: _buildField(l10n.city, _cityController, l10n.required)),
                const SizedBox(width: 12),
                Expanded(child: _buildField(l10n.country, _countryController, l10n.required)),
              ],
            ),
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
                      fillColor: Colors.white,
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
                color: Colors.white,
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
          fillColor: Colors.white,
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
