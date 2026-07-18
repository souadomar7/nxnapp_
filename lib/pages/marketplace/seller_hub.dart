import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../services/marketplace_service.dart';
import 'product_catalog_page.dart';
import '../smart_inventory_stage.dart';
import '../receive_goods_stage.dart';
import '../request_delivery_page.dart';
import 'seller_settings_page.dart';
import 'create_shop_page.dart';
import '../../l10n/app_localizations.dart';
import '../../models/marketplace_models.dart';

class SellerHub extends StatefulWidget {
  const SellerHub({super.key});

  @override
  State<SellerHub> createState() => _SellerHubState();
}

class _SellerHubState extends State<SellerHub> {
  final MarketplaceService _service = MarketplaceService();
  late Future<Map<String, dynamic>> _statsFuture;
  late Future<MarketplaceShop?> _shopFuture;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  void _loadStats() {
    setState(() {
      _statsFuture = _service.getDashboardStats();
      _shopFuture = _service.getMyShop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC), // Lighter, cooler background
      body: FutureBuilder(
        future: Future.wait([_statsFuture, _shopFuture]),
        builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
          int activeShelves = 0;
          int totalItems = 0;
          int pendingOrders = 0;
          int shelvesThisMonth = 0;
          MarketplaceShop? shop;

          if (snapshot.hasData) {
            final stats = snapshot.data![0] as Map<String, dynamic>;
            shop = snapshot.data![1] as MarketplaceShop?;
            
            activeShelves = stats['shelves'] ?? 0;
            totalItems = stats['items'] ?? 0;
            pendingOrders = stats['pendingOrders'] ?? 0;
            shelvesThisMonth = stats['shelvesThisMonth'] ?? 0;
          }

          // Calculate capacity metrics
          double capacityPercentage = activeShelves > 0 ? (totalItems / (activeShelves * 50.0)) : 0.0;
          capacityPercentage = capacityPercentage.clamp(0.0, 1.0);

          return CustomScrollView(
            slivers: [
              // 1. Professional Gradient Header
              SliverAppBar(
                expandedHeight: 150,
                pinned: true,
                backgroundColor: AppColors.bluePrimary,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1E3C72), Color(0xFF2A5298)], // Premium Navy/Blue Gradient
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Text(
                          'Store Dashboard',
                          style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.storefront_rounded, color: Colors.white.withValues(alpha: 0.7), size: 16),
                            const SizedBox(width: 6),
                            Text(
                              shop != null ? shop.shopName : 'Setup pending',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                            const Spacer(),
                            if (shop != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: shop.isVerified ? Colors.green.withValues(alpha: 0.25) : Colors.orange.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                    color: shop.isVerified ? Colors.greenAccent.withValues(alpha: 0.5) : Colors.orangeAccent.withValues(alpha: 0.5),
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      shop.isVerified ? Icons.verified_user_rounded : Icons.hourglass_empty_rounded,
                                      color: shop.isVerified ? Colors.greenAccent : Colors.orangeAccent,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      shop.isVerified ? 'VERIFIED' : 'PENDING',
                                      style: TextStyle(
                                        color: shop.isVerified ? Colors.greenAccent : Colors.orangeAccent,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.settings_outlined, color: Colors.white, size: 26),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SellerSettingsPage())),
                  ),
                ],
              ),
              
              if (shop == null && snapshot.connectionState == ConnectionState.done)
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.orange.shade50, Colors.orange.shade100],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
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
                              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                              child: Icon(Icons.storefront_rounded, color: Colors.orange.shade800, size: 28),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Register Your Store',
                                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.orange.shade900),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Setup your profile to sell on NXN Marketplace.',
                                    style: TextStyle(fontSize: 12, color: Colors.orange.shade800),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateShopPage()));
                              if (result == true) {
                                _loadStats();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange.shade700,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Setup Store Now', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // 2. Capacity & Metrics Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Space Capacity Progress indicator
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF9DA8C4).withValues(alpha: 0.08),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Warehouse Shelf Capacity',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                                ),
                                Text(
                                  '${(capacityPercentage * 100).toInt()}% Used',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: capacityPercentage > 0.85 ? Colors.red : AppColors.bluePrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: capacityPercentage,
                                minHeight: 10,
                                backgroundColor: Colors.grey.shade100,
                                color: capacityPercentage > 0.85 ? Colors.red : AppColors.bluePrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              activeShelves > 0
                                  ? '$totalItems items stored across $activeShelves active shelves.'
                                  : 'No shelves rented yet. Book space to store inventory.',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              title: AppLocalizations.of(context)!.shelvesStat,
                              value: '$activeShelves',
                              icon: Icons.shelves,
                              color: Colors.orange,
                              trend: AppLocalizations.of(context)!.trendPlusMonth(shelvesThisMonth),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _StatCard(
                              title: AppLocalizations.of(context)!.itemsStat,
                              value: '$totalItems',
                              icon: Icons.inventory_2,
                              color: AppColors.bluePrimary,
                              trend: AppLocalizations.of(context)!.trendStocked(
                                activeShelves > 0 ? ((totalItems / (activeShelves * 50)) * 100).clamp(0, 100).toInt() : 0
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _StatCard(
                        title: AppLocalizations.of(context)!.pendingOrdersStat,
                        value: '$pendingOrders',
                        icon: Icons.local_shipping,
                        color: Colors.redAccent,
                        isFullWidth: true,
                        trend: pendingOrders > 0 ? AppLocalizations.of(context)!.actionRequired : "All Caught Up",
                        trendColor: pendingOrders > 0 ? Colors.red : Colors.green,
                      ),
                      
                      const SizedBox(height: 32),
                      
                      const Text(
                        'Operations Management',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 16),
                      
                      // 3. Modern Grid
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.1,
                        children: [
                          _ActionCard(
                            title: AppLocalizations.of(context)!.myInventoryAction,
                            icon: Icons.inventory_2_rounded,
                            color: const Color(0xFF2E86DE), // Nice Blue
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SmartInventoryStageEN())),
                          ),
                          _ActionCard(
                            title: AppLocalizations.of(context)!.productCatalogAction,
                            icon: Icons.inventory_rounded,
                            color: const Color(0xFF10AC84), // Teal/Green
                            onTap: () async {
                              await Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductCatalogPage()));
                              _loadStats();
                            },
                          ),
                          _ActionCard(
                            title: AppLocalizations.of(context)!.bookDropoffAction,
                            icon: Icons.move_to_inbox_rounded,
                            color: const Color(0xFFFF9F43), // Orange
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReceiveGoodsStagePageEN())),
                          ),
                          _ActionCard(
                            title: AppLocalizations.of(context)!.requestDeliveryAction,
                            icon: Icons.outbox_rounded,
                            color: const Color(0xFF5F27CD), // Purple
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RequestDeliveryPage())),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool isFullWidth;
  final String? trend;
  final Color? trendColor;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.isFullWidth = false,
    this.trend,
    this.trendColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24), // Increased padding
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24), // More rounded
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9DA8C4).withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 8),
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 28), // Larger Icon
              ),
              if (isFullWidth && trend != null)
                 Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: (trendColor ?? Colors.green).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                    child: Text(trend!, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: trendColor ?? Colors.green)),
                 ),
            ],
          ),
          const SizedBox(height: 20),
          Text(value, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.textPrimary)), // Larger Value
          const SizedBox(height: 6),
          Text(title, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
          if (!isFullWidth && trend != null) ...[
            const SizedBox(height: 12),
            Text(trend!, style: TextStyle(fontSize: 12, color: trendColor ?? Colors.green, fontWeight: FontWeight.w600)),
          ]
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF9DA8C4).withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18), // Larger circle
              decoration: BoxDecoration(
                 gradient: LinearGradient(
                   begin: Alignment.topLeft,
                   end: Alignment.bottomRight,
                   colors: [color.withValues(alpha: 0.8), color],
                 ),
                 shape: BoxShape.circle,
                 boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 5))],
              ),
              child: Icon(icon, size: 36, color: Colors.white), // Larger Icon
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
