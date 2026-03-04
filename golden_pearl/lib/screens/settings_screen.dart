import 'package:flutter/material.dart';
import '../l10n/generated/app_localizations.dart';
import '../main.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../providers/auth_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final langProvider = Provider.of<LanguageProvider>(context);
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Column(
              children: [
                Image.asset('assets/images/logo.png', height: 80),
                const SizedBox(height: 12),
                Text(l10n.appName, style: playfairDisplay(fontSize: 24, fontWeight: FontWeight.w700, color: kCharcoal)),
                const SizedBox(height: 4),
                Text(l10n.aboutBrand, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (auth.isLoggedIn) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kGoldPrimary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kGoldPrimary.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: kGoldPrimary.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person, color: kGoldPrimary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${l10n.welcomeBack}, ${auth.userName}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kCharcoal)),
                        Text(auth.userEmail, style: const TextStyle(fontSize: 12, color: kSecondaryText)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (auth.isAdminOrStaff) ...[
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kGoldPrimary.withOpacity(0.3)),
                boxShadow: [BoxShadow(color: kGoldPrimary.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: kGoldPrimary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.admin_panel_settings, color: kGoldPrimary, size: 22),
                ),
                title: Text(l10n.adminPanel, style: const TextStyle(fontWeight: FontWeight.w600, color: kCharcoal)),
                trailing: const Icon(Icons.chevron_right, color: kGoldPrimary),
                onTap: () => Navigator.pushNamed(context, '/admin'),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Column(
              children: [
                if (!auth.isLoggedIn)
                  ListTile(
                    leading: const Icon(Icons.login, color: kGoldPrimary),
                    title: Text(l10n.login),
                    trailing: const Icon(Icons.chevron_right, color: kSecondaryText),
                    onTap: () => Navigator.pushNamed(context, '/login'),
                  ),
                if (!auth.isLoggedIn) Divider(height: 0, color: kDivider),
                ListTile(
                  leading: const Icon(Icons.notifications_outlined, color: kGoldPrimary),
                  title: Text(l10n.notifications),
                  trailing: const Icon(Icons.chevron_right, color: kSecondaryText),
                  onTap: () => Navigator.pushNamed(context, '/notifications'),
                ),
                Divider(height: 0, color: kDivider),
                ListTile(
                  leading: const Icon(Icons.receipt_long_outlined, color: kGoldPrimary),
                  title: Text(l10n.myOrders),
                  trailing: const Icon(Icons.chevron_right, color: kSecondaryText),
                  onTap: () => Navigator.pushNamed(context, '/orders'),
                ),
                Divider(height: 0, color: kDivider),
                ListTile(
                  leading: const Icon(Icons.language, color: kGoldPrimary),
                  title: Text(l10n.language),
                  subtitle: Text(langProvider.isArabic ? l10n.arabic : l10n.english),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: kCreamBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () => langProvider.setLanguage('ar'),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: langProvider.isArabic ? kGoldPrimary : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text('AR', style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: langProvider.isArabic ? Colors.white : kSecondaryText,
                            )),
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => langProvider.setLanguage('en'),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: !langProvider.isArabic ? kGoldPrimary : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text('EN', style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: !langProvider.isArabic ? Colors.white : kSecondaryText,
                            )),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Divider(height: 0, color: kDivider),
                ListTile(
                  leading: const Icon(Icons.local_shipping_outlined, color: kGoldPrimary),
                  title: Text(l10n.shippingInfo),
                ),
                Divider(height: 0, color: kDivider),
                ListTile(
                  leading: const Icon(Icons.replay, color: kGoldPrimary),
                  title: Text(l10n.returnPolicy),
                ),
                Divider(height: 0, color: kDivider),
                ListTile(
                  leading: const Icon(Icons.lock_outline, color: kGoldPrimary),
                  title: Text(l10n.securePayment),
                ),
                if (auth.isLoggedIn) ...[
                  Divider(height: 0, color: kDivider),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: Text(l10n.logout, style: const TextStyle(color: Colors.red)),
                    onTap: () async {
                      await auth.logout();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.logoutSuccess),
                            backgroundColor: kGoldPrimary,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 32),
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kGoldPrimary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                l10n.welcomeDiscount,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: kGoldDark, fontWeight: FontWeight.w500),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text('v1.0.0', style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}
