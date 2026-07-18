import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../theme.dart';
import '../../services/marketplace_service.dart';
import '../settings/wms_integration_page.dart';


class SellerSettingsPage extends StatefulWidget {
  const SellerSettingsPage({super.key});

  @override
  State<SellerSettingsPage> createState() => _SellerSettingsPageState();
}

class _SellerSettingsPageState extends State<SellerSettingsPage> {
  final MarketplaceService _service = MarketplaceService();
  bool _autoAccept = true;
  bool _vacationMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FB), // Premium Background
      body: CustomScrollView(
        slivers: [
          // 1. Premium Blue Header
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.bluePrimary,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            "NXN",
                            style: TextStyle(
                              color: AppColors.bluePrimary,
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.settings_suggest_rounded, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              AppLocalizations.of(context)!.sellerSettingsTitle,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Manage your store preferences",
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 2. Settings Content
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF3F6FB),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              transform: Matrix4.translationValues(0, -20, 0),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 30, 20, 40),
                child: Column(
                  children: [
                    _SettingsCard(
                      title: AppLocalizations.of(context)!.autoAcceptOrdersLabel,
                      subtitle: 'Automatically accept new delivery requests',
                      icon: Icons.check_circle_outline_rounded,
                      value: _autoAccept,
                      onChanged: (val) => setState(() => _autoAccept = val),
                    ),
                    const SizedBox(height: 16),
                    _SettingsCard(
                      title: AppLocalizations.of(context)!.vacationModeLabel,
                      subtitle: 'Pause all new orders temporarily',
                      icon: Icons.beach_access_rounded,
                      iconColor: Colors.orange,
                      value: _vacationMode,
                      onChanged: (val) => setState(() => _vacationMode = val),
                    ),
                    const SizedBox(height: 16),
                    // WMS & IoT Integration
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      color: Colors.white,
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.bluePrimary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.settings_input_hdmi_rounded, color: AppColors.bluePrimary, size: 20),
                        ),
                        title: const Text(
                          'WMS & IoT Integration',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        subtitle: const Text(
                          'Link physical warehouse API and RFID gates',
                          style: TextStyle(fontSize: 11),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const WmsIntegrationPage()),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Developer Tools
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('DEVELOPER TOOLS', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Force Verify Shop', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                          const SizedBox(height: 4),
                          const Text('Instantly marks your shop as verified (For testing purposes only).', style: TextStyle(fontSize: 12, color: Colors.red)),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () async {
                              await _service.forceVerifyShop();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Shop forcefully verified!')));
                                Navigator.pop(context); // Go back to refresh
                              }
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                            child: const Text('Force Verify Now'),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.bluePrimary,
                          foregroundColor: Colors.white,
                          elevation: 4,
                          shadowColor: AppColors.bluePrimary.withValues(alpha: 0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Store settings updated')));
                        },
                        child: Text(
                          AppLocalizations.of(context)!.saveChangesButton,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color iconColor;

  const _SettingsCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
    this.iconColor = AppColors.bluePrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E6F2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1F36),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: iconColor,
          ),
        ],
      ),
    );
  }
}
