/// Design Tokens - Spacing
///
/// Provides consistent spacing values throughout the application.
/// Based on 4px base unit for scalable design system.
class SpacingTokens {
  const SpacingTokens._();

  /// Base unit (4px) - Foundation for all spacing
  static const double base = 4.0;

  /// Extra extra small spacing (2px)
  static const double xxs = base * 0.5;

  /// Extra small spacing (4px)
  static const double xs = base * 1;

  /// Small spacing (8px)
  static const double s = base * 2;

  /// Medium spacing (12px)
  static const double m = base * 3;

  /// Large spacing (16px)
  static const double l = base * 4;

  /// Extra large spacing (20px)
  static const double xl = base * 5;

  /// Extra extra large spacing (24px)
  static const double xxl = base * 6;

  /// Extra extra extra large spacing (32px)
  static const double xxxl = base * 8;

  /// Gutter spacing (48px) - For major layout sections
  static const double gutter = base * 12;
}

/// Design Tokens - Dimensions
///
/// Provides consistent sizing for UI components.
class DimensionTokens {
  const DimensionTokens._();

  /// Icon sizes
  static const double iconXs = 12.0;
  static const double iconS = 16.0;
  static const double iconM = 20.0;
  static const double iconL = 24.0;
  static const double iconXl = 32.0;
  static const double iconXxl = 48.0;

  /// Button heights
  static const double buttonS = 28.0;
  static const double buttonM = 32.0;
  static const double buttonL = 36.0;
  static const double buttonXl = 40.0;

  /// Button minimum width
  static const double buttonMinWidth = 56.0;

  /// Input field heights
  static const double inputS = 32.0;
  static const double inputM = 40.0;
  static const double inputL = 48.0;

  /// Border radius values
  static const double radiusXs = 2.0;
  static const double radiusS = 4.0;
  static const double radiusM = 6.0;
  static const double radiusL = 8.0;
  static const double radiusXl = 12.0;
  static const double radiusXxl = 16.0;
  static const double radiusFull = 999.0; // For pills/circular elements

  /// Card dimensions
  static const double cardMinHeight = 80.0;
  static const double cardMaxWidth = 600.0;

  /// Dialog dimensions
  static const double dialogMinWidth = 280.0;
  static const double dialogMaxWidth = 560.0;
  static const double dialogMinHeight = 180.0;

  /// Layout constraints
  static const double maxContentWidth = 1200.0;
  static const double sidebarWidth = 280.0;
  static const double appBarHeight = 56.0;
}
