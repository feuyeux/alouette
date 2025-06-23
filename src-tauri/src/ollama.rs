use reqwest;
use serde::{Deserialize, Serialize};
use crate::common::{clean_translation_result, get_explicit_language_spec, get_embedded_system_prompt};

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
