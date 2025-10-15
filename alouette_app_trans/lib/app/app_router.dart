import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:alouette_ui/alouette_ui.dart';
import 'translation_app.dart';

class AppRouter extends StatefulWidget {
  const AppRouter({super.key});

  @override
  State<AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<AppRouter> {
  static const platform = MethodChannel('com.example.alouette_trans/menu');
  bool _isAboutPageOpen = false;

  @override
  void initState() {
    super.initState();
    // Only setup method channel on macOS
    if (!kIsWeb && Platform.isMacOS) {
      _setupMethodChannel();
    }
  }

  void _setupMethodChannel() {
    platform.setMethodCallHandler((call) async {
      if (call.method == 'showAbout') {
        _showAboutPage();
      }
    });
  }

  void _showAboutPage() {
    final context = navigatorKey.currentContext;
    if (context != null && !_isAboutPageOpen) {
      _isAboutPageOpen = true;
      Navigator.of(context)
          .push(
            MaterialPageRoute(
              builder: (context) => const AboutPage(
                appName: 'Alouette Trans',
                copyright: 'Copyright © 2025 @feuyeux. All rights reserved.',
              ),
            ),
          )
          .then((_) {
            _isAboutPageOpen = false;
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    return const TranslationHomeScreen();
  }
}
