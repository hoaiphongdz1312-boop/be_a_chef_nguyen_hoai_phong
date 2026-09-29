import 'package:flutter/material.dart';

import 'core/config.dart';
import 'core/theme.dart';
import 'screens/splash_scan_screen.dart';

class BeAChefApp extends StatelessWidget {
  const BeAChefApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const SplashScanScreen(),
    );
  }
}
