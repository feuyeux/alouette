/// Base implementations for UI controllers
library alouette_ui.state.controllers.base;

import 'dart:async';

import 'interfaces.dart';

/// Base implementation for UI controllers
abstract class BaseController implements IController {
  bool _isDisposed = false;

  @override
  bool get isDisposed => _isDisposed;

  @override
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    onDispose();
  }

  /// Override this method to clean up resources
  void onDispose() {}

  /// Ensure the controller is not disposed before operations
  void ensureNotDisposed() {
    if (_isDisposed) {
      throw StateError('Controller has been disposed');
    }
  }
}

/// Base implementation for loading state management
abstract class BaseLoadingController extends BaseController
    implements ILoadingController {
  final StreamController<bool> _loadingController =
      StreamController<bool>.broadcast();
  bool _isLoading = false;

  @override
  bool get isLoading => _isLoading;

  @override
  Stream<bool> get loadingStream => _loadingController.stream;

  /// Set the loading state
  void setLoading(bool loading) {
    ensureNotDisposed();
    if (_isLoading != loading) {
      _isLoading = loading;
      _loadingController.add(loading);
    }
  }

  @override
  void onDispose() {
    _loadingController.close();
    super.onDispose();
  }
}

/// Base implementation for error state management
abstract class BaseErrorController extends BaseController
    implements IErrorController {
  final StreamController<String?> _errorController =
      StreamController<String?>.broadcast();
  String? _errorMessage;

  @override
  String? get errorMessage => _errorMessage;

  @override
  Stream<String?> get errorStream => _errorController.stream;

  @override
  void clearError() {
    ensureNotDisposed();
    if (_errorMessage != null) {
      _errorMessage = null;
      _errorController.add(null);
    }
  }

  /// Set an error message
  void setError(String error) {
    ensureNotDisposed();
    _errorMessage = error;
    _errorController.add(error);
  }

  /// Handle exceptions and set error state
  void handleException(Object exception, [StackTrace? stackTrace]) {
    ensureNotDisposed();
    setError(exception.toString());
  }

  @override
  void onDispose() {
    _errorController.close();
    super.onDispose();
  }
}

/// Base implementation for controllers with loading and error state
abstract class BaseStateController extends BaseController
    implements IStateController {
  final StreamController<bool> _loadingController =
      StreamController<bool>.broadcast();
  final StreamController<String?> _errorController =
      StreamController<String?>.broadcast();
  final StreamController<bool> _readyController =
      StreamController<bool>.broadcast();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  bool get isLoading => _isLoading;

  @override
  Stream<bool> get loadingStream => _loadingController.stream;

  @override
  String? get errorMessage => _errorMessage;

  @override
  Stream<String?> get errorStream => _errorController.stream;

  @override
  bool get isReady => !isLoading && errorMessage == null;

  @override
  Stream<bool> get readyStream => _readyController.stream;

  @override
  void clearError() {
    ensureNotDisposed();
    if (_errorMessage != null) {
      _errorMessage = null;
      _errorController.add(null);
      _updateReadyState();
    }
  }

  /// Set the loading state
  void setLoading(bool loading) {
    ensureNotDisposed();
    if (_isLoading != loading) {
      _isLoading = loading;
      _loadingController.add(loading);
      _updateReadyState();
    }
  }

  /// Set an error message
  void setError(String error) {
    ensureNotDisposed();
    _errorMessage = error;
    _errorController.add(error);
    _updateReadyState();
  }

  /// Handle exceptions and set error state
  void handleException(Object exception, [StackTrace? stackTrace]) {
    ensureNotDisposed();
    setError(exception.toString());
  }

  /// Execute an async operation with loading and error handling
  Future<T> executeAsync<T>(Future<T> Function() operation) async {
    ensureNotDisposed();

    try {
      setLoading(true);
      clearError();
      final result = await operation();
      return result;
    } catch (e, stackTrace) {
      handleException(e, stackTrace);
      rethrow;
    } finally {
      setLoading(false);
    }
  }

  void _updateReadyState() {
    _readyController.add(isReady);
  }

  @override
  void onDispose() {
    _loadingController.close();
    _errorController.close();
    _readyController.close();
    super.onDispose();
  }
}

/// Base implementation for text input controllers
abstract class BaseTextController extends BaseController
    implements ITextController {
  final StreamController<String> _textController =
      StreamController<String>.broadcast();
  final StreamController<bool> _validationController =
      StreamController<bool>.broadcast();
  String _text = '';

  @override
  String get text => _text;

  @override
  set text(String value) {
    ensureNotDisposed();
    if (_text != value) {
      _text = value;
      _textController.add(value);
      _validateAndNotify();
    }
  }

  @override
  Stream<String> get textStream => _textController.stream;

  @override
  bool get isValid => validateText(_text);

  @override
  Stream<bool> get validationStream => _validationController.stream;

  @override
  void clear() {
    text = '';
  }

  /// Override this method to implement custom validation
  bool validateText(String text) => true;

  void _validateAndNotify() {
    final valid = isValid;
    _validationController.add(valid);
  }

  @override
  void onDispose() {
    _textController.close();
    _validationController.close();
    super.onDispose();
  }
}

/// Base implementation for selection controllers
abstract class BaseSelectionController<T> extends BaseController
    implements ISelectionController<T> {
  final StreamController<List<T>> _selectionController =
      StreamController<List<T>>.broadcast();
  final List<T> _selectedItems = [];

  @override
  List<T> get selectedItems => List.unmodifiable(_selectedItems);

  @override
  Stream<List<T>> get selectionStream => _selectionController.stream;

  @override
  bool isSelected(T item) => _selectedItems.contains(item);

  @override
  void select(T item) {
    ensureNotDisposed();
    if (!_selectedItems.contains(item)) {
      _selectedItems.add(item);
      _notifySelectionChange();
    }
  }

  @override
  void deselect(T item) {
    ensureNotDisposed();
    if (_selectedItems.remove(item)) {
      _notifySelectionChange();
    }
  }

  @override
  void toggle(T item) {
    if (isSelected(item)) {
      deselect(item);
    } else {
      select(item);
    }
  }

  @override
  void clearSelection() {
    ensureNotDisposed();
    if (_selectedItems.isNotEmpty) {
      _selectedItems.clear();
      _notifySelectionChange();
    }
  }

  @override
  void selectMultiple(List<T> items) {
    ensureNotDisposed();
    bool changed = false;
    for (final item in items) {
      if (!_selectedItems.contains(item)) {
        _selectedItems.add(item);
        changed = true;
      }
    }
    if (changed) {
      _notifySelectionChange();
    }
  }

  void _notifySelectionChange() {
    _selectionController.add(selectedItems);
  }

  @override
  void onDispose() {
    _selectionController.close();
    super.onDispose();
  }
}

/// Protected method indicator for documentation
/// In Dart, we use underscore prefix for private methods
/// or simply document methods as "internal use only"
class Protected {
  const Protected();
}

/// Use this annotation to mark methods as internal
const protected = Protected();
