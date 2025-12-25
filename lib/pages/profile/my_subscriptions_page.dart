import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


class MySubscriptionsPage extends StatefulWidget {
  const MySubscriptionsPage({super.key});

  @override
  State<MySubscriptionsPage> createState() => _MySubscriptionsPageState();
}

class _MySubscriptionsPageState extends State<MySubscriptionsPage> {
  final _supabase = Supabase.instance.client;
  late Future<List<Map<String, dynamic>>> _subsFuture;

  @override
  void initState() {
    super.initState();
    _loadSubs();
  }

  void _loadSubs() {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      _subsFuture = _supabase
          .from('sme_subscriptions')
          .select('*, warehouses(name, emirate)')
          .eq('seller_id', user.id)
          .order('end_date', ascending: true);
    } else {
      _subsFuture = Future.value([]);
    }
  }

  Future<void> _cancelSubscription(String id) async {
    // Mock Cancel: Just update status or delete
    // Real logic: trigger stored procedure or update status
    await _supabase.from('sme_subscriptions').update({'is_active': false}).eq('id', id);
    setState(() => _loadSubs());
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cancellation Requested. Staff will contact you.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Subscriptions'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _subsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text('No active subscriptions'));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final sub = snapshot.data![index];
              final isActive = sub['is_active'] as bool;
              final warehouse = sub['warehouses'];
              // ignore: unnecessary_cast
              final endDate = DateTime.parse(sub['end_date'] as String);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey[200]!)),
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(warehouse['name'] ?? 'Warehouse', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isActive ? Colors.green[50] : Colors.red[50],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(isActive ? 'Active' : 'Cancelled', style: TextStyle(color: isActive ? Colors.green : Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('${sub['shelves_count']} Shelves • Ends ${endDate.day}/${endDate.month}/${endDate.year}'),
                      const SizedBox(height: 16),
                      if (isActive)
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Renew Logic (Mock)')));
                                },
                                child: const Text('Renew'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _cancelSubscription(sub['id']),
                                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                                child: const Text('Cancel'),
                              ),
                            ),
                          ],
                        )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
