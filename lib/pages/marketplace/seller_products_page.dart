import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../services/marketplace_service.dart';
import '../../models/marketplace_models.dart';
import 'add_product_page.dart';

class SellerProductsPage extends StatefulWidget {
  const SellerProductsPage({super.key});

  @override
  State<SellerProductsPage> createState() => _SellerProductsPageState();
}

class _SellerProductsPageState extends State<SellerProductsPage> {
  final MarketplaceService _service = MarketplaceService();
  List<SmeProduct> _products = [];
  List<SmeProduct> _filteredProducts = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _searchController.addListener(_filterProducts);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final products = await _service.getProducts();
      if (mounted) {
        setState(() {
          _products = products;
          _filterProducts();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _filterProducts() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredProducts = List.from(_products);
      } else {
        _filteredProducts = _products.where((p) {
          final matchName = p.name.toLowerCase().contains(query);
          final matchDesc = p.description?.toLowerCase().contains(query) ?? false;
          return matchName || matchDesc;
        }).toList();
      }
    });
  }

  Future<void> _showEditPriceDialog(SmeProduct product, bool isAr) async {
    final priceController = TextEditingController(text: product.price.toStringAsFixed(2));
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 24,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isAr ? 'تعديل سعر المنتج' : 'Update Product Price',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.bluePrimary),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  product.name,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: priceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: isAr ? 'السعر الجديد (درهم إماراتي)' : 'New Unit Price (AED)',
                    prefixText: 'AED ',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return isAr ? 'يرجى إدخال السعر' : 'Please enter a price';
                    }
                    final p = double.tryParse(val.trim());
                    if (p == null || p <= 0) {
                      return isAr ? 'السعر يجب أن يكون أكبر من صفر' : 'Price must be greater than 0';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.bluePrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      final newPrice = double.parse(priceController.text.trim());
                      Navigator.pop(ctx);
                      await _service.updateProductPrice(product.id, newPrice);
                      _loadProducts();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isAr ? 'تم تحديث السعر بنجاح إلى $newPrice درهم' : 'Price updated successfully to AED $newPrice',
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
                    child: Text(
                      isAr ? 'حفظ السعر' : 'Save Price',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(SmeProduct product, bool isAr) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isAr ? 'حذف المنتج' : 'Delete Product'),
        content: Text(
          isAr
              ? 'هل أنت متأكد من رغبتك في إزالة "${product.name}" من كتالوج المتجر؟'
              : 'Are you sure you want to remove "${product.name}" from your catalog?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(isAr ? 'إلغاء' : 'Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(isAr ? 'حذف' : 'Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _service.deleteProduct(product.id);
      _loadProducts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isAr ? 'تم حذف المنتج من الكتالوج' : 'Product removed from catalog'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(
          isAr ? 'كتالوج المنتجات والأسعار' : 'Product Catalog & Pricing',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.bluePrimary),
        ),
        backgroundColor: AppColors.bg,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.bluePrimary),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.bluePrimary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          isAr ? 'إضافة منتج' : 'Add Product',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddProductPage()),
          );
          _loadProducts();
        },
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Header Stats Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  color: Colors.white,
                  child: Column(
                    children: [
                      // Search bar
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: isAr ? 'بحث بالاسم أو الوصف...' : 'Search products by name or details...',
                          prefixIcon: const Icon(Icons.search, color: Colors.grey),
                          filled: true,
                          fillColor: AppColors.bg,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isAr
                                ? '${_filteredProducts.length} منتج مسجل'
                                : '${_filteredProducts.length} Listed Products',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10AC84).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.price_change_outlined, size: 14, color: Color(0xFF10AC84)),
                                const SizedBox(width: 4),
                                Text(
                                  isAr ? 'تحكم كامل بالأسعار' : 'Direct Merchant Pricing',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF10AC84)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Products list
                Expanded(
                  child: _filteredProducts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              Text(
                                isAr ? 'لا توجد منتجات في الكتالوج' : 'No products found',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                isAr
                                    ? 'أضف منتجاتك لتظهر في سوق NXN وتحدد أسعارها'
                                    : 'Add your products to sell on NXN Marketplace and control pricing',
                                style: const TextStyle(fontSize: 13, color: Colors.grey),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.bluePrimary,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                icon: const Icon(Icons.add, color: Colors.white),
                                label: Text(
                                  isAr ? 'إضافة أول منتج' : 'Add First Product',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                                onPressed: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const AddProductPage()),
                                  );
                                  _loadProducts();
                                },
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredProducts.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final product = _filteredProducts[index];
                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Image Thumbnail
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Container(
                                        width: 80,
                                        height: 80,
                                        color: Colors.grey.shade100,
                                        child: product.photoUrl != null && product.photoUrl!.isNotEmpty
                                            ? Image.network(
                                                product.photoUrl!,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) => const Icon(
                                                  Icons.image_not_supported_outlined,
                                                  color: Colors.grey,
                                                ),
                                              )
                                            : const Icon(Icons.inventory_2_outlined, color: Colors.grey),
                                      ),
                                    ),
                                    const SizedBox(width: 14),

                                    // Product Info & Price
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  product.name,
                                                  style: const TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.bluePrimary),
                                                    padding: EdgeInsets.zero,
                                                    constraints: const BoxConstraints(),
                                                    onPressed: () async {
                                                      await Navigator.push(
                                                        context,
                                                        MaterialPageRoute(builder: (_) => AddProductPage(product: product)),
                                                      );
                                                      _loadProducts();
                                                    },
                                                  ),
                                                  const SizedBox(width: 8),
                                                  IconButton(
                                                    icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                                                    padding: EdgeInsets.zero,
                                                    constraints: const BoxConstraints(),
                                                    onPressed: () => _confirmDelete(product, isAr),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          if (product.description != null && product.description!.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              product.description!,
                                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                          const SizedBox(height: 10),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              // Price badge
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    isAr ? 'سعر الوحدة' : 'Unit Price',
                                                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                                                  ),
                                                  Text(
                                                    'AED ${product.price.toStringAsFixed(2)}',
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w800,
                                                      color: AppColors.bluePrimary,
                                                    ),
                                                  ),
                                                ],
                                              ),

                                              // Edit Price button
                                              OutlinedButton.icon(
                                                style: OutlinedButton.styleFrom(
                                                  side: const BorderSide(color: AppColors.bluePrimary),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                ),
                                                icon: const Icon(Icons.edit, size: 15, color: AppColors.bluePrimary),
                                                label: Text(
                                                  isAr ? 'تعديل السعر' : 'Edit Price',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppColors.bluePrimary,
                                                  ),
                                                ),
                                                onPressed: () => _showEditPriceDialog(product, isAr),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                !product.isHidden ? (isAr ? 'مباشر' : 'Live') : (isAr ? 'مخفي' : 'Hidden'),
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold,
                                                  color: !product.isHidden ? Colors.green : Colors.grey,
                                                ),
                                              ),
                                              Switch(
                                                value: !product.isHidden,
                                                onChanged: (val) async {
                                                  final supabase = Supabase.instance.client;
                                                  await supabase.from('sme_products').update({
                                                    'is_hidden': !val,
                                                  }).eq('id', product.id);
                                                  _loadProducts();
                                                },
                                                activeThumbColor: AppColors.bluePrimary,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
