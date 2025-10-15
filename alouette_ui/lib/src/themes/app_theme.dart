import 'package:flutter/material.dart';
import '../tokens/color_tokens.dart';
import '../tokens/typography_tokens.dart';
import '../tokens/dimension_tokens.dart';
import '../tokens/motion_tokens.dart';
import '../tokens/elevation_tokens.dart';
import '../tokens/effect_tokens.dart';
import '../services/theme_service.dart';

/// App theme for Alouette applications
///
/// This class provides theme configurations using design tokens
/// for consistent styling across all applications.
class AppTheme {
  // Brand colors using design tokens
  static const Color primaryColor = ColorTokens.primary;
  static const Color secondaryColor = ColorTokens.secondary;
  static const Color accentColor = ColorTokens.tertiary;

  // Animation duration using motion tokens
  static const Duration animationDuration = MotionTokens.normal;

  /// Get light theme using design tokens
  ///
  /// For new applications, prefer using ThemeService.getLightTheme()
  /// which provides more customization options.
  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: ColorScheme.light(
        primary: ColorTokens.primary,
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
      ),
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: ElevationTokens.level0,
        backgroundColor: ColorTokens.surface,
        foregroundColor: ColorTokens.onSurface,
        shadowColor: ColorTokens.shadow,
        titleTextStyle: TypographyTokens.titleLargeStyle.copyWith(
          color: ColorTokens.onSurface,
        ),
        iconTheme: IconThemeData(
          color: ColorTokens.onSurface,
          size: DimensionTokens.iconL,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: ElevationTokens.level1,
        shadowColor: ColorTokens.shadow,
        shape: RoundedRectangleBorder(borderRadius: EffectTokens.radiusLarge),
        color: ColorTokens.surface,
        clipBehavior: Clip.antiAlias,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: EffectTokens.radiusMedium,
          borderSide: EffectTokens.borderDefault,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: EffectTokens.radiusMedium,
          borderSide: EffectTokens.borderDefault,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: EffectTokens.radiusMedium,
          borderSide: EffectTokens.borderPrimaryThick,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: SpacingTokens.l,
          vertical: SpacingTokens.m,
        ),
        filled: true,
        fillColor: ColorTokens.surfaceVariant,
        isDense: false,
        hintStyle: TypographyTokens.bodyMediumStyle.copyWith(
          color: ColorTokens.onSurfaceVariant,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorTokens.primary,
          foregroundColor: ColorTokens.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: EffectTokens.radiusMedium,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: SpacingTokens.xl,
            vertical: SpacingTokens.m,
          ),
          elevation: ElevationTokens.level1,
          shadowColor: ColorTokens.shadow,
          minimumSize: const Size(
            DimensionTokens.buttonMinWidth,
            DimensionTokens.buttonL,
          ),
          textStyle: TypographyTokens.labelLargeStyle,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ColorTokens.primary,
          shape: RoundedRectangleBorder(borderRadius: EffectTokens.radiusSmall),
          padding: const EdgeInsets.symmetric(
            horizontal: SpacingTokens.l,
            vertical: SpacingTokens.s,
          ),
          textStyle: TypographyTokens.labelLargeStyle,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: ColorTokens.onSurface,
          backgroundColor: Colors.transparent,
          hoverColor: ColorTokens.surfaceHover,
          iconSize: DimensionTokens.iconL,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: ColorTokens.primary,
        foregroundColor: ColorTokens.onPrimary,
        elevation: ElevationTokens.level3,
        shape: RoundedRectangleBorder(borderRadius: EffectTokens.radiusLarge),
      ),
      dividerTheme: DividerThemeData(
        color: ColorTokens.outline,
        thickness: 1,
        space: SpacingTokens.l,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ColorTokens.gray800,
        contentTextStyle: TypographyTokens.bodyMediumStyle.copyWith(
          color: ColorTokens.gray100,
        ),
        shape: RoundedRectangleBorder(borderRadius: EffectTokens.radiusSmall),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
      extensions: [
        AlouetteThemeExtension(
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
        ),
      ],
    );
  }

  /// Get dark theme using design tokens
  ///
  /// For new applications, prefer using ThemeService.getDarkTheme()
  /// which provides more customization options.
  static ThemeData get darkTheme {
    return ThemeData(
      colorScheme: ColorScheme.dark(
        primary: ColorTokens.darkPrimary,
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
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: ColorTokens.darkBackground,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: ElevationTokens.level0,
        backgroundColor: ColorTokens.darkSurface,
        foregroundColor: ColorTokens.darkOnSurface,
        shadowColor: ColorTokens.shadow,
        titleTextStyle: TypographyTokens.titleLargeStyle.copyWith(
          color: ColorTokens.darkOnSurface,
        ),
        iconTheme: IconThemeData(
          color: ColorTokens.darkOnSurface,
          size: DimensionTokens.iconL,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: ElevationTokens.level2,
        shadowColor: ColorTokens.shadowStrong,
        shape: RoundedRectangleBorder(borderRadius: EffectTokens.radiusLarge),
        color: ColorTokens.darkSurface,
        clipBehavior: Clip.antiAlias,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: EffectTokens.radiusMedium,
          borderSide: BorderSide(color: ColorTokens.darkOutline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: EffectTokens.radiusMedium,
          borderSide: BorderSide(color: ColorTokens.darkOutline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: EffectTokens.radiusMedium,
          borderSide: BorderSide(color: ColorTokens.darkPrimary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: SpacingTokens.l,
          vertical: SpacingTokens.m,
        ),
        filled: true,
        fillColor: ColorTokens.darkSurfaceVariant,
        isDense: false,
        hintStyle: TypographyTokens.bodyMediumStyle.copyWith(
          color: ColorTokens.darkOnSurfaceVariant,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorTokens.darkPrimary,
          foregroundColor: ColorTokens.darkOnPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: EffectTokens.radiusMedium,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: SpacingTokens.xl,
            vertical: SpacingTokens.m,
          ),
          elevation: ElevationTokens.level1,
          shadowColor: ColorTokens.shadowStrong,
          minimumSize: const Size(
            DimensionTokens.buttonMinWidth,
            DimensionTokens.buttonL,
          ),
          textStyle: TypographyTokens.labelLargeStyle,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ColorTokens.darkPrimary,
          shape: RoundedRectangleBorder(borderRadius: EffectTokens.radiusSmall),
          padding: const EdgeInsets.symmetric(
            horizontal: SpacingTokens.l,
            vertical: SpacingTokens.s,
          ),
          textStyle: TypographyTokens.labelLargeStyle,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: ColorTokens.darkOnSurface,
          backgroundColor: Colors.transparent,
          hoverColor: ColorTokens.darkOnSurface.withValues(alpha: 0.1),
          iconSize: DimensionTokens.iconL,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: ColorTokens.darkPrimary,
        foregroundColor: ColorTokens.darkOnPrimary,
        elevation: ElevationTokens.level3,
        shape: RoundedRectangleBorder(borderRadius: EffectTokens.radiusLarge),
      ),
      dividerTheme: DividerThemeData(
        color: ColorTokens.darkOutline,
        thickness: 1,
        space: SpacingTokens.l,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ColorTokens.gray200,
        contentTextStyle: TypographyTokens.bodyMediumStyle.copyWith(
          color: ColorTokens.gray800,
        ),
        shape: RoundedRectangleBorder(borderRadius: EffectTokens.radiusSmall),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
      extensions: [
        AlouetteThemeExtension(
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
        ),
      ],
    );
  }

  /// Create a theme service instance for advanced theme management
  ///
  /// This provides theme switching, customization, and persistence.
  static ThemeService createThemeService() {
    return ThemeService();
  }
}
