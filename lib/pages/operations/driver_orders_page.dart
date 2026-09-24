import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme.dart';

class DriverOrdersPage extends StatefulWidget {
  const DriverOrdersPage({super.key});

  @override
  State<DriverOrdersPage> createState() => _DriverOrdersPageState();
}

class _DriverOrdersPageState extends State<DriverOrdersPage> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;
      // Load orders assigned to this driver OR all shipped orders if admin driver
      final data = await _supabase
          .from('buyer_orders')
          .select('*, sme_products(name, photo_url)')
          .inFilter('order_status', ['confirmed', 'preparing', 'ready_for_shipment', 'shipped'])
          .order('created_at', ascending: false);
      setState(() {
        _orders = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<Position?> _getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;
    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  Future<void> _markDelivered(Map<String, dynamic> order) async {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final orderId = order['id'] as String;

    // Step 1: Camera-only photo capture
    final picker = ImagePicker();
    XFile? photo;
    try {
      photo = await picker.pickImage(source: ImageSource.camera, imageQuality: 75);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isAr ? 'الكاميرا غير متاحة: $e' : 'Camera not available: $e'),
          backgroundColor: Colors.red,
        ));
      }
      return;
    }

    if (photo == null) return; // User cancelled

    // Show loading dialog
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
    }

    try {
      // Step 2: Get GPS coordinates
      final position = await _getCurrentPosition();

      // Step 3: Upload PoD photo to Supabase Storage
      final file = File(photo.path);
      final fileName = 'pod_${orderId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await _supabase.storage.from('delivery_proofs').upload(fileName, file);
      final photoUrl = _supabase.storage.from('delivery_proofs').getPublicUrl(fileName);

      // Step 4: Update order with GPS + photo + status
      await _supabase.from('buyer_orders').update({
        'order_status': 'delivered',
        'pod_photo_url': photoUrl,
        'pod_timestamp': DateTime.now().toIso8601String(),
        'delivery_lat': position?.latitude,
        'delivery_lng': position?.longitude,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', orderId);

      if (mounted) Navigator.pop(context); // close loading

      _loadOrders();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: Colors.green.shade700,
          content: Text(isAr
            ? '✅ تم تسجيل التسليم بنجاح مع صورة الإثبات'
            : '✅ Delivery confirmed with proof-of-delivery photo'),
        ));
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // close loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  Color _statusColor(String? s) {
    switch (s) {
      case 'confirmed': return AppColors.bluePrimary;
      case 'preparing': return Colors.purple;
      case 'ready_for_shipment': return Colors.indigo;
      case 'shipped': return Colors.orange;
      case 'delivered': return Colors.green;
      default: return Colors.grey;
    }
  }

  String _statusLabel(String? s, bool isAr) {
    switch (s) {
      case 'confirmed': return isAr ? 'مؤكد' : 'Confirmed';
      case 'preparing': return isAr ? 'قيد التجهيز' : 'Preparing';
      case 'ready_for_shipment': return isAr ? 'جاهز للشحن' : 'Ready to Ship';
      case 'shipped': return isAr ? 'في الطريق' : 'Shipped';
      case 'delivered': return isAr ? 'تم التسليم' : 'Delivered';
      default: return s ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: AppColors.bluePrimary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          isAr ? '🚚 طلباتي للتوصيل' : '🚚 My Delivery Orders',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _loadOrders,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.local_shipping_outlined, size: 72, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        isAr ? 'لا توجد طلبات للتوصيل حالياً' : 'No delivery orders assigned',
                        style: TextStyle(fontSize: 16, color: Colors.grey.shade500, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadOrders,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _orders.length,
                    itemBuilder: (ctx, i) {
                      final o = _orders[i];
                      final status = o['order_status'] as String?;
                      final isDelivered = status == 'delivered';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0,4))],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.person_outline_rounded, size: 18, color: AppColors.bluePrimary),
                                  const SizedBox(width: 6),
                                  Expanded(child: Text(o['buyer_name'] ?? '',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _statusColor(status).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(_statusLabel(status, isAr),
                                        style: TextStyle(color: _statusColor(status),
                                            fontWeight: FontWeight.bold, fontSize: 12)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Expanded(child: Text(o['buyer_address'] ?? '',
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13))),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.phone_outlined, size: 16, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(o['buyer_phone'] ?? '',
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                                ],
                              ),
                              if (o['pod_photo_url'] != null) ...([
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.green),
                                    const SizedBox(width: 4),
                                    Text(isAr ? 'صورة الإثبات متاحة ✓' : 'Proof of delivery captured ✓',
                                        style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ]),
                              if (!isDelivered) ...[
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () => _markDelivered(o),
                                    icon: const Icon(Icons.camera_alt_rounded),
                                    label: Text(isAr ? 'تصوير وتأكيد التسليم' : 'Capture PoD & Mark Delivered'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green.shade700,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
