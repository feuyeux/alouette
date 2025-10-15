import 'package:flutter/material.dart';
import 'package:alouette_ui/alouette_ui.dart';
import 'app/alouette_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize only core services (non-blocking)
  ServiceLocator.initialize();

  // Run app with unified initialization wrapper
  runApp(
    AppInitializationWrapper(
      title: 'Alouette',
      splashMessage: 'Initializing services...',
      initializer: CombinedAppInitializer(),
      app: const AlouetteApp(),
    ),
  );
}
