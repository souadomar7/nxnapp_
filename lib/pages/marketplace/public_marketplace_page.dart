import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/cart_provider.dart';
import '../../theme.dart';
import '../../services/marketplace_service.dart';
import '../../models/marketplace_models.dart';
import 'public_product_detail_page.dart';
import 'cart_page.dart';

class PublicMarketplacePage extends StatefulWidget {
  const PublicMarketplacePage({super.key});

  @override
  State<PublicMarketplacePage> createState() => _PublicMarketplacePageState();
}

class _PublicMarketplacePageState extends State<PublicMarketplacePage>
    with TickerProviderStateMixin {
  final MarketplaceService _service = MarketplaceService();
  late Future<List<SmeProduct>> _productsFuture;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _sortBy = 'newest';
  AnimationController? _headerAnimCtrl;

  final List<Map<String, dynamic>> _categories = [
    {'label': 'All', 'labelAr': 'الكل', 'icon': Icons.grid_view_rounded},
    {'label': 'Electronics', 'labelAr': 'إلكترونيات', 'icon': Icons.devices_rounded},
    {'label': 'Food & Beverage', 'labelAr': 'أغذية ومشروبات', 'icon': Icons.restaurant_rounded},
    {'label': 'Fashion', 'labelAr': 'أزياء', 'icon': Icons.checkroom_rounded},
    {'label': 'Home', 'labelAr': 'المنزل', 'icon': Icons.home_rounded},
    {'label': 'Beauty', 'labelAr': 'جمال', 'icon': Icons.spa_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _loadProducts();
    MarketplaceService.updateNotifier.addListener(_loadProducts);
    _headerAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  void _loadProducts() {
    setState(() {
      _productsFuture = _service.getPublicMarketplaceProducts();
    });
  }

  @override
  void dispose() {
    MarketplaceService.updateNotifier.removeListener(_loadProducts);
    _searchCtrl.dispose();
    _headerAnimCtrl?.dispose();
    super.dispose();
  }

  String _normalizeArabic(String input) {
    return input
      .toLowerCase()
      .replaceAll(RegExp(r'[أإآا]'), 'ا')   // normalize alef variants
      .replaceAll(RegExp(r'[ةه]'), 'ه')       // normalize taa marbuta
      .replaceAll(RegExp(r'[يى]'), 'ي')       // normalize ya
      .replaceAll(RegExp(r'[ًٌٍَُِّْ]'), '') // remove diacritics (tashkeel)
      .trim();
  }

  List<SmeProduct> _filterAndSort(List<SmeProduct> products) {
    final query = _normalizeArabic(_searchQuery);
    var filtered = products.where((product) {
      final nameMatch = _normalizeArabic(product.name).contains(query) ||
          _normalizeArabic(product.nameAr ?? '').contains(query) ||
          _normalizeArabic(product.description ?? '').contains(query) ||
          _normalizeArabic(product.shopName ?? '').contains(query);
      
      final categoryMatch = _selectedCategory == 'All' ||
          _selectedCategory == 'الكل' ||
          (product.category ?? '').toLowerCase() == _selectedCategory.toLowerCase();
      
      return (query.isEmpty || nameMatch) && categoryMatch;
    }).toList();

    switch (_sortBy) {
      case 'price_low':
        filtered.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_high':
        filtered.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'name':
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
      default: // newest
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final screenW = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ─── Hero Header ─────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: const Color(0xFF0A1628),
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                isAr ? Icons.arrow_forward_ios_rounded : Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              // Cart Button with Badge
              Consumer<CartProvider>(
                builder: (context, cart, _) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 24),
                        tooltip: isAr ? 'سلة المشتريات' : 'Cart',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const CartPage()),
                          );
                        },
                      ),
                      if (cart.isNotEmpty)
                        Positioned(
                          top: 6,
                          right: isAr ? null : 6,
                          left: isAr ? 6 : null,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Color(0xFFEF4444),
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                            child: Center(
                              child: Text(
                                '${cart.totalItemCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(width: 4),
              // Language Toggle
              Consumer<LocaleProvider>(
                builder: (context, localeProvider, _) {
                  return InkWell(
                    onTap: () => localeProvider.toggleLocale(),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.language_rounded, color: Colors.white70, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            isAr ? 'EN' : 'العربية',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _headerAnimCtrl != null
                ? FadeTransition(
                    opacity: CurvedAnimation(parent: _headerAnimCtrl!, curve: Curves.easeOutCubic),
                    child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF0A1628), Color(0xFF1A3A6B), Color(0xFF2563EB)],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Decorative circles
                      Positioned(
                        top: -40,
                        right: isAr ? null : -30,
                        left: isAr ? -30 : null,
                        child: Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.04),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 10,
                        left: isAr ? null : -20,
                        right: isAr ? -20 : null,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.03),
                          ),
                        ),
                      ),
                      // Content
                      Positioned(
                        bottom: 50,
                        left: isAr ? null : 20,
                        right: isAr ? 20 : null,
                        child: Column(
                          crossAxisAlignment: isAr ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF10B981),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    isAr ? 'متجر حي' : 'Live Store',
                                    style: const TextStyle(color: Color(0xFF6EE7B7), fontSize: 11, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isAr ? 'سوق NXN المعتمد' : 'NXN Verified Market',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isAr ? 'منتجات موثقة من تجار معتمدين في الإمارات' : 'Trusted products from verified UAE merchants',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                  )
                : const SizedBox.shrink(),
            ),
          ),

          // ─── Search Bar ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 4)),
                ],
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (val) => setState(() => _searchQuery = val),
                textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
                decoration: InputDecoration(
                  hintText: isAr ? '🔍  ابحث عن المنتجات والمتاجر...' : '🔍  Search products & stores...',
                  hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, color: Color(0xFF94A3B8)),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                ),
              ),
            ),
          ),

          // ─── Category Chips ──────────────────────────────────────
          SliverToBoxAdapter(
            child: SizedBox(
              height: 56,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                itemCount: _categories.length,
                itemBuilder: (ctx, i) {
                  final cat = _categories[i];
                  final label = isAr ? cat['labelAr'] as String : cat['label'] as String;
                  final selected = _selectedCategory == cat['label'];
                  return Padding(
                    padding: EdgeInsets.only(right: isAr ? 0 : 8, left: isAr ? 8 : 0),
                    child: InkWell(
                      onTap: () => setState(() => _selectedCategory = cat['label'] as String),
                      borderRadius: BorderRadius.circular(12),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: selected ? const Color(0xFF0A1628) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected ? const Color(0xFF0A1628) : const Color(0xFFE2E8F0),
                          ),
                          boxShadow: selected
                              ? [BoxShadow(color: const Color(0xFF0A1628).withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 2))]
                              : [],
                        ),
                        child: Row(
                          children: [
                            Icon(cat['icon'] as IconData, size: 16, color: selected ? Colors.white : const Color(0xFF64748B)),
                            const SizedBox(width: 6),
                            Text(
                              label,
                              style: TextStyle(
                                color: selected ? Colors.white : const Color(0xFF334155),
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // ─── Sort Row & Product Count ────────────────────────────
          SliverToBoxAdapter(
            child: FutureBuilder<List<SmeProduct>>(
              future: _productsFuture,
              builder: (ctx, snap) {
                final count = snap.hasData ? _filterAndSort(snap.data!).length : 0;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isAr ? '$count منتج متاح' : '$count Products Available',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF334155),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _sortBy,
                            isDense: true,
                            icon: const Icon(Icons.unfold_more_rounded, size: 16, color: Color(0xFF64748B)),
                            style: const TextStyle(fontSize: 12, color: Color(0xFF334155), fontWeight: FontWeight.w600),
                            items: [
                              DropdownMenuItem(value: 'newest', child: Text(isAr ? 'الأحدث' : 'Newest')),
                              DropdownMenuItem(value: 'price_low', child: Text(isAr ? 'الأقل سعراً' : 'Price: Low')),
                              DropdownMenuItem(value: 'price_high', child: Text(isAr ? 'الأعلى سعراً' : 'Price: High')),
                              DropdownMenuItem(value: 'name', child: Text(isAr ? 'الاسم' : 'Name A-Z')),
                            ],
                            onChanged: (v) => setState(() => _sortBy = v ?? 'newest'),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          // ─── Product Grid ────────────────────────────────────────
          FutureBuilder<List<SmeProduct>>(
            future: _productsFuture,
            builder: (ctx, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Color(0xFF2563EB)),
                        SizedBox(height: 16),
                        Text('Loading marketplace...', style: TextStyle(color: Color(0xFF64748B), fontSize: 14)),
                      ],
                    ),
                  ),
                );
              }

              if (snapshot.hasError) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.cloud_off_rounded, size: 60, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          isAr ? 'حدث خطأ في تحميل السوق' : 'Error loading marketplace',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => setState(() => _productsFuture = _service.getPublicMarketplaceProducts()),
                          icon: const Icon(Icons.refresh_rounded),
                          label: Text(isAr ? 'إعادة المحاولة' : 'Retry'),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.bluePrimary),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (snapshot.data == null || snapshot.data!.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB).withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.storefront_rounded, size: 56, color: Color(0xFF2563EB)),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          isAr ? 'السوق يتجهز قريباً! 🚀' : 'Marketplace opening soon! 🚀',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isAr ? 'لا تتوفر منتجات حالياً. كن أول بائع!' : 'No products yet. Be the first seller!',
                          style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final products = _filterAndSort(snapshot.data!);

              if (products.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.search_off_rounded, size: 56, color: Color(0xFF94A3B8)),
                        const SizedBox(height: 12),
                        Text(
                          isAr ? 'لا توجد نتائج لـ "$_searchQuery"' : 'No results for "$_searchQuery"',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() {
                              _searchQuery = '';
                              _selectedCategory = 'All';
                            });
                          },
                          child: Text(isAr ? 'مسح البحث' : 'Clear Search'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // 2-column grid
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: screenW > 600 ? 3 : 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.62,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (ctx, index) {
                      final product = products[index];
                      return _ProductCard(
                        product: product,
                        index: index,
                        isAr: isAr,
                        onTap: () {
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (_, a, __) => PublicProductDetailPage(product: product),
                              transitionsBuilder: (_, anim, __, child) {
                                return FadeTransition(opacity: anim, child: child);
                              },
                              transitionDuration: const Duration(milliseconds: 300),
                            ),
                          );
                        },
                      );
                    },
                    childCount: products.length,
                  ),
                ),
              );
            },
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

