import 'package:flutter/material.dart';
import 'package:alouette_lib_tts/alouette_tts.dart';
import '../../tokens/app_tokens.dart';
import '../atoms/atomic_elements.dart';

import '../molecules/voice_selector.dart';
import '../molecules/status_indicator.dart';

/// TTS Control Panel Organism
///
/// Complex component for TTS controls including voice selection,
/// playback controls, and volume adjustment.
class TTSControlPanel extends StatefulWidget {
  final VoiceModel? selectedVoice;
  final List<VoiceModel> availableVoices;
  final ValueChanged<VoiceModel?>? onVoiceChanged;
  final String? currentText;
  final VoidCallback? onPlay;
  final VoidCallback? onPause;
  final VoidCallback? onStop;
  final bool isPlaying;
  final bool isPaused;
  final bool isLoading;
  final double volume;
  final ValueChanged<double>? onVolumeChanged;
  final double speechRate;
  final ValueChanged<double>? onSpeechRateChanged;
  final double pitch;
  final ValueChanged<double>? onPitchChanged;
  final String? errorMessage;
  final bool showAdvancedControls;

  const TTSControlPanel({
    super.key,
    this.selectedVoice,
    required this.availableVoices,
    this.onVoiceChanged,
    this.currentText,
    this.onPlay,
    this.onPause,
    this.onStop,
    this.isPlaying = false,
    this.isPaused = false,
    this.isLoading = false,
    this.volume = 1.0,
    this.onVolumeChanged,
    this.speechRate = 1.0,
    this.onSpeechRateChanged,
    this.pitch = 1.0,
    this.onPitchChanged,
    this.errorMessage,
    this.showAdvancedControls = false,
  });

  @override
  State<TTSControlPanel> createState() => _TTSControlPanelState();
}

class _TTSControlPanelState extends State<TTSControlPanel> {
  bool _showAdvanced = false;

  @override
  void initState() {
    super.initState();
    _showAdvanced = widget.showAdvancedControls;
  }

