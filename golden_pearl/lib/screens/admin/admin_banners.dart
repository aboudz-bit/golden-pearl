import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../../l10n/generated/app_localizations.dart';
import '../../main.dart';
import '../../services/api_service.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class AdminBannersScreen extends StatefulWidget {
  const AdminBannersScreen({super.key});

  @override
  State<AdminBannersScreen> createState() => _AdminBannersScreenState();
}

class _AdminBannersScreenState extends State<AdminBannersScreen> {
  List<Map<String, dynamic>> _banners = [];
  bool _loading = true;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _loadBanners();
  }

  Future<void> _loadBanners() async {
    try {
      final banners = await apiService.getBanners();
      if (mounted) setState(() { _banners = banners; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _localizedText(String en, String ar) {
    final lang = Provider.of<LanguageProvider>(context, listen: false).languageCode;
    return lang == 'ar' ? ar : en;
  }

  Future<void> _pickAndUploadFile() async {
    final input = html.FileUploadInputElement();
    input.accept = 'image/*,video/*';
    input.click();

    input.onChange.listen((event) async {
      final files = input.files;
      if (files == null || files.isEmpty) return;
      final file = files[0];
      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);
      reader.onLoadEnd.listen((event) async {
        if (!mounted) return;
        setState(() => _uploading = true);
        try {
          final bytes = (reader.result as Uint8List).toList();
          final filename = file.name;
          final uploadResult = await apiService.uploadFile(bytes, filename);
          final url = uploadResult['url'] as String;

          String type = 'image';
          final lowerName = filename.toLowerCase();
          if (lowerName.endsWith('.mp4') || lowerName.endsWith('.mov') || lowerName.endsWith('.webm') || lowerName.endsWith('.avi')) {
            type = 'video';
          }

          await apiService.createBanner({'url': url, 'type': type, 'active': true});
          await _loadBanners();
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${_localizedText('Upload failed', 'فشل الرفع')}: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } finally {
          if (mounted) setState(() => _uploading = false);
        }
      });
    });
  }

  Future<void> _toggleActive(Map<String, dynamic> banner) async {
    final id = banner['id'] as int;
    final currentActive = banner['active'] == true || banner['active'] == 1;
    try {
      await apiService.updateBanner(id, {'active': !currentActive});
      await _loadBanners();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_localizedText('Update failed', 'فشل التحديث')}: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteBanner(Map<String, dynamic> banner) async {
    final id = banner['id'] as int;
    final url = banner['url'] as String? ?? '';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kCardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          _localizedText('Delete Banner', 'حذف البانر'),
          style: playfairDisplay(fontSize: 18, fontWeight: FontWeight.w600, color: kCharcoal),
        ),
        content: Text(
          _localizedText('Are you sure you want to delete this banner?', 'هل أنت متأكد من حذف هذا البانر؟'),
          style: const TextStyle(color: kSecondaryText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(_localizedText('Cancel', 'إلغاء'), style: const TextStyle(color: kSecondaryText)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(_localizedText('Delete', 'حذف'), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await apiService.deleteBanner(id);
        if (url.isNotEmpty) {
          try {
            await apiService.deleteUpload(url);
          } catch (_) {}
        }
        await _loadBanners();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${_localizedText('Delete failed', 'فشل الحذف')}: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex--;
    final item = _banners.removeAt(oldIndex);
    _banners.insert(newIndex, item);
    setState(() {});

    final items = <Map<String, dynamic>>[];
    for (int i = 0; i < _banners.length; i++) {
      items.add({'id': _banners[i]['id'], 'sortOrder': i});
    }
    try {
      await apiService.reorderBanners(items);
    } catch (e) {
      await _loadBanners();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: kGoldPrimary));
    }

    return Scaffold(
      backgroundColor: kCreamBg,
      body: _banners.isEmpty ? _buildEmptyState() : _buildBannerList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _uploading ? null : _pickAndUploadFile,
        backgroundColor: kGoldPrimary,
        foregroundColor: Colors.white,
        icon: _uploading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Icon(Icons.add_photo_alternate_outlined),
        label: Text(
          _uploading ? _localizedText('Uploading...', 'جاري الرفع...') : _localizedText('Add Banner', 'إضافة بانر'),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_outlined, size: 64, color: kSecondaryText.withOpacity(0.4)),
          const SizedBox(height: 16),
          Text(
            _localizedText('No banners yet', 'لا توجد بانرات بعد'),
            style: playfairDisplay(fontSize: 20, fontWeight: FontWeight.w600, color: kCharcoal),
          ),
          const SizedBox(height: 8),
          Text(
            _localizedText('Add hero banners for your homepage', 'أضف بانرات للصفحة الرئيسية'),
            style: const TextStyle(color: kSecondaryText, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerList() {
    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: _banners.length,
      onReorder: _onReorder,
      proxyDecorator: (child, index, animation) {
        return Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(16),
          shadowColor: kGoldPrimary.withOpacity(0.3),
          color: Colors.transparent,
          child: child,
        );
      },
      itemBuilder: (context, index) {
        final banner = _banners[index];
        return _buildBannerCard(banner, index);
      },
    );
  }

  Widget _buildBannerCard(Map<String, dynamic> banner, int index) {
    final url = banner['url'] as String? ?? '';
    final type = banner['type'] as String? ?? 'image';
    final isActive = banner['active'] == true || banner['active'] == 1;
    final isVideo = type == 'video';
    final fullUrl = url.startsWith('http') ? url : '${ApiService.baseUrl}$url';

    return Container(
      key: ValueKey(banner['id']),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isActive ? kGoldPrimary.withOpacity(0.3) : kDivider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            child: Stack(
              children: [
                isVideo
                    ? Container(
                        height: 160,
                        color: kCharcoal.withOpacity(0.05),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.videocam_outlined, size: 48, color: kGoldPrimary.withOpacity(0.7)),
                              const SizedBox(height: 8),
                              Text(
                                _localizedText('Video Banner', 'بانر فيديو'),
                                style: TextStyle(color: kSecondaryText.withOpacity(0.7), fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      )
                    : url.isNotEmpty
                        ? Image.network(
                            fullUrl,
                            height: 160,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              height: 160,
                              color: kCreamBg,
                              child: Center(
                                child: Icon(Icons.broken_image_outlined, size: 48, color: kSecondaryText.withOpacity(0.4)),
                              ),
                            ),
                          )
                        : Container(
                            height: 160,
                            color: kCreamBg,
                            child: Center(
                              child: Icon(Icons.image_outlined, size: 48, color: kSecondaryText.withOpacity(0.4)),
                            ),
                          ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isVideo ? Colors.deepPurple : kGoldPrimary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isVideo ? Icons.videocam : Icons.image,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isVideo ? _localizedText('Video', 'فيديو') : _localizedText('Image', 'صورة'),
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '#${index + 1}',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(Icons.drag_handle, color: kSecondaryText.withOpacity(0.4), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_localizedText('Banner', 'بانر')} ${index + 1}',
                        style: const TextStyle(fontWeight: FontWeight.w600, color: kCharcoal, fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isActive ? _localizedText('Active', 'نشط') : _localizedText('Inactive', 'غير نشط'),
                        style: TextStyle(
                          color: isActive ? Colors.green : kSecondaryText,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: isActive,
                  onChanged: (_) => _toggleActive(banner),
                  activeColor: kGoldPrimary,
                  activeTrackColor: kGoldPrimary.withOpacity(0.3),
                ),
                const SizedBox(width: 4),
                InkWell(
                  onTap: () => _deleteBanner(banner),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
