import 'package:flutter/material.dart';
import 'package:alouette_ui/alouette_ui.dart';
import 'app_router.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class AlouetteApp extends StatelessWidget {
  const AlouetteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Alouette',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: const AppRouter(),
      debugShowCheckedModeBanner: false,
    );
  }
}
