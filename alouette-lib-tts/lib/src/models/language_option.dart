/// Language option model representing a supported TTS language
class LanguageOption {
  /// Language code (e.g., 'en-US', 'zh-CN')
  final String code;
  
  /// Display name of the language
  final String name;
  
  /// Flag emoji representing the language/country
  final String flag;

  const LanguageOption({
    required this.code,
    required this.name,
    required this.flag,
  });

  /// Create a copy of this LanguageOption with optionally updated values
  LanguageOption copyWith({
    String? code,
    String? name,
    String? flag,
  }) {
    return LanguageOption(
      code: code ?? this.code,
      name: name ?? this.name,
      flag: flag ?? this.flag,
    );
  }

  /// Convert to JSON representation
  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'flag': flag,
    };
  }

  /// Create from JSON representation
  factory LanguageOption.fromJson(Map<String, dynamic> json) {
    return LanguageOption(
      code: json['code'] as String,
      name: json['name'] as String,
      flag: json['flag'] as String,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LanguageOption &&
        other.code == code &&
        other.name == name &&
        other.flag == flag;
  }

  @override
  int get hashCode => Object.hash(code, name, flag);

  @override
  String toString() {
    return 'LanguageOption(code: $code, name: $name, flag: $flag)';
  }
}