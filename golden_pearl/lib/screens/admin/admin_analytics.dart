import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../main.dart';
import '../../services/api_service.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    try {
      final data = await apiService.getAnalytics();
      if (mounted) setState(() { _data = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lang = Provider.of<LanguageProvider>(context).languageCode;

    if (_loading) return const Center(child: CircularProgressIndicator(color: kGoldPrimary));

    if (_data == null) {
      return Center(child: Text(l10n.error, style: const TextStyle(color: kSecondaryText)));
    }

    final totalViews = _data!['totalViews'] ?? 0;
    final uniqueSessions = _data!['uniqueSessions'] ?? 0;
    final topProducts = (_data!['topProducts'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return RefreshIndicator(
      onRefresh: _loadAnalytics,
      color: kGoldPrimary,
      child: ListView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.all(20),
        children: [
          Text(l10n.analytics, style: playfairDisplay(fontSize: 24, fontWeight: FontWeight.w700, color: kCharcoal)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _metricCard(Icons.visibility, l10n.totalVisits, '$totalViews', Colors.blue)),
              const SizedBox(width: 12),
              Expanded(child: _metricCard(Icons.people, l10n.uniqueSessions, '$uniqueSessions', Colors.green)),
            ],
          ),
          const SizedBox(height: 24),
          Text(l10n.topProducts, style: playfairDisplay(fontSize: 18, fontWeight: FontWeight.w600, color: kCharcoal)),
          const SizedBox(height: 12),
          if (topProducts.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: kCardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kDivider),
              ),
              child: Center(child: Text(l10n.noProducts, style: const TextStyle(color: kSecondaryText))),
            )
          else
            ...topProducts.asMap().entries.map((entry) {
              final idx = entry.key;
              final item = entry.value;
              final product = item['product'] as Map<String, dynamic>?;
              final views = item['views'] ?? 0;
              final name = product != null
                  ? (lang == 'ar' ? product['nameAr'] : product['nameEn']) ?? 'Product #${item['productId']}'
                  : 'Product #${item['productId']}';

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: kCardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kDivider),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: kGoldPrimary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(child: Text('${idx + 1}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kGoldPrimary))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: kCharcoal), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    Text('$views ${l10n.views}', style: const TextStyle(fontSize: 12, color: kSecondaryText)),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _metricCard(IconData icon, String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kDivider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(value, style: playfairDisplay(fontSize: 24, fontWeight: FontWeight.w700, color: kCharcoal)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontSize: 12, color: kSecondaryText)),
        ],
      ),
    );
  }
}
