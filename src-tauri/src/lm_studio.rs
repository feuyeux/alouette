use reqwest;
use serde::{Deserialize, Serialize};
use std::fs;
use std::path::Path;

/**
 * Request structure for OpenAI-compatible API calls (LM Studio)
 * Matches the OpenAI API specification for chat completions
 */
#[derive(Debug, Serialize, Deserialize)]
pub struct OpenAIRequest {
    pub model: String,
    pub messages: Vec<OpenAIMessage>,
    pub temperature: f32,
    pub max_tokens: Option<i32>,
    pub stream: bool,
}

/**
 * Message structure for OpenAI-compatible API
 */
#[derive(Debug, Serialize, Deserialize)]
pub struct OpenAIMessage {
    pub role: String,
    pub content: String,
}

/**
 * Response structure for OpenAI-compatible API responses
 */
#[derive(Debug, Serialize, Deserialize)]
pub struct OpenAIResponse {
    pub choices: Vec<OpenAIChoice>,
}

/**
 * Choice structure for OpenAI API responses
 */
#[derive(Debug, Serialize, Deserialize)]
pub struct OpenAIChoice {
    pub message: OpenAIMessage,
}

/**
 * Internal function to call LM Studio API for translation
 * Handles the actual HTTP communication with the LM Studio server using OpenAI-compatible API
 * 
 * @param text - Text to translate
 * @param target_lang - Target language for translation
 * @param server_url - LM Studio server URL
 * @param model_name - AI model to use for translation
 * @param api_key - Optional API key for authentication
 * @returns Translated text or error message
 */
pub async fn call_lmstudio_translate(text: &str, target_lang: &str, server_url: &str, model_name: &str, api_key: Option<&str>) -> Result<String, String> {
    use once_cell::sync::Lazy;
    static HTTP_CLIENT: Lazy<reqwest::Client> = Lazy::new(|| {
        reqwest::Client::builder()
            .timeout(std::time::Duration::from_secs(30))
            .build()
            .expect("Failed to create HTTP client")
    });
    let client = &*HTTP_CLIENT;

    // Load system prompt template
    let manifest_dir = std::env::var("CARGO_MANIFEST_DIR").unwrap_or_else(|_| ".".to_string());
    let prompt_path = Path::new(&manifest_dir).join("system_prompt.txt");
    let prompt_template = fs::read_to_string(&prompt_path)
        .map_err(|e| format!("Failed to read system prompt file: {} (path: {:?})", e, prompt_path))?;
    let system_prompt = prompt_template.replace("{{lang}}", target_lang);

    let api_url = format!("{}/v1/chat/completions", server_url.trim_end_matches('/'));
    
    let messages = vec![
        OpenAIMessage {
            role: "system".to_string(),
            content: system_prompt,
        },
        OpenAIMessage {
            role: "user".to_string(),
            content: text.to_string(),
        },
    ];

    let request_body = OpenAIRequest {
        model: model_name.to_string(),
        messages,
        temperature: 0.1,
        max_tokens: Some(150),
        stream: false,
    };

    println!("Sending request to LM Studio: {}", api_url);
    
    let mut request_builder = client.post(&api_url).json(&request_body);
    
    // Add API key if provided
    if let Some(key) = api_key {
        request_builder = request_builder.bearer_auth(key);
    }
    
    let response = request_builder.send().await;
    
    match response {
        Ok(resp) if resp.status().is_success() => {
            let response_text = resp.text().await.map_err(|e| format!("Failed to read response: {}", e))?;
            let response_json: OpenAIResponse = serde_json::from_str(&response_text)
                .map_err(|e| format!("Failed to parse response JSON: {} - Response: {}", e, response_text))?;
            
            if let Some(choice) = response_json.choices.first() {
                let raw_translation = choice.message.content.trim();
                if !raw_translation.is_empty() {
                    // 清理翻译结果，移除可能的前缀、后缀和解释性文本
                    let translation = clean_translation_result(raw_translation, target_lang);
                    println!("Translation result: '{}'", translation);
                    return Ok(translation);
                }
            }
        },
        Ok(resp) => {
            let status = resp.status();
            let error_text = resp.text().await.unwrap_or_default();
            println!("HTTP error: {} - {}", status, error_text);
        },
        Err(e) => {
            println!("Request failed: {}", e);
        }
    }
    
    Err(format!("Translation failed for text: '{}' to language: '{}'. Please check LM Studio server and model.", text, target_lang))
}

