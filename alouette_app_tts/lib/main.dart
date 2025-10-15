import 'package:flutter/material.dart';
import 'package:alouette_ui/alouette_ui.dart';
import 'app/tts_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize only core services (non-blocking)
  ServiceLocator.initialize();

  // Run app with unified initialization wrapper
  runApp(
    AppInitializationWrapper(
      title: 'Alouette TTS',
      splashMessage: 'Initializing text-to-speech...',
      initializer: TTSAppInitializer(),
      app: const TTSApp(),
    ),
  );
}
