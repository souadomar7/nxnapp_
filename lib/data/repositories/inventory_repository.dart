import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;
import '../../core/errors/app_exception.dart';

class InventoryRepository {
  final SupabaseClient _supabase;

  InventoryRepository({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  String get _currentUserId {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw const AuthException(message: 'User must be authenticated');
    }
    return user.id;
  }

  /// Get inventory items across all shelves for the current merchant
  Future<List<Map<String, dynamic>>> getMyInventory() async {
    try {
      final res = await _supabase
          .from('sme_inventory')
          .select('*, sme_products!sme_inventory_product_id_fkey(name, name_ar, price, photo_url), warehouses(name, emirate)')
          .eq('seller_id', _currentUserId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      debugPrint('Error fetching inventory: $e');
      throw ServerException(message: 'Failed to fetch inventory: $e', statusCode: 500);
    }
  }

  /// Get inventory movements audit log for the current merchant
  Future<List<Map<String, dynamic>>> getMovements({int limit = 50}) async {
    try {
      final res = await _supabase
          .from('inventory_movements')
          .select('*, sme_products(name)')
          .eq('seller_id', _currentUserId)
          .order('created_at', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      debugPrint('Error fetching movements: $e');
      return [];
    }
  }

  /// Record an inbound or outbound inventory movement
  Future<void> recordMovement({
    required String productId,
    required String movementType,
    required int quantityDelta,
    String? warehouseId,
    String? shelfLabel,
    String? referenceType,
    String? notes,
  }) async {
    try {
      await _supabase.from('inventory_movements').insert({
        'product_id': productId,
        'seller_id': _currentUserId,
        'warehouse_id': warehouseId,
        'shelf_label': shelfLabel,
        'movement_type': movementType,
        'quantity_delta': quantityDelta,
        'reference_type': referenceType,
        'notes': notes,
        'created_by': _currentUserId,
      });
    } catch (e) {
      debugPrint('Error recording inventory movement: $e');
      throw ServerException(message: 'Failed to record movement: $e', statusCode: 500);
    }
  }
}
