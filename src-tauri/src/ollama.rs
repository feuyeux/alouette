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
            .timeout(std::time::Duration::from_secs(30))
            .build()
            .expect("Failed to create HTTP client")
    });
    let client = &*HTTP_CLIENT;

    // Load system prompt template
    // Use CARGO_MANIFEST_DIR as global resource directory
    let manifest_dir = std::env::var("CARGO_MANIFEST_DIR").unwrap_or_else(|_| ".".to_string());
    let prompt_path = Path::new(&manifest_dir).join("system_prompt.txt");
    let prompt_template = fs::read_to_string(&prompt_path)
        .map_err(|e| format!("Failed to read system prompt file: {} (path: {:?})", e, prompt_path))?;
    
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
    println!("Sending request to: {}", api_url);
    let response = client
        .post(&api_url)
        .json(&request_body)
        .send()
        .await;
    match response {
        Ok(resp) if resp.status().is_success() => {
            let response_text = resp.text().await.map_err(|e| format!("Failed to read response: {}", e))?;
            let response_json: serde_json::Value = serde_json::from_str(&response_text)
                .map_err(|e| format!("Failed to parse response JSON: {}", e))?;
            let raw_translation = response_json["response"].as_str().unwrap_or("").trim();
            
            if !raw_translation.is_empty() {
                // Clean translation result, remove possible prefixes, suffixes and explanatory text
                let translation = clean_translation_result(raw_translation, target_lang);
                println!("Translation result: '{}'", translation);
                return Ok(translation);
            }
        },
        Ok(resp) => {
            println!("HTTP error: {}", resp.status());
        },
        Err(e) => {
            println!("Request failed: {}", e);
        }
    }
    Err(format!("Translation failed for text: '{}' to language: '{}'. Please check Ollama server and model. Try running curl -X POST {}/api/generate ... to debug.", text, target_lang, ollama_url))
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
