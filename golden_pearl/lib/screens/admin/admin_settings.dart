import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../main.dart';
import '../../services/api_service.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final Map<String, TextEditingController> _controllers = {};
  bool _loading = true;
  bool _saving = false;

  final _settingKeys = [
    'hero_banner',
    'category_dresses',
    'category_jalabiyas',
    'category_kids',
    'category_gifts',
  ];

  @override
  void initState() {
    super.initState();
    for (final key in _settingKeys) {
      _controllers[key] = TextEditingController();
    }
    _loadSettings();
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await apiService.getAllSettings();
      for (final s in settings) {
        final key = s['key'] as String?;
        final value = s['value'] as String?;
        if (key != null && _controllers.containsKey(key)) {
          _controllers[key]!.text = value ?? '';
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _saveSetting(String key) async {
    setState(() => _saving = true);
    try {
      await apiService.updateSetting(key, _controllers[key]!.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.saved),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.error), backgroundColor: Colors.red.shade400, behavior: SnackBarBehavior.floating),
        );
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  String _settingLabel(String key, AppLocalizations l10n) {
    switch (key) {
      case 'hero_banner': return l10n.heroBanner;
      case 'category_dresses': return l10n.dresses;
      case 'category_jalabiyas': return l10n.jalabiyas;
      case 'category_kids': return l10n.kids;
      case 'category_gifts': return l10n.gifts;
      default: return key;
    }
  }

  IconData _settingIcon(String key) {
    switch (key) {
      case 'hero_banner': return Icons.panorama;
      case 'category_dresses': return Icons.checkroom;
      case 'category_jalabiyas': return Icons.dry_cleaning;
      case 'category_kids': return Icons.child_care;
      case 'category_gifts': return Icons.card_giftcard;
      default: return Icons.settings;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_loading) return const Center(child: CircularProgressIndicator(color: kGoldPrimary));

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        Text(l10n.manageBanners, style: playfairDisplay(fontSize: 20, fontWeight: FontWeight.w700, color: kCharcoal)),
        const SizedBox(height: 16),
        ..._settingKeys.map((key) => _settingCard(key, l10n)),
      ],
    );
  }

  Widget _settingCard(String key, AppLocalizations l10n) {
    final controller = _controllers[key]!;
    final hasValue = controller.text.trim().isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kDivider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_settingIcon(key), color: kGoldPrimary, size: 20),
              const SizedBox(width: 8),
              Text(_settingLabel(key, l10n), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kCharcoal)),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: l10n.imageUrlHint,
              hintStyle: const TextStyle(fontSize: 13, color: kSecondaryText),
              filled: true,
              fillColor: kCreamBg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            style: const TextStyle(fontSize: 13, color: kCharcoal),
          ),
          if (hasValue) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                controller.text.trim(),
                height: 100,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 60,
                  color: kCreamBg,
                  child: const Center(child: Icon(Icons.broken_image, color: kSecondaryText)),
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: ElevatedButton(
              onPressed: _saving ? null : () => _saveSetting(key),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                minimumSize: Size.zero,
              ),
              child: Text(l10n.save, style: const TextStyle(fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }
}
