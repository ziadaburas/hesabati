import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '/core/themes/app_theme.dart';
import '/core/constants/app_constants.dart';
import '/core/localization/localization_service.dart';
import '/data/services/database_service.dart';
import '/data/services/connectivity_service.dart';
import '/data/services/sync_service.dart';
import '/presentation/controllers/controllers.dart';
import '/presentation/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Database
  await DatabaseService.instance.database;
  
  // Initialize Controllers
  _initializeControllers();
  
  runApp(const QitaaLedgerApp());
}

/// تهيئة جميع Controllers
void _initializeControllers() {
  // Auth Controller
  Get.put(AuthController(), permanent: true);
  
  // Settings Controller
  Get.put(SettingsController(), permanent: true);
  
  // Local Account Controller
  Get.put(LocalAccountController(), permanent: true);
  
  // Connectivity Service
  Get.put(ConnectivityService(), permanent: true);
  
  // Sync Service
  Get.put(SyncService(), permanent: true);
}

class QitaaLedgerApp extends StatelessWidget {
  const QitaaLedgerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      
      // Themes
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      
      // Localization
      translations: LocalizationService(),
      locale: LocalizationService.defaultLocale,
      fallbackLocale: const Locale('en', 'US'),
      
      // RTL Support for Arabic
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
      
      // Initial Screen
      home: const SplashScreen(),
    );
  }
}
