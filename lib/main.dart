import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:nxnapp/core/services/notification_service.dart';
import 'package:app_links/app_links.dart';
import 'pages/onboarding/profile_setup_page.dart';
import 'services/uae_pass_service.dart';
import 'services/gate_pass_sync_service.dart';
import 'services/marketplace_service.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:nxnapp/l10n/app_localizations.dart';

import 'theme.dart';
import 'providers/locale_provider.dart';
import 'providers/user_provider.dart';
import 'pages/splash_page.dart';
import 'pages/smart_inventory_stage.dart';

import 'data/inventory_controller.dart';
import 'data/supabase_inventory_service.dart';
import 'data/receive_result.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'providers/cart_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/platform_settings_provider.dart';
import 'providers/merchant_data_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    await NotificationService().initialize();
  } catch (e) {
    debugPrint('Firebase messaging initialization warning: $e');
  }

  await dotenv.load(fileName: ".env");

  // SECURITY: Never fall back to hardcoded credentials.
  // If .env is missing or keys are absent the app must not launch silently.
  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

  assert(
    supabaseUrl != null && supabaseAnonKey != null,
    '\n\n⛔ FATAL: SUPABASE_URL or SUPABASE_ANON_KEY is missing from .env.\n'
    'Copy .env.example to .env and fill in your Supabase project credentials.\n',
  );

  await Supabase.initialize(
    url: supabaseUrl!,
    anonKey: supabaseAnonKey!,
  );

  // Clear any cached local demo data / stale storage on launch
  try {
    await MarketplaceService().clearAllData();
  } catch (_) {}

  try {
    await Hive.initFlutter();
    await GatePassSyncService.initialize();
  } catch (e) {
    debugPrint('GatePassSyncService initialization warning: $e');
  }

  // Handle UAE PASS OAuth callback deep link
  final appLinks = AppLinks();
  appLinks.uriLinkStream.listen((uri) async {
    if (uri.scheme == 'nxn' && uri.host == 'auth') {
      final code = uri.queryParameters['code'];
      if (code != null) {
        try {
          final uaePassService = UaePassService();
          final tokenData = await uaePassService.exchangeCodeForToken(code);
          if (tokenData != null) {
            final profile = await uaePassService.getUserProfile(tokenData);
            if (profile != null) {
              // Navigate to profile setup with the data
              WarehouseApp.navigatorKey.currentState?.pushReplacement(
                MaterialPageRoute(
                  builder: (_) => ProfileSetupPage(uaePassData: {
                    'businessName': profile['fullnameEN'] ?? '',
                    'contactNumber': profile['mobile'] ?? '',
                    'licenseNumber': profile['licenseNumber'] ?? '',
                    'email': profile['email'] ?? '',
                    'uaePassUuid': profile['uuid'] ?? '',
                    'licenseOwnerName': profile['licenseOwnerName'] ?? '',
                  }),
                ),
              );
            }
          }
        } catch (e) {
          debugPrint('UAE PASS callback error: $e');
        }
      }
    }
  });

  runApp(const WarehouseApp());
}

class WarehouseApp extends StatelessWidget {
  const WarehouseApp({super.key});
  
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => PlatformSettingsProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => MerchantDataProvider()..initialize()),
        ChangeNotifierProvider(
          create: (_) => InventoryController(SupabaseInventoryService()),
        ),
      ],
      child: Consumer2<LocaleProvider, ThemeProvider>(
        builder: (context, localeProvider, themeProvider, child) {
          return MaterialApp(
            navigatorKey: WarehouseApp.navigatorKey,
            debugShowCheckedModeBanner: false,
            title: 'NXN Warehouses',
            theme: appTheme,
            darkTheme: darkAppTheme,
            themeMode: themeProvider.themeMode,
            locale: localeProvider.locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'), // English
              Locale('ar'), // Arabic
            ],
            home: const SplashPage(), // Start here
            onGenerateRoute: (settings) {
              if (settings.name == '/stage6') {
                final arg = settings.arguments;
                final result = (arg is ReceiveResult) ? arg : null;
                return MaterialPageRoute(
                  builder: (_) => SmartInventoryStageEN(result: result),
                );
              }
              return null;
            },
          );
        },
      ),
    );
  }
}
