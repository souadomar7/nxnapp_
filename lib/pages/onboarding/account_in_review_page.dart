import 'package:flutter/material.dart';
import '../../theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../splash_page.dart';
import '../home_shell.dart';

class AccountInReviewPage extends StatefulWidget {
  const AccountInReviewPage({super.key});

  @override
  State<AccountInReviewPage> createState() => _AccountInReviewPageState();
}

class _AccountInReviewPageState extends State<AccountInReviewPage> {
  bool _isChecking = false;

  Future<void> _checkStatus() async {
    setState(() => _isChecking = true);
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final data = await Supabase.instance.client
            .from('sme_sellers')
            .select('is_verified')
            .eq('id', user.id)
            .maybeSingle();

        final isVerified = data?['is_verified'] == true;
        if (isVerified) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.green.shade700,
              content: Text(
                isAr
                    ? 'تم اعتماد حسابك بنجاح! مرحباً بك في NXN 🎉'
                    : 'Your account has been approved! Welcome to NXN 🎉',
              ),
            ),
          );
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const HomeShell()),
            (route) => false,
          );
          return;
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isAr
                ? 'الحساب لا يزال قيد المراجعة لدى فريق التدقيق.'
                : 'Your account is still under review by our compliance team.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error checking status: $e')),
      );
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.hourglass_top_rounded, size: 64, color: Colors.orange.shade700),
              ),
              const SizedBox(height: 32),
              Text(
                isAr ? 'الحساب قيد المراجعة' : 'Account Under Review',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Text(
                  isAr
                    ? 'يتطلب اعتماد الرخصة التجارية لتفعيل حجز المستودعات.\n\nيقوم فريق الامتثال بالتحقق من بيانات المنشأة لإعادة تفعيل الحساب فوراً.'
                    : 'Trade license review is required to unlock full warehouse booking.\n\nOur compliance team is verifying your credentials to activate your account.',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.orange.shade800,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _isChecking ? null : _checkStatus,
                icon: _isChecking
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.refresh_rounded),
                label: Text(
                  isAr ? 'تحقق من حالة الاعتماد' : 'Check Approval Status',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.bluePrimary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  await Supabase.instance.client.auth.signOut();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const SplashPage()),
                      (r) => false,
                    );
                  }
                },
                icon: const Icon(Icons.logout_rounded),
                label: Text(isAr ? 'تسجيل خروج' : 'Sign Out'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isAr
                            ? 'للمساعدة تواصل مع support@nxn.ae'
                            : 'For assistance please email support@nxn.ae',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.support_agent_outlined),
                label: Text(isAr ? 'تواصل مع الدعم' : 'Contact Support'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.bluePrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
