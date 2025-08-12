import 'package:flutter/material.dart';
import 'package:alouette_lib_tts/alouette_lib_tts.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Alouette TTS Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: TTSExamplePage(),
    );
  }
}

class TTSExamplePage extends StatefulWidget {
  @override
  _TTSExamplePageState createState() => _TTSExamplePageState();
}

class _TTSExamplePageState extends State<TTSExamplePage> {
  final TTSService _ttsService = TTSService();
  final TextEditingController _textController = TextEditingController();
  
  bool _isInitialized = false;
  String _status = 'Not initialized';
  LanguageOption _selectedLanguage = TTSConstants.defaultLanguage;
  double _speechRate = TTSConstants.defaultSpeechRate;
  double _volume = TTSConstants.defaultVolume;
  double _pitch = TTSConstants.defaultPitch;

  @override
  void initState() {
    super.initState();
    _textController.text = 'Hello, this is a test of the Alouette TTS library!';
    _initializeTTS();
  }

  Future<void> _initializeTTS() async {
    try {
      await _ttsService.initialize(
        onStart: () {
          setState(() => _status = 'Speaking...');
        },
        onComplete: () {
          setState(() => _status = 'Completed');
        },
        onError: (error) {
          setState(() => _status = 'Error: $error');
        },
      );
      setState(() {
        _isInitialized = true;
        _status = 'Ready';
      });
    } catch (e) {
      setState(() => _status = 'Initialization failed: $e');
    }
  }

  Future<void> _speak() async {
    if (!_isInitialized || _textController.text.isEmpty) return;
    
    try {
      await _ttsService.speak(
        text: _textController.text,
        languageCode: _selectedLanguage.code,
        speechRate: _speechRate,
        volume: _volume,
        pitch: _pitch,
      );
    } catch (e) {
      setState(() => _status = 'Speech failed: $e');
    }
  }

  Future<void> _stop() async {
    if (!_isInitialized) return;
    
    try {
      await _ttsService.stop();
      setState(() => _status = 'Stopped');
    } catch (e) {
      setState(() => _status = 'Stop failed: $e');
    }
  }

  @override
  void dispose() {
    _ttsService.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Alouette TTS Example'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Status:', style: Theme.of(context).textTheme.titleMedium),
                    SizedBox(height: 8),
                    Text(_status),
                    SizedBox(height: 8),
                    Text('State: ${_ttsService.currentState.name}'),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 16),
            
            // Text input
            TextField(
              controller: _textController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Text to speak',
                border: OutlineInputBorder(),
              ),
            ),
            
            SizedBox(height: 16),
            
            // Language selection
            DropdownButtonFormField<LanguageOption>(
              value: _selectedLanguage,
              decoration: InputDecoration(
                labelText: 'Language',
                border: OutlineInputBorder(),
              ),
              items: TTSConstants.supportedLanguages.map((lang) {
                return DropdownMenuItem(
                  value: lang,
                  child: Text('${lang.flag} ${lang.name}'),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedLanguage = value);
                }
              },
            ),
            
            SizedBox(height: 16),
            
            // Speech rate
            Row(
              children: [
                Text('Speech Rate: ${_speechRate.toStringAsFixed(1)}'),
                Expanded(
                  child: Slider(
                    value: _speechRate,
                    min: TTSConstants.minSpeechRate,
                    max: TTSConstants.maxSpeechRate,
                    divisions: 20,
                    onChanged: (value) {
                      setState(() => _speechRate = value);
                    },
                  ),
                ),
              ],
            ),
            
            // Volume
            Row(
              children: [
                Text('Volume: ${_volume.toStringAsFixed(1)}'),
                Expanded(
                  child: Slider(
                    value: _volume,
                    min: TTSConstants.minVolume,
                    max: TTSConstants.maxVolume,
                    divisions: 10,
                    onChanged: (value) {
                      setState(() => _volume = value);
                    },
                  ),
                ),
              ],
            ),
            
            // Pitch
            Row(
              children: [
                Text('Pitch: ${_pitch.toStringAsFixed(1)}'),
                Expanded(
                  child: Slider(
                    value: _pitch,
                    min: TTSConstants.minPitch,
                    max: TTSConstants.maxPitch,
                    divisions: 20,
                    onChanged: (value) {
                      setState(() => _pitch = value);
                    },
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 24),
            
            // Control buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isInitialized && !_ttsService.isSpeaking ? _speak : null,
                    child: Text('Speak'),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isInitialized && _ttsService.isSpeaking ? _stop : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: Text('Stop'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}