import 'package:flutter/material.dart';
import 'package:alouette_lib_tts/alouette_tts.dart';
import '../../tokens/app_tokens.dart';
import '../atoms/atomic_elements.dart';
import '../atoms/atomic_input.dart';

/// Extension to add UI-specific properties to VoiceGender
extension VoiceGenderUI on VoiceGender {
  IconData get icon {
    switch (this) {
      case VoiceGender.male:
        return Icons.person;
      case VoiceGender.female:
        return Icons.person_outline;
      case VoiceGender.neutral:
        return Icons.person_2;
      case VoiceGender.unknown:
        return Icons.help_outline;
    }
  }
}

/// Voice Selector Molecule
///
/// Dropdown component for selecting TTS voices with filtering capabilities
class VoiceSelector extends StatelessWidget {
  final VoiceModel? selectedVoice;
  final List<VoiceModel> availableVoices;
  final ValueChanged<VoiceModel?> onVoiceChanged;
  final String? labelText;
  final bool isRequired;
  final bool isEnabled;
  final String? errorText;
  final VoiceGender? filterByGender;
  final String? filterByLanguage;

  const VoiceSelector({
    super.key,
    this.selectedVoice,
    required this.availableVoices,
    required this.onVoiceChanged,
    this.labelText = 'Voice',
    this.isRequired = false,
    this.isEnabled = true,
    this.errorText,
    this.filterByGender,
    this.filterByLanguage,
  });

  @override
  Widget build(BuildContext context) {
    final filteredVoices = _getFilteredVoices();

    final items = filteredVoices
        .map(
          (voice) => AtomicDropdownItem<VoiceModel>(
            value: voice,
            text: _formatVoiceName(voice),
            icon: voice.gender.icon,
          ),
        )
        .toList();

    return AtomicDropdown<VoiceModel>(
      value: selectedVoice,
      items: items,
      onChanged: isEnabled ? onVoiceChanged : null,
      labelText: labelText,
      hintText: 'Select a voice',
      errorText: errorText,
      isRequired: isRequired,
      isEnabled: isEnabled,
    );
  }

  List<VoiceModel> _getFilteredVoices() {
    return availableVoices.where((voice) {
      if (filterByGender != null && voice.gender != filterByGender) {
        return false;
      }
      if (filterByLanguage != null && voice.languageCode != filterByLanguage) {
        return false;
      }
      return true;
    }).toList();
  }

  String _formatVoiceName(VoiceModel voice) {
    final parts = <String>[voice.displayName];

    if (voice.isNeural) {
      parts.add('(Neural)');
    }

    parts.add('- ${voice.gender.name}');

    return parts.join(' ');
  }
}

/// Voice Grid Selector Molecule
///
/// Grid-based voice selection for better visual presentation
class VoiceGridSelector extends StatelessWidget {
  final VoiceModel? selectedVoice;
  final List<VoiceModel> availableVoices;
  final ValueChanged<VoiceModel?> onVoiceChanged;
  final String? labelText;
  final int crossAxisCount;
  final VoiceGender? filterByGender;
  final String? filterByLanguage;

  const VoiceGridSelector({
    super.key,
    this.selectedVoice,
    required this.availableVoices,
    required this.onVoiceChanged,
    this.labelText = 'Voices',
    this.crossAxisCount = 2,
    this.filterByGender,
    this.filterByLanguage,
  });

  @override
  Widget build(BuildContext context) {
    final filteredVoices = _getFilteredVoices();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (labelText != null) ...[
          AtomicText(labelText!, variant: AtomicTextVariant.labelMedium),
          const AtomicSpacer(AtomicSpacing.small),
        ],
        if (filteredVoices.isEmpty)
          _buildEmptyState(context)
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: 2.5,
              crossAxisSpacing: SpacingTokens.s,
              mainAxisSpacing: SpacingTokens.s,
            ),
            itemCount: filteredVoices.length,
            itemBuilder: (context, index) {
              final voice = filteredVoices[index];
              final isSelected = selectedVoice == voice;

              return VoiceChip(
                voice: voice,
                isSelected: isSelected,
                onTap: () => onVoiceChanged(voice),
              );
            },
          ),
      ],
    );
  }

  List<VoiceModel> _getFilteredVoices() {
    return availableVoices.where((voice) {
      if (filterByGender != null && voice.gender != filterByGender) {
        return false;
      }
      if (filterByLanguage != null && voice.languageCode != filterByLanguage) {
        return false;
      }
      return true;
    }).toList();
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.l),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DimensionTokens.radiusL),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          AtomicIcon(
            Icons.voice_over_off,
            size: AtomicIconSize.medium,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const AtomicSpacer(
            AtomicSpacing.small,
            direction: AtomicSpacerDirection.horizontal,
          ),
          Expanded(
            child: AtomicText(
              'No voices available for the selected filters',
              variant: AtomicTextVariant.bodySmall,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Voice Chip Component
///
/// Individual voice selection chip with voice details
class VoiceChip extends StatelessWidget {
  final VoiceModel voice;
  final bool isSelected;
  final VoidCallback onTap;

  const VoiceChip({
    super.key,
    required this.voice,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: isSelected
          ? colorScheme.primaryContainer
          : colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(DimensionTokens.radiusL),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DimensionTokens.radiusL),
        child: Container(
          padding: const EdgeInsets.all(SpacingTokens.s),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(DimensionTokens.radiusL),
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.outline.withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  AtomicIcon(
                    voice.gender.icon,
                    size: AtomicIconSize.small,
                    color: isSelected
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onSurfaceVariant,
                  ),
                  const AtomicSpacer(
                    AtomicSpacing.xs,
                    direction: AtomicSpacerDirection.horizontal,
                  ),
                  Expanded(
                    child: AtomicText(
                      voice.displayName,
                      variant: AtomicTextVariant.labelMedium,
                      color: isSelected
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurface,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (voice.isNeural)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.secondary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: AtomicText(
                        'AI',
                        variant: AtomicTextVariant.caption,
                        color: colorScheme.secondary,
                      ),
                    ),
                ],
              ),
              const AtomicSpacer(AtomicSpacing.xs),
              AtomicText(
                '${voice.languageCode} • ${voice.gender.name}',
                variant: AtomicTextVariant.caption,
                color: isSelected
                    ? colorScheme.onPrimaryContainer.withValues(alpha: 0.7)
                    : colorScheme.onSurfaceVariant,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
