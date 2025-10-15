import 'package:flutter/material.dart';

import '../tokens/color_tokens.dart';
import '../tokens/typography_tokens.dart';
import '../tokens/dimension_tokens.dart';

/// Theme modes supported by the application
enum AlouetteThemeMode { light, dark, system }

/// Theme service for managing application themes and design tokens
class ThemeService extends ChangeNotifier {
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal();

  AlouetteThemeMode _themeMode = AlouetteThemeMode.system;
  bool _useCustomColors = false;
  Color _customPrimaryColor = ColorTokens.primary;

  /// Current theme mode
  AlouetteThemeMode get themeMode => _themeMode;

  /// Whether custom colors are enabled
  bool get useCustomColors => _useCustomColors;

  /// Custom primary color
  Color get customPrimaryColor => _customPrimaryColor;

  /// Initialize the theme service
  Future<void> initialize() async {
    // Load saved theme preferences if any
    // For now, just use defaults
    _updateSystemUI();
  }

  /// Set theme mode
  void setThemeMode(AlouetteThemeMode mode) {
    if (_themeMode != mode) {
      _themeMode = mode;
      _updateSystemUI();
      notifyListeners();
    }
  }

  /// Enable/disable custom colors
  void setUseCustomColors(bool use) {
    if (_useCustomColors != use) {
      _useCustomColors = use;
      notifyListeners();
    }
  }

  /// Set custom primary color
  void setCustomPrimaryColor(Color color) {
    if (_customPrimaryColor != color) {
      _customPrimaryColor = color;
      if (_useCustomColors) {
        notifyListeners();
      }
    }
  }

  /// Get the current brightness based on theme mode and system settings
  Brightness getCurrentBrightness(BuildContext context) {
    switch (_themeMode) {
      case AlouetteThemeMode.light:
        return Brightness.light;
      case AlouetteThemeMode.dark:
        return Brightness.dark;
      case AlouetteThemeMode.system:
        return MediaQuery.of(context).platformBrightness;
    }
  }

  /// Get light theme with current customizations
  ThemeData getLightTheme() {
    final primaryColor = _useCustomColors
        ? _customPrimaryColor
        : ColorTokens.primary;

    return ThemeData(
      colorScheme: _buildLightColorScheme(primaryColor),
      useMaterial3: true,
      typography: _buildTypography(),
      appBarTheme: _buildAppBarTheme(true),
      cardTheme: _buildCardTheme(true),
      inputDecorationTheme: _buildInputDecorationTheme(true),
      elevatedButtonTheme: _buildElevatedButtonTheme(true, primaryColor),
      textButtonTheme: _buildTextButtonTheme(true, primaryColor),
      iconButtonTheme: _buildIconButtonTheme(true),
      floatingActionButtonTheme: _buildFloatingActionButtonTheme(primaryColor),
      dividerTheme: _buildDividerTheme(true),
      snackBarTheme: _buildSnackBarTheme(true),
      pageTransitionsTheme: _buildPageTransitionsTheme(),
      extensions: [_buildCustomThemeExtension(true, primaryColor)],
    );
  }

  /// Get dark theme with current customizations
  ThemeData getDarkTheme() {
    final primaryColor = _useCustomColors
        ? _customPrimaryColor
        : ColorTokens.darkPrimary;

    return ThemeData(
      colorScheme: _buildDarkColorScheme(primaryColor),
      useMaterial3: true,
      typography: _buildTypography(),
      scaffoldBackgroundColor: ColorTokens.darkBackground,
      appBarTheme: _buildAppBarTheme(false),
      cardTheme: _buildCardTheme(false),
      inputDecorationTheme: _buildInputDecorationTheme(false),
      elevatedButtonTheme: _buildElevatedButtonTheme(false, primaryColor),
      textButtonTheme: _buildTextButtonTheme(false, primaryColor),
      iconButtonTheme: _buildIconButtonTheme(false),
      floatingActionButtonTheme: _buildFloatingActionButtonTheme(primaryColor),
      dividerTheme: _buildDividerTheme(false),
      snackBarTheme: _buildSnackBarTheme(false),
      pageTransitionsTheme: _buildPageTransitionsTheme(),
      extensions: [_buildCustomThemeExtension(false, primaryColor)],
    );
  }

