import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/generated/app_localizations.dart';
import '../main.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/language_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isRegister = false;
  bool _submitting = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _hasSavedAccount = false;
  bool _prefsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadSavedAccount();
  }

  Future<void> _loadSavedAccount() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getBool('rememberAccount') ?? false;
    final identifier = prefs.getString('savedIdentifier') ?? '';
    final savedLang = prefs.getString('savedLanguage');

    if (saved && identifier.isNotEmpty) {
      _emailController.text = identifier;
      _rememberMe = true;
      _hasSavedAccount = true;

      if (savedLang != null && mounted) {
        final langProvider = Provider.of<LanguageProvider>(context, listen: false);
        if (langProvider.languageCode != savedLang) {
          langProvider.setLanguage(savedLang);
        }
      }
    }

    if (mounted) setState(() => _prefsLoaded = true);
  }

  Future<void> _saveRememberMe(String identifier) async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setBool('rememberAccount', true);
      await prefs.setString('savedIdentifier', identifier);
      final lang = Provider.of<LanguageProvider>(context, listen: false).languageCode;
      await prefs.setString('savedLanguage', lang);
    } else {
      await prefs.remove('rememberAccount');
      await prefs.remove('savedIdentifier');
      await prefs.remove('savedLanguage');
    }
  }

  Future<void> _clearSavedAccount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('rememberAccount');
    await prefs.remove('savedIdentifier');
    await prefs.remove('savedLanguage');
    setState(() {
      _emailController.clear();
      _passwordController.clear();
      _rememberMe = false;
      _hasSavedAccount = false;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final cart = Provider.of<CartProvider>(context, listen: false);

    String? error;
    if (_isRegister) {
      error = await auth.register(
        _emailController.text.trim(),
        _passwordController.text,
        _nameController.text.trim(),
        _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
      );
    } else {
      error = await auth.login(_emailController.text.trim(), _passwordController.text);
    }

    if (!mounted) return;

    if (error != null) {
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    if (!_isRegister) {
      await _saveRememberMe(_emailController.text.trim());
    }

    try {
      await apiService.mergeCart();
      await cart.loadCart();
    } catch (_) {}

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: kCreamBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Image.asset('assets/images/logo.png', height: 72),
              const SizedBox(height: 16),
              Text(
                l10n.appName,
                style: playfairDisplay(fontSize: 26, fontWeight: FontWeight.w700, color: kCharcoal),
              ),
              const SizedBox(height: 8),
              Text(
                _isRegister ? l10n.createAccount : l10n.loginToProceed,
                style: const TextStyle(fontSize: 14, color: kSecondaryText),
              ),
              const SizedBox(height: 32),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    if (_isRegister) ...[
                      _buildField(
                        label: l10n.fullName,
                        controller: _nameController,
                        icon: Icons.person_outline,
                        validator: (v) => (v == null || v.trim().isEmpty) ? l10n.required : null,
                        testId: 'input-name',
                      ),
                      const SizedBox(height: 14),
                      _buildField(
                        label: l10n.phone,
                        controller: _phoneController,
                        icon: Icons.phone_outlined,
                        keyboard: TextInputType.phone,
                        testId: 'input-phone',
                      ),
                      const SizedBox(height: 14),
                    ],
                    _buildField(
                      label: l10n.email,
                      controller: _emailController,
                      icon: Icons.email_outlined,
                      keyboard: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return l10n.required;
                        if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())) return l10n.invalidEmail;
                        return null;
                      },
                      testId: 'input-email',
                    ),
                    const SizedBox(height: 14),
                    _buildField(
                      label: l10n.password,
                      controller: _passwordController,
                      icon: Icons.lock_outline,
                      obscure: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: kSecondaryText, size: 20),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return l10n.required;
                        if (v.length < 6) return l10n.passwordTooShort;
                        return null;
                      },
                      testId: 'input-password',
                    ),
                  ],
                ),
              ),
              if (!_isRegister && _prefsLoaded) ...[
                const SizedBox(height: 12),
                InkWell(
                  onTap: () => setState(() => _rememberMe = !_rememberMe),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 22,
                          height: 22,
                          child: Checkbox(
                            value: _rememberMe,
                            onChanged: (v) => setState(() => _rememberMe = v ?? false),
                            activeColor: kGoldPrimary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            side: BorderSide(color: _rememberMe ? kGoldPrimary : kSecondaryText, width: 1.5),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          l10n.rememberMe,
                          style: TextStyle(
                            fontSize: 14,
                            color: _rememberMe ? kCharcoal : kSecondaryText,
                            fontWeight: _rememberMe ? FontWeight.w500 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(_isRegister ? l10n.register : l10n.login),
                ),
              ),
              if (!_isRegister && _hasSavedAccount) ...[
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: _clearSavedAccount,
                  icon: const Icon(Icons.switch_account_outlined, size: 18, color: kGoldPrimary),
                  label: Text(
                    l10n.useAnotherAccount,
                    style: const TextStyle(fontSize: 13, color: kGoldPrimary, fontWeight: FontWeight.w500),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: kGoldPrimary.withOpacity(0.2)),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isRegister ? l10n.alreadyHaveAccount : l10n.dontHaveAccount,
                    style: const TextStyle(fontSize: 14, color: kSecondaryText),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _isRegister = !_isRegister),
                    child: Text(
                      _isRegister ? l10n.login : l10n.register,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kGoldPrimary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboard = TextInputType.text,
    bool obscure = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    String? testId,
  }) {
    return TextFormField(
      key: testId != null ? Key(testId) : null,
      controller: controller,
      keyboardType: keyboard,
      obscureText: obscure,
      validator: validator,
      style: const TextStyle(fontSize: 16, color: kCharcoal),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: kSecondaryText, fontSize: 14),
        prefixIcon: Icon(icon, color: kGoldPrimary, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: kCardBg,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kDivider)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kDivider)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kGoldPrimary)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}
