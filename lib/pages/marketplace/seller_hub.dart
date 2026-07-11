import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../services/marketplace_service.dart';
import 'product_catalog_page.dart';
import 'inventory_page.dart';
import 'dropoff_booking_page.dart';
import 'delivery_request_page.dart';
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
          MarketplaceShop? shop;

          if (snapshot.hasData) {
            final stats = snapshot.data![0] as Map<String, dynamic>;
            shop = snapshot.data![1] as MarketplaceShop?;
            
            activeShelves = stats['shelves'] ?? 0;
            totalItems = stats['items'] ?? 0;
            pendingOrders = stats['pendingOrders'] ?? 0;
          }

          return CustomScrollView(
            slivers: [
              // 1. Professional Header
              SliverAppBar(
                expandedHeight: 140,
                pinned: true,
                backgroundColor: AppColors.bluePrimary,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1A47B8), Color(0xFF0D2566)], // NXN Blue Gradient
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.dashboardTitle,
                          style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              shop != null ? shop.shopName : AppLocalizations.of(context)!.dashboardSubtitle,
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14),
                            ),
                            const Spacer(),
                            if (shop != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: shop.isVerified ? Colors.green.withValues(alpha: 0.2) : Colors.orange.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    Icon(shop.isVerified ? Icons.verified : Icons.pending, color: shop.isVerified ? Colors.greenAccent : Colors.orangeAccent, size: 14),
                                    const SizedBox(width: 4),
                                    Text(shop.isVerified ? AppLocalizations.of(context)!.verifiedSeller : 'Pending Approval', style: TextStyle(color: shop.isVerified ? Colors.greenAccent : Colors.orangeAccent, fontSize: 10, fontWeight: FontWeight.bold)),
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
                    icon: const Icon(Icons.settings, color: Colors.white),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SellerSettingsPage())),
                  ),
                ],
              ),
              
              if (shop == null && snapshot.connectionState == ConnectionState.done)
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.store, color: Colors.orange.shade700, size: 32),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Setup Your Shop', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade900)),
                              const SizedBox(height: 4),
                              Text('Create a verified marketplace profile to list your products publicly.', style: TextStyle(fontSize: 12, color: Colors.orange.shade800)),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateShopPage()));
                            if (result == true) {
                              _loadStats();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.shade600,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Setup'),
                        ),
                      ],
                    ),
                  ),
                ),

              // 2. Stats Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              title: AppLocalizations.of(context)!.shelvesStat,
                              value: '$activeShelves',
                              icon: Icons.shelves,
                              color: Colors.orange,
                              trend: AppLocalizations.of(context)!.trendPlusMonth(2),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _StatCard(
                              title: AppLocalizations.of(context)!.itemsStat,
                              value: '$totalItems',
                              icon: Icons.inventory_2,
                              color: AppColors.bluePrimary,
                              trend: AppLocalizations.of(context)!.trendStocked(98),
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
                        trend: AppLocalizations.of(context)!.actionRequired,
                        trendColor: Colors.red,
                      ),
                      
                      const SizedBox(height: 32),
                      
                      Text(
                        AppLocalizations.of(context)!.quickActionsTitle,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
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
                            icon: Icons.list_alt_rounded,
                            color: const Color(0xFF2E86DE), // Nice Blue
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InventoryPage())),
                          ),
                          _ActionCard(
                            title: AppLocalizations.of(context)!.productCatalogAction,
                            icon: Icons.category_rounded,
                            color: const Color(0xFF10AC84), // Teal/Green
                            onTap: () async {
                               await Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductCatalogPage()));
                               _loadStats();
                            },
                          ),
                          _ActionCard(
                            title: AppLocalizations.of(context)!.bookDropoffAction,
                            icon: Icons.add_business_rounded,
                            color: const Color(0xFFFF9F43), // Orange
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DropoffBookingPage())),
                          ),
                           _ActionCard(
                            title: AppLocalizations.of(context)!.requestDeliveryAction,
                            icon: Icons.local_shipping_rounded,
                            color: const Color(0xFF5F27CD), // Purple
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DeliveryRequestPage())),
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
