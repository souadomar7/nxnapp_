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
import 'marketplace/public_marketplace_page.dart';
import 'request_delivery_page.dart';
import 'receive_goods_stage.dart';
import 'operations/gate_pass_page.dart';
import 'copilot_page.dart';

import '../services/marketplace_service.dart';
import '../models/history_models.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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
    MarketplaceService.updateNotifier.addListener(_refreshData);
  }

  @override
  void dispose() {
    MarketplaceService.updateNotifier.removeListener(_refreshData);
    super.dispose();
  }

  // Wrapper for listener
  void _refreshData() => _loadData();

  Future<void> _loadData() async {
    setState(() {
      _activityFuture = _marketService.getRecentActivity();
    });
    // Fetch stats separately so they don't block the UI
    final stats = await _marketService.getDashboardStats();
    if (mounted) setState(() => _stats = stats);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      floatingActionButton: FloatingActionButton(
        heroTag: 'home_fab',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CopilotPage()),
          );
        },
        backgroundColor: AppColors.bluePrimary,
        child: const Icon(Icons.smart_toy_rounded, size: 28, color: Colors.white),
      ),
      // Wrapped in RefreshIndicator for standard "Pull to Refresh" behavior
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.bluePrimary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildHeader(l10n),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0), // Increased margin
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatsOverview(l10n),
                    // Reduced spacing due to Transform.translate on Stats
                    const SizedBox(height: 0), 
                    _buildAlertsSection(l10n),
                    const SizedBox(height: 16),
                    _buildWarehousePrep(context, l10n),
                    const SizedBox(height: 16),
                    _buildQuickActions(context, l10n),
                    const SizedBox(height: 16),
                    _buildActiveRentals(l10n),
                    const SizedBox(height: 16),
                    _buildRecentActivitySection(l10n),
                    const SizedBox(height: 40), // Bottom padding for scrolling
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 1. Header: Increased breathing room and font size
  Widget _buildHeader(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 50), // Increased bottom pad to push stats down
      decoration: const BoxDecoration(
        color: AppColors.bluePrimary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const BrandLogo(height: 36, isLight: true),
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 28),
                onPressed: () {},
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Consumer<UserProvider>(
            builder: (context, user, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.helloUser(user.displayName),
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Here's what's happening today.", // Optional subtitle for context
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // 2. Stats: Floating effect
  Widget _buildStatsOverview(AppLocalizations l10n) {
    return Transform.translate(
      offset: const Offset(0, -30),
      child: Row(
        children: [
          _buildStatCard(
            title: l10n.totalShelves,
            value: '${_stats['shelves']}',
            icon: Icons.shelves,
            color: AppColors.bluePrimary,
          ),
          const SizedBox(width: 16),
          _buildStatCard(
            title: l10n.stockValue,
            value: 'AED ${( (_stats['totalValue'] as num) / 1000).toStringAsFixed(1)}k',
            icon: Icons.monetization_on_rounded,
            color: Colors.green,
          ),
        ],
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
              color: const Color(0xFF1A1F3D).withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                // Optional trend arrow
                // Icon(Icons.arrow_upward_rounded, color: Colors.green, size: 16),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              title,
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

  // 3. Alerts: Cleaner look
  Widget _buildAlertsSection(AppLocalizations l10n) {
    if (_stats['pendingOrders'] == 0) return const SizedBox.shrink(); // Hide if empty

    return Row(
      children: [
        Expanded(
          child: _buildAlertChip(
            label: l10n.lowStockCount(3),
            icon: Icons.warning_amber_rounded,
            color: Colors.amber,
            bgColor: Colors.amber.shade50,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildAlertChip(
            label: l10n.outOfStockCount(1),
            icon: Icons.error_outline_rounded,
            color: Colors.red,
            bgColor: Colors.red.shade50,
          ),
        ),
      ],
    );
  }

  Widget _buildAlertChip({required String label, required IconData icon, required Color color, required Color bgColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontWeight: FontWeight.w700, color: color.withValues(alpha: 0.8), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // 4. Hero Action: Warehouse Prep
  Widget _buildWarehousePrep(BuildContext context, AppLocalizations l10n) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ReceiveGoodsStagePageEN()),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2E63FF), Color(0xFF0038A8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2E63FF).withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
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
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Manage incoming goods", // Helper text
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }

  // 5. Quick Actions: Larger touch targets and clearer icons
  Widget _buildQuickActions(BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.quickActionsTitle,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 125, // Safely increased height to avoid text overflow
          child: ListView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none, // Allow shadows to paint outside
            children: [
              _buildActionCard(
                title: l10n.gatePassTitle,
                icon: Icons.qr_code_2_rounded,
                color: const Color(0xFF2D3436),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GatePassPage())),
              ),
              const SizedBox(width: 16),
              _buildActionCard(
                title: l10n.bookSpace,
                icon: Icons.store_mall_directory_rounded,
                color: AppColors.bluePrimary,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BookingPage())),
              ),
              const SizedBox(width: 16),
              _buildActionCard(
                title: l10n.requestDeliveryAction,
                icon: Icons.local_shipping_rounded,
                color: Colors.purple,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RequestDeliveryPage())),
              ),
              const SizedBox(width: 16),
              _buildActionCard(
                title: l10n.myInventoryAction,
                icon: Icons.inventory_2_rounded,
                color: Colors.orange,
                onTap: () => Navigator.pushNamed(context, '/stage6'),
              ),
              const SizedBox(width: 16),
              _buildActionCard(
                title: 'Marketplace',
                icon: Icons.storefront,
                color: Colors.green,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PublicMarketplacePage())),
              ),
              const SizedBox(width: 16),
              _buildActionCard(
                title: l10n.navPayments,
                icon: Icons.receipt_long_rounded,
                color: Colors.teal,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentsPage())),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 90,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 6. Active Rental: Informational
  Widget _buildActiveRentals(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
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
              children: [
                Text(
                  l10n.alAinBranch,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                Text(
                  l10n.activeShelves(5),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.bluePrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
                l10n.managingTag,
                style: const TextStyle(color: AppColors.bluePrimary, fontSize: 11, fontWeight: FontWeight.bold)
            ),
          ),
        ],
      ),
    );
  }

  // 7. Recent Activity: Full list with error handling
  Widget _buildRecentActivitySection(AppLocalizations l10n) {
    return Column(
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
            TextButton(
              onPressed: () {}, // Navigate to full history page
              child: const Text("View All"),
            )
          ],
        ),
        const SizedBox(height: 8),
        FutureBuilder<List<DashboardActivity>>(
          future: _activityFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Padding(
                padding: const EdgeInsets.all(20.0),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              );
            }
            if (snapshot.hasError) {
              return Container(
                padding: const EdgeInsets.all(20),
                width: double.infinity,
                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
                child: Text(l10n.failedToLoadHistory, textAlign: TextAlign.center, style: TextStyle(color: Colors.red)),
              );
            }
            final activities = snapshot.data ?? [];
            if (activities.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    Icon(Icons.history_toggle_off, size: 40, color: Colors.grey.shade300),
                    const SizedBox(height: 10),
                    Text(l10n.noRecentActivity, style: TextStyle(color: Colors.grey.shade500)),
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(), // Let parent scroll
              shrinkWrap: true,
              itemCount: activities.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final activity = activities[index];
                return _buildActivityItem(
                  title: activity.title,
                  subtitle: activity.subtitle,
                  time: _formatDate(activity.date, l10n),
                  icon: activity.icon,
                  color: activity.color,
                );
              },
            );
          },
        ),
      ],
    );
  }

  String _formatDate(DateTime date, AppLocalizations l10n) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) {
      if (diff.inHours == 0) return l10n.minutesAgo(diff.inMinutes);
      return l10n.hoursAgo(diff.inHours);
    }
    if (diff.inDays == 1) return l10n.yesterday;
    if (diff.inDays < 7) return l10n.daysAgo(diff.inDays);
    return DateFormat('MMM d', l10n.localeName).format(date);
  }

  Widget _buildActivityItem({
    required String title,
    required String subtitle,
    required String time,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}