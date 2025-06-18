use reqwest;
use serde::{Deserialize, Serialize};
use std::fs;
use std::path::Path;

/**
 * Request structure for Ollama API calls
 * Matches the Ollama API specification for generation requests
 */
#[derive(Debug, Serialize, Deserialize)]
pub struct OllamaRequest {
    pub model: String,
    pub prompt: String,
    pub stream: bool,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub system: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub options: Option<serde_json::Value>,
}

/**
 * Response structure for Ollama API responses
 * Contains the generated text response from the model
 */
#[derive(Debug, Serialize, Deserialize)]
pub struct OllamaResponse {
    pub response: String,
}

/**
 * Internal function to call Ollama API for translation
 * Handles the actual HTTP communication with the Ollama server
 * 
 * @param text - Text to translate
 * @param target_lang - Target language for translation
 * @param ollama_url - Ollama server URL
 * @param model_name - AI model to use for translation
 * @returns Translated text or error message
 */
pub async fn call_ollama_translate(text: &str, target_lang: &str, ollama_url: &str, model_name: &str) -> Result<String, String> {
    use once_cell::sync::Lazy;
    static HTTP_CLIENT: Lazy<reqwest::Client> = Lazy::new(|| {
        reqwest::Client::builder()
            .timeout(std::time::Duration::from_secs(60)) // Increased timeout for Android
            .connect_timeout(std::time::Duration::from_secs(30))
            .build()
            .expect("Failed to create HTTP client")
    });
    let client = &*HTTP_CLIENT;

    println!("Android Debug - Starting Ollama translation");
    println!("Android Debug - Text: '{}'", text);
    println!("Android Debug - Target language: '{}'", target_lang);
    println!("Android Debug - Server URL: '{}'", ollama_url);
    println!("Android Debug - Model: '{}'", model_name);

    // Load system prompt template
    // For Android compatibility, use embedded prompt instead of file system
    let prompt_template = get_embedded_system_prompt();
    
    // Use explicit language specification to avoid confusion between similar languages
    let explicit_lang = get_explicit_language_spec(target_lang);
    let system_prompt = prompt_template.replace("{{lang}}", &explicit_lang);

    let api_url = format!("{}/api/generate", ollama_url.trim_end_matches('/'));
    let request_body = serde_json::json!({
        "model": model_name,
        "prompt": text,
        "system": system_prompt,
        "stream": false,
        "options": {
            "temperature": 0.1,
            "num_predict": 150,
            "top_p": 0.1,
            "repeat_penalty": 1.05,
            "top_k": 10,
            "stop": ["\n\n", "Translation:", "Explanation:", "Note:", "Original:", "Source:"],
            "num_ctx": 2048,
            "repeat_last_n": 64
        }
    });
    
    println!("Android Debug - Sending request to: {}", api_url);
    println!("Android Debug - Request body size: {} bytes", serde_json::to_string(&request_body).unwrap_or_default().len());
    
    let response = client
        .post(&api_url)
        .json(&request_body)
        .send()
        .await;
    match response {
        Ok(resp) if resp.status().is_success() => {
            let response_text = match resp.text().await {
                Ok(text) => text,
                Err(e) => {
                    let error_msg = format!("Failed to read response body: {}", e);
                    println!("Android Debug - {}", error_msg);
                    return Err(error_msg);
                }
            };
            
            println!("Android Debug - Raw response length: {}", response_text.len());
            println!("Android Debug - Raw response (first 500 chars): {}", 
                if response_text.len() > 500 { &response_text[..500] } else { &response_text });
            
            if response_text.trim().is_empty() {
                let error_msg = format!("Received empty response from Ollama server for text: '{}'", text);
                println!("Android Debug - {}", error_msg);
                return Err(error_msg);
            }
            
            let response_json: serde_json::Value = match serde_json::from_str(&response_text) {
                Ok(json) => json,
                Err(e) => {
                    let error_msg = format!("Failed to parse JSON response: {}. Response text: {}", e, response_text);
                    println!("Android Debug - {}", error_msg);
                    return Err(error_msg);
                }
            };
            
            // More robust response parsing
            let raw_translation = match response_json.get("response") {
                Some(serde_json::Value::String(s)) => s.trim(),
                Some(other) => {
                    let error_msg = format!("Response field is not a string, got: {:?}", other);
                    println!("Android Debug - {}", error_msg);
                    return Err(error_msg);
                },
                None => {
                    let error_msg = format!("No 'response' field found in JSON. Available fields: {:?}", 
                        response_json.as_object().map(|o| o.keys().collect::<Vec<_>>()).unwrap_or_default());
                    println!("Android Debug - {}", error_msg);
                    return Err(error_msg);
                }
            };
            
            if raw_translation.is_empty() {
                let error_msg = format!("Empty translation response for text: '{}' to language: '{}'", text, target_lang);
                println!("Android Debug - {}", error_msg);
                return Err(error_msg);
            }
            
            // Clean translation result, remove possible prefixes, suffixes and explanatory text
            let translation = clean_translation_result(raw_translation, target_lang);
            println!("Android Debug - Final translation result: '{}'", translation);
            
            if translation.trim().is_empty() {
                let error_msg = format!("Translation result is empty after cleaning for text: '{}' to language: '{}'", text, target_lang);
                println!("Android Debug - {}", error_msg);
                return Err(error_msg);
            }
            
            Ok(translation)
        },
        Ok(resp) => {
            let status = resp.status();
            let response_text = resp.text().await.unwrap_or_else(|_| "Failed to read error response".to_string());
            let error_msg = format!("HTTP error {}: {}", status, response_text);
            println!("Android Debug - {}", error_msg);
            Err(error_msg)
        },
        Err(e) => {
            let error_msg = format!("Network request failed: {}", e);
            println!("Android Debug - {}", error_msg);
            Err(error_msg)
        }
    }
}

