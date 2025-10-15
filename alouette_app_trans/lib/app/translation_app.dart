import 'package:flutter/material.dart';
import 'package:alouette_ui/alouette_ui.dart';
import 'app_router.dart';

/// Global navigator key for accessing navigator from anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class TranslationApp extends StatelessWidget {
  const TranslationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Alouette Trans',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: const AppRouter(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class TranslationHomeScreen extends StatelessWidget {
  const TranslationHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Alouette Trans',
        showLogo: true,
        statusWidget: const TranslationStatusWidget(),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () => _openConfigDialog(context),
          ),
          AboutHelper.createAboutButton(
            context,
            appName: 'Alouette Trans',
            copyright: 'Copyright © 2025 @feuyeux. All rights reserved.',
          ),
        ],
      ),
      body: const TranslationPageView(),
    );
  }

  Future<void> _openConfigDialog(BuildContext context) async {
    final result = await showTranslationConfigDialog(context);
    if (result != null && context.mounted) {
      context.showSuccessMessage('Configuration updated successfully');
    }
  }
}
