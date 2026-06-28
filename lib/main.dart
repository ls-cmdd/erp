import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:window_manager/window_manager.dart';

import 'core/theme.dart';
import 'core/localization.dart';
import 'db/database.dart';
import 'providers/app_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/sales_provider.dart';
import 'providers/purchases_provider.dart';
import 'providers/inventory_provider.dart';
import 'providers/finance_provider.dart';
import 'providers/hr_provider.dart';
import 'providers/reports_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    await windowManager.ensureInitialized();
    const opts = WindowOptions(
      size             : Size(1400, 900),
      minimumSize      : Size(1100, 720),
      center           : true,
      title            : 'نظام ERP المتكامل',
      backgroundColor  : Colors.transparent,
      skipTaskbar      : false,
      titleBarStyle    : TitleBarStyle.hidden,
    );
    await windowManager.waitUntilReadyToShow(opts, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  await AppDatabase.instance.initialize();

  runApp(const ERPApp());
}

class ERPApp extends StatelessWidget {
  const ERPApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()..init()),
        ChangeNotifierProvider(create: (_) => AuthProvider()..init()),
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProvider(create: (_) => SalesProvider()),
        ChangeNotifierProvider(create: (_) => PurchasesProvider()),
        ChangeNotifierProvider(create: (_) => InventoryProvider()),
        ChangeNotifierProvider(create: (_) => FinanceProvider()),
        ChangeNotifierProvider(create: (_) => HRProvider()),
        ChangeNotifierProvider(create: (_) => ReportsProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (_, settings, __) => MaterialApp(
          title            : 'نظام ERP المتكامل',
          debugShowCheckedModeBanner: false,
          theme            : AppTheme.light(settings.primaryColor),
          darkTheme        : AppTheme.dark(settings.primaryColor),
          themeMode        : settings.themeMode,
          locale           : Locale(settings.language),
          supportedLocales : const [Locale('ar'), Locale('en')],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (ctx, child) => Directionality(
            textDirection: settings.language == 'ar' ? TextDirection.rtl : TextDirection.ltr,
            child: child!,
          ),
          home: const SplashScreen(),
        ),
      ),
    );
  }
}
