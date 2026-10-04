import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../core/auth/session_provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/cart_provider.dart';

// Screens
import 'home_page.dart';
import 'profile_page.dart';
import 'marketplace/public_marketplace_page.dart';
import 'marketplace/cart_page.dart';
import 'marketplace/seller_hub.dart';
import 'marketplace/seller_orders_page.dart';
import 'smart_inventory_stage.dart';
import 'create_shipment_page.dart';
import 'booking_page.dart';
import 'receive_goods_stage.dart';
import 'qr_scanner_page.dart';
import 'admin_panel_page.dart';
import 'operations/pick_pack_screen.dart';
import 'operations/driver_orders_page.dart';
import 'operations/gate_pass_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => HomeShellState();
}

class HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;
  final PageStorageBucket _bucket = PageStorageBucket();

  void switchToTab(int index) {
    setState(() => _currentIndex = index);
  }

  // ─── Persona 1: Buyer / Customer / Guest ──────────────────────────────────
  final List<Widget> _customerPages = const [
    HomePage(key: PageStorageKey('customer_home')),
    PublicMarketplacePage(key: PageStorageKey('customer_marketplace')),
    CartPage(key: PageStorageKey('customer_cart')),
    SellerOrdersPage(key: PageStorageKey('customer_orders'), isBuyerMode: true),
    ProfilePage(key: PageStorageKey('customer_profile')),
  ];

  // ─── Persona 2: Merchant / Vendor (Storage + Inventory + Shipping) ─────────
  final List<Widget> _vendorPages = const [
    SellerHub(key: PageStorageKey('vendor_hub')),
    SmartInventoryStageEN(key: PageStorageKey('vendor_inventory')),
    BookingPage(key: PageStorageKey('vendor_booking')),
    CreateShipmentPage(key: PageStorageKey('vendor_shipment')),
    ProfilePage(key: PageStorageKey('vendor_profile')),
  ];

  // ─── Persona 3: Driver / Courier ──────────────────────────────────────────
  final List<Widget> _driverPages = const [
    DriverOrdersPage(key: PageStorageKey('driver_orders')),
    GatePassPage(key: PageStorageKey('driver_gate_pass')),
    ProfilePage(key: PageStorageKey('driver_profile')),
  ];

  // ─── Persona 4: Warehouse Ops & Security Staff ────────────────────────────
  final List<Widget> _opsPages = const [
    ReceiveGoodsStagePageEN(key: PageStorageKey('ops_intake')),
    QrScannerPage(key: PageStorageKey('ops_scanner')),
    PickPackScreen(key: PageStorageKey('ops_pickpack'), warehouseId: 'WH-AUH-01'),
    AdminPanelPage(key: PageStorageKey('ops_admin')),
    ProfilePage(key: PageStorageKey('ops_profile')),
  ];

  Future<bool> _onWillPop() async {
    if (_currentIndex != 0) {
      setState(() => _currentIndex = 0);
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final session = SessionProvider.of(context);

    // Determine active persona
    final bool isOpsPersona = session.isWhAdmin || session.isSuperAdmin;
    final bool isDriverPersona = session.isDriver;
    final bool isVendorPersona = session.isVendor;

    final List<Widget> activePages = isOpsPersona
        ? _opsPages
        : (isDriverPersona
            ? _driverPages
            : (isVendorPersona ? _vendorPages : _customerPages));

    // Ensure index stays in valid range when role switches
    if (_currentIndex >= activePages.length) {
      _currentIndex = 0;
    }

    return SessionProviderBuilder(
      child: PopScope(
        canPop: _currentIndex == 0,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          _onWillPop();
        },
        child: AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
          ),
          child: Scaffold(
            body: PageStorage(
              bucket: _bucket,
              child: IndexedStack(
                index: _currentIndex,
                children: activePages,
              ),
            ),
            bottomNavigationBar: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: AppColors.border, width: 1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF003C8E).withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: (i) => setState(() => _currentIndex = i),
                type: BottomNavigationBarType.fixed,
                backgroundColor: Colors.transparent,
                elevation: 0,
                selectedItemColor: AppColors.bluePrimary,
                unselectedItemColor: AppColors.blueLight,
                showUnselectedLabels: true,
                selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
                items: isOpsPersona
                    ? _buildOpsNavItems(isAr, l10n)
                    : (isDriverPersona
                        ? _buildDriverNavItems(isAr, l10n)
                        : (isVendorPersona
                            ? _buildVendorNavItems(isAr, l10n)
                            : _buildCustomerNavItems(context, isAr, l10n))),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Persona 1: Customer / Guest Nav Items ────────────────────────────────
  List<BottomNavigationBarItem> _buildCustomerNavItems(
    BuildContext context,
    bool isAr,
    AppLocalizations l10n,
  ) {
    final cartItemCount = context.select<CartProvider, int>((c) => c.totalItemCount);

    return [
      BottomNavigationBarItem(
        icon: const Icon(Icons.home_outlined, size: 24),
        activeIcon: const Icon(Icons.home_rounded, size: 24),
        label: l10n.navHome,
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.storefront_outlined, size: 24),
        activeIcon: const Icon(Icons.storefront_rounded, size: 24),
        label: isAr ? 'السوق' : 'Marketplace',
      ),
      BottomNavigationBarItem(
        icon: Badge(
          isLabelVisible: cartItemCount > 0,
          label: Text(
            cartItemCount.toString(),
            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFFE74C3C),
          child: const Icon(Icons.shopping_bag_outlined, size: 24),
        ),
        activeIcon: Badge(
          isLabelVisible: cartItemCount > 0,
          label: Text(
            cartItemCount.toString(),
            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFFE74C3C),
          child: const Icon(Icons.shopping_bag_rounded, size: 24),
        ),
        label: isAr ? 'السلة' : 'Cart',
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.receipt_long_outlined, size: 24),
        activeIcon: const Icon(Icons.receipt_long_rounded, size: 24),
        label: isAr ? 'طلباتي' : 'Orders',
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.person_outline_rounded, size: 24),
        activeIcon: const Icon(Icons.person_rounded, size: 24),
        label: l10n.navProfile,
      ),
    ];
  }

  // ─── Persona 2: Vendor / Merchant Nav Items ───────────────────────────────
  List<BottomNavigationBarItem> _buildVendorNavItems(
    bool isAr,
    AppLocalizations l10n,
  ) {
    return [
      BottomNavigationBarItem(
        icon: const Icon(Icons.dashboard_outlined, size: 24),
        activeIcon: const Icon(Icons.dashboard_rounded, size: 24),
        label: isAr ? 'لوحة المتجر' : 'Seller Hub',
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.inventory_2_outlined, size: 24),
        activeIcon: const Icon(Icons.inventory_2_rounded, size: 24),
        label: isAr ? 'المخزون' : 'Inventory',
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.view_in_ar_outlined, size: 24),
        activeIcon: const Icon(Icons.view_in_ar_rounded, size: 24),
        label: isAr ? 'حجز الرفوف' : 'Rent Shelves',
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.local_shipping_outlined, size: 24),
        activeIcon: const Icon(Icons.local_shipping_rounded, size: 24),
        label: isAr ? 'الشحنات' : 'Shipments',
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.person_outline_rounded, size: 24),
        activeIcon: const Icon(Icons.person_rounded, size: 24),
        label: l10n.navProfile,
      ),
    ];
  }

  // ─── Persona 3: Driver / Courier Nav Items ────────────────────────────────
  List<BottomNavigationBarItem> _buildDriverNavItems(
    bool isAr,
    AppLocalizations l10n,
  ) {
    return [
      BottomNavigationBarItem(
        icon: const Icon(Icons.local_shipping_outlined, size: 24),
        activeIcon: const Icon(Icons.local_shipping_rounded, size: 24),
        label: isAr ? 'التوصيلات' : 'Deliveries',
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.qr_code_2_rounded, size: 24),
        activeIcon: const Icon(Icons.qr_code_rounded, size: 24),
        label: isAr ? 'التصاريح' : 'Gate Passes',
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.person_outline_rounded, size: 24),
        activeIcon: const Icon(Icons.person_rounded, size: 24),
        label: l10n.navProfile,
      ),
    ];
  }

  // ─── Persona 4: Warehouse Ops Staff Nav Items ─────────────────────────────
  List<BottomNavigationBarItem> _buildOpsNavItems(
    bool isAr,
    AppLocalizations l10n,
  ) {
    return [
      BottomNavigationBarItem(
        icon: const Icon(Icons.move_to_inbox_outlined, size: 24),
        activeIcon: const Icon(Icons.move_to_inbox_rounded, size: 24),
        label: isAr ? 'الاستلام' : 'Dock Intake',
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.qr_code_scanner_outlined, size: 24),
        activeIcon: const Icon(Icons.qr_code_scanner_rounded, size: 24),
        label: isAr ? 'فحص البوابة' : 'Gate Scanner',
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.fact_check_outlined, size: 24),
        activeIcon: const Icon(Icons.fact_check_rounded, size: 24),
        label: isAr ? 'التجهيز' : 'Pick & Pack',
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.admin_panel_settings_outlined, size: 24),
        activeIcon: const Icon(Icons.admin_panel_settings_rounded, size: 24),
        label: isAr ? 'لوحة التحكم' : 'Ops Console',
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.person_outline_rounded, size: 24),
        activeIcon: const Icon(Icons.person_rounded, size: 24),
        label: l10n.navProfile,
      ),
    ];
  }
}
