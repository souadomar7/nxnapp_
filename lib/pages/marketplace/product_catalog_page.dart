import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../services/marketplace_service.dart';
import '../../models/marketplace_models.dart';
import 'add_product_page.dart';
import '../../l10n/app_localizations.dart';

class ProductCatalogPage extends StatefulWidget {
  const ProductCatalogPage({super.key});

  @override
  State<ProductCatalogPage> createState() => _ProductCatalogPageState();
}

class _ProductCatalogPageState extends State<ProductCatalogPage> {
  final MarketplaceService _service = MarketplaceService();
  late Future<List<SmeProduct>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  void _loadProducts() {
    setState(() {
      _productsFuture = _service.getProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.productCatalogTitle),
      ),
      backgroundColor: Colors.grey[50], // Light background
      floatingActionButton: FloatingActionButton(
        heroTag: 'catalog_fab',
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddProductPage()),
          );
          if (result == true) {
            _loadProducts();
          }
        },
        backgroundColor: AppColors.bluePrimary,
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<SmeProduct>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
             return Center(child: Text(AppLocalizations.of(context)!.error(snapshot.error.toString())));
          } else if (snapshot.data == null || snapshot.data!.isEmpty) {
             return Center(
               child: Column(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey[300]),
                   const SizedBox(height: 16),
                   Text(
                     AppLocalizations.of(context)!.noProductsFound,
                     style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.bold),
                   ),
                   const SizedBox(height: 8),
                   Text(
                     AppLocalizations.of(context)!.addProductFirst,
                     style: const TextStyle(color: Colors.grey),
                   ),
                 ],
               ),
             );
          }

          final products = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 20), // More margin
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20), // More rounded
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF9DA8C4).withValues(alpha: 0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {},
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(16), // More padding
                      child: Row(
                        children: [
                          // Image / Icon Placeholder
                          Container(
                            width: 100, // Larger image
                            height: 100,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(Icons.shopping_bag_outlined, color: Colors.blueGrey[300], size: 40),
                          ),
                          const SizedBox(width: 20),
                          
                          // Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  AppLocalizations.of(context)!.productPrice(product.price),
                                  style: const TextStyle(color: AppColors.bluePrimary, fontWeight: FontWeight.w800, fontSize: 18),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(AppLocalizations.of(context)!.activeStatus, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green)),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(AppLocalizations.of(context)!.stockLabel(120), style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          
                          const Icon(Icons.arrow_forward_ios_rounded, size: 18, color: Colors.grey),
                          const SizedBox(width: 4),
                        ],
                      ),
                    ),
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
