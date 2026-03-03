import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../providers/language_provider.dart';
import '../utils/money_formatter.dart';

class OrderConfirmationScreen extends StatelessWidget {
  final dynamic order;
  const OrderConfirmationScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lang = Provider.of<LanguageProvider>(context).languageCode;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: kGoldPrimary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 40),
                ),
                const SizedBox(height: 24),
                Text(l10n.orderConfirmed, style: playfairDisplay(fontSize: 28, fontWeight: FontWeight.w700, color: kCharcoal)),
                const SizedBox(height: 12),
                Text(l10n.orderConfirmedMessage, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
                if (order != null) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: kCreamBg,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Text(
                          l10n.orderNumber('${order.id}'),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: kCharcoal),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          MoneyFormatter.format(order.total, lang),
                          style: playfairDisplay(fontSize: 26, fontWeight: FontWeight.w700, color: kGoldPrimary),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                    child: Text(l10n.continueShopping),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                  child: Text(l10n.orderHistory, style: const TextStyle(color: kGoldPrimary)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
