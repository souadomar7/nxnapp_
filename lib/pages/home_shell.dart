import 'package:flutter/material.dart';
import '../theme.dart';
import 'home_page.dart';
import 'profile_page.dart';
import '../l10n/app_localizations.dart';
import 'marketplace/seller_hub.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => HomeShellState();
}

class HomeShellState extends State<HomeShell> {
  int _index = 0;
  final PageStorageBucket _bucket = PageStorageBucket();

  void switchToTab(int index) {
    setState(() => _index = index);
  }



  final _pages = const [
    HomePage(key: PageStorageKey('home')),
    SellerHub(key: PageStorageKey('market')), 
    ProfilePage(key: PageStorageKey('profile')),
  ];

  Future<bool> _onWillPop() async {
    if (_index != 0) {
      setState(() => _index = 0);
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _onWillPop();
      },
      child: Scaffold(
        body: PageStorage(
          bucket: _bucket,
          child: IndexedStack(
            index: _index,
            children: _pages,
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _index,
          onTap: (i) => setState(() => _index = i),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.bluePrimary,
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.dashboard_rounded),
              label: l10n.navHome,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.storefront_rounded),
              label: 'Store', // Or l10n.navStore if available, hardcoded for now as confirmed by user approval implicitly
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_rounded),
              label: l10n.navProfile,
            ),
          ],
        ),
      ),
    );
  }
}
