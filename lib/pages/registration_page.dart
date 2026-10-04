import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nxnapp/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme.dart';
import '../widgets/brand_logo.dart';
import '../providers/locale_provider.dart';
import 'package:nxnapp/providers/user_provider.dart';
import 'home_shell.dart';
import 'login.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/uae_pass_service.dart';
import 'onboarding/profile_setup_page.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _confirm = TextEditingController();
  bool _isBusinessAccount = true;
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  Future<void> _skipToHome() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_guest', true);
    } catch (_) {}
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.guestMessage)),
    );
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeShell()),
      (route) => false,
    );
  }

  Future<void> _continueWithUaePass() async {
    setState(() => _isLoading = true);
    try {
      final data = await UaePassService().signIn();
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (data != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_guest', false);

        if (!mounted) return;

        final mappedData = <String, String>{
          'businessName': (data['fullnameEN'] ?? data['firstnameEN'] ?? '').toString(),
          'contactNumber': (data['mobile'] ?? '').toString(),
          'licenseNumber': (data['licenseNumber'] ?? '').toString(),
          'email': (data['email'] ?? '').toString(),
          'uaePassUuid': (data['uuid'] ?? '').toString(),
          'licenseOwnerName': (data['licenseOwnerName'] ?? '').toString(),
          'licenseName': (data['licenseName'] ?? '').toString(),
        };
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => ProfileSetupPage(uaePassData: mappedData),
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('UAE Pass browser launched. Complete verification to continue.'),
          duration: Duration(seconds: 4),
        ));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('UAE Pass error: $e'),
        backgroundColor: Colors.red,
      ));
    }
  }

  Future<void> _submitEmailSignUp() async {
    final l10n = AppLocalizations.of(context)!;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: _email.text.trim(),
        password: _pass.text.trim(),
        data: {'full_name': _name.text.trim()},
        emailRedirectTo: 'io.supabase.nxnapp://login-callback',
      );

      if (!mounted) return;

      if (response.user != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_guest', false);

        if (!mounted) return;

        if (response.session == null) {
          // Email confirmation required
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: Text(l10n.verifyEmailTitle),
              content: Text(l10n.verifyEmailMessage(_email.text)),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                    );
                  },
                  child: Text(l10n.okButton),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.accountCreated)),
          );

          // Update user provider in memory
          Provider.of<UserProvider>(context, listen: false).setUser(
            businessName: _name.text.trim(),
            contactNumber: '',
            licenseNumber: '',
            email: _email.text.trim(),
          );

          // Route to Profile Setup to complete profile and submit compliance verification
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => ProfileSetupPage(
                initialName: _name.text.trim(),
                initialEmail: _email.text.trim(),
                initialIsBusiness: _isBusinessAccount,
              ),
            ),
            (route) => false,
          );
        }
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      String msg = e.message;
      if (msg.contains('Bad Gateway') || msg.contains('502')) {
        msg = isAr
            ? 'الخدمة غير متوفرة حالياً (502). يرجى التحقق من حالة السيرفر.'
            : 'Backend service is unavailable (502 Bad Gateway). Please check if your Supabase project is paused in the dashboard.';
      } else if (msg.contains('User already registered')) {
        msg = isAr
            ? 'هذا البريد الإلكتروني مسجل بالفعل. يرجى تسجيل الدخول.'
            : 'An account with this email already exists. Please log in.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.registrationFailed), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _pass.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: AppColors.bluePrimary),
        actions: [
          IconButton(
            icon: const Icon(Icons.language, color: AppColors.bluePrimary),
            onPressed: () {
              Provider.of<LocaleProvider>(context, listen: false).toggleLocale();
            },
          ),
          TextButton(
            onPressed: _skipToHome,
            child: Text(
              l10n.skipForNow,
              style: const TextStyle(
                color: AppColors.bluePrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
        child: Column(
          children: [
            const SizedBox(height: 10),
            const BrandLogo(height: 70),
            const SizedBox(height: 32),

            // ===== UAE PASS Quick Option =====
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F9FF),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.bluePrimary.withValues(alpha: 0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.quickRegistration,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _continueWithUaePass,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: _isLoading 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                        : const Icon(Icons.fingerprint),
                    label: Text(
                      l10n.uaePassContinue,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ===== Divider =====
            Row(
              children: [
                const Expanded(child: Divider(color: AppColors.border)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Text(l10n.orDivider, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ),
                const Expanded(child: Divider(color: AppColors.border)),
              ],
            ),

            const SizedBox(height: 24),

            // ===== Email Form =====
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.registerWithEmail,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Account Type Selector
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _isBusinessAccount = true),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _isBusinessAccount ? AppColors.bluePrimary : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  isAr ? 'تاجر / منشأة' : 'Business / Merchant',
                                  style: TextStyle(
                                    color: _isBusinessAccount ? Colors.white : AppColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _isBusinessAccount = false),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: !_isBusinessAccount ? AppColors.bluePrimary : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  isAr ? 'فرد / مشتري' : 'Retail / Individual',
                                  style: TextStyle(
                                    color: !_isBusinessAccount ? Colors.white : AppColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  TextFormField(
                    controller: _name,
                    decoration: InputDecoration(
                      labelText: _isBusinessAccount 
                          ? (isAr ? 'اسم المنشأة أو التاجر' : 'Business / Merchant Name')
                          : l10n.fullName,
                      prefixIcon: Icon(_isBusinessAccount ? Icons.business_outlined : Icons.person_outline),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? l10n.requiredField : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _email,
                    decoration: InputDecoration(
                      labelText: l10n.emailLabel,
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return l10n.requiredField;
                      final ok = RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim());
                      if (!ok) return l10n.invalidEmail;
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _pass,
                    obscureText: _obscurePass,
                    decoration: InputDecoration(
                      labelText: l10n.passwordLabel,
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePass ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                          color: Colors.grey,
                        ),
                        onPressed: () => setState(() => _obscurePass = !_obscurePass),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return l10n.requiredField;
                      if (v.length < 6) return l10n.minSixChars;
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _confirm,
                    obscureText: _obscureConfirm,
                    decoration: InputDecoration(
                      labelText: l10n.confirmPassword,
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirm ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                          color: Colors.grey,
                        ),
                        onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return l10n.requiredField;
                      if (v != _pass.text) return l10n.passwordMismatch;
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Register button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submitEmailSignUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.bluePrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 2,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            l10n.createAccount,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),

                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(l10n.alreadyHaveAccountLabel, style: TextStyle(color: Colors.grey[600])),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const LoginPage()),
                          );
                        },
                        child: Text(l10n.loginButton, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
