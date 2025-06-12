use reqwest;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;

mod tts;
use tts::TTSEngine;

/**
 * Request structure for translation operations
 * Contains the text to translate, target languages, and Ollama configuration
 */
#[derive(Debug, Serialize, Deserialize)]
struct TranslationRequest {
    text: String,
    target_languages: Vec<String>,
    ollama_url: String,
    model_name: String,
}

/**
 * Response structure for translation results
 * Contains a map of language -> translated text pairs
 */
#[derive(Debug, Serialize)]
struct TranslationResponse {
    translations: HashMap<String, String>,
}

/**
 * Request structure for Ollama API calls
 * Matches the Ollama API specification for generation requests
 */
#[derive(Debug, Serialize, Deserialize)]
struct OllamaRequest {
    model: String,
    prompt: String,
    stream: bool,
    #[serde(skip_serializing_if = "Option::is_none")]
    system: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    options: Option<serde_json::Value>,
}

/**
 * Response structure for Ollama API responses
 * Contains the generated text response from the model
 */
#[derive(Debug, Serialize, Deserialize)]
struct OllamaResponse {
    response: String,
}

/**
 * Main translation command exposed to the frontend
 * Translates text to multiple target languages using configured Ollama server
 * 
 * @param request - Translation request containing text, languages, and server config
 * @returns Translation response with results for each language
 */
