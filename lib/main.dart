import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rafiki_app/features/main/presentation/pages/start_page.dart';
import 'package:rafiki_app/core/di/service_locator.dart';
import 'package:rafiki_app/core/logging/app_logger.dart';

import 'package:rafiki_app/core/l10n/app_localizations.dart';
import 'package:rafiki_app/core/theme/app_theme.dart';
import 'package:rafiki_app/core/widgets/app_error_view.dart';
import 'package:provider/provider.dart';
import 'package:rafiki_app/core/locale_provider.dart';

void main() async {
    final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  widgetsBinding.deferFirstFrame();


  final prefs = await SharedPreferences.getInstance();
  final localeProvider = LocaleProvider()..initFromPrefs(prefs);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<LocaleProvider>.value(value: localeProvider),
      ],
      child: const MyApp(),
    ),
  );

  ErrorWidget.builder = (details) =>
      AppErrorView(message: details.exceptionAsString());

  widgetsBinding.allowFirstFrame();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);

    return MaterialApp(
      title: 'رفيقي',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      // If user has a saved preference use it; otherwise fall back to device locale.
      // Passing null lets Flutter pick from supportedLocales automatically.
      locale: localeProvider.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      // When the device locale isn't supported, default to Arabic (app's primary language).
      localeResolutionCallback: (deviceLocale, supportedLocales) {
        if (localeProvider.locale != null) return localeProvider.locale;
        if (deviceLocale != null) {
          for (final supported in supportedLocales) {
            if (supported.languageCode == deviceLocale.languageCode) {
              return supported;
            }
          }
        }
        return const Locale('ar'); // fallback to Arabic
      },
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initAndNavigate();
  }

  /// Initialize core services during the splash screen,
  /// then navigate. Waits for both the minimum splash duration
  /// AND service initialization to complete.
  Future<void> _initAndNavigate() async {
    // Run initialization and minimum splash delay in parallel.
    await Future.wait([
      _initCoreServices(),
      Future.delayed(const Duration(seconds: 2)),
    ]);

    if (!mounted) return; // ✅ تجنب crash لو الـ widget اتشال
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const Start()),
    );
  }

  /// Initialize Hive, DI, and run data migrations.
  Future<void> _initCoreServices() async {
    try {
      AppLogger.info('Starting core service initialization', tag: 'App');
      await ServiceLocator.initialize();
      AppLogger.info('Core services initialized successfully', tag: 'App');
    } catch (e, st) {
      // Log but don't crash — the app can still function with
      // SharedPreferences fallback until migration completes.
      AppLogger.error(
        'Core service initialization failed — app will use fallbacks',
        tag: 'App',
        error: e,
        stackTrace: st,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05211B), // Rich dark emerald green to blend with the splash screen
      body: SizedBox.expand(
        child: Image.asset(
          'assets/rafiki.png',
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}