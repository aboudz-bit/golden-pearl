import 'dart:convert';
import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../main.dart';
import '../../services/api_service.dart';

class AdminHeroTextScreen extends StatefulWidget {
  const AdminHeroTextScreen({super.key});

  @override
  State<AdminHeroTextScreen> createState() => _AdminHeroTextScreenState();
}

class _AdminHeroTextScreenState extends State<AdminHeroTextScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _loading = true;
  bool _publishing = false;

  Map<String, dynamic> _published = {};
  Map<String, dynamic> _draft = {};

  final _fonts = ['Playfair', 'Inter', 'Cairo', 'Tajawal'];
  final _weights = [400, 500, 600, 700];
  final _presets = [
    'TopLeft', 'TopCenter', 'TopRight',
    'CenterLeft', 'Center', 'CenterRight',
    'BottomLeft', 'BottomCenter', 'BottomRight',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() { if (mounted) setState(() {}); });
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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

  Map<String, dynamic> _defaultOverlay() => {
    'ar': {
      'headline': 'أناقة لا تُضاهى',
      'subheadline': 'اكتشفي أحدث مجموعتنا من الأزياء الفاخرة المصنوعة يدوياً',
      'cta': 'تسوقي الآن',
      'style': _defaultStyle(),
    },
    'en': {
      'headline': 'Elegance Redefined',
      'subheadline': 'Discover our latest collection of handcrafted luxury fashion',
      'cta': 'Shop Now',
      'style': _defaultStyle(),
    },
  };

  Future<void> _loadData() async {
    try {
      final overlay = await apiService.getHeroOverlay();
      final data = overlay ?? _defaultOverlay();
      if (data['ar'] == null) data['ar'] = _defaultOverlay()['ar'];
      if (data['en'] == null) data['en'] = _defaultOverlay()['en'];
      if ((data['ar'] as Map)['style'] == null) (data['ar'] as Map)['style'] = _defaultStyle();
      if ((data['en'] as Map)['style'] == null) (data['en'] as Map)['style'] = _defaultStyle();
      _published = jsonDecode(jsonEncode(data));
      _draft = jsonDecode(jsonEncode(data));
    } catch (_) {
      _published = _defaultOverlay();
      _draft = jsonDecode(jsonEncode(_published));
    }
    if (mounted) setState(() => _loading = false);
  }

  String get _activeLang => _tabController.index == 0 ? 'ar' : 'en';

  Map<String, dynamic> get _activeDraft =>
      (_draft[_activeLang] as Map<String, dynamic>?) ?? _defaultOverlay()[_activeLang]!;

  Map<String, dynamic> get _activeStyle =>
      (_activeDraft['style'] as Map<String, dynamic>?) ?? _defaultStyle();

  void _updateDraft(String key, dynamic value) {
    setState(() {
      (_draft[_activeLang] as Map<String, dynamic>)[key] = value;
    });
  }

  void _updateStyle(String key, dynamic value) {
    setState(() {
      ((_draft[_activeLang] as Map<String, dynamic>)['style'] as Map<String, dynamic>)[key] = value;
    });
  }

  void _updateShadow(String key, dynamic value) {
    setState(() {
      final shadow = Map<String, dynamic>.from(_activeStyle['shadow'] as Map? ?? {});
      shadow[key] = value;
      _updateStyle('shadow', shadow);
    });
  }

  Future<void> _publish() async {
    setState(() => _publishing = true);
    try {
      await apiService.saveHeroOverlay(_draft);
      _published = jsonDecode(jsonEncode(_draft));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Published successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red.shade400, behavior: SnackBarBehavior.floating),
        );
      }
    }
    if (mounted) setState(() => _publishing = false);
  }

  void _reset() {
    setState(() {
      _draft = jsonDecode(jsonEncode(_published));
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Reset to published state'),
        backgroundColor: kGoldPrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Color _hexToColor(String hex, {double opacity = 1.0}) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    try {
      return Color(int.parse(hex, radix: 16)).withOpacity(opacity);
    } catch (_) {
      return Colors.white.withOpacity(opacity);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: kGoldPrimary));

    return Column(
      children: [
        Container(
          color: kCreamBg,
          child: TabBar(
            controller: _tabController,
            labelColor: kGoldPrimary,
            unselectedLabelColor: kSecondaryText,
            indicatorColor: kGoldPrimary,
            tabs: const [
              Tab(text: 'العربية (AR)'),
              Tab(text: 'English (EN)'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildEditor('ar'),
              _buildEditor('en'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEditor(String lang) {
    final draft = (_draft[lang] as Map<String, dynamic>?) ?? {};
    final style = (draft['style'] as Map<String, dynamic>?) ?? _defaultStyle();
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
        _textField('CTA Button Label', draft['cta'] ?? '', (v) => _updateDraft('cta', v)),
        const Divider(height: 32),
        _sectionTitle('Typography'),
        _dropdownRow('Font Family', style['fontFamily'] ?? 'Playfair', _fonts, (v) => _updateStyle('fontFamily', v)),
        _sliderRow('Headline Size', (style['headlineSize'] as num?)?.toDouble() ?? 30, 16, 60, (v) => _updateStyle('headlineSize', v.round())),
        _sliderRow('Subheadline Size', (style['subheadlineSize'] as num?)?.toDouble() ?? 14, 10, 30, (v) => _updateStyle('subheadlineSize', v.round())),
        _dropdownRow('Font Weight', (style['fontWeight'] as num?)?.toInt() ?? 700, _weights, (v) => _updateStyle('fontWeight', v)),
        _sliderRow('Letter Spacing', (style['letterSpacing'] as num?)?.toDouble() ?? 0, -3, 10, (v) => _updateStyle('letterSpacing', double.parse(v.toStringAsFixed(1)))),
        const Divider(height: 32),
        _sectionTitle('Color & Shadow'),
        _colorField('Text Color', style['color'] ?? '#FFFFFF', (v) => _updateStyle('color', v)),
        _switchRow('Text Shadow', shadow['enabled'] == true, (v) => _updateShadow('enabled', v)),
        if (shadow['enabled'] == true) ...[
          _colorField('Shadow Color', shadow['color'] ?? '#000000', (v) => _updateShadow('color', v)),
          _sliderRow('Shadow Blur', (shadow['blur'] as num?)?.toDouble() ?? 8, 0, 30, (v) => _updateShadow('blur', v.round())),
          _sliderRow('Shadow Opacity', (shadow['opacity'] as num?)?.toDouble() ?? 0.5, 0, 1, (v) => _updateShadow('opacity', double.parse(v.toStringAsFixed(2)))),
          _sliderRow('Shadow X', (shadow['offsetX'] as num?)?.toDouble() ?? 0, -10, 10, (v) => _updateShadow('offsetX', v.round())),
          _sliderRow('Shadow Y', (shadow['offsetY'] as num?)?.toDouble() ?? 2, -10, 10, (v) => _updateShadow('offsetY', v.round())),
        ],
        const Divider(height: 32),
        _sectionTitle('Layout & Position'),
        _alignmentSelector(style['align'] ?? 'center', (v) => _updateStyle('align', v)),
        const SizedBox(height: 12),
        _presetGrid(style['positionPreset'] ?? 'BottomCenter', (v) => _updateStyle('positionPreset', v)),
        _sliderRow('X Offset %', (style['offsetXPercent'] as num?)?.toDouble() ?? 0, -30, 30, (v) => _updateStyle('offsetXPercent', v.round())),
        _sliderRow('Y Offset %', (style['offsetYPercent'] as num?)?.toDouble() ?? 0, -30, 30, (v) => _updateStyle('offsetYPercent', v.round())),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _reset,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Reset'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: kSecondaryText,
                  side: const BorderSide(color: kDivider),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: _publishing ? null : _publish,
                icon: _publishing ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.publish, size: 18),
                label: Text(_publishing ? 'Publishing...' : 'Publish'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildPreview(Map<String, dynamic> draft, Map<String, dynamic> style) {
    final headline = draft['headline'] ?? '';
    final sub = draft['subheadline'] ?? '';
    final cta = draft['cta'] ?? '';
    final color = _hexToColor(style['color'] ?? '#FFFFFF');
    final weight = FontWeight.values[((style['fontWeight'] as num? ?? 700) ~/ 100).clamp(1, 8)];
    final hSize = (style['headlineSize'] as num?)?.toDouble() ?? 30;
    final sSize = (style['subheadlineSize'] as num?)?.toDouble() ?? 14;
    final spacing = (style['letterSpacing'] as num?)?.toDouble() ?? 0;
    final fontFamily = style['fontFamily'] ?? 'Playfair';
    final textAlign = _parseAlign(style['align']);
    final crossAlign = _parseCross(style['align']);

    List<Shadow>? shadows;
    final shadowMap = style['shadow'] as Map<String, dynamic>?;
    if (shadowMap != null && shadowMap['enabled'] == true) {
      shadows = [
        Shadow(
          color: _hexToColor(shadowMap['color'] ?? '#000000', opacity: (shadowMap['opacity'] as num?)?.toDouble() ?? 0.5),
          blurRadius: (shadowMap['blur'] as num?)?.toDouble() ?? 8,
          offset: Offset((shadowMap['offsetX'] as num?)?.toDouble() ?? 0, (shadowMap['offsetY'] as num?)?.toDouble() ?? 2),
        ),
      ];
    }

    final preset = style['positionPreset'] ?? 'BottomCenter';
    final xOff = (style['offsetXPercent'] as num?)?.toDouble() ?? 0;
    final yOff = (style['offsetYPercent'] as num?)?.toDouble() ?? 0;
    final alignment = _presetAlignment(preset, xOff, yOff);

    TextStyle headlineStyle;
    if (fontFamily == 'Playfair') {
      headlineStyle = playfairDisplay(fontSize: hSize.clamp(16, 36).toDouble(), fontWeight: weight, color: color).copyWith(
        letterSpacing: spacing, shadows: shadows,
      );
    } else {
      headlineStyle = TextStyle(fontSize: hSize.clamp(16, 36).toDouble(), fontWeight: weight, color: color, letterSpacing: spacing, shadows: shadows);
    }

    final subStyle = TextStyle(fontSize: sSize.clamp(10, 20).toDouble(), color: color.withOpacity(0.7), height: 1.4, letterSpacing: spacing, shadows: shadows);

    return Container(
      height: 240,
      decoration: BoxDecoration(
        color: kCharcoal,
        borderRadius: BorderRadius.circular(12),
        image: const DecorationImage(
          image: AssetImage('assets/images/hero1.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  stops: const [0.0, 0.45],
                  colors: [Colors.black.withOpacity(0.65), Colors.transparent],
                ),
              ),
            ),
            Align(
              alignment: alignment,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: crossAlign,
                  children: [
                    if (headline.isNotEmpty)
                      Text(headline, style: headlineStyle, textAlign: textAlign, maxLines: 2, overflow: TextOverflow.ellipsis),
                    if (sub.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(sub, style: subStyle, textAlign: textAlign, maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                    if (cta.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: kGoldPrimary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(cta, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                      ),
                    ],
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
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('PREVIEW', style: TextStyle(color: Colors.white60, fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 1)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Alignment _presetAlignment(String preset, double xOff, double yOff) {
    double x = 0, y = 0;
    switch (preset) {
      case 'TopLeft':       x = -1; y = -1; break;
      case 'TopCenter':     x = 0;  y = -1; break;
      case 'TopRight':      x = 1;  y = -1; break;
      case 'CenterLeft':    x = -1; y = 0;  break;
      case 'Center':        x = 0;  y = 0;  break;
      case 'CenterRight':   x = 1;  y = 0;  break;
      case 'BottomLeft':    x = -1; y = 1;  break;
      case 'BottomCenter':  x = 0;  y = 1;  break;
      case 'BottomRight':   x = 1;  y = 1;  break;
    }
    return Alignment((x + xOff / 50).clamp(-1.0, 1.0), (y + yOff / 50).clamp(-1.0, 1.0));
  }

  TextAlign _parseAlign(String? a) {
    switch (a) { case 'left': return TextAlign.left; case 'right': return TextAlign.right; default: return TextAlign.center; }
  }

  CrossAxisAlignment _parseCross(String? a) {
    switch (a) { case 'left': return CrossAxisAlignment.start; case 'right': return CrossAxisAlignment.end; default: return CrossAxisAlignment.center; }
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: playfairDisplay(fontSize: 16, fontWeight: FontWeight.w600, color: kCharcoal)),
    );
  }

  Widget _textField(String label, String value, ValueChanged<String> onChanged, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: TextEditingController(text: value),
        maxLines: maxLines,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 13, color: kSecondaryText),
          filled: true,
          fillColor: kCreamBg,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
        style: const TextStyle(fontSize: 14, color: kCharcoal),
      ),
    );
  }

  Widget _dropdownRow<T>(String label, T value, List<T> items, ValueChanged<T> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(fontSize: 13, color: kCharcoal))),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(color: kCreamBg, borderRadius: BorderRadius.circular(10)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<T>(
                  value: items.contains(value) ? value : items.first,
                  isExpanded: true,
                  items: items.map((e) => DropdownMenuItem(value: e, child: Text('$e', style: const TextStyle(fontSize: 13)))).toList(),
                  onChanged: (v) { if (v != null) onChanged(v); },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sliderRow(String label, double value, double min, double max, ValueChanged<double> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(fontSize: 12, color: kCharcoal))),
          Expanded(
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              divisions: ((max - min) * (max - min < 5 ? 20 : 1)).round().clamp(1, 100),
              activeColor: kGoldPrimary,
              onChanged: onChanged,
            ),
          ),
          SizedBox(
            width: 44,
            child: Text(
              value == value.roundToDouble() ? '${value.round()}' : value.toStringAsFixed(1),
              style: const TextStyle(fontSize: 12, color: kSecondaryText),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _colorField(String label, String hex, ValueChanged<String> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(fontSize: 13, color: kCharcoal))),
          Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: _hexToColor(hex),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: kDivider),
            ),
          ),
          Expanded(
            child: SizedBox(
              height: 38,
              child: TextField(
                controller: TextEditingController(text: hex),
                onChanged: (v) {
                  final clean = v.startsWith('#') ? v : '#$v';
                  if (RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(clean)) onChanged(clean);
                },
                decoration: InputDecoration(
                  hintText: '#FFFFFF',
                  hintStyle: const TextStyle(fontSize: 12, color: kSecondaryText),
                  filled: true,
                  fillColor: kCreamBg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                ),
                style: const TextStyle(fontSize: 13, color: kCharcoal),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _switchRow(String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: kCharcoal)),
          const Spacer(),
          Switch(value: value, activeColor: kGoldPrimary, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _alignmentSelector(String current, ValueChanged<String> onChanged) {
    return Row(
      children: [
        const SizedBox(width: 0),
        const Text('Text Align', style: TextStyle(fontSize: 13, color: kCharcoal)),
        const Spacer(),
        ToggleButtons(
          isSelected: ['left', 'center', 'right'].map((a) => a == current).toList(),
          onPressed: (i) => onChanged(['left', 'center', 'right'][i]),
          borderRadius: BorderRadius.circular(8),
          selectedColor: kGoldPrimary,
          fillColor: kGoldPrimary.withOpacity(0.1),
          constraints: const BoxConstraints(minWidth: 44, minHeight: 36),
          children: const [
            Icon(Icons.format_align_left, size: 18),
            Icon(Icons.format_align_center, size: 18),
            Icon(Icons.format_align_right, size: 18),
          ],
        ),
      ],
    );
  }

  Widget _presetGrid(String current, ValueChanged<String> onChanged) {
    final labels = {
      'TopLeft': '↖', 'TopCenter': '↑', 'TopRight': '↗',
      'CenterLeft': '←', 'Center': '●', 'CenterRight': '→',
      'BottomLeft': '↙', 'BottomCenter': '↓', 'BottomRight': '↘',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Position Preset', style: TextStyle(fontSize: 13, color: kCharcoal)),
        const SizedBox(height: 8),
        Center(
          child: SizedBox(
            width: 180,
            child: GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              children: _presets.map((p) {
                final sel = p == current;
                return GestureDetector(
                  onTap: () => onChanged(p),
                  child: Container(
                    decoration: BoxDecoration(
                      color: sel ? kGoldPrimary : kCreamBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: sel ? kGoldPrimary : kDivider),
                    ),
                    child: Center(
                      child: Text(labels[p]!, style: TextStyle(fontSize: 18, color: sel ? Colors.white : kSecondaryText)),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
