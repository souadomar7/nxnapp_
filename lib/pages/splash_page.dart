import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme.dart';
import 'onboarding/service_overview_page.dart';



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
    // Wait a bit for splash effect
    await Future.delayed(const Duration(seconds: 2));

    try {
      // Explicitly sign out to ensure clean state as per user request
      await Supabase.instance.client.auth.signOut();
    } catch (_) {
      // Ignore errors if already signed out or network issues during splash
    }

    if (!mounted) return;

    // Always redirect to Onboarding/Login Flow (Disable Auto-Login)
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const ServiceOverviewPage()),
    );
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

