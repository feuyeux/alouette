import 'package:flutter/material.dart';
import 'package:alouette_ui/alouette_ui.dart';
import '../controllers/tts_controller.dart' as local;
import '../widgets/tts_input_section.dart';
import '../widgets/tts_control_section.dart';

class TTSPage extends StatefulWidget {
  final local.TTSController controller;
  final TextEditingController textController;

  const TTSPage({
    super.key,
    required this.controller,
    required this.textController,
  });

  @override
  State<TTSPage> createState() => _TTSPageState();
}

class _TTSPageState extends State<TTSPage> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final inputHeight = _resolveInputHeight(constraints.maxHeight);

        Widget buildInputSection() => ListenableBuilder(
          listenable: widget.controller,
          builder: (context, child) {
            return TTSInputSection(
              controller: widget.controller,
              textController: widget.textController,
            );
          },
        );

        Widget buildControlSection() => ListenableBuilder(
          listenable: widget.controller,
          builder: (context, child) {
            return TTSControlSection(
              controller: widget.controller,
              textController: widget.textController,
            );
          },
        );

        if (constraints.maxHeight.isFinite && constraints.maxHeight < 680) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(SpacingTokens.s),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: inputHeight, child: buildInputSection()),
                const SizedBox(height: SpacingTokens.s),
                buildControlSection(),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(SpacingTokens.s),
          child: Column(
            children: [
              SizedBox(height: inputHeight, child: buildInputSection()),
              const SizedBox(height: SpacingTokens.s),
              Expanded(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: buildControlSection(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  double _resolveInputHeight(double maxHeight) {
    if (!maxHeight.isFinite || maxHeight <= 0) {
      return 260;
    }

    const minHeight = 220.0;
    final preferred = maxHeight * 0.35;
    final maxAllowed = maxHeight * 0.55;

    // Ensure min is less than max before clamping
    final actualMin = minHeight;
    final actualMax = maxAllowed.clamp(minHeight, double.infinity);

    return preferred.clamp(actualMin, actualMax).toDouble();
  }
}
