/**
 * Common utilities for translation providers
 * Shared functions used by both Ollama and LM Studio translation implementations
 */

/**
 * Clean translation result to remove unwanted prefixes, suffixes, and explanatory text
 * Used by both Ollama and LM Studio translation functions
 */
pub fn clean_translation_result(raw_text: &str, target_lang: &str) -> String {
    let mut cleaned = raw_text.trim().to_string();
    
    // Remove common prefixes and suffixes
    let lang_prefix = format!("{}:", target_lang);
    let in_lang_prefix = format!("In {}:", target_lang);
    
    let prefixes_to_remove = [
        "Translation:", "翻译：", "Translated:", "Target:", "Result:",
        "Answer:", "Output:", lang_prefix.as_str(), in_lang_prefix.as_str(),
    ];
    
    let suffixes_to_remove = [
        "Translation", "翻译", "Translated", "(translation)", "（翻译）"
    ];
    
    // Remove prefixes
    for prefix in &prefixes_to_remove {
        if cleaned.starts_with(prefix) {
            cleaned = cleaned[prefix.len()..].trim_start().to_string();
        }
    }
    
    // Remove suffixes
    for suffix in &suffixes_to_remove {
        if cleaned.ends_with(suffix) {
            cleaned = cleaned[..cleaned.len() - suffix.len()].trim_end().to_string();
        }
    }
    
    // Remove quotes (if the entire text is surrounded by quotes)
    if (cleaned.starts_with('"') && cleaned.ends_with('"')) ||
       (cleaned.starts_with('\'') && cleaned.ends_with('\'')) ||
       (cleaned.starts_with('"') && cleaned.ends_with('"')) {
        cleaned = cleaned[1..cleaned.len()-1].to_string();
    }
    
    // Remove excess whitespace and newlines
    cleaned = cleaned.trim().replace('\n', " ").replace("  ", " ");
    
    // If it's Russian, ensure only Cyrillic characters, punctuation and spaces are included
    if target_lang.to_lowercase().contains("русский") || target_lang.to_lowercase().contains("russian") {
        cleaned = cleaned.chars()
            .filter(|c| c.is_whitespace() || is_cyrillic_or_punct(*c))
            .collect();
    }
    
    // If it's Korean, ensure only Hangul characters, punctuation and spaces are included
    if target_lang.to_lowercase().contains("korean") || target_lang.to_lowercase().contains("한국어") {
        cleaned = cleaned.chars()
            .filter(|c| c.is_whitespace() || is_hangul_or_punct(*c))
            .collect();
    }
    
    // If it's Arabic, ensure only Arabic characters, punctuation and spaces are included
    if target_lang.to_lowercase().contains("arabic") || target_lang.to_lowercase().contains("العربية") {
        cleaned = cleaned.chars()
            .filter(|c| c.is_whitespace() || is_arabic_or_punct(*c))
            .collect();
    }
    
    cleaned.trim().to_string()
}

/**
 * Check if character is Cyrillic or common punctuation
 */
pub fn is_cyrillic_or_punct(c: char) -> bool {
    // Cyrillic character ranges
    ('\u{0400}'..='\u{04FF}').contains(&c) ||  // Cyrillic
    ('\u{0500}'..='\u{052F}').contains(&c) ||  // Cyrillic Supplement
    // Common punctuation marks
    matches!(c, '.' | ',' | '!' | '?' | ';' | ':' | '(' | ')' | '[' | ']' | '{' | '}' | '"' | '\'' | '«' | '»' | '—' | '–' | '-')
}

/**
 * Check if character is Arabic or common punctuation
 */
