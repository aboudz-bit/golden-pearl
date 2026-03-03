import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../../main.dart';
import '../../services/api_service.dart';
import '../../models/product.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class AdminProductFormScreen extends StatefulWidget {
  final Product? product;
  const AdminProductFormScreen({super.key, this.product});

  @override
  State<AdminProductFormScreen> createState() => _AdminProductFormScreenState();
}

class _AdminProductFormScreenState extends State<AdminProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameEnCtrl;
  late TextEditingController _nameArCtrl;
  late TextEditingController _descEnCtrl;
  late TextEditingController _descArCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _originalPriceCtrl;
  late TextEditingController _stockCtrl;
  late TextEditingController _fabricEnCtrl;
  late TextEditingController _fabricArCtrl;
  late TextEditingController _sizesCtrl;
  late TextEditingController _colorsCtrl;

  String _category = 'dresses';
  bool _featured = false;
  bool _inStock = true;
  List<String> _images = [];
  String? _videoUrl;
  bool _saving = false;
  bool _uploading = false;

  bool get _isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameEnCtrl = TextEditingController(text: p?.nameEn ?? '');
    _nameArCtrl = TextEditingController(text: p?.nameAr ?? '');
    _descEnCtrl = TextEditingController(text: p?.descriptionEn ?? '');
    _descArCtrl = TextEditingController(text: p?.descriptionAr ?? '');
    _priceCtrl = TextEditingController(text: p != null ? (p.price / 100).toStringAsFixed(0) : '');
    _originalPriceCtrl = TextEditingController(text: p?.originalPrice != null ? (p!.originalPrice! / 100).toStringAsFixed(0) : '');
    _stockCtrl = TextEditingController(text: '${p?.stock ?? 100}');
    _fabricEnCtrl = TextEditingController(text: p?.fabricEn ?? '');
    _fabricArCtrl = TextEditingController(text: p?.fabricAr ?? '');
    _sizesCtrl = TextEditingController(text: p?.sizes.join(', ') ?? 'S, M, L, XL');
    _colorsCtrl = TextEditingController(text: p?.colors.join(', ') ?? '');
    _category = p?.category ?? 'dresses';
    _featured = p?.featured ?? false;
    _inStock = p?.inStock ?? true;
    _images = List.from(p?.images ?? []);
    _videoUrl = p?.videoUrl;
  }

  @override
  void dispose() {
    _nameEnCtrl.dispose();
    _nameArCtrl.dispose();
    _descEnCtrl.dispose();
    _descArCtrl.dispose();
    _priceCtrl.dispose();
    _originalPriceCtrl.dispose();
    _stockCtrl.dispose();
    _fabricEnCtrl.dispose();
    _fabricArCtrl.dispose();
    _sizesCtrl.dispose();
    _colorsCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    final input = html.FileUploadInputElement()..accept = 'image/*';
    input.click();
    input.onChange.listen((event) async {
      final files = input.files;
      if (files == null || files.isEmpty) return;
      final file = files[0];
      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);
      reader.onLoadEnd.listen((e) async {
        if (!mounted) return;
        setState(() => _uploading = true);
        try {
          final bytes = (reader.result as Uint8List).toList();
          final uploaded = await apiService.uploadFile(bytes, file.name);
          if (mounted) setState(() => _images.add(uploaded['url'] as String));
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.red),
            );
          }
        }
        if (mounted) setState(() => _uploading = false);
      });
    });
  }

  Future<void> _pickAndUploadVideo() async {
    final input = html.FileUploadInputElement()..accept = 'video/*';
    input.click();
    input.onChange.listen((event) async {
      final files = input.files;
      if (files == null || files.isEmpty) return;
      final file = files[0];
      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);
      reader.onLoadEnd.listen((e) async {
        if (!mounted) return;
        setState(() => _uploading = true);
        try {
          final bytes = (reader.result as Uint8List).toList();
          final uploaded = await apiService.uploadFile(bytes, file.name);
          if (mounted) setState(() => _videoUrl = uploaded['url'] as String);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.red),
            );
          }
        }
        if (mounted) setState(() => _uploading = false);
      });
    });
  }

  void _removeImage(int index) {
    setState(() => _images.removeAt(index));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final priceInHalalas = ((double.tryParse(_priceCtrl.text) ?? 0) * 100).round();
    final origPriceRaw = double.tryParse(_originalPriceCtrl.text);
    final origPrice = origPriceRaw != null ? (origPriceRaw * 100).round() : null;

    final data = {
      'nameEn': _nameEnCtrl.text.trim(),
      'nameAr': _nameArCtrl.text.trim(),
      'descriptionEn': _descEnCtrl.text.trim(),
      'descriptionAr': _descArCtrl.text.trim(),
      'price': priceInHalalas,
      'originalPrice': origPrice,
      'category': _category,
      'images': _images,
      'videoUrl': _videoUrl,
      'sizes': _sizesCtrl.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
      'colors': _colorsCtrl.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
      'fabricEn': _fabricEnCtrl.text.trim().isEmpty ? null : _fabricEnCtrl.text.trim(),
      'fabricAr': _fabricArCtrl.text.trim().isEmpty ? null : _fabricArCtrl.text.trim(),
      'inStock': _inStock,
      'featured': _featured,
      'stock': int.tryParse(_stockCtrl.text) ?? 100,
    };

    try {
      if (_isEdit) {
        await apiService.updateProduct(widget.product!.id, data);
      } else {
        await apiService.createProduct(data);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEdit ? 'Product updated' : 'Product created'),
            backgroundColor: kGoldPrimary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Product' : 'Add Product',
            style: playfairDisplay(fontSize: 18, fontWeight: FontWeight.w700, color: kCharcoal)),
        backgroundColor: kCreamBg,
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: kGoldPrimary))
                : const Text('Save', style: TextStyle(color: kGoldPrimary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _sectionTitle('Images'),
            SizedBox(
              height: 110,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ..._images.asMap().entries.map((e) => _imageThumb(e.key, e.value)),
                  _addImageButton(),
                ],
              ),
            ),
            if (_videoUrl != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.videocam, color: kGoldPrimary, size: 18),
                  const SizedBox(width: 6),
                  Expanded(child: Text('Video: ${_videoUrl!.split('/').last}', style: const TextStyle(fontSize: 12, color: kSecondaryText), overflow: TextOverflow.ellipsis)),
                  IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => setState(() => _videoUrl = null)),
                ],
              ),
            ],
            OutlinedButton.icon(
              onPressed: _uploading ? null : _pickAndUploadVideo,
              icon: const Icon(Icons.videocam_outlined, size: 18),
              label: Text(_videoUrl != null ? 'Replace Video' : 'Add Video'),
              style: OutlinedButton.styleFrom(foregroundColor: kGoldPrimary, side: const BorderSide(color: kDivider)),
            ),
            const SizedBox(height: 20),
            _sectionTitle('Product Info'),
            const SizedBox(height: 8),
            _field(_nameEnCtrl, 'Name (English)', required: true),
            _field(_nameArCtrl, 'Name (Arabic)', required: true, textDirection: TextDirection.rtl),
            _field(_descEnCtrl, 'Description (English)', maxLines: 3),
            _field(_descArCtrl, 'Description (Arabic)', maxLines: 3, textDirection: TextDirection.rtl),
            const SizedBox(height: 12),
            _sectionTitle('Category'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: _inputDecoration('Category'),
              items: const [
                DropdownMenuItem(value: 'dresses', child: Text('Dresses / فساتين')),
                DropdownMenuItem(value: 'jalabiyas', child: Text('Jalabiyas / جلابيات')),
                DropdownMenuItem(value: 'kids', child: Text('Kids / أطفال')),
                DropdownMenuItem(value: 'gifts', child: Text('Gifts / هدايا')),
              ],
              onChanged: (v) => setState(() => _category = v ?? 'dresses'),
            ),
            const SizedBox(height: 20),
            _sectionTitle('Pricing & Stock'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _field(_priceCtrl, 'Price (SAR)', required: true, keyboardType: TextInputType.number)),
                const SizedBox(width: 12),
                Expanded(child: _field(_originalPriceCtrl, 'Original Price', keyboardType: TextInputType.number)),
              ],
            ),
            _field(_stockCtrl, 'Stock', keyboardType: TextInputType.number),
            const SizedBox(height: 20),
            _sectionTitle('Variants'),
            const SizedBox(height: 8),
            _field(_sizesCtrl, 'Sizes (comma separated)'),
            _field(_colorsCtrl, 'Colors (comma separated)'),
            const SizedBox(height: 20),
            _sectionTitle('Fabric'),
            const SizedBox(height: 8),
            _field(_fabricEnCtrl, 'Fabric (English)'),
            _field(_fabricArCtrl, 'Fabric (Arabic)', textDirection: TextDirection.rtl),
            const SizedBox(height: 20),
            _sectionTitle('Options'),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('In Stock', style: TextStyle(fontSize: 14, color: kCharcoal)),
              value: _inStock,
              activeColor: kGoldPrimary,
              onChanged: (v) => setState(() => _inStock = v),
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              title: const Text('Featured', style: TextStyle(fontSize: 14, color: kCharcoal)),
              value: _featured,
              activeColor: kGoldPrimary,
              onChanged: (v) => setState(() => _featured = v),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: kGoldPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _saving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(_isEdit ? 'Update Product' : 'Create Product', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title, style: playfairDisplay(fontSize: 16, fontWeight: FontWeight.w600, color: kCharcoal));
  }

  Widget _field(TextEditingController ctrl, String label,
      {bool required = false, int maxLines = 1, TextInputType? keyboardType, TextDirection? textDirection}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboardType,
        textDirection: textDirection,
        decoration: _inputDecoration(label),
        validator: required ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null : null,
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 13, color: kSecondaryText),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kDivider)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kDivider)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kGoldPrimary)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      filled: true,
      fillColor: Colors.white,
    );
  }

  Widget _imageThumb(int index, String url) {
    final fullUrl = url.startsWith('http') ? url : '${ApiService.baseUrl}$url';
    return Container(
      width: 90,
      height: 110,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kDivider),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: Image.network(fullUrl, width: 90, height: 110, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: kCreamBg, child: const Icon(Icons.broken_image, color: kSecondaryText))),
          ),
          Positioned(
            top: 2,
            right: 2,
            child: GestureDetector(
              onTap: () => _removeImage(index),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                child: const Icon(Icons.close, color: Colors.white, size: 14),
              ),
            ),
          ),
          if (index == 0)
            Positioned(
              bottom: 2,
              left: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(color: kGoldPrimary, borderRadius: BorderRadius.circular(4)),
                child: const Text('Main', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _addImageButton() {
    return GestureDetector(
      onTap: _uploading ? null : _pickAndUploadImage,
      child: Container(
        width: 90,
        height: 110,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: kGoldPrimary.withOpacity(0.3)),
          color: kGoldPrimary.withOpacity(0.05),
        ),
        child: _uploading
            ? const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: kGoldPrimary)))
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_outlined, color: kGoldPrimary.withOpacity(0.7), size: 28),
                  const SizedBox(height: 4),
                  Text('Add', style: TextStyle(fontSize: 11, color: kGoldPrimary.withOpacity(0.7))),
                ],
              ),
      ),
    );
  }
}
