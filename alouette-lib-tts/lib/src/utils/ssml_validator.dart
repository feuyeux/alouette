import '../enums/tts_platform.dart';

/// Utility class for validating and processing SSML markup
class SSMLValidator {
  /// Supported SSML tags by platform
  static const Map<TTSPlatform, Set<String>> _supportedTags = {
    TTSPlatform.android: {
      'speak', 'p', 's', 'break', 'emphasis', 'prosody', 'say-as', 'sub',
      'phoneme', 'voice', 'lang', 'mark', 'audio'
    },
    TTSPlatform.ios: {
      'speak', 'p', 's', 'break', 'emphasis', 'prosody', 'say-as', 'sub',
      'phoneme', 'voice', 'lang', 'mark'
    },
    TTSPlatform.web: {
      'speak', 'p', 's', 'break', 'emphasis', 'prosody', 'say-as'
    },
    TTSPlatform.linux: {
      'speak', 'p', 's', 'break', 'emphasis', 'prosody', 'say-as', 'sub',
      'phoneme', 'voice', 'lang', 'mark', 'audio', 'express-as', 'mstts:express-as'
    },
    TTSPlatform.macos: {
      'speak', 'p', 's', 'break', 'emphasis', 'prosody', 'say-as', 'sub',
      'phoneme', 'voice', 'lang', 'mark', 'audio', 'express-as', 'mstts:express-as'
    },
    TTSPlatform.windows: {
      'speak', 'p', 's', 'break', 'emphasis', 'prosody', 'say-as', 'sub',
      'phoneme', 'voice', 'lang', 'mark', 'audio', 'express-as', 'mstts:express-as'
    },
  };

  /// Validates SSML markup for the target platform
  /// 
  /// [ssml] - The SSML markup to validate
  /// [platform] - Target platform for validation
  /// [strict] - Whether to use strict validation (throws on unsupported tags)
  /// Returns validation result with any issues found
  static SSMLValidationResult validateSSML(
    String ssml,
    TTSPlatform platform, {
    bool strict = false,
  }) {
    final issues = <SSMLValidationIssue>[];
    
    try {
      // 1. Check if SSML is well-formed XML
      final xmlIssues = _validateXMLStructure(ssml);
      issues.addAll(xmlIssues);

      // 2. Check for supported tags
      final tagIssues = _validateTags(ssml, platform, strict);
      issues.addAll(tagIssues);

      // 3. Validate SSML structure
      final structureIssues = _validateSSMLStructure(ssml);
      issues.addAll(structureIssues);

      // 4. Validate attributes
      final attributeIssues = _validateAttributes(ssml, platform);
      issues.addAll(attributeIssues);

      // 5. Check for platform-specific limitations
      final platformIssues = _validatePlatformSpecific(ssml, platform);
      issues.addAll(platformIssues);

      return SSMLValidationResult(
        isValid: issues.where((i) => i.severity == SSMLIssueSeverity.error).isEmpty,
        issues: issues,
      );
    } catch (e) {
      issues.add(SSMLValidationIssue(
        type: SSMLIssueType.malformedXML,
        severity: SSMLIssueSeverity.error,
        message: 'Failed to parse SSML: $e',
        position: 0,
      ));
      
      return SSMLValidationResult(
        isValid: false,
        issues: issues,
      );
    }
  }

  /// Sanitizes SSML for the target platform by removing unsupported elements
  /// 
  /// [ssml] - The SSML markup to sanitize
  /// [platform] - Target platform for sanitization
  /// Returns sanitized SSML markup
  static String sanitizeSSML(String ssml, TTSPlatform platform) {
    final supportedTags = _supportedTags[platform] ?? <String>{};
    
    // Remove unsupported tags while preserving their content
    String sanitized = ssml;
    
    // Find all XML tags
    final tagRegex = RegExp(r'<(/?)([a-zA-Z][a-zA-Z0-9:_-]*)[^>]*>');
    final matches = tagRegex.allMatches(ssml).toList().reversed;
    
    for (final match in matches) {
  final tagName = match.group(2)!.toLowerCase();
      
      if (!supportedTags.contains(tagName)) {
        // Remove the tag but keep the content
        sanitized = sanitized.replaceRange(match.start, match.end, '');
      }
    }
    
    return sanitized;
  }

  /// Wraps plain text in a basic SSML structure
  /// 
  /// [text] - Plain text to wrap
  /// [languageCode] - Language code for the speak element
  /// Returns SSML-wrapped text
  static String wrapInSSML(String text, {String? languageCode}) {
    final langAttr = languageCode != null ? ' xml:lang="$languageCode"' : '';
    return '<speak$langAttr>$text</speak>';
  }

  /// Extracts plain text from SSML markup
  /// 
  /// [ssml] - SSML markup to extract text from
  /// Returns plain text content
  static String extractTextFromSSML(String ssml) {
    // Remove all XML tags
    return ssml.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }

