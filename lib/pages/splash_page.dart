import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme.dart';
import '../providers/user_provider.dart';
import 'home_shell.dart';
import 'login.dart';
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
    // Give the splash logo a brief moment to display
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Read the persisted terms-accepted flag directly from SharedPreferences
    // so we don't depend on UserProvider having finished its async load.
    bool termsAccepted = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      termsAccepted = prefs.getBool('terms_accepted') ?? false;
    } catch (_) {}

    if (!mounted) return;

    // Check if the user is already authenticated with Supabase
    final currentUser = Supabase.instance.client.auth.currentUser;
    final isLoggedIn = currentUser != null;

    if (isLoggedIn && termsAccepted) {
      // Returning authenticated user — go straight to the app
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeShell()),
      );
    } else if (!isLoggedIn && termsAccepted) {
      // User has accepted T&C before but is not logged in — skip onboarding
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    } else {
      // First-time user or T&C not yet accepted — show the full onboarding flow
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
