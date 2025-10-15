/// Controller interfaces for state management in UI components
library alouette_ui.state.controllers;

import 'dart:async';

/// Base interface for all UI controllers
abstract class IController {
  /// Whether the controller is currently disposed
  bool get isDisposed;

  /// Dispose of resources when the controller is no longer needed
  void dispose();
}

/// Base interface for controllers that manage loading states
abstract class ILoadingController extends IController {
  /// Whether an operation is currently in progress
  bool get isLoading;

  /// Stream of loading state changes
  Stream<bool> get loadingStream;
}

/// Base interface for controllers that can handle errors
abstract class IErrorController extends IController {
  /// Current error message, if any
  String? get errorMessage;

  /// Stream of error changes
  Stream<String?> get errorStream;

  /// Clear the current error
  void clearError();
}

/// Combined interface for controllers with loading and error handling
abstract class IStateController
    implements ILoadingController, IErrorController {
  /// Whether the controller is in a ready state (not loading, no errors)
  bool get isReady => !isLoading && errorMessage == null;

  /// Stream of ready state changes
  Stream<bool> get readyStream;
}

/// Interface for text input controllers
abstract class ITextController extends IController {
  /// Current text value
  String get text;

  /// Set the text value
  set text(String value);

  /// Stream of text changes
  Stream<String> get textStream;

  /// Whether the text is valid
  bool get isValid;

  /// Stream of validation state changes
  Stream<bool> get validationStream;

  /// Clear the text
  void clear();
}

/// Interface for selection controllers (like language selection)
abstract class ISelectionController<T> extends IController {
  /// Currently selected items
  List<T> get selectedItems;

  /// Stream of selection changes
  Stream<List<T>> get selectionStream;

  /// Whether an item is currently selected
  bool isSelected(T item);

  /// Select an item
  void select(T item);

  /// Deselect an item
  void deselect(T item);

  /// Toggle selection of an item
  void toggle(T item);

  /// Clear all selections
  void clearSelection();

  /// Select multiple items
  void selectMultiple(List<T> items);
}

/// Interface for translation controllers
abstract class ITranslationController extends IStateController {
  /// Input text to translate
  String get inputText;

  /// Set input text
  set inputText(String value);

  /// Selected source language
  String? get sourceLanguage;

  /// Selected target languages
  List<String> get targetLanguages;

  /// Translation results
  Map<String, String> get translations;

  /// Stream of translation results
  Stream<Map<String, String>> get translationStream;

  /// Set source language
  void setSourceLanguage(String? languageCode);

  /// Set target languages
  void setTargetLanguages(List<String> languageCodes);

  /// Perform translation
  Future<void> translate();

  /// Clear translations
  void clearTranslations();
}

/// Interface for TTS controllers
abstract class ITTSController extends IStateController {
  /// Current TTS text
  String get text;

  /// Set TTS text
  set text(String value);

  /// Current voice/language
  String? get selectedVoice;

  /// Available voices
  List<String> get availableVoices;

  /// Whether TTS is currently speaking
  bool get isSpeaking;

  /// Whether TTS is paused
  bool get isPaused;

  /// Current speech rate (1.0 = normal speed)
  double get speechRate;

  /// Current speech pitch (1.0 = normal pitch)
  double get speechPitch;

  /// Current speech volume (1.0 = 100%)
  double get speechVolume;

  /// Stream of speaking state changes
  Stream<bool> get speakingStream;

  /// Stream of paused state changes
  Stream<bool> get pausedStream;

  /// Current language code (e.g., 'zh-CN', 'en-US')
  String? get languageCode;

  /// Set the voice/language
  void setVoice(String voiceId);

  /// Set language code for TTS
  void setLanguageCode(String? languageCode);

  /// Set speech parameters
  void setSpeechRate(double rate);
  void setSpeechPitch(double pitch);
  void setSpeechVolume(double volume);

  /// TTS control methods
  Future<void> speak();

  /// Speak with explicit language (preferred when language is known)
  Future<void> speakWithLanguage(String languageCode);
  Future<void> pause();
  Future<void> resume();
  Future<void> stop();
}

/// Interface for search controllers
abstract class ISearchController extends IStateController {
  /// Current search query
  String get query;

  /// Set search query
  set query(String value);

  /// Search results
  List<dynamic> get results;

  /// Stream of search results
  Stream<List<dynamic>> get resultsStream;

  /// Whether there are more results to load
  bool get hasMoreResults;

  /// Perform search
  Future<void> search();

  /// Load more results
  Future<void> loadMore();

  /// Clear search
  void clearSearch();
}

/// Interface for form controllers
abstract class IFormController extends IStateController {
  /// All form field values
  Map<String, dynamic> get values;

  /// Stream of form value changes
  Stream<Map<String, dynamic>> get valuesStream;

  /// Whether the form is valid
  bool get isFormValid;

  /// Stream of form validation changes
  Stream<bool> get formValidationStream;

  /// Field validation errors
  Map<String, String> get fieldErrors;

  /// Stream of field error changes
  Stream<Map<String, String>> get fieldErrorsStream;

  /// Get a specific field value
  T? getValue<T>(String fieldName);

  /// Set a specific field value
  void setValue(String fieldName, dynamic value);

  /// Validate a specific field
  bool validateField(String fieldName);

  /// Validate the entire form
  bool validateForm();

  /// Reset the form
  void reset();

  /// Submit the form
  Future<void> submit();
}
