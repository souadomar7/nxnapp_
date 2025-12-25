import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';

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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://hvstjsygmijbvjnyiqli.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imh2c3Rqc3lnbWlqYnZqbnlpcWxpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjUzODExNDMsImV4cCI6MjA4MDk1NzE0M30._9FuRhokLoqX5ndQu13CAm67Y02wBY_Lh7Zow2OVjYo',
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
