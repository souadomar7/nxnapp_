import 'package:flutter/material.dart';
import '../theme.dart';
import 'package:provider/provider.dart';
import '../providers/locale_provider.dart';
import '../providers/user_provider.dart';
import '../l10n/app_localizations.dart';
import '../core/auth/session_provider.dart';
import '../core/auth/user_role.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'splash_page.dart';
import 'settings/kyc_page.dart';
import 'settings/notification_settings_page.dart';
import 'profile/my_subscriptions_page.dart';
import 'profile/wallet_page.dart';
import 'marketplace/seller_hub.dart';
import '../services/marketplace_service.dart';
import 'login.dart';
import 'registration_page.dart';
import 'demo_menu_page.dart';
import 'admin_panel_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final MarketplaceService _service = MarketplaceService();
  int _activeShelves = 0;
  int _pendingInvoices = 0;
  int _catalogCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final stats = await _service.getDashboardStats();
      final invoices = await _service.getInvoices();
      final products = await _service.getProducts();

      if (mounted) {
        setState(() {
          _activeShelves = stats['shelves'] ?? 0;
          _pendingInvoices = invoices.where((e) => !e.paid).length;
          _catalogCount = products.length;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final session = SessionProvider.of(context);
    final isGuest = session.role == UserRole.guest;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FB),
      body: CustomScrollView(
        slivers: [
          // ─── HEADER ───────────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            expandedHeight: isGuest ? 220 : 240,
            backgroundColor: AppColors.bluePrimary,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  color: AppColors.bluePrimary,
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    child: isGuest
                        ? _buildGuestHeader(context)
                        : _buildMerchantHeader(l10n),
                  ),
                ),
              ),
            ),
          ),

          // ─── BODY ────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: isGuest
                    ? _buildGuestSections(context, l10n)
                    : _buildMerchantSections(context, l10n),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── GUEST HEADER ─────────────────────────────────────────────────────────

  Widget _buildGuestHeader(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: const BoxDecoration(
            color: Colors.white24,
            shape: BoxShape.circle,
          ),
          child: const CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            child: Icon(Icons.person_outline_rounded,
                color: AppColors.bluePrimary, size: 30),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isAr ? 'زائر' : 'Guest User',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const LoginPage())),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white54),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(isAr ? 'تسجيل الدخول' : 'Sign In',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const RegistrationPage())),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.bluePrimary,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(isAr ? 'إنشاء حساب' : 'Register',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── MERCHANT HEADER ──────────────────────────────────────────────────────

  Widget _buildMerchantHeader(AppLocalizations l10n) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.white24,
                shape: BoxShape.circle,
              ),
              child: CircleAvatar(
                radius: 36,
                backgroundColor: Colors.white,
                child: Consumer<UserProvider>(
                  builder: (context, user, _) {
                    final initial = user.displayName.isNotEmpty
                        ? user.displayName.substring(0, 1).toUpperCase()
                        : 'M';
                    return Text(
                      initial,
                      style: const TextStyle(
                        color: AppColors.bluePrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Consumer<UserProvider>(
                    builder: (context, user, _) => Text(
                      user.displayName.isNotEmpty
                          ? user.displayName
                          : l10n.guestUser,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 1),
                    ),
                    child: Text(
                      l10n.tenantOwnerLabel,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          padding:
              const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.1), width: 1),
          ),
          child: Builder(
            builder: (ctx) {
              final isAr = Localizations.localeOf(ctx).languageCode == 'ar';
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _HeaderStat(
                      label: isAr ? 'فواتير معلقة' : 'Pending Bills',
                      value: _isLoading ? '...' : '$_pendingInvoices'),
                  Container(width: 1, height: 24, color: Colors.white12),
                  _HeaderStat(
                      label: isAr ? 'المنتجات' : 'Catalog Items',
                      value: _isLoading ? '...' : '$_catalogCount'),
                  Container(width: 1, height: 24, color: Colors.white12),
                  _HeaderStat(
                      label: isAr ? 'أرفف نشطة' : 'Active Shelves',
                      value: _isLoading ? '...' : '$_activeShelves'),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  // ─── GUEST SECTIONS ───────────────────────────────────────────────────────

  List<Widget> _buildGuestSections(
      BuildContext context, AppLocalizations l10n) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return [
      // Locked account section with CTA
      _buildGuestLockedCard(
        context: context,
        icon: Icons.lock_outline_rounded,
        title: isAr ? 'خصائص الحساب مقفلة' : 'Account Features Locked',
        body: isAr
            ? 'قم بتسجيل الدخول أو إنشاء حساب للوصول إلى اشتراكاتك، الفواتير، المحفظة، ومستندات التحقق (KYC).'
            : 'Sign in or register to access your subscriptions, invoices, wallet, and KYC documents.',
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const RegistrationPage())),
      ),
      const SizedBox(height: 20),

      // Preferences (language still accessible)
      _SectionHeader(title: l10n.preferencesSection),
      _MenuCard(children: [
        _ProfileTile(
          icon: Icons.notifications_outlined,
          title: l10n.notificationsTitle,
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const NotificationSettingsPage())),
        ),
        _Divider(),
        Consumer<LocaleProvider>(
          builder: (context, provider, _) => _ProfileTile(
            icon: Icons.language_rounded,
            title: l10n.languageTitle,
            trailingText: provider.locale.languageCode == 'en'
                ? 'English'
                : 'العربية',
            onTap: () => provider.toggleLocale(),
          ),
        ),
      ]),

      const SizedBox(height: 24),

      // Sign out / back
      _MenuCard(children: [
        _ProfileTile(
          icon: Icons.exit_to_app_rounded,
          title: isAr ? 'الخروج من وضع الزائر' : 'Exit Guest Mode',
          iconColor: Colors.redAccent,
          textColor: Colors.redAccent,
          showTrailing: false,
          onTap: () async {
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
        l10n.version('1.0.2'),
        style: TextStyle(color: Colors.grey[400], fontSize: 12),
      ),
      const SizedBox(height: 20),
    ];
  }

  Widget _buildGuestLockedCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String body,
    required VoidCallback onTap,
  }) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: AppColors.bluePrimary.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9DA8C4).withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.bluePrimary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.bluePrimary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            body,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.bluePrimary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
              child: Text(
                isAr ? 'إنشاء حساب تاجر مجاني' : 'Create Free Merchant Account',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── MERCHANT SECTIONS ────────────────────────────────────────────────────

  List<Widget> _buildMerchantSections(
      BuildContext context, AppLocalizations l10n) {
    return [
      _SectionHeader(title: l10n.accountSection),
      _MenuCard(children: [
        _ProfileTile(
          icon: Icons.inventory_2_outlined,
          title: l10n.mySubscriptions,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const MySubscriptionsPage())),
        ),
        _Divider(),
        _ProfileTile(
          icon: Icons.account_balance_wallet_outlined,
          title: l10n.walletInvoices,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const WalletPage())),
        ),
        _Divider(),
        _ProfileTile(
          icon: Icons.verified_user_outlined,
          title: l10n.kycDocsTitle,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const KYCPage())),
        ),
      ]),

      const SizedBox(height: 24),

      _SectionHeader(title: l10n.preferencesSection),
      _MenuCard(children: [
        _ProfileTile(
          icon: Icons.notifications_outlined,
          title: l10n.notificationsTitle,
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const NotificationSettingsPage())),
        ),
        _Divider(),
        Consumer<LocaleProvider>(
          builder: (context, provider, _) => _ProfileTile(
            icon: Icons.language_rounded,
            title: l10n.languageTitle,
            trailingText: provider.locale.languageCode == 'en'
                ? 'English'
                : 'العربية',
            onTap: () => provider.toggleLocale(),
          ),
        ),
      ]),

      const SizedBox(height: 24),

      _SectionHeader(title: 'System & Tools'),
      _MenuCard(children: [
        _ProfileTile(
          icon: Icons.admin_panel_settings_rounded,
          title: Localizations.localeOf(context).languageCode == 'ar' ? 'لوحة تحكم الإدارة والمستودع' : 'Super Admin & Ops Control Panel',
          subtitle: Localizations.localeOf(context).languageCode == 'ar' ? 'إشراف الشحنات والاعتمادات والسحوبات' : 'Inbound, Outbound, KYC & Payouts control',
          iconColor: Colors.amber.shade800,
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const AdminPanelPage())),
        ),
        _Divider(),
        _ProfileTile(
          icon: Icons.developer_mode_rounded,
          title: 'All Features Demo Menu',
          subtitle: 'Quick access to all app pages',
          iconColor: AppColors.bluePrimary,
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const DemoMenuPage())),
        ),
      ]),

      const SizedBox(height: 24),

      _SectionHeader(title: l10n.businessSection),
      _MenuCard(children: [
        _ProfileTile(
          icon: Icons.store_mall_directory_outlined,
          title: l10n.marketplaceTitle,
          subtitle: l10n.marketplaceSubtitle,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const SellerHub())),
        ),
      ]),

      const SizedBox(height: 32),

      _MenuCard(children: [
        _ProfileTile(
          icon: Icons.logout_rounded,
          title: l10n.logoutTitle,
          iconColor: Colors.redAccent,
          textColor: Colors.redAccent,
          showTrailing: false,
          onTap: () async {
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
        l10n.version('1.0.2'),
        style: TextStyle(color: Colors.grey[400], fontSize: 12),
      ),
      const SizedBox(height: 20),
    ];
  }
}

// ─── SHARED HELPER WIDGETS ────────────────────────────────────────────────────

class _HeaderStat extends StatelessWidget {
  final String label;
  final String value;
  const _HeaderStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w500)),
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
            fontSize: 13,
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
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9DA8C4).withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(children: children),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
        height: 1,
        thickness: 1,
        color: Colors.grey.shade100,
        indent: 64);
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
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w700,
          fontSize: 14.5,
        ),
      ),
      subtitle: subtitle != null
          ? Text(subtitle!,
              style:
                  const TextStyle(fontSize: 11.5, color: Colors.grey))
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingText != null)
            Text(trailingText!,
                style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
          if (showTrailing) ...[
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: Colors.grey.shade400),
          ],
        ],
      ),
    );
  }
}
