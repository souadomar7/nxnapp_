import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:nxnapp/l10n/app_localizations.dart';
import 'home_shell.dart';
import 'package:provider/provider.dart';
import '../providers/locale_provider.dart';
import 'package:nxnapp/providers/user_provider.dart';
import '../theme.dart';
import '../services/uae_pass_service.dart';
import 'onboarding/profile_setup_page.dart';
import 'onboarding/account_in_review_page.dart';
import 'registration_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _showForgotPasswordDialog() async {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final resetEmailController = TextEditingController(text: _emailController.text.trim());
    final resetFormKey = GlobalKey<FormState>();
    bool isResetting = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            isAr ? 'إعادة تعيين كلمة المرور' : 'Reset Password',
            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.bluePrimary),
          ),
          content: Form(
            key: resetFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAr
                      ? 'أدخل بريدك الإلكتروني المسجل وسنرسل لك رابطاً لإعادة تعيين كلمة المرور.'
                      : 'Enter your registered email and we will send you a password reset link.',
                  style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: resetEmailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: isAr ? 'البريد الإلكتروني' : 'Email Address',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return isAr ? 'هذا الحقل مطلوب' : 'This field is required';
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim())) {
                      return isAr ? 'بريد إلكتروني غير صالح' : 'Invalid email address';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isResetting ? null : () => Navigator.pop(ctx),
              child: Text(isAr ? 'إلغاء' : 'Cancel'),
            ),
            ElevatedButton(
              onPressed: isResetting
                  ? null
                  : () async {
                      if (!resetFormKey.currentState!.validate()) return;
                      setDialogState(() => isResetting = true);
                      try {
                        await Supabase.instance.client.auth.resetPasswordForEmail(
                          resetEmailController.text.trim(),
                        );
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: Colors.green.shade700,
                              content: Text(
                                isAr
                                    ? 'تم إرسال رابط إعادة التعيين إلى بريدك الإلكتروني.'
                                    : 'Password reset link sent to your email.',
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => isResetting = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.bluePrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: isResetting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(isAr ? 'إرسال الرابط' : 'Send Link'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _signIn() async {
    final l10n = AppLocalizations.of(context)!;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authRes = await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = authRes.user ?? Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('User authentication failed');
      }

      // Reset guest flag upon explicit sign-in
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_guest', false);

      // Verify user profile and role from backend
      Map<String, dynamic>? profileDoc;
      try {
        profileDoc = await Supabase.instance.client
            .from('profiles')
            .select('full_name, phone, role, status, kyc_status')
            .eq('id', user.id)
            .maybeSingle();
      } catch (err) {
        debugPrint('Profile fetch note: $err');
      }

      Map<String, dynamic>? sellerDoc;
      try {
        sellerDoc = await Supabase.instance.client
            .from('sme_sellers')
            .select('business_name, contact_number, license_number, is_verified')
            .eq('id', user.id)
            .maybeSingle();
      } catch (err) {
        debugPrint('Seller fetch note: $err');
      }

      final role = profileDoc?['role']?.toString() ?? (sellerDoc != null ? 'merchant' : 'customer');
      final fullName = profileDoc?['full_name']?.toString() ?? sellerDoc?['business_name']?.toString() ?? user.userMetadata?['full_name'] ?? 'User';
      final phone = profileDoc?['phone']?.toString() ?? sellerDoc?['contact_number']?.toString() ?? '';

      if (mounted) {
        Provider.of<UserProvider>(context, listen: false).setUser(
          businessName: fullName,
          contactNumber: phone,
          licenseNumber: sellerDoc?['license_number']?.toString() ?? '',
          email: user.email,
        );
      }

      // If merchant, check license verification
      if (role == 'merchant' && sellerDoc != null) {
        final prefs = await SharedPreferences.getInstance();
        final isVerified = sellerDoc['is_verified'] == true ||
            prefs.getBool('is_verified_${user.id}') == true ||
            (prefs.getBool('merchant_verified') == true && prefs.getBool('is_merchant_pending') == false);
        if (!isVerified) {
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const AccountInReviewPage()),
              (route) => false,
            );
          }
          return;
        }
      }

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeShell()),
          (route) => false,
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        String msg = e.message;
        if (msg.contains('Bad Gateway') || msg.contains('502')) {
          msg = isAr 
              ? 'الخدمة غير متوفرة حالياً (502). يرجى التحقق من حالة السيرفر.'
              : 'Backend service is unavailable (502 Bad Gateway). Please check if your Supabase project is active.';
        } else if (msg.contains('Failed host lookup') || msg.contains('SocketException')) {
          msg = isAr
              ? 'تعذر الاتصال بالخادم. يرجى التأكد من اتصال الإنترنت وإعادة تشغيل التطبيق.'
              : 'Unable to reach the backend server. Please check your internet connection and restart the app.';
        } else if (msg.contains('Invalid login credentials')) {
          msg = isAr
              ? 'بيانات تسجيل الدخول غير صحيحة. يرجى التحقق من البريد وكلمة المرور.'
              : 'Invalid email or password. Please try again.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        final errStr = e.toString();
        String displayError = l10n.unexpectedError;
        if (errStr.contains('SocketException') || errStr.contains('Failed host lookup') || errStr.contains('ClientException')) {
          displayError = isAr
              ? 'تعذر الاتصال بالخادم. يرجى التأكد من الاتصال بالإنترنت أو إعادة تشغيل التطبيق بالكامل (Hot Restart).'
              : 'Network connection error. Please verify your internet connection or perform a full restart (Hot Restart).';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(displayError), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signInWithUaePass() async {
    setState(() => _isLoading = true);

    try {
      final uaePassData = await UaePassService().signIn();

      if (!mounted) return;

      setState(() => _isLoading = false);

      if (uaePassData != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_guest', false);

        if (!mounted) return;

        final Map<String, String> mappedData = {
          'businessName': (uaePassData['fullnameEN'] ?? '').toString(),
          'contactNumber': (uaePassData['mobile'] ?? '').toString(),
          'licenseNumber': (uaePassData['licenseNumber'] ?? '').toString(),
          'email': (uaePassData['email'] ?? '').toString(),
          'licenseOwnerName': (uaePassData['licenseOwnerName'] ?? '').toString(),
        };

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProfileSetupPage(
              uaePassData: mappedData,
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        leading: const BackButton(color: AppColors.bluePrimary),
        actions: [
          IconButton(
            icon: const Icon(Icons.language, color: AppColors.bluePrimary),
            onPressed: () {
              Provider.of<LocaleProvider>(context, listen: false).toggleLocale();
            },
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Image.asset('assets/images/nxn_logo.jpg', height: 90),
                const SizedBox(height: 36),
                
                Text(
                  l10n.welcomeBack,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.bluePrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: l10n.emailLabel,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return l10n.requiredField;
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim())) {
                      return l10n.invalidEmail;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: l10n.passwordLabel,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                        color: Colors.grey,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  obscureText: _obscurePassword,
                  validator: (v) {
                    if (v == null || v.isEmpty) return l10n.requiredField;
                    if (v.length < 6) return l10n.minSixChars;
                    return null;
                  },
                ),
                const SizedBox(height: 8),

                Align(
                  alignment: isAr ? Alignment.centerLeft : Alignment.centerRight,
                  child: TextButton(
                    onPressed: _showForgotPasswordDialog,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(50, 30),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      isAr ? 'نسيت كلمة المرور؟' : 'Forgot Password?',
                      style: const TextStyle(
                        color: AppColors.bluePrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // UAE PASS Button
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _signInWithUaePass,
                  icon: const Icon(Icons.fingerprint, color: Colors.white),
                  label: Text(l10n.loginWithUaePass, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                   style: ElevatedButton.styleFrom(
                     backgroundColor: AppColors.success,
                     padding: const EdgeInsets.symmetric(vertical: 16),
                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                   ),
                ),
                const SizedBox(height: 16),

                Row(children: [
                  const Expanded(child: Divider()), 
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8), 
                    child: Text(isAr ? "أو" : "OR", style: const TextStyle(color: Colors.grey))
                  ), 
                  const Expanded(child: Divider()),
                ]),
                const SizedBox(height: 16),

                ElevatedButton(
                  onPressed: _isLoading ? null : _signIn,
                  style: ElevatedButton.styleFrom(
                   backgroundColor: AppColors.bluePrimary,
                   padding: const EdgeInsets.symmetric(vertical: 16),
                   shape: RoundedRectangleBorder(
                     borderRadius: BorderRadius.circular(12),
                   ),
                 ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          l10n.loginButton,
                          style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RegistrationPage()),
                    );
                  },
                  child: Text(l10n.registerText, style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('is_guest', true);

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.guestMessage)),
                        );
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const HomeShell()),
                          (route) => false,
                        );
                      }
                  },
                  child: Text(
                     l10n.skipForNow,
                     style: const TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
