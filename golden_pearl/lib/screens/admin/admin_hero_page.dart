import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../main.dart';
import '../../services/api_service.dart';
import '../../services/platform_io.dart';

class AdminHeroPage extends StatefulWidget {
  const AdminHeroPage({super.key});

  @override
  State<AdminHeroPage> createState() => _AdminHeroPageState();
}

class _AdminHeroPageState extends State<AdminHeroPage> {
  List<Map<String, dynamic>> _slides = [];
  bool _loading = true;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _loadSlides();
  }

  Future<void> _loadSlides() async {
    try {
      final banners = await apiService.getBanners();
      if (mounted) setState(() { _slides = banners; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Map<String, dynamic> _defaultOverlay() => {
    'ar': {
      'headline': 'أناقة لا تُضاهى',
      'subheadline': 'اكتشفي أحدث مجموعتنا',
      'cta': 'تسوقي الآن',
      'style': _defaultStyle(),
    },
    'en': {
      'headline': 'Elegance Redefined',
      'subheadline': 'Discover our latest collection',
      'cta': 'Shop Now',
      'style': _defaultStyle(),
    },
  };

  Map<String, dynamic> _defaultStyle() => {
    'fontFamily': 'Playfair',
    'headlineSize': 30,
    'subheadlineSize': 14,
    'fontWeight': 700,
    'letterSpacing': 0,
    'color': '#FFFFFF',
    'shadow': {'enabled': true, 'color': '#000000', 'blur': 8, 'offsetX': 0, 'offsetY': 2, 'opacity': 0.5},
    'align': 'center',
    'positionPreset': 'BottomCenter',
    'offsetXPercent': 0,
    'offsetYPercent': 0,
  };

  Future<void> _pickAndUploadSlide() async {
    if (!kIsWeb) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Slide upload is available in the web admin panel.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }
    final PickedMedia? picked = await pickMediaFile(
      accept: 'image/jpeg,image/png,image/webp,video/mp4',
    );
    if (picked == null || !mounted) return;

    setState(() => _uploading = true);
    try {
      final uploadResult = await apiService.uploadFile(picked.bytes.toList(), picked.name);
      final url = uploadResult['url'] as String;
      final uploadType = uploadResult['type'] as String? ?? 'image';

      final overlay = _defaultOverlay();
      await apiService.createBanner({
        'url': url,
        'type': uploadType,
        'active': true,
        'overlay': jsonEncode(overlay),
      });
      await _loadSlides();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Slide added'), backgroundColor: kGoldPrimary, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _duplicateSlide(Map<String, dynamic> slide) async {
    try {
      final overlay = slide['overlay'] ?? jsonEncode(_defaultOverlay());
      await apiService.createBanner({
        'url': slide['url'] ?? '',
        'type': slide['type'] ?? 'image',
        'active': false,
        'overlay': overlay is String ? overlay : jsonEncode(overlay),
      });
      await _loadSlides();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Slide duplicated (inactive)'), backgroundColor: kGoldPrimary, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Duplicate failed: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  Future<void> _toggleActive(Map<String, dynamic> slide) async {
    final id = slide['id'] as int;
    final current = slide['active'] == true || slide['active'] == 1;
    try {
      await apiService.updateBanner(id, {'active': !current});
      await _loadSlides();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteSlide(Map<String, dynamic> slide) async {
    final id = slide['id'] as int;
    final url = slide['url'] as String? ?? '';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kCardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Slide', style: playfairDisplay(fontSize: 18, fontWeight: FontWeight.w600, color: kCharcoal)),
        content: const Text('Are you sure you want to delete this banner?', style: TextStyle(color: kSecondaryText)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(color: kSecondaryText))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await apiService.deleteBanner(id);
        if (url.isNotEmpty) {
          try { await apiService.deleteUpload(url); } catch (_) {}
        }
        await _loadSlides();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Delete failed: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex--;
    final item = _slides.removeAt(oldIndex);
    _slides.insert(newIndex, item);
    setState(() {});

    final items = <Map<String, dynamic>>[];
    for (int i = 0; i < _slides.length; i++) {
      items.add({'id': _slides[i]['id'], 'sortOrder': i});
    }
    try {
      await apiService.reorderBanners(items);
    } catch (e) {
      await _loadSlides();
    }
  }

  Future<void> _editSlideOverlay(Map<String, dynamic> slide) async {
    final id = slide['id'] as int;
    Map<String, dynamic> overlay;
    try {
      final raw = slide['overlay'];
      if (raw is String && raw.isNotEmpty) {
        overlay = Map<String, dynamic>.from(jsonDecode(raw));
      } else if (raw is Map) {
        overlay = Map<String, dynamic>.from(raw);
      } else {
        overlay = _defaultOverlay();
      }
    } catch (_) {
      overlay = _defaultOverlay();
    }

    if (overlay['ar'] == null) overlay['ar'] = _defaultOverlay()['ar'];
    if (overlay['en'] == null) overlay['en'] = _defaultOverlay()['en'];
    if ((overlay['ar'] as Map)['style'] == null) (overlay['ar'] as Map)['style'] = _defaultStyle();
    if ((overlay['en'] as Map)['style'] == null) (overlay['en'] as Map)['style'] = _defaultStyle();

    final imageUrl = slide['url'] as String? ?? '';
    final fullUrl = imageUrl.startsWith('http') ? imageUrl : '${ApiService.baseUrl}$imageUrl';

    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => _SlideOverlayEditor(
          overlay: overlay,
          imageUrl: fullUrl,
          defaultStyle: _defaultStyle,
          defaultOverlay: _defaultOverlay,
        ),
      ),
    );

    if (result != null) {
      try {
        await apiService.updateBanner(id, {'overlay': jsonEncode(result)});
        await _loadSlides();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: const Text('Slide text updated'), backgroundColor: kGoldPrimary, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Save failed: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Color _hexToColor(String hex, {double opacity = 1.0}) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    try { return Color(int.parse(hex, radix: 16)).withOpacity(opacity); } catch (_) { return Colors.white.withOpacity(opacity); }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: kGoldPrimary));

    return Scaffold(
      backgroundColor: kCreamBg,
      body: _slides.isEmpty ? _buildEmptyState() : _buildSlideList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _uploading ? null : _pickAndUploadSlide,
        backgroundColor: kGoldPrimary,
        foregroundColor: Colors.white,
        icon: _uploading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Icon(Icons.add_photo_alternate_outlined),
        label: Text(
          _uploading ? 'Uploading...' : 'Add Slide',
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
          Icon(Icons.photo_library_outlined, size: 64, color: kSecondaryText.withOpacity(0.4)),
          const SizedBox(height: 16),
          Text('No banners yet', style: playfairDisplay(fontSize: 20, fontWeight: FontWeight.w600, color: kCharcoal)),
          const SizedBox(height: 8),
          const Text('Add homepage banners with images and text overlays', style: TextStyle(color: kSecondaryText, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildSlideList() {
    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: _slides.length,
      onReorder: _onReorder,
      proxyDecorator: (child, index, animation) {
        return Material(elevation: 4, borderRadius: BorderRadius.circular(16), shadowColor: kGoldPrimary.withOpacity(0.3), color: Colors.transparent, child: child);
      },
      itemBuilder: (context, index) {
        final slide = _slides[index];
        return _buildSlideCard(slide, index);
      },
    );
  }

  void _showPreview(Map<String, dynamic> slide) {
    final url = slide['url'] as String? ?? '';
    final fullUrl = url.startsWith('http') ? url : '${ApiService.baseUrl}$url';
    final isVideo = (slide['type'] as String?) == 'video';

    Map<String, dynamic>? overlay;
    try {
      final raw = slide['overlay'];
      if (raw is String && raw.isNotEmpty) overlay = Map<String, dynamic>.from(jsonDecode(raw));
      else if (raw is Map) overlay = Map<String, dynamic>.from(raw);
    } catch (_) {}

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: 9 / 16,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (isVideo)
                  Container(color: kCharcoal, child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.play_circle_outline, color: Colors.white54, size: 64), const SizedBox(height: 8), const Text('Video Preview', style: TextStyle(color: Colors.white54))])))
                else
                  Image.network(fullUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: kCharcoal, child: const Center(child: Icon(Icons.broken_image, color: Colors.white54, size: 48)))),
                Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, stops: const [0.0, 0.5], colors: [Colors.black.withOpacity(0.6), Colors.transparent]))),
                if (overlay != null) _buildPreviewOverlayText(overlay),
                Positioned(top: 8, right: 8, child: IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(20)), child: const Icon(Icons.close, color: Colors.white, size: 20)),
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewOverlayText(Map<String, dynamic> overlay) {
    final lang = 'en';
    final langData = overlay[lang] as Map<String, dynamic>? ?? {};
    final headline = langData['headline'] as String? ?? '';
    final sub = langData['subheadline'] as String? ?? '';
    final cta = langData['cta'] as String? ?? '';
    final style = langData['style'] as Map<String, dynamic>? ?? {};
    final preset = style['positionPreset'] ?? 'BottomCenter';
    final xOff = (style['offsetXPercent'] as num?)?.toDouble() ?? 0;
    final yOff = (style['offsetYPercent'] as num?)?.toDouble() ?? 0;
    final alignment = _presetToAlignment(preset, xOff, yOff);

    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (headline.isNotEmpty) Text(headline, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700, shadows: [Shadow(blurRadius: 6, color: Colors.black54)]), textAlign: TextAlign.center),
            if (sub.isNotEmpty) ...[const SizedBox(height: 4), Text(sub, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14), textAlign: TextAlign.center)],
            if (cta.isNotEmpty) ...[const SizedBox(height: 10), Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), decoration: BoxDecoration(color: kGoldPrimary, borderRadius: BorderRadius.circular(8)), child: Text(cta, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)))],
          ],
        ),
      ),
    );
  }

  Alignment _presetToAlignment(String preset, double xOff, double yOff) {
    double x = 0, y = 0;
    switch (preset) {
      case 'TopLeft': x = -1; y = -1; break; case 'TopCenter': x = 0; y = -1; break; case 'TopRight': x = 1; y = -1; break;
      case 'CenterLeft': x = -1; y = 0; break; case 'Center': x = 0; y = 0; break; case 'CenterRight': x = 1; y = 0; break;
      case 'BottomLeft': x = -1; y = 1; break; case 'BottomCenter': x = 0; y = 1; break; case 'BottomRight': x = 1; y = 1; break;
    }
    return Alignment((x + xOff / 50).clamp(-1.0, 1.0), (y + yOff / 50).clamp(-1.0, 1.0));
  }

  Widget _buildSlideCard(Map<String, dynamic> slide, int index) {
    final url = slide['url'] as String? ?? '';
    final isActive = slide['active'] == true || slide['active'] == 1;
    final slideType = (slide['type'] as String?) ?? 'image';
    final isVideo = slideType == 'video';
    final fullUrl = url.startsWith('http') ? url : '${ApiService.baseUrl}$url';

    Map<String, dynamic>? overlay;
    try {
      final raw = slide['overlay'];
      if (raw is String && raw.isNotEmpty) {
        overlay = Map<String, dynamic>.from(jsonDecode(raw));
      } else if (raw is Map) {
        overlay = Map<String, dynamic>.from(raw);
      }
    } catch (_) {}

    String enHeadline = '';
    String arHeadline = '';
    if (overlay != null) {
      final enMap = overlay['en'] as Map<String, dynamic>?;
      final arMap = overlay['ar'] as Map<String, dynamic>?;
      enHeadline = (enMap?['headline'] as String?) ?? '';
      arHeadline = (arMap?['headline'] as String?) ?? '';
    }

    return Container(
      key: ValueKey(slide['id']),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isActive ? kGoldPrimary.withOpacity(0.3) : kDivider),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            child: Stack(
              children: [
                if (isVideo)
                  Container(height: 160, color: kCharcoal.withOpacity(0.8), child: Center(child: Icon(Icons.videocam_outlined, size: 48, color: Colors.white.withOpacity(0.5))))
                else if (url.isNotEmpty)
                  Image.network(fullUrl, height: 160, width: double.infinity, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(height: 160, color: kCreamBg, child: Center(child: Icon(Icons.broken_image_outlined, size: 48, color: kSecondaryText.withOpacity(0.4)))))
                else
                  Container(height: 160, color: kCreamBg, child: Center(child: Icon(Icons.image_outlined, size: 48, color: kSecondaryText.withOpacity(0.4)))),
                Container(
                  height: 160,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, stops: const [0.0, 0.5], colors: [Colors.black.withOpacity(0.5), Colors.transparent]),
                  ),
                ),
                if (enHeadline.isNotEmpty)
                  Positioned(
                    bottom: 12,
                    left: 12,
                    right: 12,
                    child: Text(enHeadline, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600, shadows: [Shadow(blurRadius: 4, color: Colors.black54)]), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: kGoldPrimary, borderRadius: BorderRadius.circular(20)),
                        child: Text('#${index + 1}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: isVideo ? Colors.deepPurple : Colors.blue.shade600, borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(isVideo ? Icons.videocam : Icons.image, color: Colors.white, size: 12),
                            const SizedBox(width: 4),
                            Text(isVideo ? 'Video' : 'Image', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: isActive ? Colors.green : Colors.red.shade400, borderRadius: BorderRadius.circular(12)),
                    child: Text(isActive ? 'Active' : 'Inactive', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
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
                      Text('Slide ${index + 1}', style: const TextStyle(fontWeight: FontWeight.w600, color: kCharcoal, fontSize: 14)),
                      if (arHeadline.isNotEmpty)
                        Text(arHeadline, style: const TextStyle(fontSize: 12, color: kSecondaryText), textDirection: TextDirection.rtl, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                _actionButton(Icons.visibility_outlined, kSecondaryText, () => _showPreview(slide), tooltip: 'Preview'),
                const SizedBox(width: 4),
                _actionButton(Icons.edit_note, kGoldPrimary, () => _editSlideOverlay(slide), tooltip: 'Edit'),
                const SizedBox(width: 4),
                _actionButton(Icons.copy_outlined, Colors.blue, () => _duplicateSlide(slide), tooltip: 'Duplicate'),
                const SizedBox(width: 4),
                Switch(value: isActive, onChanged: (_) => _toggleActive(slide), activeColor: kGoldPrimary, activeTrackColor: kGoldPrimary.withOpacity(0.3)),
                _actionButton(Icons.delete_outline, Colors.red, () => _deleteSlide(slide), tooltip: 'Delete'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(IconData icon, Color color, VoidCallback onTap, {String? tooltip}) {
    final child = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: color, size: 18),
      ),
    );
    return tooltip != null ? Tooltip(message: tooltip, child: child) : child;
  }
}

class _SlideOverlayEditor extends StatefulWidget {
  final Map<String, dynamic> overlay;
  final String imageUrl;
  final Map<String, dynamic> Function() defaultStyle;
  final Map<String, dynamic> Function() defaultOverlay;

  const _SlideOverlayEditor({required this.overlay, required this.imageUrl, required this.defaultStyle, required this.defaultOverlay});

  @override
  State<_SlideOverlayEditor> createState() => _SlideOverlayEditorState();
}

class _SlideOverlayEditorState extends State<_SlideOverlayEditor> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Map<String, dynamic> _draft;

  final _fonts = ['Playfair', 'Inter', 'Cairo', 'Tajawal'];
  final _weights = [400, 500, 600, 700];
  final _presets = ['TopLeft', 'TopCenter', 'TopRight', 'CenterLeft', 'Center', 'CenterRight', 'BottomLeft', 'BottomCenter', 'BottomRight'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() { if (mounted) setState(() {}); });
    _draft = jsonDecode(jsonEncode(widget.overlay));
  }

  @override
  void dispose() { _tabController.dispose(); super.dispose(); }

  String get _activeLang => _tabController.index == 0 ? 'ar' : 'en';

  Map<String, dynamic> get _activeDraft => (_draft[_activeLang] as Map<String, dynamic>?) ?? widget.defaultOverlay()[_activeLang]!;
  Map<String, dynamic> get _activeStyle => (_activeDraft['style'] as Map<String, dynamic>?) ?? widget.defaultStyle();

  void _updateDraft(String key, dynamic value) {
    setState(() { (_draft[_activeLang] as Map<String, dynamic>)[key] = value; });
  }

  void _updateStyle(String key, dynamic value) {
    setState(() { ((_draft[_activeLang] as Map<String, dynamic>)['style'] as Map<String, dynamic>)[key] = value; });
  }

  void _updateShadow(String key, dynamic value) {
    setState(() {
      final shadow = Map<String, dynamic>.from(_activeStyle['shadow'] as Map? ?? {});
      shadow[key] = value;
      _updateStyle('shadow', shadow);
    });
  }

  Color _hexToColor(String hex, {double opacity = 1.0}) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    try { return Color(int.parse(hex, radix: 16)).withOpacity(opacity); } catch (_) { return Colors.white.withOpacity(opacity); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kCreamBg,
      appBar: AppBar(
        title: Text('Edit Slide Text', style: playfairDisplay(fontSize: 18, fontWeight: FontWeight.w700, color: kCharcoal)),
        backgroundColor: kCreamBg,
        foregroundColor: kCharcoal,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context, _draft),
            icon: const Icon(Icons.check, color: kGoldPrimary, size: 20),
            label: const Text('Save', style: TextStyle(color: kGoldPrimary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: kCreamBg,
            child: TabBar(
              controller: _tabController,
              labelColor: kGoldPrimary,
              unselectedLabelColor: kSecondaryText,
              indicatorColor: kGoldPrimary,
              tabs: const [Tab(text: 'العربية (AR)'), Tab(text: 'English (EN)')],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildEditor('ar'), _buildEditor('en')],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditor(String lang) {
    final draft = (_draft[lang] as Map<String, dynamic>?) ?? {};
    final style = (draft['style'] as Map<String, dynamic>?) ?? widget.defaultStyle();
    final shadow = (style['shadow'] as Map<String, dynamic>?) ?? {};

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        _buildPreview(draft, style),
        const SizedBox(height: 20),
        _sectionTitle('Text Content'),
        _textField('Headline', draft['headline'] ?? '', (v) => _updateDraft('headline', v), maxLines: 2),
        _textField('Subheadline', draft['subheadline'] ?? '', (v) => _updateDraft('subheadline', v), maxLines: 2),
        _textField('CTA Button', draft['cta'] ?? '', (v) => _updateDraft('cta', v)),
        const Divider(height: 32),
        _sectionTitle('Typography'),
        _dropdownRow('Font Family', style['fontFamily'] ?? 'Playfair', _fonts, (v) => _updateStyle('fontFamily', v)),
        _sliderRow('Headline Size', (style['headlineSize'] as num?)?.toDouble() ?? 30, 18, 60, (v) => _updateStyle('headlineSize', v.round())),
        _sliderRow('Sub Size', (style['subheadlineSize'] as num?)?.toDouble() ?? 14, 12, 34, (v) => _updateStyle('subheadlineSize', v.round())),
        _sliderRow('CTA Size', (style['ctaSize'] as num?)?.toDouble() ?? 14, 12, 24, (v) => _updateStyle('ctaSize', v.round())),
        _dropdownRow('H. Weight', (style['headlineWeight'] as num?)?.toInt() ?? (style['fontWeight'] as num?)?.toInt() ?? 700, _weights, (v) => _updateStyle('headlineWeight', v)),
        _dropdownRow('Sub Weight', (style['subheadlineWeight'] as num?)?.toInt() ?? 400, _weights, (v) => _updateStyle('subheadlineWeight', v)),
        _sliderRow('Spacing', (style['letterSpacing'] as num?)?.toDouble() ?? 0, -3, 10, (v) => _updateStyle('letterSpacing', double.parse(v.toStringAsFixed(1)))),
        const Divider(height: 32),
        _sectionTitle('Color & Shadow'),
        _colorField('Text Color', style['color'] ?? '#FFFFFF', (v) => _updateStyle('color', v)),
        _switchRow('Shadow', shadow['enabled'] == true, (v) => _updateShadow('enabled', v)),
        if (shadow['enabled'] == true) ...[
          _sliderRow('Blur', (shadow['blur'] as num?)?.toDouble() ?? 8, 0, 30, (v) => _updateShadow('blur', v.round())),
          _sliderRow('Opacity', (shadow['opacity'] as num?)?.toDouble() ?? 0.5, 0, 1, (v) => _updateShadow('opacity', double.parse(v.toStringAsFixed(2)))),
        ],
        const Divider(height: 32),
        _sectionTitle('Position'),
        _alignmentSelector(style['align'] ?? 'center', (v) => _updateStyle('align', v)),
        const SizedBox(height: 12),
        _presetGrid(style['positionPreset'] ?? 'BottomCenter', (v) => _updateStyle('positionPreset', v)),
        _sliderRow('X Offset', (style['offsetXPercent'] as num?)?.toDouble() ?? 0, -30, 30, (v) => _updateStyle('offsetXPercent', v.round())),
        _sliderRow('Y Offset', (style['offsetYPercent'] as num?)?.toDouble() ?? 0, -30, 30, (v) => _updateStyle('offsetYPercent', v.round())),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildPreview(Map<String, dynamic> draft, Map<String, dynamic> style) {
    final headline = draft['headline'] ?? '';
    final sub = draft['subheadline'] ?? '';
    final cta = draft['cta'] ?? '';
    final color = _hexToColor(style['color'] ?? '#FFFFFF');
    final hWeight = FontWeight.values[((style['headlineWeight'] as num? ?? style['fontWeight'] as num? ?? 700) ~/ 100).clamp(1, 8)];
    final sWeight = FontWeight.values[((style['subheadlineWeight'] as num? ?? 400) ~/ 100).clamp(1, 8)];
    final hSize = (style['headlineSize'] as num?)?.toDouble() ?? 30;
    final sSize = (style['subheadlineSize'] as num?)?.toDouble() ?? 14;
    final ctaSize = (style['ctaSize'] as num?)?.toDouble() ?? 14;
    final spacing = (style['letterSpacing'] as num?)?.toDouble() ?? 0;
    final fontFamily = style['fontFamily'] ?? 'Playfair';
    final textAlign = _parseAlign(style['align']);
    final crossAlign = _parseCross(style['align']);
    final preset = style['positionPreset'] ?? 'BottomCenter';
    final xOff = (style['offsetXPercent'] as num?)?.toDouble() ?? 0;
    final yOff = (style['offsetYPercent'] as num?)?.toDouble() ?? 0;
    final alignment = _presetAlignment(preset, xOff, yOff);

    List<Shadow>? shadows;
    final shadowMap = style['shadow'] as Map<String, dynamic>?;
    if (shadowMap != null && shadowMap['enabled'] == true) {
      shadows = [Shadow(color: _hexToColor(shadowMap['color'] ?? '#000000', opacity: (shadowMap['opacity'] as num?)?.toDouble() ?? 0.5), blurRadius: (shadowMap['blur'] as num?)?.toDouble() ?? 8, offset: Offset((shadowMap['offsetX'] as num?)?.toDouble() ?? 0, (shadowMap['offsetY'] as num?)?.toDouble() ?? 2))];
    }

    TextStyle headlineStyle;
    if (fontFamily == 'Playfair') {
      headlineStyle = playfairDisplay(fontSize: hSize.clamp(16, 36).toDouble(), fontWeight: hWeight, color: color).copyWith(letterSpacing: spacing, shadows: shadows);
    } else {
      headlineStyle = TextStyle(fontSize: hSize.clamp(16, 36).toDouble(), fontWeight: hWeight, color: color, letterSpacing: spacing, shadows: shadows);
    }
    final subStyle = TextStyle(fontSize: sSize.clamp(10, 20).toDouble(), fontWeight: sWeight, color: color.withOpacity(0.7), height: 1.4, letterSpacing: spacing, shadows: shadows);

    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: kCharcoal,
        borderRadius: BorderRadius.circular(12),
        image: widget.imageUrl.isNotEmpty ? DecorationImage(image: NetworkImage(widget.imageUrl), fit: BoxFit.cover) : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, stops: const [0.0, 0.45], colors: [Colors.black.withOpacity(0.65), Colors.transparent]))),
            Align(
              alignment: alignment,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: crossAlign,
                  children: [
                    if (headline.isNotEmpty) Text(headline, style: headlineStyle, textAlign: textAlign, maxLines: 2, overflow: TextOverflow.ellipsis),
                    if (sub.isNotEmpty) ...[const SizedBox(height: 4), Text(sub, style: subStyle, textAlign: textAlign, maxLines: 2, overflow: TextOverflow.ellipsis)],
                    if (cta.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6), decoration: BoxDecoration(color: kGoldPrimary, borderRadius: BorderRadius.circular(8)), child: Text(cta, style: TextStyle(color: Colors.white, fontSize: ctaSize.clamp(10, 18).toDouble(), fontWeight: FontWeight.w600))),
                    ],
                  ],
                ),
              ),
            ),
            Positioned(top: 8, right: 8, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(6)), child: const Text('PREVIEW', style: TextStyle(color: Colors.white60, fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 1)))),
          ],
        ),
      ),
    );
  }

  Alignment _presetAlignment(String preset, double xOff, double yOff) {
    double x = 0, y = 0;
    switch (preset) {
      case 'TopLeft': x = -1; y = -1; break; case 'TopCenter': x = 0; y = -1; break; case 'TopRight': x = 1; y = -1; break;
      case 'CenterLeft': x = -1; y = 0; break; case 'Center': x = 0; y = 0; break; case 'CenterRight': x = 1; y = 0; break;
      case 'BottomLeft': x = -1; y = 1; break; case 'BottomCenter': x = 0; y = 1; break; case 'BottomRight': x = 1; y = 1; break;
    }
    return Alignment((x + xOff / 50).clamp(-1.0, 1.0), (y + yOff / 50).clamp(-1.0, 1.0));
  }

  TextAlign _parseAlign(String? a) { switch (a) { case 'left': return TextAlign.left; case 'right': return TextAlign.right; default: return TextAlign.center; } }
  CrossAxisAlignment _parseCross(String? a) { switch (a) { case 'left': return CrossAxisAlignment.start; case 'right': return CrossAxisAlignment.end; default: return CrossAxisAlignment.center; } }

  Widget _sectionTitle(String title) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(title, style: playfairDisplay(fontSize: 16, fontWeight: FontWeight.w600, color: kCharcoal)));

  Widget _textField(String label, String value, ValueChanged<String> onChanged, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: TextEditingController(text: value),
        maxLines: maxLines,
        onChanged: onChanged,
        decoration: InputDecoration(labelText: label, labelStyle: const TextStyle(fontSize: 13, color: kSecondaryText), filled: true, fillColor: kCreamBg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
        style: const TextStyle(fontSize: 14, color: kCharcoal),
      ),
    );
  }

  Widget _dropdownRow<T>(String label, T value, List<T> items, ValueChanged<T> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(fontSize: 13, color: kCharcoal))),
          Expanded(child: Container(padding: const EdgeInsets.symmetric(horizontal: 12), decoration: BoxDecoration(color: kCreamBg, borderRadius: BorderRadius.circular(10)), child: DropdownButtonHideUnderline(child: DropdownButton<T>(value: items.contains(value) ? value : items.first, isExpanded: true, items: items.map((e) => DropdownMenuItem(value: e, child: Text('$e', style: const TextStyle(fontSize: 13)))).toList(), onChanged: (v) { if (v != null) onChanged(v); })))),
        ],
      ),
    );
  }

  Widget _sliderRow(String label, double value, double min, double max, ValueChanged<double> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(label, style: const TextStyle(fontSize: 12, color: kCharcoal))),
          Expanded(child: Slider(value: value.clamp(min, max), min: min, max: max, divisions: ((max - min) * (max - min < 5 ? 20 : 1)).round().clamp(1, 100), activeColor: kGoldPrimary, onChanged: onChanged)),
          SizedBox(width: 40, child: Text(value == value.roundToDouble() ? '${value.round()}' : value.toStringAsFixed(1), style: const TextStyle(fontSize: 12, color: kSecondaryText), textAlign: TextAlign.end)),
        ],
      ),
    );
  }

  Widget _colorField(String label, String hex, ValueChanged<String> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(label, style: const TextStyle(fontSize: 13, color: kCharcoal))),
          Container(width: 32, height: 32, margin: const EdgeInsets.only(right: 8), decoration: BoxDecoration(color: _hexToColor(hex), borderRadius: BorderRadius.circular(6), border: Border.all(color: kDivider))),
          Expanded(child: SizedBox(height: 38, child: TextField(controller: TextEditingController(text: hex), onChanged: (v) { final clean = v.startsWith('#') ? v : '#$v'; if (RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(clean)) onChanged(clean); }, decoration: InputDecoration(hintText: '#FFFFFF', hintStyle: const TextStyle(fontSize: 12, color: kSecondaryText), filled: true, fillColor: kCreamBg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0)), style: const TextStyle(fontSize: 13, color: kCharcoal)))),
        ],
      ),
    );
  }

  Widget _switchRow(String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [Text(label, style: const TextStyle(fontSize: 13, color: kCharcoal)), const Spacer(), Switch(value: value, activeColor: kGoldPrimary, onChanged: onChanged)]));
  }

  Widget _alignmentSelector(String current, ValueChanged<String> onChanged) {
    return Row(children: [
      const Text('Align', style: TextStyle(fontSize: 13, color: kCharcoal)),
      const Spacer(),
      ToggleButtons(
        isSelected: ['left', 'center', 'right'].map((a) => a == current).toList(),
        onPressed: (i) => onChanged(['left', 'center', 'right'][i]),
        borderRadius: BorderRadius.circular(8),
        selectedColor: kGoldPrimary,
        fillColor: kGoldPrimary.withOpacity(0.1),
        constraints: const BoxConstraints(minWidth: 44, minHeight: 36),
        children: const [Icon(Icons.format_align_left, size: 18), Icon(Icons.format_align_center, size: 18), Icon(Icons.format_align_right, size: 18)],
      ),
    ]);
  }

  Widget _presetGrid(String current, ValueChanged<String> onChanged) {
    final labels = {'TopLeft': '↖', 'TopCenter': '↑', 'TopRight': '↗', 'CenterLeft': '←', 'Center': '●', 'CenterRight': '→', 'BottomLeft': '↙', 'BottomCenter': '↓', 'BottomRight': '↘'};
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Position', style: TextStyle(fontSize: 13, color: kCharcoal)),
      const SizedBox(height: 8),
      Center(child: SizedBox(width: 180, child: GridView.count(crossAxisCount: 3, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), mainAxisSpacing: 4, crossAxisSpacing: 4, children: _presets.map((p) {
        final sel = p == current;
        return GestureDetector(onTap: () => onChanged(p), child: Container(decoration: BoxDecoration(color: sel ? kGoldPrimary : kCreamBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: sel ? kGoldPrimary : kDivider)), child: Center(child: Text(labels[p]!, style: TextStyle(fontSize: 18, color: sel ? Colors.white : kSecondaryText)))));
      }).toList()))),
      const SizedBox(height: 12),
    ]);
  }
}