  /// Build light color scheme
  ColorScheme _buildLightColorScheme(Color primaryColor) {
    return ColorScheme.light(
      primary: primaryColor,
      onPrimary: ColorTokens.onPrimary,
      primaryContainer: ColorTokens.primaryContainer,
      onPrimaryContainer: ColorTokens.onPrimaryContainer,
      secondary: ColorTokens.secondary,
      onSecondary: ColorTokens.onSecondary,
      secondaryContainer: ColorTokens.secondaryContainer,
      onSecondaryContainer: ColorTokens.onSecondaryContainer,
      tertiary: ColorTokens.tertiary,
      onTertiary: ColorTokens.onTertiary,
      tertiaryContainer: ColorTokens.tertiaryContainer,
      onTertiaryContainer: ColorTokens.onTertiaryContainer,
      error: ColorTokens.error,
      onError: ColorTokens.onError,
      errorContainer: ColorTokens.errorContainer,
      onErrorContainer: ColorTokens.onErrorContainer,
      surface: ColorTokens.surface,
      onSurface: ColorTokens.onSurface,
      surfaceContainerHighest: ColorTokens.surfaceVariant,
      onSurfaceVariant: ColorTokens.onSurfaceVariant,
      outline: ColorTokens.outline,
      outlineVariant: ColorTokens.outlineVariant,
    );
  }

  /// Build dark color scheme
  ColorScheme _buildDarkColorScheme(Color primaryColor) {
    return ColorScheme.dark(
      primary: primaryColor,
      onPrimary: ColorTokens.darkOnPrimary,
      primaryContainer: ColorTokens.darkPrimaryContainer,
      onPrimaryContainer: ColorTokens.darkOnPrimaryContainer,
      secondary: ColorTokens.darkSecondary,
      onSecondary: ColorTokens.darkOnSecondary,
      secondaryContainer: ColorTokens.darkSecondaryContainer,
      onSecondaryContainer: ColorTokens.darkOnSecondaryContainer,
      tertiary: ColorTokens.darkTertiary,
      onTertiary: ColorTokens.darkOnTertiary,
      tertiaryContainer: ColorTokens.darkTertiaryContainer,
      onTertiaryContainer: ColorTokens.darkOnTertiaryContainer,
      error: ColorTokens.darkError,
      onError: ColorTokens.darkOnError,
      errorContainer: ColorTokens.darkErrorContainer,
      onErrorContainer: ColorTokens.darkOnErrorContainer,
      surface: ColorTokens.darkSurface,
      onSurface: ColorTokens.darkOnSurface,
      surfaceContainerHighest: ColorTokens.darkSurfaceVariant,
      onSurfaceVariant: ColorTokens.darkOnSurfaceVariant,
      outline: ColorTokens.darkOutline,
      outlineVariant: ColorTokens.darkOutlineVariant,
    );
  }

  /// Build typography theme
  Typography _buildTypography() {
    return Typography.material2021(platform: TargetPlatform.android);
  }

