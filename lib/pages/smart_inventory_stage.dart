import 'package:flutter/material.dart';
import 'package:nxnapp/pages/restock_page.dart';
import 'package:provider/provider.dart';

import '../data/inventory_controller.dart';
import '../data/receive_result.dart';
import '../l10n/app_localizations.dart';

// Match BookingPage/ReceivePage colors
class InventoryColors {
  static const primary = Color(0xFF0057FF); // Vibrant Blue
  static const background = Color(0xFFF3F6FB); // Light Grey-Blue
  static const textDark = Color(0xFF1A1F36); // Dark user text
  static const cardBorder = Color(0xFFE0E6F2);
}

class SmartInventoryStageEN extends StatefulWidget {
  /// Optional – shown if we navigated from ReceiveGoodsStagePageEN (Stage 5)
  final ReceiveResult? result;

  const SmartInventoryStageEN({super.key, this.result});

  @override
  State<SmartInventoryStageEN> createState() => _SmartInventoryStageENState();
}

class _SmartInventoryStageENState extends State<SmartInventoryStageEN> {
  @override
  void initState() {
    super.initState();
    // Load inventory once when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventoryController>().load();
    });
  }

  String _fmtDateTime(DateTime dt) {
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '${dt.day}/${dt.month}/${dt.year}  $hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<InventoryController>();

    return Scaffold(
      backgroundColor: InventoryColors.background,
      body: CustomScrollView(
        slivers: [
          // 1. Sliver Header
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: InventoryColors.primary,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded, color: Colors.white),
                onPressed: () {},
              ),
            ],
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
                              color: InventoryColors.primary,
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          const Icon(Icons.analytics_rounded, color: Colors.white, size: 28),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              "Smart Inventory", // Localize ideally
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppLocalizations.of(context)!.visualAnalyticsText,
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 2. Main Content
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: InventoryColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              transform: Matrix4.translationValues(0, -20, 0),
              padding: const EdgeInsets.fromLTRB(20, 30, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
                  // Inbound summary from receiving flow (Stage 5)
                  if (widget.result != null) ...[
                    _SectionHeader(title: AppLocalizations.of(context)!.lastInboundTitle),
                    const SizedBox(height: 12),
                    _InfoCard(
                      child: Column(
                        children: [
                          _infoRow(AppLocalizations.of(context)!.smartStorageNo, widget.result!.storageNo, isHighlight: true),
                          const Divider(height: 24, color: Color(0xFFF0F0F0)),
                          _infoRow(AppLocalizations.of(context)!.smartBay, widget.result!.bay),
                          _infoRow(AppLocalizations.of(context)!.smartScheduledAt, _fmtDateTime(widget.result!.scheduledAt)),
                          _infoRow(AppLocalizations.of(context)!.smartStorageModel, widget.result!.storageMode),
                          _infoRow(AppLocalizations.of(context)!.smartWorkers,'${widget.result!.workers} (AED ${widget.result!.workers * 50})'),
                          if (widget.result!.notes.trim().isNotEmpty)
                            _infoRow(AppLocalizations.of(context)!.notesLabel, widget.result!.notes),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Stats Overview
                  _SectionHeader(title: AppLocalizations.of(context)!.warehouseStockOverview),
                  const SizedBox(height: 12),
                  
                  if (c.loading)
                    const _SkeletonStats()
                  else ...[
                    // Key Metrics
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            title: AppLocalizations.of(context)!.smartWarehouse,
                            value: '${c.summary.suppliers} Shelves',
                            icon: Icons.warehouse_rounded,
                            color: InventoryColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            title: 'Stock Value',
                            value: 'AED ${(c.summary.totalValue / 1000).toStringAsFixed(1)}k',
                            icon: Icons.monetization_on_rounded,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Alerts
                    if (c.summary.lowStock > 0 || c.summary.outOfStock > 0)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            if (c.summary.lowStock > 0)
                              Expanded(child: _AlertCard('Low Stock', '${c.summary.lowStock} Items', Colors.orange)),
                            if (c.summary.lowStock > 0 && c.summary.outOfStock > 0)
                              const SizedBox(width: 12),
                            if (c.summary.outOfStock > 0)
                              Expanded(child: _AlertCard('Out of Stock', '${c.summary.outOfStock} Items', Colors.red)),
                          ],
                        ),
                      ),
                      
                    // Chart
                    Container(
                      height: 240,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: InventoryColors.cardBorder),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: c.series.isEmpty
                          ? Center(child: Text(AppLocalizations.of(context)!.noChartData, style: const TextStyle(color: Colors.grey)))
                          : _SimpleBars(
                              values: c.series.map((e) => e.value.toDouble()).toList(),
                              labels: c.series.map((e) => e.label).toList(),
                            ),
                    ),
                    const SizedBox(height: 24),

                    // Active Rentals List
                    if (c.summary.activeRentals.isNotEmpty) ...[
                      const _SectionHeader(title: 'Active Rentals'),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 110,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: c.summary.activeRentals.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final r = c.summary.activeRentals[index];
                            final warehouse = r['warehouse'] ?? 'Unknown';
                            return Container(
                              width: 160,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: InventoryColors.cardBorder),
                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(children: [
                                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                                    const SizedBox(width: 6),
                                    const Text("Active", style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold))
                                  ]),
                                  const SizedBox(height: 10),
                                  Text(warehouse, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: InventoryColors.textDark)),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ],

                  // Quick Actions
                  const _SectionHeader(title: "Quick Actions"),
                  const SizedBox(height: 12),
                  // ActionTile for Request Delivery removed as per user request to move it to Home only.
                  const SizedBox(height: 10),
                  _ActionTile(
                    label: AppLocalizations.of(context)!.restockBtn,
                    icon: Icons.inventory_outlined,
                    onTap: c.loading ? null : () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RestockPage()),
                      );
                      if (context.mounted) {
                         context.read<InventoryController>().load();
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  _ActionTile(
                    label: AppLocalizations.of(context)!.viewReportsBtn,
                    icon: Icons.bar_chart_rounded,
                    onTap: c.loading ? null : () async {
                      final url = await c.openReports();
                      if (context.mounted) {
                        _toast(context, url != null ? AppLocalizations.of(context)!.openingReports : AppLocalizations.of(context)!.noReportsAvailable);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper Methods & Widgets

  Widget _infoRow(String k, String v, {bool isHighlight = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            k,
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: Text(
            v,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: isHighlight ? InventoryColors.primary : InventoryColors.textDark,
              fontWeight: isHighlight ? FontWeight.w800 : FontWeight.w600,
              fontSize: isHighlight ? 16 : 14,
            ),
          ),
        ),
      ],
    ),
  );

  static void _toast(BuildContext ctx, String msg) {
    ScaffoldMessenger.of(ctx).hideCurrentSnackBar();
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(msg)));
  }
}

