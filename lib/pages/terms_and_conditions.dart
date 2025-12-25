import 'package:flutter/material.dart';
import 'package:nxnapp/l10n/app_localizations.dart';
import '../theme.dart';
import '../widgets/brand_logo.dart';
import 'package:provider/provider.dart';
import '../providers/locale_provider.dart';
import 'login.dart';

class TermsAndConditionsPage extends StatefulWidget {
  const TermsAndConditionsPage({super.key});

  @override
  State<TermsAndConditionsPage> createState() => _TermsAndConditionsPageState();
}

class _TermsAndConditionsPageState extends State<TermsAndConditionsPage> {
  bool _agreed = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          l10n.termsPageTitle,
          style: const TextStyle(
            color: AppColors.bluePrimary,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.language, color: AppColors.bluePrimary),
            onPressed: () {
              Provider.of<LocaleProvider>(context, listen: false).toggleLocale();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              const BrandLogo(height: 90),
              const SizedBox(height: 32),
              
              Text(
                l10n.termsPageTitle, 
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24, 
                  fontWeight: FontWeight.bold, 
                  color: AppColors.textPrimary
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please review and accept our terms to proceed.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14, 
                  color: AppColors.textSecondary.withValues(alpha: 0.8)
                ),
              ),
              const SizedBox(height: 32),

              // ===== Terms Card =====
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.termsSummaryTitle,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.bluePrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _TermsPoint(l10n.termsPoint1),
                        _TermsPoint(l10n.termsPoint2),
                        _TermsPoint(l10n.termsPoint3),
                        _TermsPoint(l10n.termsPoint4),
                        _TermsPoint(l10n.termsPoint5),
                        _TermsPoint(l10n.termsPoint6),
                        _TermsPoint(l10n.termsPoint7),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Agree Checkbox
              Container(
                decoration: BoxDecoration(
                  color: _agreed ? AppColors.bluePrimary.withValues(alpha: 0.05) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _agreed ? AppColors.bluePrimary : AppColors.border, 
                    width: _agreed ? 1.5 : 1
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Transform.scale(
                      scale: 1.2,
                      child: Checkbox(
                        value: _agreed,
                        activeColor: AppColors.bluePrimary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        onChanged: (v) => setState(() => _agreed = v ?? false),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        l10n.termsAgreement,
                        style: TextStyle(
                          color: _agreed ? AppColors.bluePrimary : AppColors.textSecondary,
                          fontWeight: _agreed ? FontWeight.w600 : FontWeight.normal,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Continue Button
              ElevatedButton(
                onPressed: _agreed
                    ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                  );
                }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.bluePrimary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[300],
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  elevation: _agreed ? 4 : 0,
                  shadowColor: AppColors.bluePrimary.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      l10n.continueButton,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    if (_agreed) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 20),
                    ]
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _TermsPoint extends StatelessWidget {
  final String text;
  const _TermsPoint(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.circle, size: 6, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