  /// Validates XML structure of SSML
  static List<SSMLValidationIssue> _validateXMLStructure(String ssml) {
    final issues = <SSMLValidationIssue>[];
    
    // Check for basic XML well-formedness
    final tagStack = <String>[];
    final tagRegex = RegExp(r'<(/?)([a-zA-Z][a-zA-Z0-9:_-]*)[^>]*(/?)>');
    
    for (final match in tagRegex.allMatches(ssml)) {
      final isClosing = match.group(1) == '/';
      final tagName = match.group(2)!.toLowerCase();
      final isSelfClosing = match.group(3) == '/';
      
      if (isClosing) {
        if (tagStack.isEmpty) {
          issues.add(SSMLValidationIssue(
            type: SSMLIssueType.malformedXML,
            severity: SSMLIssueSeverity.error,
            message: 'Unexpected closing tag: $tagName',
            position: match.start,
          ));
        } else if (tagStack.last != tagName) {
          issues.add(SSMLValidationIssue(
            type: SSMLIssueType.malformedXML,
            severity: SSMLIssueSeverity.error,
            message: 'Mismatched closing tag: expected ${tagStack.last}, found $tagName',
            position: match.start,
          ));
        } else {
          tagStack.removeLast();
        }
      } else if (!isSelfClosing) {
        tagStack.add(tagName);
      }
    }
    
    if (tagStack.isNotEmpty) {
      issues.add(SSMLValidationIssue(
        type: SSMLIssueType.malformedXML,
        severity: SSMLIssueSeverity.error,
        message: 'Unclosed tags: ${tagStack.join(', ')}',
        position: ssml.length,
      ));
    }
    
    return issues;
  }

  /// Validates SSML tags for platform support
  static List<SSMLValidationIssue> _validateTags(
    String ssml,
    TTSPlatform platform,
    bool strict,
  ) {
    final issues = <SSMLValidationIssue>[];
    final supportedTags = _supportedTags[platform] ?? <String>{};
    
    final tagRegex = RegExp(r'<(/?)([a-zA-Z][a-zA-Z0-9:_-]*)[^>]*>');
    
    for (final match in tagRegex.allMatches(ssml)) {
      final tagName = match.group(2)!.toLowerCase();
      
      if (!supportedTags.contains(tagName)) {
        final severity = strict ? SSMLIssueSeverity.error : SSMLIssueSeverity.warning;
        issues.add(SSMLValidationIssue(
          type: SSMLIssueType.unsupportedTag,
          severity: severity,
          message: 'Tag "$tagName" is not supported on ${platform.platformName}',
          position: match.start,
          tagName: tagName,
        ));
      }
    }
    
    return issues;
  }

  /// Validates SSML document structure
  static List<SSMLValidationIssue> _validateSSMLStructure(String ssml) {
    final issues = <SSMLValidationIssue>[];
    
    // Check for required speak element
    if (!ssml.contains(RegExp(r'<speak[^>]*>'))) {
      issues.add(SSMLValidationIssue(
        type: SSMLIssueType.missingRequiredElement,
        severity: SSMLIssueSeverity.error,
        message: 'SSML document must contain a <speak> root element',
        position: 0,
      ));
    }
    
    // Check for multiple speak elements
    final speakMatches = RegExp(r'<speak[^>]*>').allMatches(ssml);
    if (speakMatches.length > 1) {
      issues.add(SSMLValidationIssue(
        type: SSMLIssueType.invalidStructure,
        severity: SSMLIssueSeverity.error,
        message: 'SSML document should contain only one <speak> root element',
        position: speakMatches.elementAt(1).start,
      ));
    }
    
    return issues;
  }

  /// Validates SSML attributes
  static List<SSMLValidationIssue> _validateAttributes(String ssml, TTSPlatform platform) {
    final issues = <SSMLValidationIssue>[];
    
    // Validate prosody attributes
    final prosodyRegex = RegExp(r'<prosody[^>]*>');
    for (final match in prosodyRegex.allMatches(ssml)) {
      final prosodyTag = match.group(0)!;
      
      // Check rate attribute
      final rateMatch = RegExp(r'rate="([^"]*)"').firstMatch(prosodyTag);
      if (rateMatch != null) {
        final rateValue = rateMatch.group(1)!;
        if (!_isValidRateValue(rateValue)) {
          issues.add(SSMLValidationIssue(
            type: SSMLIssueType.invalidAttribute,
            severity: SSMLIssueSeverity.warning,
            message: 'Invalid rate value: $rateValue',
            position: match.start,
            attributeName: 'rate',
            attributeValue: rateValue,
          ));
        }
      }
      
      // Check pitch attribute
      final pitchMatch = RegExp(r'pitch="([^"]*)"').firstMatch(prosodyTag);
      if (pitchMatch != null) {
        final pitchValue = pitchMatch.group(1)!;
        if (!_isValidPitchValue(pitchValue)) {
          issues.add(SSMLValidationIssue(
            type: SSMLIssueType.invalidAttribute,
            severity: SSMLIssueSeverity.warning,
            message: 'Invalid pitch value: $pitchValue',
            position: match.start,
            attributeName: 'pitch',
            attributeValue: pitchValue,
          ));
        }
      }
    }
    
    return issues;
  }

