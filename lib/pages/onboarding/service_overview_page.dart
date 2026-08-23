import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/locale_provider.dart';
import '../terms_and_conditions.dart';
import '../../theme.dart';
import '../../l10n/app_localizations.dart';

class ServiceOverviewPage extends StatelessWidget {
  const ServiceOverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // VERY COMPACT LAYOUT - Single Scroll View for natural flow
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Logo & Language Switcher
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 60), // balance center logo
                  Image.asset('assets/images/nxn_logo.jpg', height: 60),
                  Consumer<LocaleProvider>(
                    builder: (context, localeProvider, _) {
                      final isAr = localeProvider.locale.languageCode == 'ar';
                      return InkWell(
                        onTap: () => localeProvider.toggleLocale(),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.bluePrimary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.bluePrimary.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.language_rounded, color: AppColors.bluePrimary, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                isAr ? 'EN' : 'العربية',
                                style: const TextStyle(
                                  color: AppColors.bluePrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                l10n.soHeroTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 24, // Increased from 20
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.soHeroSubtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.3), // Increased from 12
              ),
              
              const SizedBox(height: 24), // Increased from 16

              // 2. Locations Stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStat('4', l10n.soStatLocations),
                  Container(height: 36, width: 1, color: Colors.grey[300]), // Increased height
                  _buildStat('100%', l10n.soStatSecure),
                  Container(height: 36, width: 1, color: Colors.grey[300]),
                  _buildStat('24/7', l10n.soStatAccess),
                ],
              ),

              const SizedBox(height: 24), // Increased from 20

              // 3. Branches List
              Builder(
                builder: (context) {
                  final isAr = Localizations.localeOf(context).languageCode == 'ar';
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          l10n.soAvailableHubs,
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 12),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 2.6,
                        padding: EdgeInsets.zero,
                        children: [
                          _buildGridBranchItem(Icons.location_on_outlined, isAr ? 'أبو ظبي' : 'Abu Dhabi'),
                          _buildGridBranchItem(Icons.location_on_outlined, isAr ? 'العين' : 'Al Ain'),
                          _buildGridBranchItem(Icons.location_on_outlined, isAr ? 'دبي' : 'Dubai'),
                          _buildGridBranchItem(Icons.location_on_outlined, isAr ? 'الشارقة' : 'Sharjah'),
                        ],
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 24),

              // 4. Pricing
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: BoxDecoration(
                  color: AppColors.bluePrimary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.bluePrimary.withValues(alpha: 0.1)),
                ),
                child: Builder(
                  builder: (context) {
                    final isAr = Localizations.localeOf(context).languageCode == 'ar';
                    return Column(
                      children: [
                        Text(l10n.soSimplePricing, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.bluePrimary)),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(isAr ? 'درهم' : 'AED', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 4),
                            const Text('100', style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                            Text(l10n.soPerShelf, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                          ],
                        ),
                        Text(l10n.soFlatRate, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                      ],
                    );
                  },
                ),
              ),

              const SizedBox(height: 24), // Standard spacing before button

              // 5. Actions
              ElevatedButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsAndConditionsPage()));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.bluePrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16), // Increased from 14
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(l10n.soGetStarted, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)), // Increased from 15
              ),
              const SizedBox(height: 12),
              Text(l10n.soPoweredBy, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 12)), // Increased from 10
              const SizedBox(height: 12), // Bottom safe area buffer
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.bluePrimary)), // Increased from 20
        const SizedBox(height: 2),
        Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)), // Increased from 10
      ],
    );
  }

  Widget _buildGridBranchItem(IconData icon, String name) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), // Increased vertical padding
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10), // Increased radius
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 3, // Increased blur
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.bluePrimary, size: 18), // Increased form 16
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary), // Increased from 12
            ),
          ),
        ],
      ),
    );
  }
}
