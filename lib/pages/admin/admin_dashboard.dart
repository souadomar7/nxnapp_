import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../services/marketplace_service.dart';
import '../../models/invoice.dart';
import 'receiving_flow.dart';
import 'put_away_page.dart';
import 'dispatch_page.dart';
import 'history_page.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  // --- Replaced Mock Data with Future from Service ---
  final MarketplaceService _mp = MarketplaceService();
  Future<List<Map<String, dynamic>>>? _tasksFuture;

  @override
  void initState() {
    super.initState();
    _refreshTasks();
  }

  void _refreshTasks() {
    setState(() {
      _tasksFuture = _mp.getAdminTasks();
    });
  }

  void _onTaskComplete() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Task Completed & Archived'), backgroundColor: Colors.green),
    );
    _refreshTasks(); // Reload from DB
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 700;
        final isUltraWide = constraints.maxWidth >= 1100;

        return Scaffold(
          backgroundColor: Colors.grey[100],
          appBar: AppBar(
            title: const Text('NXN Warehouse Panel - Al Karama'),
            backgroundColor: Colors.white,
            foregroundColor: Colors.blueGrey[900],
            elevation: 1,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _refreshTasks, // Manual Refresh
              ),
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => Navigator.of(context).pushReplacementNamed('/'),
              ),
            ],
          ),
          body: Row(
            children: [
              if (isWide)
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (int index) {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                  labelType: NavigationRailLabelType.all,
                  leading: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Icon(Icons.warehouse_rounded, size: 40, color: AppColors.bluePrimary),
                  ),
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.dashboard_outlined),
                      selectedIcon: Icon(Icons.dashboard),
                      label: Text('Overview'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.corporate_fare_outlined),
                      selectedIcon: Icon(Icons.corporate_fare),
                      label: Text('Rentals'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.local_shipping_outlined),
                      selectedIcon: Icon(Icons.local_shipping),
                      label: Text('Dispatch'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.history_outlined),
                      selectedIcon: Icon(Icons.history),
                      label: Text('History'),
                    ),
                  ],
                ),
              if (isWide) const VerticalDivider(thickness: 1, width: 1),
              
              Expanded(
                child: _buildContent(isWide, isUltraWide),
              ),
            ],
          ),
          bottomNavigationBar: !isWide ? BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) => setState(() => _selectedIndex = index),
            selectedItemColor: AppColors.bluePrimary,
            unselectedItemColor: Colors.grey,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Overview'),
              BottomNavigationBarItem(icon: Icon(Icons.corporate_fare), label: 'Rentals'),
              BottomNavigationBarItem(icon: Icon(Icons.local_shipping), label: 'Dispatch'),
              BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
            ],
          ) : null,
          floatingActionButton: _selectedIndex == 0 ? FloatingActionButton.extended(
            heroTag: 'admin_fab',
            onPressed: () async {
                 // Open Scan Flow (Generic/Manual)
                 final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const ReceivingFlowPage()));
                 if (result == true) _onTaskComplete();
            },
            label: Text(isWide ? 'Scan Incoming' : 'Scan'),
            icon: const Icon(Icons.qr_code_scanner),
            backgroundColor: AppColors.bluePrimary,
          ) : null,
        );
      },
    );
  }

  Widget _buildContent(bool isWide, bool isUltraWide) {
    switch (_selectedIndex) {
      case 0:
        return _buildOverview(isWide, isUltraWide);
      case 1:
        return _buildSpaceRentals();
      case 2:
        return const DispatchPage();
      case 3:
        return const HistoryPage();
      default:
        return _buildOverview(isWide, isUltraWide);
    }
  }

  Widget _buildOverview(bool isWide, bool isUltraWide) {
    final gridCount = isUltraWide ? 3 : (isWide ? 2 : 1);
    final aspectRatio = isWide ? 1.5 : 1.6;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _tasksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
             return Center(child: Text('Error: ${snapshot.error}'));
          }

          final tasks = snapshot.data ?? [];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   const Text('Active Tasks', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                   Text('${tasks.length} Pending', style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 24),
              
              Expanded(
                child: tasks.isEmpty 
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline, size: 80, color: Colors.green[200]),
                        const SizedBox(height: 16),
                        const Text('All caught up! No Pending Requests', style: TextStyle(fontSize: 20, color: Colors.grey)),
                      ],
                    ),
                  )
                : GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: gridCount,
                      childAspectRatio: aspectRatio,
                      crossAxisSpacing: 24,
                      mainAxisSpacing: 24,
                    ),
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return _buildTaskCard(task);
                    },
                  ),
              ),
            ],
          );
        }
      ),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () async {
          // Navigate based on type
          if (task['type'] == 'receive') {
             // Pass partial data or ID to ReceivingFlow
             final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => ReceivingFlowPage(bookingData: task['raw'])));
             if (result == true) _onTaskComplete();
          } else {
             await Navigator.push(context, MaterialPageRoute(builder: (_) => const PutAwayPage()));
             // Simple mock completion for put away too if it returns true
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Container(
                     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                     decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(6)),
                     child: Row(
                       children: [
                         Icon(Icons.access_time, size: 12, color: Colors.grey[700]),
                         const SizedBox(width: 4),
                         Text(task['time'], style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[800])),
                       ],
                     ),
                   ),
                   Container(
                     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                     decoration: BoxDecoration(color: (task['color'] as Color).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                     child: Text(task['badge'], style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: task['color'])),
                   ),
                ],
              ),
              const Spacer(),
              Text(task['title'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(task['subtitle'], maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpaceRentals() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Space Rentals', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Expanded(
            child: FutureBuilder<List<Invoice>>(
              future: _mp.getAdminInvoices(InvoiceType.rental),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final rentals = snapshot.data ?? [];
                if (rentals.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.warehouse_outlined, size: 80, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No active space rentals found.', style: TextStyle(fontSize: 18, color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: rentals.length,
                  itemBuilder: (context, index) {
                    final rental = rentals[index];
                    final String warehouseIds = (rental.metaData?['warehouseIds'] as List?)?.join(', ') ?? 'N/A';
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade50,
                          child: const Icon(Icons.warehouse, color: AppColors.bluePrimary),
                        ),
                        title: Text(rental.warehouseName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            'Locations: ${warehouseIds.toUpperCase()}\nDate: ${rental.formattedDate}',
                            style: const TextStyle(height: 1.4),
                          ),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('AED ${rental.total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: rental.paid ? Colors.green.shade50 : Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                rental.paid ? 'Paid' : 'Unpaid',
                                style: TextStyle(
                                  color: rental.paid ? Colors.green : Colors.orange,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
