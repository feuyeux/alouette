/// Controller factory for creating and managing UI controllers
library alouette_ui.state.controllers.factory;

import 'package:flutter/widgets.dart';
import 'package:alouette_lib_trans/alouette_lib_trans.dart' as trans_lib;

import '../../../alouette_ui.dart';

/// Factory for creating UI controllers with proper dependency injection
class ControllerFactory {
  static final ControllerFactory _instance = ControllerFactory._internal();
  factory ControllerFactory() => _instance;
  ControllerFactory._internal();

  /// Create a translation controller
  ITranslationController createTranslationController() {
    final translationService =
        ServiceLocator.get<trans_lib.TranslationService>();
    return TranslationController(translationService);
  }

  /// Create a TTS controller
  ITTSController createTTSController() {
    return TTSController();
  }

  /// Create a language selection controller
  ISelectionController<String> createLanguageSelectionController([
    List<String>? availableLanguages,
  ]) {
    final languages =
        availableLanguages ??
        [
          'en-US',
          'es-ES',
          'fr-FR',
          'de-DE',
          'it-IT',
          'pt-BR',
          'zh-CN',
          'ja-JP',
        ];
    return LanguageSelectionController(languages);
  }

  /// Create a form controller
  IFormController createFormController() {
    return FormController();
  }

  /// Create a search controller
  ISearchController createSearchController() {
    return SearchController();
  }

  /// Create a text controller with optional validation
  ITextController createTextController({bool Function(String)? validator}) {
    return ValidatedTextController(validator: validator) as ITextController;
  }
}

/// Text controller with validation support
class ValidatedTextController extends BaseTextController {
  final bool Function(String)? _validator;

  ValidatedTextController({bool Function(String)? validator})
    : _validator = validator;

  @override
  bool validateText(String text) {
    return _validator?.call(text) ?? true;
  }
}

/// Controller lifecycle management mixin
mixin ControllerLifecycle {
  final List<IController> _controllers = [];

  /// Register a controller for automatic disposal
  T registerController<T extends IController>(T controller) {
    _controllers.add(controller);
    return controller;
  }

  /// Dispose all registered controllers
  void disposeControllers() {
    for (final controller in _controllers) {
      if (!controller.isDisposed) {
        controller.dispose();
      }
    }
    _controllers.clear();
  }
}

/// Widget mixin for automatic controller management
mixin ControllerWidget {
  final ControllerFactory _controllerFactory = ControllerFactory();
  final List<IController> _managedControllers = [];

  /// Get the controller factory
  ControllerFactory get controllerFactory => _controllerFactory;

  /// Create and manage a controller
  T createController<T extends IController>(T Function() factory) {
    final controller = factory();
    _managedControllers.add(controller);
    return controller;
  }

  /// Create a translation controller
  ITranslationController createTranslationController() {
    return createController(
      () => _controllerFactory.createTranslationController(),
    );
  }

  /// Create a TTS controller
  ITTSController createTTSController() {
    return createController(() => _controllerFactory.createTTSController());
  }

  /// Create a language selection controller
  ISelectionController<String> createLanguageSelectionController([
    List<String>? availableLanguages,
  ]) {
    return createController(
      () => _controllerFactory.createLanguageSelectionController(
        availableLanguages,
      ),
    );
  }

  /// Create a form controller
  IFormController createFormController() {
    return createController(() => _controllerFactory.createFormController());
  }

  /// Create a search controller
  ISearchController createSearchController() {
    return createController(() => _controllerFactory.createSearchController());
  }

  /// Create a text controller
  ITextController createTextController({bool Function(String)? validator}) {
    return createController(
      () => _controllerFactory.createTextController(validator: validator),
    );
  }

  /// Dispose all managed controllers
  void disposeManagedControllers() {
    for (final controller in _managedControllers) {
      if (!controller.isDisposed) {
        controller.dispose();
      }
    }
    _managedControllers.clear();
  }
}

/// Convenient controller mixin for StatefulWidgets
mixin AutoControllerDisposal<T extends StatefulWidget> on State<T>
    implements ControllerWidget {
  @override
  final ControllerFactory _controllerFactory = ControllerFactory();
  @override
  final List<IController> _managedControllers = [];

  @override
  ControllerFactory get controllerFactory => _controllerFactory;

  @override
  T createController<T extends IController>(T Function() factory) {
    final controller = factory();
    _managedControllers.add(controller);
    return controller;
  }

  @override
  ITranslationController createTranslationController() {
    return createController(
      () => _controllerFactory.createTranslationController(),
    );
  }

  @override
  ITTSController createTTSController() {
    return createController(() => _controllerFactory.createTTSController());
  }

  @override
  ISelectionController<String> createLanguageSelectionController([
    List<String>? availableLanguages,
  ]) {
    return createController(
      () => _controllerFactory.createLanguageSelectionController(
        availableLanguages,
      ),
    );
  }

  @override
  IFormController createFormController() {
    return createController(() => _controllerFactory.createFormController());
  }

  @override
  ISearchController createSearchController() {
    return createController(() => _controllerFactory.createSearchController());
  }

  @override
  ITextController createTextController({bool Function(String)? validator}) {
    return createController(
      () => _controllerFactory.createTextController(validator: validator),
    );
  }

  @override
  void dispose() {
    disposeManagedControllers();
    super.dispose();
  }

  @override
  void disposeManagedControllers() {
    for (final controller in _managedControllers) {
      if (!controller.isDisposed) {
        controller.dispose();
      }
    }
    _managedControllers.clear();
  }
}
