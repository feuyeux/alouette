import 'package:flutter/material.dart';
import 'package:alouette_ui/alouette_ui.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Alouette',
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
            appName: 'Alouette',
            copyright: 'Copyright © 2025 @feuyeux. All rights reserved.',
          ),
        ],
      ),
      body: const TranslationPageView(enableTTS: true),
    );
  }

  Future<void> _openConfigDialog(BuildContext context) async {
    final result = await showTranslationConfigDialog(context);
    if (result != null && context.mounted) {
      context.showSuccessMessage('Configuration updated successfully');
    }
  }
}