#[tauri::command]
async fn translate_text(request: TranslationRequest) -> Result<TranslationResponse, String> {
    println!("Starting translation process for text: '{}'", request.text);
    println!("Target languages: {:?}", request.target_languages);
    println!("Using Ollama server: {}", request.ollama_url);
    println!("Using model: {}", request.model_name);
    
    let mut translations = HashMap::new();
    
    // Process each target language sequentially
    for lang in &request.target_languages {
        println!("Translating to {}", lang);
        
        match call_ollama_translate(&request.text, lang, &request.ollama_url, &request.model_name).await {
            Ok(translation) => {
                println!("Successfully translated to {}: '{}'", lang, translation);
                translations.insert(lang.clone(), translation);
            }
            Err(e) => {
                println!("Failed to translate to {}: {}", lang, e);
                return Err(format!("Translation failed for {}: {}", lang, e));
            }
        }
    }
    
    println!("Translation process completed successfully");
    Ok(TranslationResponse { translations })
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
async fn call_ollama_translate(text: &str, target_lang: &str, ollama_url: &str, model_name: &str) -> Result<String, String> {
    println!("Preparing Ollama API call for translation to {}", target_lang);
    
    // Create HTTP client with timeout
    let client = reqwest::Client::builder()
        .timeout(std::time::Duration::from_secs(30))
        .build()
        .map_err(|e| format!("Failed to create HTTP client: {}", e))?;
    
    // Map Chinese language names to English for better translation results
    let english_lang = match target_lang {
        "English" => "English",
        "Japanese" => "Japanese", 
        "Korean" => "Korean",
        "French" => "French",
        "German" => "German",
        "Spanish" => "Spanish",
        "Russian" => "Russian",
        "Italian" => "Italian",
        "Hindi" => "Hindi",
        "Greek" => "Greek",
        "Arabic" => "Arabic",
        _ => target_lang,
    };

    // Enhanced prompts with better context and instructions
    let prompts = vec![
        format!(
            "Translate this Chinese text to {}: \"{}\"\n\nIMPORTANT:\n- Only output the direct translation\n- No explanations or notes\n- Preserve the exact meaning\n- Use natural {} expressions\n\nTranslation:",
            english_lang, text, english_lang
        ),
        format!(
            "Chinese: \"{}\"\n{}: ",
            text, english_lang
        ),
        format!(
            "Please translate \"{}\" from Chinese into {}. Output only the translation:",
            text, english_lang
        ),
    ];

    let api_url = format!("{}/api/generate", ollama_url.trim_end_matches('/'));
    
    // Try each prompt until we get a good translation
    for (i, prompt) in prompts.iter().enumerate() {
        println!("Trying prompt #{}: {}", i + 1, prompt);
        
        // Prepare request body with optimized parameters for translation
        let request_body = serde_json::json!({
            "model": model_name,
            "prompt": prompt,
            "stream": false,
             "think": false, 
            "options": {
                "temperature": 0.2,    // Lower temperature for more consistent translations
                "num_predict": 150,    // Increased to allow for complete translations
                "top_p": 0.8,
                "repeat_penalty": 1.1,
                "top_k": 20
            }
        });

        println!("Sending request to: {}", api_url);
        
        // Send request to Ollama API
        let response = client
            .post(&api_url)
            .json(&request_body)
            .send()
            .await;

        match response {
            Ok(resp) if resp.status().is_success() => {
                // Parse response
                let response_text = resp.text().await.map_err(|e| format!("Failed to read response: {}", e))?;
                let response_json: serde_json::Value = serde_json::from_str(&response_text)
                    .map_err(|e| format!("Failed to parse response JSON: {}", e))?;
                
                let translation = response_json["response"]
                    .as_str()
                    .unwrap_or("")
                    .trim();
                
                println!("Raw response: '{}'", translation);
                println!("Translation length: {}", translation.len());
                
                // Enhanced quality check for translations
                if !translation.is_empty() && 
                   translation.len() > 1 &&
                   translation != text &&
                   !translation.to_lowercase().contains("i don't know") &&
                   !translation.to_lowercase().contains("i cannot") &&
                   !translation.to_lowercase().contains("sorry") &&
                   !translation.to_lowercase().contains("translate") &&
                   !translation.to_lowercase().contains("translation") &&
                   !translation.to_lowercase().contains("chinese") &&
                   !translation.contains(text) {  // Avoid responses that contain original text
                    println!("Translation successful with prompt #{}: {} -> {}", i + 1, text, translation);
                    return Ok(translation.to_string());
                }
                
                println!("Translation attempt #{} was not satisfactory, trying next prompt", i + 1);
            },
            Ok(resp) => {
                println!("HTTP error for prompt #{}: {}", i + 1, resp.status());
            },
            Err(e) => {
                println!("Request failed for prompt #{}: {}", i + 1, e);
            }
        }
    }

    // If all prompts failed, return an error
    Err(format!("All translation attempts failed for text: '{}' to language: '{}'", text, target_lang))
}

// ================================
// Text-to-Speech Commands
// ================================

/**
 * Play text-to-speech for given text and language
 * Main TTS command exposed to the frontend
 * 
 * @param text - Text to synthesize
 * @param lang - Language for voice selection
 * @returns Success or error message
 */
#[tauri::command]
async fn play_tts(text: String, lang: String) -> Result<(), String> {
    println!("TTS request - Text: '{}', Language: '{}'", text, lang);
    
    let tts_engine = TTSEngine::new();
    match tts_engine.play_tts(&text, &lang).await {
        Ok(()) => {
            println!("TTS playback completed successfully");
            Ok(())
        }
        Err(e) => {
            println!("TTS playback failed: {}", e);
            Err(e)
        }
    }
}

/**
 * Play TTS with advanced settings (currently simplified)
 * Extended TTS command with rate, volume, and voice selection options
 * 
 * @param text - Text to synthesize
 * @param lang - Language for voice selection
 * @param _rate - Speech rate (currently unused in simplified implementation)
 * @param _volume - Audio volume (currently unused in simplified implementation)
 * @param _auto_select_voice - Auto voice selection flag (currently unused)
 * @returns Success or error message
 */
#[tauri::command]
async fn play_tts_with_settings(
    text: String, 
    lang: String, 
    _rate: f32, 
    _volume: f32, 
    _auto_select_voice: bool
) -> Result<(), String> {
    println!("TTS with settings request - Text: '{}', Language: '{}'", text, lang);
    
    let tts_engine = TTSEngine::new();
    // Simplified version primarily uses language parameter for voice selection
    tts_engine.play_tts(&text, &lang).await
}

/**
 * Get available voices organized by language
 * Returns voice information for TTS engine selection
 * 
 * @returns Map of language -> voice list
 */
#[tauri::command]
async fn get_edge_tts_voices() -> Result<HashMap<String, Vec<String>>, String> {
    println!("Fetching available TTS voices");
    let tts_engine = TTSEngine::new();
    let voices = tts_engine.get_voices_by_language();
    println!("Found {} language groups with voices", voices.len());
    Ok(voices)
}

// ================================
// TTS Cache Management Commands
// ================================

/**
 * Clear all TTS cache files
 * Removes cached audio files to free up disk space
 * 
 * @returns Total size of cleared files in bytes
 */
#[tauri::command]
async fn clear_tts_cache() -> Result<u64, String> {
    println!("Starting TTS cache cleanup");
    let tts_engine = TTSEngine::new();
    match tts_engine.clear_cache().await {
        Ok(size) => {
            println!("TTS cache cleared successfully, freed {} bytes", size);
            Ok(size)
        }
        Err(e) => {
            println!("Failed to clear TTS cache: {}", e);
            Err(e)
        }
    }
}

/**
 * Get TTS cache information
 * Returns statistics about cached files and disk usage
 * 
 * @returns JSON object with file count and total size information
 */
#[tauri::command]
async fn get_tts_cache_info() -> Result<serde_json::Value, String> {
    println!("Retrieving TTS cache information");
    let tts_engine = TTSEngine::new();
    
    match tts_engine.get_cache_info().await {
        Ok((file_count, total_size)) => {
            let cache_info = serde_json::json!({
                "file_count": file_count,
                "total_size": total_size,
                "total_size_mb": (total_size as f64) / (1024.0 * 1024.0)
            });
            println!("Cache info: {} files, {} bytes", file_count, total_size);
            Ok(cache_info)
        }
        Err(e) => {
            println!("Failed to get cache info: {}", e);
            Err(e)
        }
    }
}

/**
 * Get available TTS voices in structured format
 * Returns detailed voice information for frontend display
 * 
 * @returns Array of voice objects with metadata
 */
#[tauri::command]
fn get_available_tts_voices() -> Result<Vec<serde_json::Value>, String> {
    println!("Retrieving available TTS voices");
    let tts_engine = TTSEngine::new();
    let voices = tts_engine.get_available_voices();
    
    let voice_list: Vec<serde_json::Value> = voices.iter().map(|voice| {
        serde_json::json!({
            "id": voice.name,
            "name": voice.display_name,
            "language": voice.language,
            "gender": voice.gender,
            "locale": voice.locale
        })
    }).collect();
    
    println!("Found {} available voices", voice_list.len());
    Ok(voice_list)
}

// ================================
// Ollama Connection Commands
// ================================

/**
 * Test connection to Ollama server and fetch available models
 * Verifies server connectivity and retrieves model list
 * 
 * @param ollama_url - Ollama server URL to test
 * @returns List of available model names
 */
#[tauri::command]
async fn connect_ollama(ollama_url: String) -> Result<Vec<String>, String> {
    println!("Testing connection to Ollama server: {}", ollama_url);
    
    let client = reqwest::Client::new();
    let api_url = format!("{}/api/tags", ollama_url.trim_end_matches('/'));
    
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

// ================================
// File Management Commands
// ================================

/**
 * Save translation results to file
 * Utility command for exporting translation data
 * 
 * @param content - Translation content to save
 * @param filename - Desired filename for the export
 * @returns Full path of the saved file
 */
#[tauri::command]
async fn save_translation_file(content: String, filename: String) -> Result<String, String> {
    use std::fs;
    use std::path::Path;

    println!("Saving translation file: {}", filename);

    // Create translations directory if it doesn't exist
    let translations_dir = Path::new("translations");
    if !translations_dir.exists() {
        fs::create_dir_all(translations_dir)
            .map_err(|e| format!("Failed to create translations directory: {}", e))?;
    }

    let file_path = translations_dir.join(&filename);

    fs::write(&file_path, content)
        .map_err(|e| format!("Failed to write file: {}", e))?;

    let saved_path = file_path.to_string_lossy().to_string();
    println!("Translation file saved successfully: {}", saved_path);
    Ok(saved_path)
}

// ================================
// Development/Testing Commands
// ================================

/**
 * Simple greeting command for testing Tauri communication
 * Development utility for verifying frontend-backend connectivity
 * 
 * @param name - Name to include in greeting
 * @returns Greeting message
 */
#[tauri::command]
fn greet(name: &str) -> String {
    println!("Greeting request for: {}", name);
    format!("Hello, {}! You've been greeted from Rust!", name)
}

// ================================
// Debug Commands
// ================================

// ================================
// Application Entry Point
// ================================

/**
 * Main application entry point
 * Configures Tauri with all available commands and starts the application
 */
#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    println!("Starting Alouette application...");
    
    tauri::Builder::default()
        .invoke_handler(tauri::generate_handler![
            // Core functionality
            greet, 
            translate_text, 
            save_translation_file,
            
            // TTS functionality
            play_tts,
            play_tts_with_settings,
            get_available_tts_voices,
            get_edge_tts_voices,
            
            // Cache management
            clear_tts_cache,
            get_tts_cache_info,
            
            // Ollama integration
            connect_ollama
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
