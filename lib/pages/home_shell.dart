import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
        child: AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
          ),
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
              elevation: 3,
              child: const Icon(Icons.support_agent_outlined, color: Colors.white, size: 26),
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
                currentIndex: _index,
                onTap: (i) => setState(() => _index = i),
                type: BottomNavigationBarType.fixed,
                backgroundColor: Colors.transparent,
                elevation: 0,
                selectedItemColor: AppColors.bluePrimary,
                unselectedItemColor: AppColors.blueLight,
                showUnselectedLabels: true,
                selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
                items: [
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.home_outlined, size: 24),
                    activeIcon: const Icon(Icons.home_rounded, size: 24),
                    label: l10n.navHome,
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.storefront_outlined, size: 24),
                    activeIcon: const Icon(Icons.storefront_rounded, size: 24),
                    label: Localizations.localeOf(context).languageCode == 'ar' ? 'المتجر' : 'Store',
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.smart_toy_outlined, size: 24),
                    activeIcon: const Icon(Icons.smart_toy_rounded, size: 24),
                    label: Localizations.localeOf(context).languageCode == 'ar' ? 'المساعد' : 'AI Agent',
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.person_outline_rounded, size: 24),
                    activeIcon: const Icon(Icons.person_rounded, size: 24),
                    label: l10n.navProfile,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
