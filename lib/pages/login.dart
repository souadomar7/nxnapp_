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
import 'admin/admin_login_page.dart'; // secret admin portal
import 'registration_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _signIn() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _isLoading = true;
    });

    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Fetch user details for Profile
      final user = Supabase.instance.client.auth.currentUser;
      final metadata = user?.userMetadata;
      if (mounted && user != null) {
        Provider.of<UserProvider>(context, listen: false).setUser(
          businessName: metadata?['full_name'] ?? 'User',
          contactNumber: '', 
          licenseNumber: '',
          email: user.email,
        );
      }

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeShell()),
           (route) => false,
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.unexpectedError), backgroundColor: Colors.red),
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
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
          IconButton(
            icon: const Icon(Icons.admin_panel_settings, color: Colors.grey),
            tooltip: 'Secret Admin Portal',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminLoginPage()));
            },
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Image.asset('assets/images/nxn_logo.jpg', height: 100),
              const SizedBox(height: 48),
              
              Text(
                l10n.welcomeBack,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.bluePrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: l10n.emailLabel,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: l10n.passwordLabel,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 24),

              // UAE PASS Button
              ElevatedButton.icon(
                onPressed: _isLoading ? null : () async {
                   setState(() => _isLoading = true);
                   
                   try {
                     // Use the service
                     final uaePassData = await UaePassService().signIn();
                     
                     if (!context.mounted) return;
                     
                     setState(() => _isLoading = false);
                        
                     if (uaePassData != null) {
                        // Extract useful fields for profile setup
                        final Map<String, String> mappedData = {
                          'businessName': (uaePassData['fullnameEN'] ?? '').toString(),
                          'contactNumber': (uaePassData['mobile'] ?? '').toString(),
                          'licenseNumber': (uaePassData['licenseNumber'] ?? '').toString(),
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
                      if (!context.mounted) return;
                      setState(() => _isLoading = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                      );
                   }
                },
                icon: const Icon(Icons.fingerprint, color: Colors.white),
                label: Text(l10n.loginWithUaePass, style: const TextStyle(color: Colors.white, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 16),

              const Row(children: [Expanded(child: Divider()), Padding(padding: EdgeInsets.all(8), child: Text("OR")), Expanded(child: Divider())]),
              const SizedBox(height: 16),

              ElevatedButton(
                onPressed: _isLoading ? null : _signIn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.bluePrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
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
                        style: const TextStyle(fontSize: 16, color: Colors.white),
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
                child: Text(l10n.registerText),
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
                   l10n.skipForNow, // Using 'Skip for now' or similar
                   style: const TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
