import 'package:flutter/material.dart';
import 'package:alouette_lib_tts/alouette_tts.dart';
import 'package:alouette_ui/alouette_ui.dart';
import '../controllers/tts_controller.dart' as local;

/// Settings page for TTS configuration
class TTSSettingsPage extends StatefulWidget {
  final local.TTSController controller;

  const TTSSettingsPage({
    super.key,
    required this.controller,
  });

  @override
  State<TTSSettingsPage> createState() => _TTSSettingsPageState();
}

class _TTSSettingsPageState extends State<TTSSettingsPage> {
  Map<String, dynamic> _platformInfo = {};

  @override
  void initState() {
    super.initState();
    _loadPlatformInfo();
  }

  Future<void> _loadPlatformInfo() async {
    final info = await widget.controller.getPlatformInfo();
    if (mounted) {
      setState(() {
        _platformInfo = info;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'TTS Settings',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Engine Information
                CustomCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Engine Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow('Current Engine', widget.controller.currentEngine?.name ?? 'None'),
                      _buildInfoRow('Platform', _platformInfo['platformName'] ?? 'Unknown'),
                      _buildInfoRow('Initialized', widget.controller.isInitialized ? 'Yes' : 'No'),
                      _buildInfoRow('Available Voices', widget.controller.availableVoices.length.toString()),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Engine Selection
                if (_platformInfo['supportedEngines'] != null)
                  CustomCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Engine Selection',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ..._buildEngineButtons(),
                      ],
                    ),
                  ),

                const SizedBox(height: 16),

                // Voice Parameters
                CustomCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Voice Parameters',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildParameterSlider(
                        'Speech Rate',
                        widget.controller.rate,
                        0.1,
                        3.0,
                        '${widget.controller.rate.toStringAsFixed(1)}x',
                        widget.controller.updateRate,
                      ),
                      const SizedBox(height: 16),
                      _buildParameterSlider(
                        'Pitch',
                        widget.controller.pitch,
                        0.5,
                        2.0,
                        '${widget.controller.pitch.toStringAsFixed(1)}x',
                        widget.controller.updatePitch,
                      ),
                      const SizedBox(height: 16),
                      _buildParameterSlider(
                        'Volume',
                        widget.controller.volume,
                        0.0,
                        1.0,
                        '${(widget.controller.volume * 100).toInt()}%',
                        widget.controller.updateVolume,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Platform Information
                CustomCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Platform Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ..._buildPlatformInfo(),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(value),
        ],
      ),
    );
  }

  List<Widget> _buildEngineButtons() {
    final supportedEngines = _platformInfo['supportedEngines'] as List<dynamic>?;
    if (supportedEngines == null) return [];

    return supportedEngines.map<Widget>((engineName) {
      final engineType = TTSEngineType.values.firstWhere(
        (e) => e.name == engineName,
        orElse: () => TTSEngineType.flutter,
      );
      
      final isSelected = widget.controller.currentEngine == engineType;

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: CustomButton(
          onPressed: () => widget.controller.switchEngine(engineType),
          text: engineName.toString().toUpperCase(),
          type: isSelected ? CustomButtonType.primary : CustomButtonType.secondary,
          size: CustomButtonSize.medium,
        ),
      );
    }).toList();
  }

  Widget _buildParameterSlider(
    String label,
    double value,
    double min,
    double max,
    String displayValue,
    Function(double) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            Text(displayValue),
          ],
        ),
        const SizedBox(height: 8),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: ((max - min) * 10).round(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  List<Widget> _buildPlatformInfo() {
    final widgets = <Widget>[];
    
    _platformInfo.forEach((key, value) {
      if (key != 'supportedEngines' && key != 'config') {
        widgets.add(_buildInfoRow(
          key.replaceAllMapped(
            RegExp(r'([A-Z])'),
            (match) => ' ${match.group(1)}',
          ).trim(),
          value.toString(),
        ));
      }
    });

    return widgets;
  }
}