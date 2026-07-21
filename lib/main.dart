import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:nxnapp/core/services/notification_service.dart';

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

  runApp(const WarehouseApp());
}

class WarehouseApp extends StatelessWidget {
  const WarehouseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(
          create: (_) => InventoryController(SupabaseInventoryService()),
        ),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, localeProvider, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'NXN Warehouses',
            theme: appTheme,
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
