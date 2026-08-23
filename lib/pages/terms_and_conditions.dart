import 'package:flutter/material.dart';
import 'package:nxnapp/l10n/app_localizations.dart';
import '../theme.dart';
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
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          isAr ? 'الشروط والأحكام' : 'Terms & Conditions',
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
              Center(child: Image.asset('assets/images/nxn_logo.jpg', height: 80)),
              const SizedBox(height: 16),
              
              Text(
                l10n.termsReviewRequest,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13, 
                  color: AppColors.textSecondary.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),

              // ===== Clean & Structured Terms Card =====
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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

              const SizedBox(height: 20),

              // Agree Checkbox
              InkWell(
                onTap: () => setState(() => _agreed = !_agreed),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    color: _agreed ? AppColors.bluePrimary.withValues(alpha: 0.05) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _agreed ? AppColors.bluePrimary : AppColors.border, 
                      width: _agreed ? 1.5 : 1,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.termsAgreement,
                          style: TextStyle(
                            color: _agreed ? AppColors.bluePrimary : AppColors.textSecondary,
                            fontWeight: _agreed ? FontWeight.bold : FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

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
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: _agreed ? 3 : 0,
                  shadowColor: AppColors.bluePrimary.withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      l10n.continueButton,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    if (_agreed) ...[
                      const SizedBox(width: 8),
                      Icon(
                        isAr
                            ? Icons.arrow_back_rounded
                            : Icons.arrow_forward_rounded,
                        size: 18,
                      ),
                    ]
                  ],
                ),
              ),
              const SizedBox(height: 10),
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
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.bluePrimary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