  /// Build app bar theme
  AppBarTheme _buildAppBarTheme(bool isLight) {
    return AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: isLight ? ColorTokens.surface : ColorTokens.darkSurface,
      foregroundColor: isLight
          ? ColorTokens.onSurface
          : ColorTokens.darkOnSurface,
      shadowColor: ColorTokens.shadow,
      titleTextStyle: TypographyTokens.titleLargeStyle.copyWith(
        color: isLight ? ColorTokens.onSurface : ColorTokens.darkOnSurface,
      ),
      iconTheme: IconThemeData(
        color: isLight ? ColorTokens.onSurface : ColorTokens.darkOnSurface,
        size: DimensionTokens.iconL,
      ),
    );
  }

  /// Build card theme
  CardThemeData _buildCardTheme(bool isLight) {
    return CardThemeData(
      elevation: 2,
      shadowColor: ColorTokens.shadow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DimensionTokens.radiusXl),
      ),
      color: isLight ? ColorTokens.surface : ColorTokens.darkSurface,
      clipBehavior: Clip.antiAlias,
    );
  }

  /// Build input decoration theme
  InputDecorationTheme _buildInputDecorationTheme(bool isLight) {
    final borderColor = isLight ? ColorTokens.outline : ColorTokens.darkOutline;
    final fillColor = isLight
        ? ColorTokens.surfaceVariant
        : ColorTokens.darkSurfaceVariant;

    return InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DimensionTokens.radiusL),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DimensionTokens.radiusL),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DimensionTokens.radiusL),
        borderSide: BorderSide(
          color: _useCustomColors ? _customPrimaryColor : ColorTokens.primary,
          width: 2,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.l,
        vertical: SpacingTokens.m,
      ),
      filled: true,
      fillColor: fillColor,
      isDense: false,
      hintStyle: TypographyTokens.bodyMediumStyle.copyWith(
        color: isLight
            ? ColorTokens.onSurfaceVariant
            : ColorTokens.darkOnSurfaceVariant,
      ),
    );
  }

  /// Build elevated button theme
  ElevatedButtonThemeData _buildElevatedButtonTheme(
    bool isLight,
    Color primaryColor,
  ) {
    return ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(primaryColor),
        foregroundColor: WidgetStateProperty.all(ColorTokens.onPrimary),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DimensionTokens.radiusL),
          ),
        ),
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(
            horizontal: SpacingTokens.xl,
            vertical: SpacingTokens.m,
          ),
        ),
        elevation: WidgetStateProperty.all(2),
        shadowColor: WidgetStateProperty.all(ColorTokens.shadow),
        minimumSize: WidgetStateProperty.all(
          const Size(DimensionTokens.buttonMinWidth, DimensionTokens.buttonL),
        ),
        textStyle: WidgetStateProperty.all(TypographyTokens.labelLargeStyle),
      ),
    );
  }

  /// Build text button theme
  TextButtonThemeData _buildTextButtonTheme(bool isLight, Color primaryColor) {
    return TextButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.all(primaryColor),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DimensionTokens.radiusM),
          ),
        ),
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(
            horizontal: SpacingTokens.l,
            vertical: SpacingTokens.s,
          ),
        ),
        textStyle: WidgetStateProperty.all(TypographyTokens.labelLargeStyle),
      ),
    );
  }

  /// Build icon button theme
  IconButtonThemeData _buildIconButtonTheme(bool isLight) {
    return IconButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.all(
          isLight ? ColorTokens.onSurface : ColorTokens.darkOnSurface,
        ),
        backgroundColor: WidgetStateProperty.all(Colors.transparent),
        overlayColor: WidgetStateProperty.all(ColorTokens.surfaceHover),
        iconSize: WidgetStateProperty.all(DimensionTokens.iconL),
      ),
    );
  }

  /// Build floating action button theme
  FloatingActionButtonThemeData _buildFloatingActionButtonTheme(
    Color primaryColor,
  ) {
    return FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: ColorTokens.onPrimary,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DimensionTokens.radiusXl),
      ),
    );
  }

  /// Build divider theme
  DividerThemeData _buildDividerTheme(bool isLight) {
    return DividerThemeData(
      color: isLight ? ColorTokens.outline : ColorTokens.darkOutline,
      thickness: 1,
      space: SpacingTokens.l,
    );
  }

  /// Build snackbar theme
  SnackBarThemeData _buildSnackBarTheme(bool isLight) {
    return SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: isLight ? ColorTokens.gray800 : ColorTokens.gray200,
      contentTextStyle: TypographyTokens.bodyMediumStyle.copyWith(
        color: isLight ? ColorTokens.gray100 : ColorTokens.gray800,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DimensionTokens.radiusM),
      ),
    );
  }

  /// Build page transitions theme
  PageTransitionsTheme _buildPageTransitionsTheme() {
    return const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
      },
    );
  }

  /// Build custom theme extension
  AlouetteThemeExtension _buildCustomThemeExtension(
    bool isLight,
    Color primaryColor,
  ) {
    return AlouetteThemeExtension(
      success: ColorTokens.success,
      onSuccess: ColorTokens.onSuccess,
      successContainer: ColorTokens.successContainer,
      onSuccessContainer: ColorTokens.onSuccessContainer,
      warning: ColorTokens.warning,
      onWarning: ColorTokens.onWarning,
      warningContainer: ColorTokens.warningContainer,
      onWarningContainer: ColorTokens.onWarningContainer,
      info: ColorTokens.info,
      onInfo: ColorTokens.onInfo,
      infoContainer: ColorTokens.infoContainer,
      onInfoContainer: ColorTokens.onInfoContainer,
      scrim: ColorTokens.scrim,
      backdrop: ColorTokens.backdrop,
      shadow: ColorTokens.shadow,
      shadowStrong: ColorTokens.shadowStrong,
    );
  }

  /// Update system UI overlay style based on current theme
  void _updateSystemUI() {
    // This would be called when theme changes to update status bar, etc.
    // Implementation depends on current theme mode and platform
  }
}

