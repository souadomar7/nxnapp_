import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme.dart';
import 'home_shell.dart';
import 'login.dart';
import 'onboarding/service_overview_page.dart';
import 'onboarding/account_in_review_page.dart';
import 'terms_and_conditions.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _redirect();
  }

  Future<void> _redirect() async {
    // Give the splash logo a brief moment to display
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Read the persisted terms-accepted and guest flags directly from SharedPreferences
    bool termsAccepted = false;
    bool isGuest = false;
    SharedPreferences? prefs;
    try {
      prefs = await SharedPreferences.getInstance();
      termsAccepted = prefs.getBool('terms_accepted') ?? false;
      isGuest = prefs.getBool('is_guest') ?? false;
    } catch (_) {}

    if (!mounted) return;

    // Check if the user is already authenticated with Supabase
    final currentUser = Supabase.instance.client.auth.currentUser;
    final isLoggedIn = currentUser != null;

    if (isLoggedIn) {
      // 1. Check account verification status from database to prevent bypassing review gate
      try {
        final sellerDoc = await Supabase.instance.client
            .from('sme_sellers')
            .select('is_verified')
            .eq('id', currentUser.id)
            .maybeSingle();

        final isLocallyVerified = prefs?.getBool('is_verified_${currentUser.id}') == true ||
            (prefs?.getBool('merchant_verified') == true && prefs?.getBool('is_merchant_pending') == false);

        if (sellerDoc != null && sellerDoc['is_verified'] == false && !isLocallyVerified) {
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AccountInReviewPage()),
          );
          return;
        }
      } catch (e) {
        debugPrint('Account status check note: $e');
      }

      if (!mounted) return;

      // 2. If logged in but terms not accepted on this device (e.g. new phone or cleared cache)
      if (!termsAccepted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const TermsAndConditionsPage()),
        );
        return;
      }

      // 3. Authenticated, approved, and terms accepted
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeShell()),
      );
    } else if (isGuest && termsAccepted) {
      // Guest exploration session with terms accepted
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeShell()),
      );
    } else if (termsAccepted) {
      // User has accepted T&C before but is not logged in — skip onboarding intro
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    } else {
      // First-time user — show the full onboarding overview
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ServiceOverviewPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/nxn_logo.jpg', width: 180),
            const SizedBox(height: 24),
            const CircularProgressIndicator(
              color: AppColors.bluePrimary,
              strokeWidth: 2.5,
            ),
          ],
        ),
      ),
    );
  }
}