// ─── Product Card Widget ──────────────────────────────────────────────────────

class _ProductCard extends StatefulWidget {
  final SmeProduct product;
  final int index;
  final bool isAr;
  final VoidCallback onTap;

  const _ProductCard({
    required this.product,
    required this.index,
    required this.isAr,
    required this.onTap,
  });

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _scaleAnim;
  late Animation<Offset> _slideAnim;
  bool _isFaved = false;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 400 + (widget.index * 80).clamp(0, 400)),
    );
    _scaleAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutBack);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  // Deterministic icon/color based on product name hash
  IconData _productIcon() {
    final hash = widget.product.name.hashCode;
    final icons = [
      Icons.inventory_2_rounded,
      Icons.shopping_bag_rounded,
      Icons.local_cafe_rounded,
      Icons.headphones_rounded,
      Icons.watch_rounded,
      Icons.local_florist_rounded,
      Icons.auto_awesome_rounded,
      Icons.diamond_rounded,
    ];
    return icons[hash.abs() % icons.length];
  }

  Color _accentColor() {
    final hash = widget.product.name.hashCode;
    final colors = [
      const Color(0xFF2563EB),
      const Color(0xFF7C3AED),
      const Color(0xFF059669),
      const Color(0xFFDC2626),
      const Color(0xFFEA580C),
      const Color(0xFF0891B2),
      const Color(0xFFDB2777),
      const Color(0xFF4F46E5),
    ];
    return colors[hash.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final isAr = widget.isAr;
    final accent = _accentColor();

    return SlideTransition(
      position: _slideAnim,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Image Area ──────────────────────────────────
                Expanded(
                  flex: 5,
                  child: Stack(
                    children: [
                      // Image / Placeholder
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                          gradient: product.photoUrl == null
                              ? LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [accent.withValues(alpha: 0.08), accent.withValues(alpha: 0.18)],
                                )
                              : null,
                          image: product.photoUrl != null
                              ? DecorationImage(
                                  image: NetworkImage(product.photoUrl!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: product.photoUrl == null
                            ? Center(
                                child: Icon(_productIcon(), size: 44, color: accent.withValues(alpha: 0.5)),
                              )
                            : null,
                      ),

                      // Favorite Button
                      Positioned(
                        top: 8,
                        right: isAr ? null : 8,
                        left: isAr ? 8 : null,
                        child: GestureDetector(
                          onTap: () => setState(() => _isFaved = !_isFaved),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: _isFaved ? Colors.red.shade50 : Colors.white.withValues(alpha: 0.9),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 6),
                              ],
                            ),
                            child: Icon(
                              _isFaved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              color: _isFaved ? Colors.red : const Color(0xFF94A3B8),
                              size: 18,
                            ),
                          ),
                        ),
                      ),

                      // Verified Badge
                      if (product.isShopApproved)
                        Positioned(
                          top: 8,
                          left: isAr ? null : 8,
                          right: isAr ? 8 : null,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(color: const Color(0xFF10B981).withValues(alpha: 0.3), blurRadius: 6),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.verified_rounded, color: Colors.white, size: 11),
                                const SizedBox(width: 3),
                                Text(
                                  isAr ? 'معتمد' : 'Verified',
                                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Quick Add to Cart Button
                      Positioned(
                        bottom: 8,
                        right: isAr ? null : 8,
                        left: isAr ? 8 : null,
                        child: GestureDetector(
                          onTap: () {
                            final nav = Navigator.of(context);
                            final cart = Provider.of<CartProvider>(context, listen: false);
                            cart.addItem(product, quantity: 1);
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                duration: const Duration(seconds: 2),
                                backgroundColor: const Color(0xFF1E293B),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                content: Text(
                                  isAr ? 'تمت إضافة المنتج إلى السلة 🛒' : 'Added to Cart 🛒',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                action: SnackBarAction(
                                  label: isAr ? 'السلة' : 'Cart',
                                  textColor: const Color(0xFF60A5FA),
                                  onPressed: () {
                                    nav.push(
                                      MaterialPageRoute(builder: (_) => const CartPage()),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.bluePrimary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.bluePrimary.withValues(alpha: 0.35),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.add_shopping_cart_rounded, color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ─── Info Area ───────────────────────────────────
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Shop name
                        Row(
                          children: [
                            Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(Icons.storefront_rounded, size: 11, color: accent),
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                isAr
                                    ? (product.shopName != null ? 'متجر ${product.shopName}' : 'تاجر معتمد لدى NXN')
                                    : (product.shopName ?? 'NXN Merchant'),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: accent,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 4),

                        // Product name
                        Text(
                          isAr ? _getArabicProductName(product.name, product.nameAr) : product.name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const Spacer(),

                        // Price + Rating
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0A1628),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  isAr
                                      ? '${product.price.toStringAsFixed(0)} درهم'
                                      : 'AED ${product.price.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.star_rounded, size: 14, color: Colors.amber.shade600),
                                const SizedBox(width: 2),
                                Text(
                                  (4.0 + (product.name.hashCode.abs() % 10) / 10.0).toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF334155),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _getArabicProductName(String name, String? nameAr) {
  if (nameAr != null && nameAr.isNotEmpty) return nameAr;
  final lower = name.toLowerCase();
  if (lower.contains('espresso') || lower.contains('beans')) return 'حبوب إسبريسو فاخرة';
  if (lower.contains('earbuds') || lower.contains('wireless')) return 'سماعات لاسلكية برو';
  if (lower.contains('flower') || lower.contains('rose')) return 'باقة زهور طبيعية';
  if (lower.contains('inbound') || lower.contains('sto')) return 'دفعة شحنة واردة (STO)';
  if (lower.contains('refurbished') || lower.contains('open box')) return '$name (مجدد / مفتوح)';
  return name;
}