/// Custom theme extension for additional colors not covered by Material 3
@immutable
class AlouetteThemeExtension extends ThemeExtension<AlouetteThemeExtension> {
  const AlouetteThemeExtension({
    required this.success,
    required this.onSuccess,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.warning,
    required this.onWarning,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.info,
    required this.onInfo,
    required this.infoContainer,
    required this.onInfoContainer,
    required this.scrim,
    required this.backdrop,
    required this.shadow,
    required this.shadowStrong,
  });

  final Color success;
  final Color onSuccess;
  final Color successContainer;
  final Color onSuccessContainer;
  final Color warning;
  final Color onWarning;
  final Color warningContainer;
  final Color onWarningContainer;
  final Color info;
  final Color onInfo;
  final Color infoContainer;
  final Color onInfoContainer;
  final Color scrim;
  final Color backdrop;
  final Color shadow;
  final Color shadowStrong;

  @override
  AlouetteThemeExtension copyWith({
    Color? success,
    Color? onSuccess,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? warning,
    Color? onWarning,
    Color? warningContainer,
    Color? onWarningContainer,
    Color? info,
    Color? onInfo,
    Color? infoContainer,
    Color? onInfoContainer,
    Color? scrim,
    Color? backdrop,
    Color? shadow,
    Color? shadowStrong,
  }) {
    return AlouetteThemeExtension(
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      successContainer: successContainer ?? this.successContainer,
      onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
      warning: warning ?? this.warning,
      onWarning: onWarning ?? this.onWarning,
      warningContainer: warningContainer ?? this.warningContainer,
      onWarningContainer: onWarningContainer ?? this.onWarningContainer,
      info: info ?? this.info,
      onInfo: onInfo ?? this.onInfo,
      infoContainer: infoContainer ?? this.infoContainer,
      onInfoContainer: onInfoContainer ?? this.onInfoContainer,
      scrim: scrim ?? this.scrim,
      backdrop: backdrop ?? this.backdrop,
      shadow: shadow ?? this.shadow,
      shadowStrong: shadowStrong ?? this.shadowStrong,
    );
  }

  @override
  AlouetteThemeExtension lerp(
    ThemeExtension<AlouetteThemeExtension>? other,
    double t,
  ) {
    if (other is! AlouetteThemeExtension) {
      return this;
    }
    return AlouetteThemeExtension(
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      successContainer: Color.lerp(
        successContainer,
        other.successContainer,
        t,
      )!,
      onSuccessContainer: Color.lerp(
        onSuccessContainer,
        other.onSuccessContainer,
        t,
      )!,
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      warningContainer: Color.lerp(
        warningContainer,
        other.warningContainer,
        t,
      )!,
      onWarningContainer: Color.lerp(
        onWarningContainer,
        other.onWarningContainer,
        t,
      )!,
      info: Color.lerp(info, other.info, t)!,
      onInfo: Color.lerp(onInfo, other.onInfo, t)!,
      infoContainer: Color.lerp(infoContainer, other.infoContainer, t)!,
      onInfoContainer: Color.lerp(onInfoContainer, other.onInfoContainer, t)!,
      scrim: Color.lerp(scrim, other.scrim, t)!,
      backdrop: Color.lerp(backdrop, other.backdrop, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      shadowStrong: Color.lerp(shadowStrong, other.shadowStrong, t)!,
    );
  }
}

/// Extension to easily access custom theme colors
extension AlouetteThemeExtensionGetter on ThemeData {
  AlouetteThemeExtension get alouetteColors =>
      extension<AlouetteThemeExtension>()!;
}
