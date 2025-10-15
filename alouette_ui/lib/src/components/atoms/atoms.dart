/// Atomic Design - Atoms
///
/// This file exports all atomic components (the smallest UI building blocks)
/// following the atomic design methodology. Atoms are the basic building blocks
/// of matter applied to web interfaces - they include basic HTML elements like
/// form labels, inputs, buttons, and others that can't be broken down any further.

// Base atomic elements
export 'atomic_elements.dart';

// Form components
export 'atomic_input.dart';

// Flag rendering
export 'language_flag_icon.dart' show LanguageFlagIcon;

// Re-export commonly used classes for convenience
export 'atomic_elements.dart'
    show
        AtomicWidget,
        AtomicIcon,
        AtomicIconSize,
        AtomicText,
        AtomicTextVariant,
        AtomicSpacer,
        AtomicSpacing,
        AtomicSpacerDirection,
        AtomicDivider,
        AtomicDividerType,
        AtomicCard,
        AtomicBadge,
        AtomicBadgeSize,
        AtomicChip,
        AtomicProgressIndicator,
        AtomicProgressType,
        AtomicProgressSize;
