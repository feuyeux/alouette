/// Alouette UI Shared Library
///
/// A comprehensive Flutter UI library providing reusable components,
/// services, and utilities for all Alouette applications.
///
/// Features:
/// - Atomic Design Component Architecture (Atoms, Molecules, Organisms)
/// - Design Token System for consistent styling
/// - Service Architecture with Dependency Injection
/// - Unified State Management Controllers
/// - TTS and Translation Service Integration
library alouette_ui;

// Core Services
export 'src/services/core/service_locator.dart';
export 'src/services/core/service_manager.dart';
export 'src/services/core/service_configuration.dart';
export 'src/services/core/service_health_monitor.dart';
export 'src/services/core/configuration_manager.dart';
export 'src/services/core/configuration_migration.dart';
export 'src/services/core/logging_service.dart';

// Note: Service interfaces and implementations have been removed.
// ServiceManager now uses direct library types (alouette_lib_tts.TTSService, alouette_lib_trans.TranslationService)
// for better simplicity and maintainability.

// Design Tokens
export 'src/tokens/color_tokens.dart';
export 'src/tokens/dimension_tokens.dart';
export 'src/tokens/typography_tokens.dart';
export 'src/tokens/motion_tokens.dart';
export 'src/tokens/elevation_tokens.dart';
export 'src/tokens/effect_tokens.dart';
export 'src/tokens/app_tokens.dart';

// Atomic Design Component Architecture
export 'src/components/atoms/atoms.dart';
export 'src/components/molecules/molecules.dart';
export 'src/components/organisms/organisms.dart';

// State Management
export 'src/state/state.dart';

// Constants
export 'src/constants/ui_constants.dart';
export 'src/constants/language_constants.dart';

// Themes and Theme Management
export 'src/themes/app_theme.dart';
export 'src/services/theme_service.dart';

// Widgets (selected existing widgets)

export 'src/widgets/config_status_widget.dart'; // Includes both ConfigStatusWidget and TranslationStatusWidget

// Removed: export 'src/widgets/language_selector.dart' - Use components/molecules/language_selector.dart instead
export 'src/widgets/custom_app_bar.dart';
export 'src/widgets/custom_button.dart';
export 'src/widgets/custom_card.dart';
export 'src/widgets/custom_dropdown.dart';
export 'src/widgets/custom_text_field.dart';
export 'src/widgets/translation_input_widget.dart';
export 'src/widgets/translation_result_widget.dart';
export 'src/widgets/platform_info_widget.dart';

// Removed: export 'src/widgets/tts_control_widget.dart' - Use components/organisms/tts_control_panel.dart instead
// Removed: export 'src/widgets/tts_input_widget.dart' - Use refactored TTSInputSection instead
export 'src/widgets/tts_status_card.dart';

// Models
export 'src/models/app_configuration.dart';
export 'src/models/unified_error.dart';

// Error Handling Components
export 'src/components/error/error_display_widget.dart';
export 'src/core/errors/alouette_error.dart';
export 'src/core/errors/error_handler.dart';

// Splash and Initialization
export 'src/widgets/splash_screen.dart';
export 'src/core/app_initialization.dart';

// Dialogs
export 'src/dialogs/llm_config_dialog.dart';
export 'src/dialogs/tts_config_dialog.dart';

// Utilities
export 'src/utils/validation_utils.dart';
export 'src/utils/error_handler.dart';
export 'src/utils/ui_utils.dart';
export 'src/utils/emoji_flag_style.dart';
export 'src/utils/logger_config.dart';
export 'src/utils/about_helper.dart';

// Translation Components (new refactored widgets)
export 'src/widgets/translation/translation_text_input.dart';
export 'src/widgets/translation/language_selection_section.dart';
export 'src/widgets/translation/translation_action_button.dart';
export 'src/widgets/translation/translation_page_view.dart'
    show TranslationPageView, showTranslationConfigDialog;

// Pages
export 'src/pages/about_page.dart';

// Note: widgets/configuration/ directory has been removed (redundant)
