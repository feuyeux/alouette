import 'package:flutter/material.dart';
import '../tokens/color_tokens.dart';
import '../tokens/typography_tokens.dart';
import '../tokens/dimension_tokens.dart';

/// Splash screen shown during app initialization
class SplashScreen extends StatelessWidget {
  final String? message;
  final double? progress;

  const SplashScreen({
    super.key,
    this.message,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App icon or logo
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: ColorTokens.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.translate,
                size: 64,
                color: ColorTokens.primary,
              ),
            ),
            SizedBox(height: SpacingTokens.xl),
            
            // App name
            Text(
              'Alouette',
              style: TypographyTokens.headlineLargeStyle.copyWith(
                color: ColorTokens.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: SpacingTokens.xs),
            
            Text(
              'AI Translation & Text-to-Speech',
              style: TypographyTokens.bodyMediumStyle.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: SpacingTokens.xl),
            
            // Progress indicator
            if (progress != null)
              SizedBox(
                width: 200,
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: ColorTokens.primary.withValues(alpha: 0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    ColorTokens.primary,
                  ),
                ),
              )
            else
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(ColorTokens.primary),
              ),
            
            if (message != null) ...[
              SizedBox(height: SpacingTokens.m),
              Text(
                message!,
                style: TypographyTokens.bodySmallStyle.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Error screen shown when initialization fails
class InitializationErrorScreen extends StatelessWidget {
  final Object? error;
  final VoidCallback onRetry;

  const InitializationErrorScreen({
    super.key,
    this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(SpacingTokens.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 80,
                color: Theme.of(context).colorScheme.error,
              ),
              SizedBox(height: SpacingTokens.l),
              
              Text(
                'Initialization Failed',
                style: TypographyTokens.headlineMediumStyle.copyWith(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: SpacingTokens.m),
              
              Text(
                error?.toString() ?? 'Unknown error occurred',
                style: TypographyTokens.bodyMediumStyle,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: SpacingTokens.xl),
              
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorTokens.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: SpacingTokens.xl,
                    vertical: SpacingTokens.m,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