// --------------------------------------------------------------------------
// UI COMPONENTS
// --------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: InventoryColors.textDark,
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final Widget child;
  const _InfoCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: InventoryColors.cardBorder),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: child,
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: InventoryColors.cardBorder),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: InventoryColors.textDark)),
          const SizedBox(height: 2),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  const _AlertCard(this.title, this.subtitle, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: color, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
              Text(subtitle, style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  const _ActionTile({required this.label, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: InventoryColors.cardBorder),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: InventoryColors.background, borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: InventoryColors.primary, size: 22),
            ),
            const SizedBox(width: 14),
            Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: InventoryColors.textDark)),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

class _SimpleBars extends StatelessWidget {
  final List<double> values;
  final List<String> labels;

  const _SimpleBars({required this.values, required this.labels});

  @override
  Widget build(BuildContext context) {
    final maxV = (values.isEmpty) ? 0.0 : values.reduce((a, b) => a > b ? a : b);
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (int i = 0; i < values.length; i++)
              Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    width: 30,
                    height: maxV == 0 ? 4 : (values[i] / maxV) * (constraints.maxHeight - 30),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [InventoryColors.primary, InventoryColors.primary.withValues(alpha: 0.6)],
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 40,
                    child: Text(
                      labels[i],
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                ],
              ),
          ],
        );
      }
    );
  }
}

class _SkeletonStats extends StatelessWidget {
  const _SkeletonStats();

  @override
  Widget build(BuildContext context) {
    Widget skel() => Expanded(
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: InventoryColors.cardBorder),
        ),
      ),
    );

    return Row(
      children: [
        skel(),
        const SizedBox(width: 12),
        skel(),
      ],
    );
  }
}
