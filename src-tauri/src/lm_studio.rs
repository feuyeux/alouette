use reqwest;
use serde::{Deserialize, Serialize};
use crate::common::{clean_translation_result, get_explicit_language_spec, get_embedded_system_prompt};

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

    println!("Sending request to LM Studio: {}", server_url);
    println!("LM Studio Debug - Text: '{}'", text);
    println!("LM Studio Debug - Target language: '{}'", target_lang);
    println!("LM Studio Debug - Model: '{}'", model_name);

    // Load system prompt template - use embedded prompt for Android compatibility
    let prompt_template = get_embedded_system_prompt();
    
    // Use explicit language specification to avoid confusion between similar languages
    let explicit_lang = get_explicit_language_spec(target_lang);
    let system_prompt = prompt_template.replace("{{lang}}", &explicit_lang);

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
                    // Clean translation result, remove possible prefixes, suffixes and explanatory text
                    let translation = clean_translation_result(raw_translation, target_lang);
                    println!("LM Studio Debug - Raw translation: '{}'", raw_translation);
                    println!("LM Studio Debug - Final translation result: '{}'", translation);
                    return Ok(translation);
                }
            }
        },
        Ok(resp) => {
            let status = resp.status();
            let error_text = resp.text().await.unwrap_or_default();
            println!("LM Studio Debug - HTTP error: {} - {}", status, error_text);
        },
        Err(e) => {
            println!("LM Studio Debug - Request failed: {}", e);
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