/**
 * Internal function to connect to Ollama server
 */
pub async fn connect_ollama_internal(server_url: String) -> Result<Vec<String>, String> {
    let client = reqwest::Client::new();
    let api_url = format!("{}/api/tags", server_url.trim_end_matches('/'));
    
    println!("Sending request to: {}", api_url);
    
    let response = client
        .get(&api_url)
        .send()
        .await
        .map_err(|e| {
            let error_msg = format!("Connection failed: {}", e);
            println!("{}", error_msg);
            error_msg
        })?;
    
    let response_text = response
        .text()
        .await
        .map_err(|e| {
            let error_msg = format!("Failed to read response: {}", e);
            println!("{}", error_msg);
            error_msg
        })?;
    
    let response_json: serde_json::Value = serde_json::from_str(&response_text)
        .map_err(|e| {
            let error_msg = format!("Failed to parse response: {}", e);
            println!("{}", error_msg);
            error_msg
        })?;
    
    let models: Vec<String> = response_json["models"]
        .as_array()
        .unwrap_or(&vec![])
        .iter()
        .filter_map(|model| model["name"].as_str())
        .map(|name| name.to_string())
        .collect();
    
    println!("Successfully retrieved {} models from Ollama server", models.len());
    Ok(models)
}

/**
 * Clean translation result to remove unwanted prefixes, suffixes, and explanatory text
 */
fn clean_translation_result(raw_text: &str, target_lang: &str) -> String {
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
fn is_cyrillic_or_punct(c: char) -> bool {
    // Cyrillic character ranges
    ('\u{0400}'..='\u{04FF}').contains(&c) ||  // Cyrillic
    ('\u{0500}'..='\u{052F}').contains(&c) ||  // Cyrillic Supplement
    // Common punctuation marks
    matches!(c, '.' | ',' | '!' | '?' | ';' | ':' | '(' | ')' | '[' | ']' | '{' | '}' | '"' | '\'' | '«' | '»' | '—' | '–' | '-')
}

/**
 * Check if character is Arabic or common punctuation
 */
fn is_arabic_or_punct(c: char) -> bool {
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
fn is_hangul_or_punct(c: char) -> bool {
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
 */
fn get_explicit_language_spec(language: &str) -> String {
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
 */
fn get_embedded_system_prompt() -> String {
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
