import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/generated/app_localizations.dart';
import '../main.dart';
import '../services/api_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  int _step = 0;
  String _channel = 'email';
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _submitting = false;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  String? _resetToken;
  int _cooldown = 0;
  Timer? _cooldownTimer;

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _cooldown = 60;
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _cooldown--;
        if (_cooldown <= 0) timer.cancel();
      });
    });
  }

  Future<void> _requestOtp() async {
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();

    if (_channel == 'email' && email.isEmpty) return;
    if (_channel == 'phone' && phone.isEmpty) return;

    setState(() => _submitting = true);
    try {
      await apiService.requestPasswordReset(
        channel: _channel,
        email: _channel == 'email' ? email : null,
        phone: _channel == 'phone' ? phone : null,
      );
      _startCooldown();
      if (mounted) {
        setState(() {
          _step = 1;
          _submitting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        _showError(e.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) return;

    setState(() => _submitting = true);
    try {
      final result = await apiService.verifyPasswordResetOtp(
        channel: _channel,
        email: _channel == 'email' ? _emailController.text.trim() : null,
        phone: _channel == 'phone' ? _phoneController.text.trim() : null,
        otp: otp,
      );
      _resetToken = result['resetToken'] as String?;
      if (mounted) {
        setState(() {
          _step = 2;
          _submitting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        _showError(e.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  Future<void> _confirmReset() async {
    final newPass = _newPasswordController.text;
    final confirmPass = _confirmPasswordController.text;
    final l10n = AppLocalizations.of(context)!;

    if (newPass.length < 6) return;
    if (newPass != confirmPass) {
      _showError(l10n.passwordsDoNotMatch);
      return;
    }
    if (_resetToken == null) return;

    setState(() => _submitting = true);
    try {
      await apiService.confirmPasswordReset(resetToken: _resetToken!, newPassword: newPass);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.passwordResetSuccess),
            backgroundColor: kGoldPrimary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 4),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        _showError(e.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: kCreamBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(l10n.resetPassword, style: playfairDisplay(fontSize: 20, fontWeight: FontWeight.w600, color: kCharcoal)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const SizedBox(height: 20),
              _buildStepIndicator(),
              const SizedBox(height: 32),
              if (_step == 0) _buildRequestStep(l10n),
              if (_step == 1) _buildOtpStep(l10n),
              if (_step == 2) _buildResetStep(l10n),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        final isActive = i <= _step;
        return Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isActive ? kGoldPrimary : kDivider,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: i < _step
                    ? const Icon(Icons.check, color: Colors.white, size: 18)
                    : Text('${i + 1}', style: TextStyle(color: isActive ? Colors.white : kSecondaryText, fontWeight: FontWeight.w600, fontSize: 14)),
              ),
            ),
            if (i < 2) Container(width: 40, height: 2, color: i < _step ? kGoldPrimary : kDivider),
          ],
        );
      }),
    );
  }

  Widget _buildRequestStep(AppLocalizations l10n) {
    return Column(
      children: [
        Icon(Icons.lock_reset, size: 64, color: kGoldPrimary.withOpacity(0.6)),
        const SizedBox(height: 16),
        Text(l10n.chooseResetMethod, style: const TextStyle(fontSize: 15, color: kSecondaryText), textAlign: TextAlign.center),
        const SizedBox(height: 24),
        Container(
          decoration: BoxDecoration(
            color: kCardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kDivider),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _channel = 'email'),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: _channel == 'email' ? kGoldPrimary : Colors.transparent,
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(11)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.email_outlined, size: 18, color: _channel == 'email' ? Colors.white : kSecondaryText),
                        const SizedBox(width: 6),
                        Text(l10n.viaEmail, style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _channel == 'email' ? Colors.white : kSecondaryText,
                        )),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _channel = 'phone'),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: _channel == 'phone' ? kGoldPrimary : Colors.transparent,
                      borderRadius: const BorderRadius.horizontal(right: Radius.circular(11)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.phone_outlined, size: 18, color: _channel == 'phone' ? Colors.white : kSecondaryText),
                        const SizedBox(width: 6),
                        Text(l10n.viaPhone, style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _channel == 'phone' ? Colors.white : kSecondaryText,
                        )),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (_channel == 'email')
          _buildInputField(
            controller: _emailController,
            label: l10n.enterEmail,
            icon: Icons.email_outlined,
            keyboard: TextInputType.emailAddress,
            testId: 'input-reset-email',
          ),
        if (_channel == 'phone')
          _buildInputField(
            controller: _phoneController,
            label: l10n.enterPhone,
            icon: Icons.phone_outlined,
            keyboard: TextInputType.phone,
            testId: 'input-reset-phone',
          ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _submitting ? null : _requestOtp,
            child: _submitting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(l10n.sendCode),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.backToLogin, style: const TextStyle(color: kGoldPrimary, fontSize: 14)),
        ),
      ],
    );
  }

  Widget _buildOtpStep(AppLocalizations l10n) {
    final target = _channel == 'email' ? _emailController.text.trim() : _phoneController.text.trim();
    final sentMsg = _channel == 'email' ? l10n.codeSentToEmail : l10n.codeSentToPhone;

    return Column(
      children: [
        Icon(Icons.sms_outlined, size: 64, color: kGoldPrimary.withOpacity(0.6)),
        const SizedBox(height: 16),
        Text(sentMsg, style: const TextStyle(fontSize: 15, color: kCharcoal, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
        const SizedBox(height: 6),
        Text(target, style: const TextStyle(fontSize: 14, color: kGoldPrimary, fontWeight: FontWeight.w600)),
        const SizedBox(height: 24),
        Text(l10n.enterOtp, style: const TextStyle(fontSize: 13, color: kSecondaryText)),
        const SizedBox(height: 12),
        _buildOtpFields(),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _submitting || _otpController.text.trim().length != 6 ? null : _verifyOtp,
            child: _submitting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(l10n.verifyCode),
          ),
        ),
        const SizedBox(height: 16),
        if (_cooldown > 0)
          Text(l10n.resendCodeIn(_cooldown.toString()), style: const TextStyle(fontSize: 13, color: kSecondaryText))
        else
          TextButton(
            onPressed: _submitting ? null : () async {
              await _requestOtp();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.otpSent),
                    backgroundColor: kGoldPrimary,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              }
            },
            child: Text(l10n.resendCode, style: const TextStyle(color: kGoldPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
          ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => setState(() {
            _step = 0;
            _otpController.clear();
          }),
          child: Text(l10n.backToLogin, style: const TextStyle(color: kSecondaryText, fontSize: 13)),
        ),
      ],
    );
  }

  Widget _buildOtpFields() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 300),
      child: TextFormField(
        controller: _otpController,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 6,
        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: kCharcoal, letterSpacing: 12),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: (v) {
          setState(() {});
          if (v.length == 6) _verifyOtp();
        },
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: kCardBg,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kDivider)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kDivider)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kGoldPrimary, width: 2)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        ),
      ),
    );
  }

  Widget _buildResetStep(AppLocalizations l10n) {
    return Column(
      children: [
        Icon(Icons.vpn_key_outlined, size: 64, color: kGoldPrimary.withOpacity(0.6)),
        const SizedBox(height: 16),
        Text(l10n.resetPassword, style: playfairDisplay(fontSize: 20, fontWeight: FontWeight.w600, color: kCharcoal)),
        const SizedBox(height: 24),
        _buildInputField(
          controller: _newPasswordController,
          label: l10n.newPassword,
          icon: Icons.lock_outline,
          obscure: _obscureNew,
          suffixIcon: IconButton(
            icon: Icon(_obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: kSecondaryText, size: 20),
            onPressed: () => setState(() => _obscureNew = !_obscureNew),
          ),
          testId: 'input-new-password',
        ),
        const SizedBox(height: 14),
        _buildInputField(
          controller: _confirmPasswordController,
          label: l10n.confirmPassword,
          icon: Icons.lock_outline,
          obscure: _obscureConfirm,
          suffixIcon: IconButton(
            icon: Icon(_obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: kSecondaryText, size: 20),
            onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
          ),
          testId: 'input-confirm-password',
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _submitting ? null : _confirmReset,
            child: _submitting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(l10n.resetPassword),
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboard = TextInputType.text,
    bool obscure = false,
    Widget? suffixIcon,
    String? testId,
  }) {
    return TextFormField(
      key: testId != null ? Key(testId) : null,
      controller: controller,
      keyboardType: keyboard,
      obscureText: obscure,
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}
