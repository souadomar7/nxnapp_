import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../theme.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nxnapp/l10n/app_localizations.dart';
import 'warehouse_selection_page.dart';
import 'account_in_review_page.dart';
import '../home_shell.dart';

class ProfileSetupPage extends StatefulWidget {
  final Map<String, String>? uaePassData;
  final String? initialName;
  final String? initialEmail;
  final bool? initialIsBusiness;

  const ProfileSetupPage({
    super.key,
    this.uaePassData,
    this.initialName,
    this.initialEmail,
    this.initialIsBusiness,
  });

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isBusinessAccount = true;
  late TextEditingController _businessNameController;
  late TextEditingController _licenseController;
  late TextEditingController _contactController;
  late TextEditingController _emailController;
  late TextEditingController _licenseOwnerController;
  bool _isLoading = false;

  XFile? _documentFile; // New
  bool _showDocError = false; 

  Future<void> _pickDocument() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _documentFile = image;
        _showDocError = false;
      });
      if (mounted) {
        Provider.of<UserProvider>(context, listen: false).setDocumentUploaded(image.name);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialIsBusiness != null) {
      _isBusinessAccount = widget.initialIsBusiness!;
    } else if (widget.uaePassData != null) {
      _isBusinessAccount = (widget.uaePassData?['licenseNumber']?.isNotEmpty == true);
    } else {
      _isBusinessAccount = true;
    }

    _businessNameController = TextEditingController(
      text: widget.uaePassData?['businessName'] ?? widget.initialName ?? '',
    );
    _licenseController = TextEditingController(
      text: widget.uaePassData?['licenseNumber'] ?? '',
    );
    _contactController = TextEditingController(
      text: widget.uaePassData?['contactNumber'] ?? '',
    );
    _emailController = TextEditingController(
      text: widget.uaePassData?['email'] ?? widget.initialEmail ?? (Supabase.instance.client.auth.currentUser?.email ?? ''),
    );
    _licenseOwnerController = TextEditingController(
      text: widget.uaePassData?['licenseOwnerName'] ?? '',
    );
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _licenseController.dispose();
    _contactController.dispose();
    _emailController.dispose();
    _licenseOwnerController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final bool hasDoc = !_isBusinessAccount || _documentFile != null || userProvider.isDocumentUploaded;
    setState(() => _showDocError = !hasDoc);
    if (!_formKey.currentState!.validate() || !hasDoc) return;

    setState(() => _isLoading = true);

    try {
      var user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        final email = _emailController.text.trim().isNotEmpty
            ? _emailController.text.trim()
            : 'user_${DateTime.now().millisecondsSinceEpoch}@alfalak.ae';
        const defaultPassword = 'UaePass_Temporary_2026!';
        try {
          final res = await Supabase.instance.client.auth.signInWithPassword(
            email: email,
            password: defaultPassword,
          );
          user = res.user;
        } catch (_) {
          try {
            final res = await Supabase.instance.client.auth.signUp(
              email: email,
              password: defaultPassword,
              data: {'full_name': _businessNameController.text.trim()},
            );
            user = res.user;
          } catch (signUpErr) {
            debugPrint('Auto auth signup note: $signUpErr');
          }
        }
      }

      final isFromUaePass = widget.uaePassData != null &&
          (widget.uaePassData!['licenseNumber'] ?? '').isNotEmpty;

      if (user != null) {
        final role = _isBusinessAccount ? 'merchant' : 'customer';
        // Upsert canonical user profile with compliance terms logging
        try {
          await Supabase.instance.client.from('profiles').upsert({
            'id': user.id,
            'full_name': _businessNameController.text.trim(),
            'phone': _contactController.text.trim(),
            'role': role,
            'status': 'active',
            'kyc_status': _isBusinessAccount ? (isFromUaePass ? 'verified' : 'pending') : 'basic',
            'terms_accepted_at': DateTime.now().toIso8601String(),
            'terms_version': '2026.1',
          });
        } catch (e) {
          debugPrint('Profiles table upsert note: $e');
        }

        if (_isBusinessAccount) {
          // Upsert SME seller registration
          await Supabase.instance.client.from('sme_sellers').upsert({
            'id': user.id,
            'business_name': _businessNameController.text.trim(),
            'contact_number': _contactController.text.trim(),
            'email': _emailController.text.trim(),
            'license_owner_name': _licenseOwnerController.text.trim(),
            'license_number': _licenseController.text.trim(),
            'is_verified': isFromUaePass,
          });
        }
      }

      // Explicitly clear guest state upon completed profile registration
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_guest', false);

      if (mounted) {
        userProvider.setUser(
          businessName: _businessNameController.text.trim(),
          contactNumber: _contactController.text.trim(),
          licenseNumber: _isBusinessAccount ? _licenseController.text.trim() : '',
        );
        if (_isBusinessAccount) {
          userProvider.setDocumentUploaded(_documentFile?.name ?? userProvider.documentFileName ?? 'Trade_License_CN2891048.pdf');
        }
      }

      if (mounted) {
        if (_isBusinessAccount) {
          if (isFromUaePass) {
            // UAE PASS verified business proceeds to warehouse space booking
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const WarehouseSelectionPage()), 
              (route) => false,
            );
          } else {
            // Manual merchant document uploads must be reviewed by compliance ops
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const AccountInReviewPage()), 
              (route) => false,
            );
          }
        } else {
          // Retail / Individual buyers go directly to marketplace home
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const HomeShell()), 
            (route) => false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.completeProfileTitle),
        backgroundColor: AppColors.bg,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.bluePrimary),
        titleTextStyle: const TextStyle(color: AppColors.bluePrimary, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.uaePassData != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    border: Border.all(color: Colors.green),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context)!.uaePassVerifiedMessage,
                          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),

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
                              isAr ? 'حساب تاجر / منشأة' : 'Business / Merchant',
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

              Text(
                _isBusinessAccount
                    ? AppLocalizations.of(context)!.businessDetailsTitle
                    : (isAr ? 'البيانات الشخصية' : 'Personal Details'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _businessNameController,
                decoration: InputDecoration(
                  labelText: _isBusinessAccount
                      ? AppLocalizations.of(context)!.businessNameLabel
                      : (isAr ? 'الاسم الكامل' : 'Full Name'),
                  border: const OutlineInputBorder(),
                  prefixIcon: Icon(_isBusinessAccount ? Icons.business : Icons.person),
                ),
                validator: (value) => value == null || value.isEmpty ? AppLocalizations.of(context)!.requiredField : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return AppLocalizations.of(context)!.requiredField;
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) return 'Invalid email format';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _contactController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.mobileNumberLabel,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.phone),
                ),
                validator: (value) => value == null || value.isEmpty ? AppLocalizations.of(context)!.requiredField : null,
              ),
              const SizedBox(height: 16),

              if (_isBusinessAccount) ...[
                TextFormField(
                  controller: _licenseOwnerController,
                  decoration: const InputDecoration(
                    labelText: 'License Owner Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_pin_rounded),
                  ),
                  validator: (value) => value == null || value.isEmpty ? AppLocalizations.of(context)!.requiredField : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _licenseController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.tradeLicenseLabel,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.badge),
                  ),
                  validator: (value) => value == null || value.isEmpty ? AppLocalizations.of(context)!.requiredField : null,
                ),
                const SizedBox(height: 24),
                Text(AppLocalizations.of(context)!.requiredDocumentsTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                
                Consumer<UserProvider>(
                  builder: (context, userProvider, _) {
                    final isUploaded = _documentFile != null || userProvider.isDocumentUploaded;
                    final docName = _documentFile?.name ?? userProvider.documentFileName ?? 'Trade_License_CN2891048.pdf';
                    return InkWell(
                      onTap: _pickDocument,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        height: 120,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: isUploaded ? Colors.green.withValues(alpha: 0.05) : Colors.grey[50],
                          border: Border.all(color: isUploaded ? Colors.green : Colors.grey[300]!, width: 2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: isUploaded 
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.check_circle, color: Colors.green, size: 32),
                                const SizedBox(height: 8),
                                Text('${AppLocalizations.of(context)!.uploadedLabel}: $docName', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                TextButton(onPressed: _pickDocument, child: Text(AppLocalizations.of(context)!.changeButton))
                              ],
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.cloud_upload_outlined, size: 32, color: Colors.grey),
                                const SizedBox(height: 8),
                                Text(AppLocalizations.of(context)!.tapToUploadDoc, style: const TextStyle(color: Colors.grey)),
                              ],
                            ),
                      ),
                    );
                  },
                ),
                if (_showDocError)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, left: 4),
                    child: Text(AppLocalizations.of(context)!.docUploadRequiredError, style: const TextStyle(color: Colors.red, fontSize: 12)),
                  ),
              ],

              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                 style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.bluePrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(AppLocalizations.of(context)!.saveAndContinueButton, style: const TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
