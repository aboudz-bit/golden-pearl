import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../main.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/language_provider.dart';
import '../providers/cart_provider.dart';
import '../utils/money_formatter.dart';
import '../models/store.dart';

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

  // Fulfillment
  String _fulfillmentType = 'delivery';
  List<Store> _stores = [];
  Store? _selectedStore;
  bool _loadingStores = false;

  static const _shippingThreshold = 15000;
  static const _shippingFee = 1500;

  @override
  void initState() {
    super.initState();
    _loadStores();
  }

  Future<void> _loadStores() async {
    setState(() => _loadingStores = true);
    try {
      final stores = await apiService.getStores();
      if (mounted) {
        setState(() {
          _stores = stores;
          _loadingStores = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingStores = false);
    }
  }

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
    if (_fulfillmentType == 'pickup' && _selectedStore == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.selectStore),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    setState(() => _submitting = true);

    final cart = Provider.of<CartProvider>(context, listen: false);
    final lang = Provider.of<LanguageProvider>(context, listen: false).languageCode;
    final shipping = _fulfillmentType == 'pickup' ? 0 : (cart.subtotal >= _shippingThreshold ? 0 : _shippingFee);
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

      final orderData = <String, dynamic>{
        'items': items,
        'subtotal': cart.subtotal,
        'shipping': shipping,
        'discount': _discountAmount,
        'total': total,
        'customerName': _nameController.text,
        'customerEmail': _emailController.text,
        'customerPhone': _phoneController.text,
        'fulfillmentType': _fulfillmentType,
        'discountCode': _discountApplied ? _discountController.text : null,
      };

      if (_fulfillmentType == 'delivery') {
        orderData['shippingAddress'] = _addressController.text;
        orderData['shippingCity'] = _cityController.text;
        orderData['shippingCountry'] = _countryController.text;
      } else {
        orderData['pickupStoreId'] = _selectedStore!.id;
        orderData['pickupStoreName'] = _selectedStore!.name(lang);
        orderData['pickupAddress'] = _selectedStore!.address(lang);
        orderData['pickupHours'] = _selectedStore!.hours(lang);
        orderData['shippingAddress'] = '';
        orderData['shippingCity'] = '';
        orderData['shippingCountry'] = '';
      }

      final order = await apiService.createOrder(orderData);

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
    final shipping = _fulfillmentType == 'pickup' ? 0 : (cart.subtotal >= _shippingThreshold ? 0 : _shippingFee);
    final total = cart.subtotal + shipping - _discountAmount;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.checkout)),
      body: Form(
        key: _formKey,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            // Fulfillment type selector
            Text(l10n.deliveryMethod, style: playfairDisplay(fontSize: 20, fontWeight: FontWeight.w700, color: kCharcoal)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _fulfillmentOption('delivery', l10n.delivery, Icons.local_shipping_outlined)),
                const SizedBox(width: 12),
                Expanded(child: _fulfillmentOption('pickup', l10n.storePickup, Icons.store_outlined)),
              ],
            ),
            const SizedBox(height: 24),

            // Pickup store selector
            if (_fulfillmentType == 'pickup') ...[
              Text(l10n.selectStore, style: playfairDisplay(fontSize: 18, fontWeight: FontWeight.w600, color: kCharcoal)),
              const SizedBox(height: 12),
              if (_loadingStores)
                const Center(child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(color: kGoldPrimary),
                ))
              else if (_stores.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(l10n.noStoresAvailable, style: const TextStyle(color: kSecondaryText)),
                )
              else
                ..._stores.map((store) => _storeCard(store, lang)),
              if (_selectedStore != null) ...[
                const SizedBox(height: 16),
                _pickupInstructions(l10n),
              ],
              const SizedBox(height: 24),
            ],

            // Customer info
            Text(
              _fulfillmentType == 'delivery' ? l10n.shippingAddress : l10n.contactInfo,
              style: playfairDisplay(fontSize: 20, fontWeight: FontWeight.w700, color: kCharcoal),
            ),
            const SizedBox(height: 16),
            _buildField(l10n.fullName, _nameController, l10n.required),
            _buildField(l10n.email, _emailController, l10n.invalidEmail, keyboard: TextInputType.emailAddress),
            _buildField(l10n.phone, _phoneController, l10n.invalidPhone, keyboard: TextInputType.phone),

            if (_fulfillmentType == 'delivery') ...[
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

            // Order summary
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
                  _summaryRow(
                    l10n.shipping,
                    _fulfillmentType == 'pickup'
                        ? l10n.freeShipping
                        : (shipping == 0 ? l10n.freeShipping : MoneyFormatter.format(shipping, lang)),
                  ),
                  if (_discountAmount > 0) ...[
                    const SizedBox(height: 8),
                    _summaryRow(l10n.discount, '-${MoneyFormatter.format(_discountAmount, lang)}', color: Colors.green),
                  ],
                  if (_fulfillmentType == 'pickup') ...[
                    const SizedBox(height: 8),
                    _summaryRow(l10n.fulfillment, l10n.storePickup, color: kGoldPrimary),
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

  Widget _fulfillmentOption(String type, String label, IconData icon) {
    final isSelected = _fulfillmentType == type;
    return GestureDetector(
      onTap: () => setState(() => _fulfillmentType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? kGoldPrimary.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? kGoldPrimary : kDivider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? kGoldPrimary : kSecondaryText, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? kGoldPrimary : kCharcoal,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _storeCard(Store store, String lang) {
    final l10n = AppLocalizations.of(context)!;
    final isSelected = _selectedStore?.id == store.id;
    return GestureDetector(
      onTap: () => setState(() => _selectedStore = store),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? kGoldPrimary.withOpacity(0.06) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? kGoldPrimary : kDivider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 20,
              height: 20,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: isSelected ? kGoldPrimary : const Color(0xFFCCCCCC), width: 2),
              ),
              child: isSelected
                  ? Center(child: Container(width: 10, height: 10, decoration: const BoxDecoration(shape: BoxShape.circle, color: kGoldPrimary)))
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(store.name(lang), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: kCharcoal)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: kSecondaryText),
                      const SizedBox(width: 4),
                      Expanded(child: Text(store.address(lang), style: const TextStyle(fontSize: 12, color: kSecondaryText))),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.access_time_outlined, size: 14, color: kSecondaryText),
                      const SizedBox(width: 4),
                      Text(store.hours(lang), style: const TextStyle(fontSize: 12, color: kSecondaryText)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () => launchUrl(Uri.parse('tel:${store.phone}')),
                    child: Row(
                      children: [
                        const Icon(Icons.phone_outlined, size: 14, color: kGoldPrimary),
                        const SizedBox(width: 4),
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: Text(store.phone, style: const TextStyle(fontSize: 12, color: kGoldPrimary, fontWeight: FontWeight.w500)),
                        ),
                      ],
                    ),
                  ),
                  if (store.mapUrl != null && store.mapUrl!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => launchUrl(Uri.parse(store.mapUrl!), mode: LaunchMode.externalApplication),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: kGoldPrimary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: kGoldPrimary.withOpacity(0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.map_outlined, size: 14, color: kGoldPrimary),
                            const SizedBox(width: 6),
                            Text(l10n.openInMaps, style: const TextStyle(fontSize: 12, color: kGoldPrimary, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pickupInstructions(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kCreamBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kGoldPrimary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, size: 16, color: kGoldPrimary),
              const SizedBox(width: 8),
              Text(l10n.pickupInstructions, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kCharcoal)),
            ],
          ),
          const SizedBox(height: 8),
          _pickupItem(l10n.pickupIdRequired),
          _pickupItem(l10n.pickupOrderNumber),
          _pickupItem(l10n.pickupReadyTime),
        ],
      ),
    );
  }

  Widget _pickupItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('  •  ', style: TextStyle(fontSize: 12, color: kSecondaryText)),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12, color: kSecondaryText))),
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
