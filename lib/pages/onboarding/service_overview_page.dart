import 'package:flutter/material.dart';
import '../terms_and_conditions.dart';
import '../../theme.dart';
import '../../l10n/app_localizations.dart';



class ServiceOverviewPage extends StatelessWidget {
  const ServiceOverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Logo & Hero
                    const SizedBox(height: 20),
                    Center(child: Image.asset('assets/images/nxn_logo.jpg', height: 80)),
                    const SizedBox(height: 32),
                    Text(
                      l10n.soHeroTitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.soHeroSubtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, color: AppColors.textSecondary, height: 1.5),
                    ),
                    
                    const SizedBox(height: 48),

                    // 2. Locations Stats
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStat('4', l10n.soStatLocations),
                        Container(height: 40, width: 1, color: Colors.grey[300]),
                        _buildStat('100%', l10n.soStatSecure),
                        Container(height: 40, width: 1, color: Colors.grey[300]),
                        _buildStat('24/7', l10n.soStatAccess),
                      ],
                    ),

                    const SizedBox(height: 48),

                    // 3. Branches List
                    Text(
                      l10n.soAvailableHubs,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    _buildBranchItem('Abu Dhabi', 'Mussafah Industrial Area'),
                    _buildBranchItem('Al Ain', 'Industrial City'),
                    _buildBranchItem('Dubai (Al Karama)', 'Central Logistics Hub'),
                    _buildBranchItem('Sharjah', 'SAIF Zone'),

                    const SizedBox(height: 40),

                    // 4. Pricing
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.bluePrimary.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.bluePrimary.withValues(alpha: 0.1)),
                      ),
                      child: Column(
                        children: [
                          Text(l10n.soSimplePricing, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.bluePrimary)),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              const Text('AED', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                              const SizedBox(width: 4),
                              const Text('100', style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                              Text(l10n.soPerShelf, style: const TextStyle(fontSize: 16, color: AppColors.textSecondary)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(l10n.soFlatRate, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // 5. Actions
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsAndConditionsPage()));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.bluePrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(l10n.soGetStarted, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 8),
                  Text(l10n.soPoweredBy, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.bluePrimary)),
        const SizedBox(height: 4),
        Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildBranchItem(String name, String location) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const Icon(Icons.location_on_outlined, color: AppColors.bluePrimary, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Text(location, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}