  /// Validates platform-specific SSML limitations
  static List<SSMLValidationIssue> _validatePlatformSpecific(String ssml, TTSPlatform platform) {
    final issues = <SSMLValidationIssue>[];
    
    switch (platform) {
      case TTSPlatform.web:
        // Web Speech API has very limited SSML support
        final complexTags = ['audio', 'mark', 'phoneme', 'voice'];
        for (final tag in complexTags) {
          if (ssml.contains('<$tag')) {
            issues.add(SSMLValidationIssue(
              type: SSMLIssueType.platformLimitation,
              severity: SSMLIssueSeverity.warning,
              message: 'Tag "$tag" has limited or no support in web browsers',
              position: ssml.indexOf('<$tag'),
              tagName: tag,
            ));
          }
        }
        break;
      
      case TTSPlatform.android:
      case TTSPlatform.ios:
        // Mobile platforms have good SSML support but some limitations
        break;
      
      case TTSPlatform.linux:
      case TTSPlatform.macos:
      case TTSPlatform.windows:
        // Desktop platforms with Edge TTS have excellent SSML support
        break;
    }
    
    return issues;
  }

  /// Validates rate attribute values
  static bool _isValidRateValue(String value) {
    // Valid rate values: x-slow, slow, medium, fast, x-fast, or percentage/number
    const validRates = ['x-slow', 'slow', 'medium', 'fast', 'x-fast'];
    
    if (validRates.contains(value)) return true;
    
    // Check for percentage (e.g., "50%", "150%")
    if (RegExp(r'^\d+(\.\d+)?%$').hasMatch(value)) return true;
    
    // Check for number (e.g., "0.5", "1.5")
    if (RegExp(r'^\d+(\.\d+)?$').hasMatch(value)) return true;
    
    return false;
  }

  /// Validates pitch attribute values
  static bool _isValidPitchValue(String value) {
    // Valid pitch values: x-low, low, medium, high, x-high, or frequency/percentage
    const validPitches = ['x-low', 'low', 'medium', 'high', 'x-high'];
    
    if (validPitches.contains(value)) return true;
    
    // Check for percentage (e.g., "50%", "150%")
    if (RegExp(r'^[+-]?\d+(\.\d+)?%$').hasMatch(value)) return true;
    
    // Check for frequency (e.g., "200Hz")
    if (RegExp(r'^\d+(\.\d+)?Hz$').hasMatch(value)) return true;
    
    return false;
  }
}

/// Result of SSML validation
class SSMLValidationResult {
  /// Whether the SSML is valid
  final bool isValid;
  
  /// List of validation issues found
  final List<SSMLValidationIssue> issues;

  const SSMLValidationResult({
    required this.isValid,
    required this.issues,
  });

  /// Gets all error issues
  List<SSMLValidationIssue> get errors =>
      issues.where((i) => i.severity == SSMLIssueSeverity.error).toList();

  /// Gets all warning issues
  List<SSMLValidationIssue> get warnings =>
      issues.where((i) => i.severity == SSMLIssueSeverity.warning).toList();

  /// Gets all info issues
  List<SSMLValidationIssue> get infos =>
      issues.where((i) => i.severity == SSMLIssueSeverity.info).toList();
}

/// Represents a validation issue found in SSML
class SSMLValidationIssue {
  /// Type of the issue
  final SSMLIssueType type;
  
  /// Severity of the issue
  final SSMLIssueSeverity severity;
  
  /// Human-readable message describing the issue
  final String message;
  
  /// Position in the SSML string where the issue was found
  final int position;
  
  /// Tag name associated with the issue (if applicable)
  final String? tagName;
  
  /// Attribute name associated with the issue (if applicable)
  final String? attributeName;
  
  /// Attribute value associated with the issue (if applicable)
  final String? attributeValue;

  const SSMLValidationIssue({
    required this.type,
    required this.severity,
    required this.message,
    required this.position,
    this.tagName,
    this.attributeName,
    this.attributeValue,
  });

  @override
  String toString() {
    return '${severity.name.toUpperCase()}: $message (at position $position)';
  }
}

/// Types of SSML validation issues
enum SSMLIssueType {
  malformedXML,
  unsupportedTag,
  missingRequiredElement,
  invalidStructure,
  invalidAttribute,
  platformLimitation,
}

/// Severity levels for SSML validation issues
enum SSMLIssueSeverity {
  error,
  warning,
  info,
}