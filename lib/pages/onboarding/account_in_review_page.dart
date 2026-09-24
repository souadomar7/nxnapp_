import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../services/uae_pass_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AccountInReviewPage extends StatelessWidget {
  const AccountInReviewPage({super.key});

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
                    ? 'يتطلب تجديد الرخصة التجارية لتفعيل حجز المستودعات.\n\nتحقق من تجديد رخصتك التجارية مع الجهة المختصة، ثم تواصل مع فريق NXN لإعادة تفعيل حسابك.'
                    : 'Trade license renewal required to unlock warehouse booking.\n\nPlease renew your trade license with the relevant authority, then contact the NXN team to reactivate your account.',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.orange.shade800,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),
              OutlinedButton.icon(
                onPressed: () async {
                  await Supabase.instance.client.auth.signOut();
                  if (context.mounted) {
                    Navigator.of(context).pushNamedAndRemoveUntil('/', (r) => false);
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
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.support_agent_outlined),
                label: Text(isAr ? 'تواصل مع الدعم' : 'Contact Support'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.bluePrimary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
