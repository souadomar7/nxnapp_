import 'package:flutter/material.dart';
import '../theme.dart';
import '../core/auth/session_provider.dart';
import 'home_page.dart';
import 'profile_page.dart';
import '../l10n/app_localizations.dart';
import 'marketplace/seller_hub.dart';
import 'copilot_page.dart';

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
    CopilotPage(key: PageStorageKey('copilot')),
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
    return SessionProviderBuilder(
      child: PopScope(
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
        floatingActionButton: FloatingActionButton(
          heroTag: 'chatbot_fab',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CopilotPage()),
            );
          },
          backgroundColor: AppColors.bluePrimary,
          child: const Icon(Icons.support_agent_rounded, color: Colors.white),
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
              label: 'Store',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.smart_toy_rounded),
              label: 'Copilot',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_rounded),
              label: l10n.navProfile,
            ),
          ],
        ),
      ),   // closes Scaffold
    ),     // closes PopScope
    );     // closes SessionProviderBuilder
  }
}
