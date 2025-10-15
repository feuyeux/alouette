import 'package:flutter/material.dart';

/// Design Tokens - Animation & Motion
///
/// Provides consistent animation durations, curves, and motion patterns
/// for a cohesive user experience across all components.
class MotionTokens {
  const MotionTokens._();

  // ============================================================================
  // DURATIONS
  // ============================================================================

  /// Instant - for immediate feedback (0ms)
  static const Duration instant = Duration.zero;

  /// Faster - for micro-interactions (75ms)
  static const Duration faster = Duration(milliseconds: 75);

  /// Fast - for quick transitions (150ms)
  static const Duration fast = Duration(milliseconds: 150);

  /// Normal - for standard animations (200ms)
  static const Duration normal = Duration(milliseconds: 200);

  /// Moderate - for more noticeable changes (300ms)
  static const Duration moderate = Duration(milliseconds: 300);

  /// Slow - for complex animations (500ms)
  static const Duration slow = Duration(milliseconds: 500);

  /// Slower - for dramatic effects (750ms)
  static const Duration slower = Duration(milliseconds: 750);

  /// Slowest - for special cases (1000ms)
  static const Duration slowest = Duration(milliseconds: 1000);

  // ============================================================================
  // ANIMATION CURVES
  // ============================================================================

  /// Standard curve - for most UI animations
  static const Curve standard = Curves.easeInOut;

  /// Emphasized - for important state changes
  static const Curve emphasized = Curves.easeInOutCubic;

  /// Decelerated - for entering animations
  static const Curve decelerated = Curves.easeOut;

  /// Accelerated - for exiting animations
  static const Curve accelerated = Curves.easeIn;

  /// Sharp - for mechanical movements
  static const Curve sharp = Curves.linear;

  /// Bounce - for playful interactions
  static const Curve bounce = Curves.bounceOut;

  /// Elastic - for stretchy animations
  static const Curve elastic = Curves.elasticOut;

  // ============================================================================
  // MOTION PATTERNS
  // ============================================================================

  /// Fade animations
  static const Duration fadeIn = fast;
  static const Duration fadeOut = faster;
  static const Curve fadeInCurve = decelerated;
  static const Curve fadeOutCurve = accelerated;

  /// Scale animations
  static const Duration scaleIn = normal;
  static const Duration scaleOut = fast;
  static const Curve scaleInCurve = emphasized;
  static const Curve scaleOutCurve = accelerated;

  /// Slide animations
  static const Duration slideIn = moderate;
  static const Duration slideOut = fast;
  static const Curve slideInCurve = decelerated;
  static const Curve slideOutCurve = accelerated;

  /// Rotation animations
  static const Duration rotate = normal;
  static const Curve rotateCurve = standard;

  /// Color transitions
  static const Duration colorChange = fast;
  static const Curve colorCurve = standard;

  /// Size changes
  static const Duration resize = normal;
  static const Curve resizeCurve = emphasized;

  // ============================================================================
  // INTERACTION FEEDBACK
  // ============================================================================

  /// Button press feedback
  static const Duration buttonPress = faster;
  static const Duration buttonRelease = fast;
  static const Curve buttonCurve = sharp;

  /// Hover effects
  static const Duration hoverIn = fast;
  static const Duration hoverOut = faster;
  static const Curve hoverCurve = standard;

  /// Focus indicators
  static const Duration focusIn = fast;
  static const Duration focusOut = faster;
  static const Curve focusCurve = standard;

  /// Loading states
  static const Duration loadingSpinner = slowest;
  static const Duration loadingPulse = slow;
  static const Curve loadingCurve = standard;

  // ============================================================================
  // PAGE TRANSITIONS
  // ============================================================================

  /// Page navigation
  static const Duration pageTransition = moderate;
  static const Curve pageInCurve = decelerated;
  static const Curve pageOutCurve = accelerated;

  /// Modal dialogs
  static const Duration modalIn = moderate;
  static const Duration modalOut = fast;
  static const Curve modalInCurve = emphasized;
  static const Curve modalOutCurve = accelerated;

  /// Bottom sheets
  static const Duration sheetIn = moderate;
  static const Duration sheetOut = fast;
  static const Curve sheetInCurve = decelerated;
  static const Curve sheetOutCurve = accelerated;

  /// Snackbars & toasts
  static const Duration snackbarIn = fast;
  static const Duration snackbarOut = fast;
  static const Curve snackbarCurve = standard;

  // ============================================================================
  // STAGGER ANIMATIONS
  // ============================================================================

  /// List item stagger delay
  static const Duration staggerDelay = Duration(milliseconds: 50);

  /// Card grid stagger delay
  static const Duration gridStaggerDelay = Duration(milliseconds: 25);

  /// Menu item stagger delay
  static const Duration menuStaggerDelay = Duration(milliseconds: 30);

  // ============================================================================
  // ACCESSIBILITY CONSIDERATIONS
  // ============================================================================

  /// Reduced motion alternatives (for users with motion sensitivity)
  static const Duration reducedMotion = Duration(milliseconds: 50);
  static const Curve reducedMotionCurve = Curves.linear;

  /// Check if reduced motion is preferred (this would be set by system settings)
  static bool get prefersReducedMotion =>
      false; // System accessibility check would be implemented here

  /// Get duration with reduced motion consideration
  static Duration getDuration(Duration normal) {
    return prefersReducedMotion ? reducedMotion : normal;
  }

  /// Get curve with reduced motion consideration
  static Curve getCurve(Curve normal) {
    return prefersReducedMotion ? reducedMotionCurve : normal;
  }
}