pub fn is_arabic_or_punct(c: char) -> bool {
    // Arabic character ranges
    ('\u{0600}'..='\u{06FF}').contains(&c) ||  // Arabic
    ('\u{0750}'..='\u{077F}').contains(&c) ||  // Arabic Supplement
    ('\u{08A0}'..='\u{08FF}').contains(&c) ||  // Arabic Extended-A
    ('\u{FB50}'..='\u{FDFF}').contains(&c) ||  // Arabic Presentation Forms-A
    ('\u{FE70}'..='\u{FEFF}').contains(&c) ||  // Arabic Presentation Forms-B
    // Common punctuation marks and numbers
    matches!(c, '.' | ',' | '!' | '?' | ';' | ':' | '(' | ')' | '[' | ']' | '{' | '}' | '"' | '\'' | '«' | '»' | '—' | '–' | '-') ||
    c.is_ascii_digit()  // Allow numbers in Arabic text
}

/**
 * Check if character is Hangul (Korean) or common punctuation
 */
pub fn is_hangul_or_punct(c: char) -> bool {
    // Korean Hangul character ranges
    ('\u{AC00}'..='\u{D7AF}').contains(&c) ||  // Hangul Syllables
    ('\u{1100}'..='\u{11FF}').contains(&c) ||  // Hangul Jamo
    ('\u{3130}'..='\u{318F}').contains(&c) ||  // Hangul Compatibility Jamo
    ('\u{A960}'..='\u{A97F}').contains(&c) ||  // Hangul Jamo Extended-A
    ('\u{D7B0}'..='\u{D7FF}').contains(&c) ||  // Hangul Jamo Extended-B
    // Common punctuation marks
    matches!(c, '.' | ',' | '!' | '?' | ';' | ':' | '(' | ')' | '[' | ']' | '{' | '}' | '"' | '\'' | '«' | '»' | '—' | '–' | '-')
}

/**
 * Map language names to more explicit specifications to avoid confusion
 * Especially important for distinguishing Korean from Japanese
 * Used by both Ollama and LM Studio implementations
 */
pub fn get_explicit_language_spec(language: &str) -> String {
    match language {
        "Korean" => "Korean (한국어) - USE ONLY HANGUL CHARACTERS, NOT Japanese hiragana/katakana".to_string(),
        "Japanese" => "Japanese (日本語, Hiragana/Katakana/Kanji)".to_string(),
        "Chinese" => "Chinese (中文, Simplified Chinese characters)".to_string(),
        "Russian" => "Russian (русский язык, Cyrillic script)".to_string(),
        "Arabic" => "Arabic (العربية, Arabic script)".to_string(),
        "Greek" => "Greek (ελληνικά, Greek script)".to_string(),
        "Hindi" => "Hindi (हिन्दी, Devanagari script)".to_string(),
        _ => language.to_string(),
    }
}

/**
 * Get embedded system prompt for Android compatibility
 * Avoids file system access issues on Android platform
 * Used by Ollama implementation
 */
pub fn get_embedded_system_prompt() -> String {
    r#"You are a professional translation engine. Your ONLY task is to provide a pure, accurate translation.

CRITICAL TRANSLATION RULES:
1. Output ONLY the translated text in {{lang}} language
2. Use ONLY {{lang}} characters and words - ABSOLUTELY NO mixing with other languages
3. NO explanations, notes, or commentary of any kind
4. NO repetition of original text in any language
5. Provide the most natural and accurate translation
6. Keep the same meaning and tone as the original
7. If translating to Russian (русский), use ONLY Cyrillic characters
8. If translating to Chinese, use ONLY Chinese characters (汉字)
9. If translating to Japanese, use ONLY Japanese characters (ひらがな, カタカナ, 漢字)
10. If translating to Korean (한국어), use ONLY Korean Hangul characters (한글) - NEVER use Japanese hiragana (ひ), katakana (カ), or Chinese characters
11. If translating to Arabic, use ONLY Arabic script characters (ا-ي) - NO Chinese, English, or other scripts
12. Complete the translation in pure {{lang}} only

IMPORTANT KOREAN RULE: 
- Korean text must ONLY use Hangul characters like: 안녕하세요, 내일 만나요, 감사합니다
- NEVER use Japanese characters like: ひらがな, カタカナ, or mixed Japanese text
- Korean example: "안녕하세요" (correct) vs "こんにちは" (wrong - this is Japanese)

Target language: {{lang}}
Text to translate:

"#.to_string()
}