  @override
  Widget build(BuildContext context) {
    return AtomicCard(
      padding: const EdgeInsets.all(SpacingTokens.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const AtomicSpacer(AtomicSpacing.medium),
          if (widget.errorMessage != null) ...[
            _buildErrorDisplay(),
            const AtomicSpacer(AtomicSpacing.medium),
          ],
          _buildVoiceSelection(),
          const AtomicSpacer(AtomicSpacing.medium),
          _buildPlaybackControls(),
          const AtomicSpacer(AtomicSpacing.medium),
          _buildVolumeControl(),
          if (_showAdvanced) ...[
            const AtomicSpacer(AtomicSpacing.medium),
            _buildAdvancedControls(),
          ],
          if (widget.currentText != null) ...[
            const AtomicSpacer(AtomicSpacing.medium),
            _buildTextPreview(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const AtomicIcon(Icons.record_voice_over, size: AtomicIconSize.medium),
        const AtomicSpacer(
          AtomicSpacing.small,
          direction: AtomicSpacerDirection.horizontal,
        ),
        const AtomicText(
          'Text-to-Speech',
          variant: AtomicTextVariant.titleMedium,
        ),
        const Spacer(),
        IconButton(
          icon: Icon(_showAdvanced ? Icons.expand_less : Icons.expand_more),
          onPressed: () => setState(() => _showAdvanced = !_showAdvanced),
        ),
        if (widget.isLoading) ...[
          const AtomicSpacer(
            AtomicSpacing.small,
            direction: AtomicSpacerDirection.horizontal,
          ),
          const AtomicProgressIndicator(
            type: AtomicProgressType.circular,
            size: AtomicProgressSize.small,
          ),
        ],
      ],
    );
  }

  Widget _buildErrorDisplay() {
    return StatusIndicator(
      status: StatusType.error,
      message: widget.errorMessage!,
      actionText: 'Retry',
      onActionPressed: widget.onPlay,
    );
  }

  Widget _buildVoiceSelection() {
    if (widget.availableVoices.isEmpty) {
      return StatusIndicator(
        status: StatusType.warning,
        message: 'No voices available',
        actionText: 'Refresh',
        onActionPressed: () {
          // Trigger voice refresh - implementation depends on app
        },
      );
    }

    return VoiceSelector(
      selectedVoice: widget.selectedVoice,
      availableVoices: widget.availableVoices,
      onVoiceChanged: widget.onVoiceChanged ?? (_) {},
      labelText: 'Voice',
      isEnabled: !widget.isLoading,
    );
  }

  Widget _buildPlaybackControls() {
    final canPlay =
        widget.currentText != null &&
        widget.selectedVoice != null &&
        !widget.isLoading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AtomicText(
          'Playback Controls',
          variant: AtomicTextVariant.labelLarge,
        ),
        const AtomicSpacer(AtomicSpacing.small),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: canPlay
                  ? (widget.isPlaying && !widget.isPaused
                        ? widget.onPause
                        : widget.onPlay)
                  : null,
              child: Icon(
                widget.isPlaying && !widget.isPaused
                    ? Icons.pause
                    : Icons.play_arrow,
              ),
            ),
            const AtomicSpacer(
              AtomicSpacing.medium,
              direction: AtomicSpacerDirection.horizontal,
            ),
            OutlinedButton(
              onPressed: widget.isPlaying ? widget.onStop : null,
              child: Icon(Icons.stop),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVolumeControl() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.tune, size: 20),
            const SizedBox(width: 8),
            const AtomicText(
              'Voice Parameters',
              variant: AtomicTextVariant.labelLarge,
            ),
          ],
        ),
        const AtomicSpacer(AtomicSpacing.small),
        // Three sliders in one row
        Row(
          children: [
            // Speech Rate
            Expanded(
              child: _buildCompactSlider(
                icon: Icons.speed,
                label: 'Speech Rate',
                value: widget.speechRate,
                displayValue: '${widget.speechRate.toStringAsFixed(1)}x',
                onChanged: widget.onSpeechRateChanged,
                min: 0.5,
                max: 2.0,
                divisions: 15,
              ),
            ),
            const SizedBox(width: SpacingTokens.m),
            // Pitch
            Expanded(
              child: _buildCompactSlider(
                icon: Icons.graphic_eq,
                label: 'Pitch',
                value: widget.pitch,
                displayValue: '${widget.pitch.toStringAsFixed(1)}x',
                onChanged: widget.onPitchChanged,
                min: 0.5,
                max: 2.0,
                divisions: 15,
              ),
            ),
            const SizedBox(width: SpacingTokens.m),
            // Volume
            Expanded(
              child: _buildCompactSlider(
                icon: Icons.volume_up,
                label: 'Volume',
                value: widget.volume,
                displayValue: '${(widget.volume * 100).round()}%',
                onChanged: widget.onVolumeChanged,
                min: 0.0,
                max: 1.0,
                divisions: 10,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompactSlider({
    required IconData icon,
    required String label,
    required double value,
    required String displayValue,
    required ValueChanged<double>? onChanged,
    required double min,
    required double max,
    required int divisions,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: ColorTokens.onSurfaceVariant),
        const SizedBox(height: 4),
        AtomicText(
          displayValue,
          variant: AtomicTextVariant.labelMedium,
          color: ColorTokens.onSurface,
        ),
        Slider(
          value: value,
          onChanged: onChanged,
          min: min,
          max: max,
          divisions: divisions,
        ),
        AtomicText(
          label,
          variant: AtomicTextVariant.labelSmall,
          color: ColorTokens.onSurfaceVariant,
        ),
      ],
    );
  }

  Widget _buildAdvancedControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AtomicText(
          'Advanced Controls',
          variant: AtomicTextVariant.labelLarge,
        ),
        const AtomicSpacer(AtomicSpacing.small),
        AtomicText(
          'Additional settings and controls can be added here.',
          variant: AtomicTextVariant.body,
          color: ColorTokens.onSurfaceVariant,
        ),
      ],
    );
  }

  Widget _buildTextPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const AtomicText(
              'Text Preview',
              variant: AtomicTextVariant.labelLarge,
            ),
            const Spacer(),
            AtomicBadge(
              text: '${widget.currentText!.length} chars',
              size: AtomicBadgeSize.small,
            ),
          ],
        ),
        const AtomicSpacer(AtomicSpacing.small),
        AtomicCard(
          padding: const EdgeInsets.all(SpacingTokens.m),
          backgroundColor: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          child: SizedBox(
            width: double.infinity,
            child: AtomicText(
              widget.currentText!,
              variant: AtomicTextVariant.body,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }
}