/**
 * Internal function to connect to LM Studio server
 */
pub async fn connect_lmstudio_internal(server_url: String, api_key: Option<String>) -> Result<Vec<String>, String> {
    let client = reqwest::Client::new();
    let api_url = format!("{}/v1/models", server_url.trim_end_matches('/'));
    
    println!("Sending request to LM Studio: {}", api_url);
    
    let mut request_builder = client.get(&api_url);
    
    // Add API key if provided
    if let Some(key) = api_key {
        request_builder = request_builder.bearer_auth(key);
    }
    
    let response = request_builder
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
    
    let models: Vec<String> = response_json["data"]
        .as_array()
        .unwrap_or(&vec![])
        .iter()
        .filter_map(|model| model["id"].as_str())
        .map(|id| id.to_string())
        .collect();
    
    println!("Successfully retrieved {} models from LM Studio server", models.len());
    Ok(models)
}

/**
 * Clean translation result to remove unwanted prefixes, suffixes, and explanatory text
 */
fn clean_translation_result(raw_text: &str, target_lang: &str) -> String {
    let mut cleaned = raw_text.trim().to_string();
    
    // 移除常见的前缀和后缀
    let lang_prefix = format!("{}:", target_lang);
    let in_lang_prefix = format!("In {}:", target_lang);
    
    let prefixes_to_remove = [
        "Translation:", "翻译：", "Translated:", "Target:", "Result:",
        "Answer:", "Output:", lang_prefix.as_str(), in_lang_prefix.as_str(),
    ];
    
    let suffixes_to_remove = [
        "Translation", "翻译", "Translated", "(translation)", "（翻译）"
    ];
    
    // 移除前缀
    for prefix in &prefixes_to_remove {
        if cleaned.starts_with(prefix) {
            cleaned = cleaned[prefix.len()..].trim_start().to_string();
        }
    }
    
    // 移除后缀
    for suffix in &suffixes_to_remove {
        if cleaned.ends_with(suffix) {
            cleaned = cleaned[..cleaned.len() - suffix.len()].trim_end().to_string();
        }
    }
    
    // 移除引号（如果整个文本被引号包围）
    if (cleaned.starts_with('"') && cleaned.ends_with('"')) ||
       (cleaned.starts_with('\'') && cleaned.ends_with('\'')) ||
       (cleaned.starts_with('"') && cleaned.ends_with('"')) {
        cleaned = cleaned[1..cleaned.len()-1].to_string();
    }
    
    // 移除多余的空白和换行
    cleaned = cleaned.trim().replace('\n', " ").replace("  ", " ");
    
    // 如果是俄语，确保只包含西里尔字符、标点和空格
    if target_lang.to_lowercase().contains("русский") || target_lang.to_lowercase().contains("russian") {
        cleaned = cleaned.chars()
            .filter(|c| c.is_whitespace() || is_cyrillic_or_punct(*c))
            .collect();
    }
    
    cleaned.trim().to_string()
}

/**
 * Check if character is Cyrillic or common punctuation
 */
fn is_cyrillic_or_punct(c: char) -> bool {
    // 西里尔字符范围
    ('\u{0400}'..='\u{04FF}').contains(&c) ||  // Cyrillic
    ('\u{0500}'..='\u{052F}').contains(&c) ||  // Cyrillic Supplement
    // 常见标点符号
    matches!(c, '.' | ',' | '!' | '?' | ';' | ':' | '(' | ')' | '[' | ']' | '{' | '}' | '"' | '\'' | '«' | '»' | '—' | '–' | '-')
}
