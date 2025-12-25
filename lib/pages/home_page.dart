import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../l10n/app_localizations.dart';
import '../theme.dart';
// Models & Data

import '../widgets/brand_logo.dart';
import 'booking_page.dart';
import 'payment_page.dart'; 
import 'request_delivery_page.dart';
import 'receive_goods_stage.dart'; // Warehouse Preparation
import 'operations/gate_pass_page.dart';

import '../services/marketplace_service.dart';
import '../models/history_models.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Using rigid stats for demo purposes
  // final int _pendingDeliveries = 1; // Unused
  // final double _inventoryUsage = 0.65; // Unused

  // Real History
  final MarketplaceService _marketService = MarketplaceService();
  late Future<List<DashboardActivity>> _activityFuture;
  Map<String, dynamic> _stats = {
    'shelves': 0,
    'items': 0,
    'pendingOrders': 0,
    'totalValue': 0.0,
    'activeRentals': [],
  };

  @override
  void initState() {
    super.initState();
    _loadData();
    // Listen for real-time updates (local or remote trigger)
    MarketplaceService.updateNotifier.addListener(_loadData);
  }

  @override
  void dispose() {
    MarketplaceService.updateNotifier.removeListener(_loadData);
    super.dispose();
  }

  void _loadData() {
    setState(() {
      _activityFuture = _marketService.getRecentActivity();
      _marketService.getDashboardStats().then((s) { 
        if (mounted) setState(() => _stats = s); 
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Light grey background
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(l10n),
            _buildStatsOverview(l10n),
            const SizedBox(height: 24),
            _buildAlertsSection(l10n),
            const SizedBox(height: 24),
            _buildWarehousePrep(context, l10n),
            const SizedBox(height: 24),
            _buildQuickActions(context, l10n),
            const SizedBox(height: 24),
            _buildActiveRentals(l10n),
            const SizedBox(height: 24),
            _buildRecentActivity(l10n),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // 1. Header Section with Gradient and Greeting
  Widget _buildHeader(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
      decoration: const BoxDecoration(
        color: AppColors.bluePrimary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 5),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo & Profile Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const BrandLogo(height: 40, isLight: true), // White logo variant if available, else standard
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                  onPressed: () {
                    // TODO: Open notifications
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Greeting & Welcome
          Consumer<UserProvider>(
            builder: (context, user, _) {
              return Text(
                l10n.helloUser(user.displayName),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            l10n.welcomeBannerText,
            style: TextStyle(
              fontSize: 15,
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // 2. Stats Overview Cards
  Widget _buildStatsOverview(AppLocalizations l10n) {

    
    return Transform.translate(
      offset: const Offset(0, -20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            _buildStatCard(
              title: l10n.totalShelves,
              value: '${_stats['shelves']}',
              icon: Icons.shelves,
              color: AppColors.bluePrimary,
            ),
            const SizedBox(width: 12),
            _buildStatCard(
              title: l10n.stockValue,
              value: 'AED ${( (_stats['totalValue'] as num) / 1000).toStringAsFixed(1)}k',
              icon: Icons.monetization_on_rounded,
              color: Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({required String title, required String value, required IconData icon, required Color color}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 2.5 Alerts Section
  Widget _buildAlertsSection(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 24),
                  SizedBox(height: 4),
                  Text(l10n.lowStockCount(3), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade300),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline_rounded, color: Colors.red, size: 24),
                  SizedBox(height: 4),
                  Text(l10n.outOfStockCount(1), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 2.6 Warehouse Preparation
  Widget _buildWarehousePrep(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: InkWell(
        onTap: () {
           Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ReceiveGoodsStagePageEN()),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0057FF), Color(0xFF0038A8)], // Blue gradient
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0057FF).withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.fact_check_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.warehousePrep,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.scheduleDropoffShort,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  // 3. Active Rentals List
  Widget _buildActiveRentals(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.activeRentals,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.warehouse_rounded, color: Colors.green, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Al Ain Branch',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Active • 5 Shelves',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                const Chip(
                  label: Text('Managing', style: TextStyle(color: Colors.white, fontSize: 10)),
                  backgroundColor: AppColors.bluePrimary,
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 3. Quick Actions Grid
  Widget _buildQuickActions(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.quickActionsTitle,
            style: const TextStyle(
              fontSize: 20, // Larger Header
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              const crossAxisCount = 2; // Fixed 2 columns
              final width = (constraints.maxWidth - (16 * (crossAxisCount - 1))) / crossAxisCount; 
              // Using Wrap to simulate Grid but with auto-sizing
              return Wrap(
                spacing: 16, // More spacing
                runSpacing: 16,
                children: [
                  _buildActionCard(
                    width: width,
                    title: l10n.gatePassTitle,
                    subtitle: 'Show QR',
                    icon: Icons.qr_code_2,
                    color: const Color(0xFF2D3436),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GatePassPage())),
                  ),
                  _buildActionCard(
                    width: width,
                    title: l10n.bookSpace,
                    subtitle: l10n.findNewShelves,
                    icon: Icons.add_business_rounded,
                    color: AppColors.bluePrimary,
                    onTap: () {
                      // final shell = context.findAncestorStateOfType<HomeShellState>();
                      // if (shell != null) {
                      //   shell.switchToTab(1); // Removed tab
                      // }
                      Navigator.push(context, MaterialPageRoute(builder: (_) => BookingPage()));
                    },
                  ),
                  _buildActionCard(
                    width: width,
                    title: l10n.requestDeliveryAction,
                    subtitle: l10n.shipToCustomers,
                    icon: Icons.send_rounded,
                    color: Colors.purple,
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const RequestDeliveryPage()));
                    },
                  ),
                  _buildActionCard(
                    width: width,
                    title: l10n.myInventoryAction,
                    subtitle: l10n.manageStock,
                    icon: Icons.inventory,
                    color: Colors.orange,
                    onTap: () {
                      Navigator.pushNamed(context, '/stage6');
                    },
                  ),
                  _buildActionCard(
                    width: width,
                    title: l10n.navPayments,
                    subtitle: l10n.viewInvoices,
                    icon: Icons.receipt_long,
                    color: Colors.teal,
                    onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentsPage()));
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required double width,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: width,
        padding: const EdgeInsets.all(20), // More internal padding
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Container(
              padding: const EdgeInsets.all(12), // Larger Icon BG
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 28), // Larger Icon
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 4. Recent Activity Feed
  Widget _buildRecentActivity(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.recentActivity,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: AppColors.bluePrimary),
                onPressed: _loadData,
              ),
            ],
          ),
          const SizedBox(height: 8),
          FutureBuilder<List<DashboardActivity>>(
            future: _activityFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const Text('Failed to load history');
              }
              final activities = snapshot.data ?? [];
              if (activities.isEmpty) {
                 return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.history_toggle_off_rounded, size: 48, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'No recent activity',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                 );
              }

              return Column(
                children: activities.map((activity) {
                  return _buildActivityItem(
                    title: activity.title,
                    subtitle: activity.subtitle,
                    time: _formatDate(activity.date),
                    icon: activity.icon,
                    color: activity.color,
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) {
      if (diff.inHours == 0) return '${diff.inMinutes}m ago';
      return '${diff.inHours}h ago';
    }
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return DateFormat('MMM d').format(date);
  }

  Widget _buildActivityItem({
    required String title,
    required String subtitle,
    required String time,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
