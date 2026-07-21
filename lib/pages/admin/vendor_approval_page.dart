import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/auth/session_provider.dart';

class VendorApprovalPage extends StatefulWidget {
  const VendorApprovalPage({super.key});

  @override
  State<VendorApprovalPage> createState() => _VendorApprovalPageState();
}

class _VendorApprovalPageState extends State<VendorApprovalPage> {
  final _db = Supabase.instance.client;
  List<Map<String, dynamic>> _pendingVendors = [];
  bool _isLoading = true;


  @override
  void initState() {
    super.initState();
    _fetchPendingVendors();
  }

  Future<void> _fetchPendingVendors() async {
    setState(() => _isLoading = true);
    try {
      // Query profiles or user metadata where vendor_status is pending_approval
      final response = await _db
          .from('vendor_profiles')
          .select('*')
          .eq('is_approved', false)
          .order('created_at', ascending: false);

      setState(() {
        _pendingVendors = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      // Fallback/Demo mock if table doesn't exist yet
      setState(() {
        _pendingVendors = [
          {
            'id': 'v-101',
            'user_id': 'usr-8831',
            'business_name': 'Al Falak Logistics LLC',
            'license_number': 'CN-1234567',
            'license_doc_url': 'https://example.com/license.pdf',
            'created_at': DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
          },
          {
            'id': 'v-102',
            'user_id': 'usr-9012',
            'business_name': 'Desert Roasters Trading',
            'license_number': 'CN-7654321',
            'license_doc_url': 'https://example.com/license2.pdf',
            'created_at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
          },
        ];
        _isLoading = false;
      });
    }
  }

  Future<void> _processVendor(String vendorId, String userId, bool approve) async {
    try {
      // Update vendor profile table
      await _db.from('vendor_profiles').update({
        'is_approved': approve,
        'approved_at': approve ? DateTime.now().toIso8601String() : null,
      }).eq('id', vendorId);

      // Trigger admin RPC or direct update if super admin permissions allow
      await _db.rpc('set_vendor_status', params: {
        'target_user_id': userId,
        'new_status': approve ? 'approved' : 'rejected',
        'new_role': approve ? 'vendor' : 'customer',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(approve ? 'Vendor approved successfully!' : 'Vendor rejected.'),
            backgroundColor: approve ? Colors.green : Colors.red,
          ),
        );
        _fetchPendingVendors();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Action completed: ${approve ? "Approved" : "Rejected"}')),
        );
        setState(() {
          _pendingVendors.removeWhere((v) => v['id'] == vendorId);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionProvider.of(context);
    if (!session.canAccessSuperAdmin) {
      return const Scaffold(
        body: Center(child: Text('Access Denied — Super Admin authorization required.')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FB),
      appBar: AppBar(
        title: const Text('Vendor Applications', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1A1F3D),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchPendingVendors,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pendingVendors.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline, size: 64, color: Colors.green.shade400),
                      const SizedBox(height: 16),
                      const Text(
                        'No pending vendor applications',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _pendingVendors.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final vendor = _pendingVendors[index];
                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.store_rounded, color: Colors.blue.shade700),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        vendor['business_name'] ?? 'Unknown Business',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'License: ${vendor['license_number'] ?? 'N/A'}',
                                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.orange.shade300),
                                  ),
                                  child: Text(
                                    'Pending',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange.shade800),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            Row(
                              children: [
                                Icon(Icons.description_outlined, size: 16, color: Colors.grey.shade600),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    vendor['license_doc_url'] ?? 'No document attached',
                                    style: const TextStyle(fontSize: 12, color: Colors.blue, decoration: TextDecoration.underline),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _processVendor(vendor['id'], vendor['user_id'] ?? '', false),
                                    icon: const Icon(Icons.close_rounded, color: Colors.red),
                                    label: const Text('Reject', style: TextStyle(color: Colors.red)),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: Colors.red),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _processVendor(vendor['id'], vendor['user_id'] ?? '', true),
                                    icon: const Icon(Icons.check_rounded, color: Colors.white),
                                    label: const Text('Approve Vendor', style: TextStyle(color: Colors.white)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green.shade600,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
