import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/marketplace_models.dart';

class CartProvider extends ChangeNotifier {
  static const String _storageKey = 'nxn_user_cart_v1';

  final List<CartItem> _items = [];
  String? _appliedPromoCode;
  double _promoDiscountPercent = 0.0;
  double _promoDiscountFlat = 0.0;
  bool _isFreeDeliveryPromo = false;

  CartProvider() {
    _loadFromStorage();
  }

  List<CartItem> get items => List.unmodifiable(_items);

  int get totalItemCount => _items.fold<int>(0, (sum, item) => sum + item.quantity);

  bool get isEmpty => _items.isEmpty;

  bool get isNotEmpty => _items.isNotEmpty;

  String? get appliedPromoCode => _appliedPromoCode;

  double get subtotal => double.parse(_items.fold<double>(0.0, (sum, item) => sum + item.totalPrice).toStringAsFixed(2));

  double get vatAmount => double.parse((subtotal * 0.05).toStringAsFixed(2));

  double get deliveryFee {
    if (_items.isEmpty) return 0.0;
    if (_isFreeDeliveryPromo || subtotal >= 150.0) return 0.0;
    return 15.0;
  }

  double get discountAmount {
    if (_items.isEmpty) return 0.0;
    double discount = 0.0;
    if (_promoDiscountPercent > 0) {
      discount += subtotal * _promoDiscountPercent;
    }
    if (_promoDiscountFlat > 0) {
      discount += _promoDiscountFlat;
    }
    return discount.clamp(0.0, subtotal);
  }

  double get grandTotal {
    if (_items.isEmpty) return 0.0;
    final total = subtotal + deliveryFee - discountAmount;
    return total < 0 ? 0.0 : total;
  }

  bool isInCart(String productId) {
    return _items.any((item) => item.product.id == productId);
  }

  int getProductQuantity(String productId) {
    final idx = _items.indexWhere((item) => item.product.id == productId);
    if (idx != -1) return _items[idx].quantity;
    return 0;
  }

  void addItem(SmeProduct product, {int quantity = 1}) {
    final idx = _items.indexWhere((item) => item.product.id == product.id);
    if (idx != -1) {
      _items[idx].quantity += quantity;
    } else {
      _items.add(CartItem(product: product, quantity: quantity));
    }
    _saveToStorage();
    notifyListeners();
  }

  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeItem(productId);
      return;
    }
    final idx = _items.indexWhere((item) => item.product.id == productId);
    if (idx != -1) {
      _items[idx].quantity = quantity;
      _saveToStorage();
      notifyListeners();
    }
  }

  void increment(String productId) {
    final idx = _items.indexWhere((item) => item.product.id == productId);
    if (idx != -1) {
      _items[idx].quantity++;
      _saveToStorage();
      notifyListeners();
    }
  }

  void decrement(String productId) {
    final idx = _items.indexWhere((item) => item.product.id == productId);
    if (idx != -1) {
      if (_items[idx].quantity > 1) {
        _items[idx].quantity--;
      } else {
        _items.removeAt(idx);
      }
      _saveToStorage();
      notifyListeners();
    }
  }

  void removeItem(String productId) {
    _items.removeWhere((item) => item.product.id == productId);
    if (_items.isEmpty) {
      removePromoCode();
    }
    _saveToStorage();
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    removePromoCode();
    _saveToStorage();
    notifyListeners();
  }

  bool applyPromoCode(String rawCode) {
    final code = rawCode.trim().toUpperCase();
    if (code == 'NXN10' || code == 'NXN' || code == 'DUBAI10') {
      _appliedPromoCode = code;
      _promoDiscountPercent = 0.10;
      _promoDiscountFlat = 0.0;
      _isFreeDeliveryPromo = false;
      notifyListeners();
      return true;
    } else if (code == 'SAVE20' || code == 'WELCOME20') {
      _appliedPromoCode = code;
      _promoDiscountPercent = 0.0;
      _promoDiscountFlat = 20.0;
      _isFreeDeliveryPromo = false;
      notifyListeners();
      return true;
    } else if (code == 'FREESHIP' || code == 'FREE') {
      _appliedPromoCode = code;
      _promoDiscountPercent = 0.0;
      _promoDiscountFlat = 0.0;
      _isFreeDeliveryPromo = true;
      notifyListeners();
      return true;
    }
    return false;
  }

  void removePromoCode() {
    _appliedPromoCode = null;
    _promoDiscountPercent = 0.0;
    _promoDiscountFlat = 0.0;
    _isFreeDeliveryPromo = false;
    notifyListeners();
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = jsonEncode(_items.map((item) => item.toJson()).toList());
      await prefs.setString(_storageKey, data);
    } catch (e) {
      debugPrint('Error saving cart to storage: $e');
    }
  }

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final List list = jsonDecode(raw);
        _items.clear();
        for (var item in list) {
          try {
            _items.add(CartItem.fromJson(Map<String, dynamic>.from(item)));
          } catch (_) {}
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading cart from storage: $e');
    }
  }
}
