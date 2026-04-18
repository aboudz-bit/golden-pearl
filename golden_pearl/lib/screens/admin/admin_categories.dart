import 'package:flutter/material.dart';
import '../../main.dart';
import '../../services/api_service.dart';
import '../../services/platform_io.dart';

class AdminCategoriesScreen extends StatefulWidget {
  const AdminCategoriesScreen({super.key});

  @override
  State<AdminCategoriesScreen> createState() => _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends State<AdminCategoriesScreen> {
  List<Map<String, dynamic>> _categories = [];
  bool _loading = true;
  bool _reordering = false;
  final Set<int> _uploading = {};

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _loading = true);
    try {
      final data = await apiService.getCategories();
      setState(() {
        _categories = data;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load categories: $e'), backgroundColor: Colors.red.shade700),
        );
      }
    }
  }

  Future<void> _editCategoryNames(Map<String, dynamic> category) async {
    final id = category['id'] as int;
    final enController = TextEditingController(text: category['nameEn'] ?? category['name'] ?? '');
    final arController = TextEditingController(text: category['nameAr'] ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kCardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Edit Category Name',
          style: playfairDisplay(fontSize: 18, fontWeight: FontWeight.w600, color: kCharcoal),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: enController,
              decoration: InputDecoration(
                labelText: 'Name (English)',
                labelStyle: const TextStyle(color: kSecondaryText, fontSize: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: kGoldPrimary, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: arController,
              textDirection: TextDirection.rtl,
              decoration: InputDecoration(
                labelText: 'الاسم (عربي)',
                labelStyle: const TextStyle(color: kSecondaryText, fontSize: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: kGoldPrimary, width: 1.5),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: kSecondaryText)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save', style: TextStyle(color: kGoldPrimary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (saved == true && mounted) {
      try {
        await apiService.updateCategory(id, {
          'nameEn': enController.text.trim(),
          'nameAr': arController.text.trim(),
        });
        await _loadCategories();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: const Text('Category name updated'), backgroundColor: kGoldPrimary),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update: $e'), backgroundColor: Colors.red.shade700),
          );
        }
      }
    }
    enController.dispose();
    arController.dispose();
  }

  Future<void> _toggleVisibility(Map<String, dynamic> category) async {
    final id = category['id'] as int;
    final current = category['visible'] ?? true;
    try {
      await apiService.updateCategory(id, {'visible': !current});
      await _loadCategories();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update visibility: $e'), backgroundColor: Colors.red.shade700),
        );
      }
    }
  }

  Future<void> _pickAndUploadImage(Map<String, dynamic> category) async {
    final id = category['id'] as int;
    final PickedMedia? picked = await pickMediaFile(
      accept: 'image/jpeg,image/png,image/webp,.jpg,.jpeg,.png,.webp',
    );
    if (picked == null) return;

    setState(() => _uploading.add(id));
    try {
      final uploadResult = await apiService.uploadFile(picked.bytes.toList(), picked.name);
      final url = uploadResult['url'] as String;
      await apiService.updateCategory(id, {'imageUrl': url});
      await _loadCategories();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Image updated successfully'),
            backgroundColor: kGoldPrimary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.red.shade700),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading.remove(id));
    }
  }

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex -= 1;
    setState(() {
      final item = _categories.removeAt(oldIndex);
      _categories.insert(newIndex, item);
      _reordering = true;
    });
    try {
      final items = _categories.asMap().entries.map((e) => {
        'id': e.value['id'],
        'sortOrder': e.key,
      }).toList();
      await apiService.reorderCategories(items);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reorder failed: $e'), backgroundColor: Colors.red.shade700),
        );
      }
      await _loadCategories();
    } finally {
      setState(() => _reordering = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kCreamBg,
      appBar: AppBar(
        title: Text(
          'Categories',
          style: playfairDisplay(fontSize: 20, fontWeight: FontWeight.w700, color: kCharcoal),
        ),
        backgroundColor: kCreamBg,
        foregroundColor: kCharcoal,
        elevation: 0,
        actions: [
          if (_reordering)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: kGoldPrimary)),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _loadCategories,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kGoldPrimary))
          : _categories.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.category_outlined, size: 64, color: kSecondaryText.withOpacity(0.4)),
                      const SizedBox(height: 16),
                      Text('No categories found', style: TextStyle(color: kSecondaryText, fontSize: 16)),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12, left: 4),
                        child: Row(
                          children: [
                            Icon(Icons.drag_indicator, size: 16, color: kSecondaryText.withOpacity(0.5)),
                            const SizedBox(width: 6),
                            Text(
                              'Drag to reorder categories',
                              style: TextStyle(color: kSecondaryText, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ReorderableListView.builder(
                          itemCount: _categories.length,
                          onReorder: _onReorder,
                          proxyDecorator: (child, index, animation) {
                            return Material(
                              elevation: 6,
                              shadowColor: kGoldPrimary.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(16),
                              child: child,
                            );
                          },
                          itemBuilder: (context, index) {
                            final cat = _categories[index];
                            return _CategoryCard(
                              key: ValueKey(cat['id']),
                              category: cat,
                              isUploading: _uploading.contains(cat['id']),
                              onToggleVisibility: () => _toggleVisibility(cat),
                              onPickImage: () => _pickAndUploadImage(cat),
                              onEditName: () => _editCategoryNames(cat),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final Map<String, dynamic> category;
  final bool isUploading;
  final VoidCallback onToggleVisibility;
  final VoidCallback onPickImage;
  final VoidCallback onEditName;

  const _CategoryCard({
    super.key,
    required this.category,
    required this.isUploading,
    required this.onToggleVisibility,
    required this.onPickImage,
    required this.onEditName,
  });

  @override
  Widget build(BuildContext context) {
    final nameEn = category['nameEn'] ?? category['name'] ?? '';
    final nameAr = category['nameAr'] ?? '';
    final slug = category['slug'] ?? '';
    final imageUrl = category['imageUrl'] as String?;
    final visible = category['visible'] ?? true;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kDivider, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.drag_handle, color: kSecondaryText.withOpacity(0.4), size: 22),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: isUploading ? null : onPickImage,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: kCreamBg,
                  border: Border.all(color: kDivider, width: 1),
                ),
                clipBehavior: Clip.antiAlias,
                child: isUploading
                    ? const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: kGoldPrimary)))
                    : imageUrl != null && imageUrl.isNotEmpty
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(
                                imageUrl.startsWith('http') ? imageUrl : '${ApiService.baseUrl}$imageUrl',
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Icon(Icons.broken_image, color: kSecondaryText.withOpacity(0.4), size: 28),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: kGoldPrimary.withOpacity(0.9),
                                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(8)),
                                  ),
                                  child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate_outlined, color: kGoldPrimary.withOpacity(0.6), size: 28),
                              const SizedBox(height: 2),
                              Text('Upload', style: TextStyle(fontSize: 10, color: kSecondaryText.withOpacity(0.6))),
                            ],
                          ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GestureDetector(
                onTap: onEditName,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            nameEn,
                            style: playfairDisplay(fontSize: 16, fontWeight: FontWeight.w600, color: kCharcoal),
                          ),
                        ),
                        Icon(Icons.edit_outlined, size: 16, color: kGoldPrimary.withOpacity(0.7)),
                      ],
                    ),
                    if (nameAr.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        nameAr,
                        style: TextStyle(fontSize: 14, color: kSecondaryText, fontWeight: FontWeight.w500),
                        textDirection: TextDirection.rtl,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: kCreamBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        slug,
                        style: TextStyle(fontSize: 11, color: kSecondaryText.withOpacity(0.7), fontFamily: 'monospace'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: visible ? kGoldPrimary.withOpacity(0.1) : Colors.red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    visible ? 'Visible' : 'Hidden',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: visible ? kGoldPrimary : Colors.red.shade400,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Switch(
                  value: visible,
                  onChanged: (_) => onToggleVisibility(),
                  activeColor: kGoldPrimary,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
