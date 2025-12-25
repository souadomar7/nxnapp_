import 'package:flutter/material.dart';
import '../theme.dart';
import 'package:provider/provider.dart';
import '../providers/locale_provider.dart';
import '../providers/user_provider.dart';
import '../l10n/app_localizations.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'splash_page.dart';
import 'settings/kyc_page.dart';
import 'settings/notification_settings_page.dart';
import 'profile/my_subscriptions_page.dart';
import 'profile/wallet_page.dart';
import 'marketplace/seller_hub.dart';
import 'demo_menu_page.dart';

import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC), // Premium light grey bg
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 200,
            backgroundColor: AppColors.bluePrimary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.bluePrimary, AppColors.blueSecondary],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                              ),
                              child: const CircleAvatar(
                                radius: 32,
                                backgroundColor: Color(0xFFE3F2FD),
                                child: Icon(Icons.person, color: AppColors.bluePrimary, size: 36),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Consumer<UserProvider>(
                                    builder: (context, user, _) {
                                      return Text(
                                        user.displayName.isNotEmpty ? user.displayName : 'Guest User',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      AppLocalizations.of(context)!.tenantOwnerLabel,
                                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _HeaderStat(label: AppLocalizations.of(context)!.bookingsLabel, value: '3'),
                            Container(width: 1, height: 30, color: Colors.white24),
                            _HeaderStat(label: AppLocalizations.of(context)!.savedLabel, value: '8'),
                            Container(width: 1, height: 30, color: Colors.white24),
                            _HeaderStat(label: AppLocalizations.of(context)!.rentedShelvesLabel, value: '240'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // --- Account Section ---
                  _SectionHeader(title: 'Account'),
                  _MenuCard(children: [
                    _ProfileTile(
                      icon: Icons.inventory_2_outlined,
                      title: 'My Subscriptions',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MySubscriptionsPage())),
                    ),
                    _Divider(),
                    _ProfileTile(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'Wallet & Invoices',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletPage())),
                    ),
                    _Divider(),
                    _ProfileTile(
                      icon: Icons.verified_user_outlined,
                      title: AppLocalizations.of(context)!.kycDocsTitle,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const KYCPage())),
                    ),
                  ]),
                  
                  const SizedBox(height: 24),

                  // --- Settings Section ---
                  _SectionHeader(title: 'Preferences'), // Add to l10n later if needed
                  _MenuCard(children: [
                    _ProfileTile(
                      icon: Icons.notifications_outlined,
                      title: AppLocalizations.of(context)!.notificationsTitle,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationSettingsPage())),
                    ),
                    _Divider(),
                    Consumer<LocaleProvider>(
                      builder: (context, provider, _) => _ProfileTile(
                        icon: Icons.language,
                        title: AppLocalizations.of(context)!.languageTitle,
                        trailingText: provider.locale.languageCode == 'en' ? 'English' : 'العربية',
                        onTap: () => provider.toggleLocale(),
                      ),
                    ),
                  ]),

                  const SizedBox(height: 24),

                  // --- Business Section ---
                  _SectionHeader(title: 'Business'),
                  _MenuCard(children: [
                    _ProfileTile(
                      icon: Icons.store_mall_directory_outlined,
                      title: AppLocalizations.of(context)!.marketplaceTitle,
                      subtitle: AppLocalizations.of(context)!.marketplaceSubtitle,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SellerHub())),
                    ),
                    _Divider(),
                     _ProfileTile(
                      icon: Icons.layers_outlined,
                      title: 'All Features / Demo',
                      subtitle: 'Explore all screens',
                      iconColor: Colors.purple,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DemoMenuPage())),
                    ),
                  ]),

                  const SizedBox(height: 32),

                  // --- Logout ---
                  _MenuCard(children: [
                    _ProfileTile(
                      icon: Icons.logout_rounded,
                      title: AppLocalizations.of(context)!.logoutTitle,
                      iconColor: Colors.redAccent,
                      textColor: Colors.redAccent,
                      showTrailing: false,
                        onTap: () async {
                        // Clear guest mode persistence
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.remove('is_guest');

                        await Supabase.instance.client.auth.signOut();
                        if (context.mounted) {
                          Navigator.pushAndRemoveUntil(
                            context, 
                            MaterialPageRoute(builder: (_) => const SplashPage()),
                            (route) => false,
                          );
                        }
                      },
                    ),
                  ]),
                  
                  const SizedBox(height: 40),
                  Text(
                    'Version 1.0.2',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Helper Widgets ---

class _HeaderStat extends StatelessWidget {
  final String label;
  final String value;
  const _HeaderStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4, right: 4),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final List<Widget> children;
  const _MenuCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.white),
      ),
      child: Column(children: children),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(height: 1, thickness: 1, color: Colors.grey[100], indent: 60);
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? trailingText;
  final Color iconColor;
  final Color textColor;
  final bool showTrailing;
  final VoidCallback onTap;

  const _ProfileTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailingText,
    this.iconColor = AppColors.bluePrimary,
    this.textColor = AppColors.textPrimary,
    this.showTrailing = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), // Spacious click area
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 24),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      subtitle: subtitle != null 
          ? Text(subtitle!, style: const TextStyle(fontSize: 12, color: Colors.grey)) 
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingText != null) 
            Text(trailingText!, style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500)),
          if (showTrailing) ...[
             const SizedBox(width: 8),
             Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey[400]),
          ],
        ],
      ),
    );
  }
}
