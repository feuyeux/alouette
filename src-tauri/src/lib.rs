use serde::{Deserialize, Serialize};
use std::collections::HashMap;

mod tts;
mod ollama;
mod lm_studio;

use tts::TTSEngine;
use ollama::{call_ollama_translate, connect_ollama_internal};
use lm_studio::{call_lmstudio_translate, connect_lmstudio_internal};

/**
 * Request structure for translation operations
 * Contains the text to translate, target languages, and LLM provider configuration
 */
#[derive(Debug, Serialize, Deserialize)]
struct TranslationRequest {
    text: String,
    target_languages: Vec<String>,
    provider: String,
    server_url: String,
    model_name: String,
    api_key: Option<String>,
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
 * Main translation command exposed to the frontend
 * Translates text to multiple target languages using configured LLM provider
 * 
 * @param request - Translation request containing text, languages, and provider config
 * @returns Translation response with results for each language
 */
#[tauri::command]
async fn translate_text(request: TranslationRequest) -> Result<TranslationResponse, String> {
    println!("Starting translation process for text: '{}'", request.text);
    println!("Target languages: {:?}", request.target_languages);
    println!("Using {} provider: {}", request.provider, request.server_url);
    println!("Using model: {}", request.model_name);
    
    let mut translations = HashMap::new();
    
    // Process each target language sequentially
    for lang in &request.target_languages {
        println!("Translating to {}", lang);
        
        let translation_result = match request.provider.as_str() {
            "ollama" => call_ollama_translate(&request.text, lang, &request.server_url, &request.model_name).await,
            "lmstudio" => call_lmstudio_translate(&request.text, lang, &request.server_url, &request.model_name, request.api_key.as_deref()).await,
            _ => Err(format!("Unsupported provider: {}", request.provider))
        };
        
        match translation_result {
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
    connect_ollama_internal(ollama_url).await
}

/**
 * Connect to LLM provider and retrieve available models
 * Supports both Ollama and LM Studio (OpenAI-compatible) APIs
 * 
 * @param provider - Provider type ("ollama" or "lmstudio")
 * @param server_url - Server URL
 * @param api_key - Optional API key for authentication
 * @returns List of available model names
 */
#[tauri::command]
async fn connect_llm(provider: String, server_url: String, api_key: Option<String>) -> Result<Vec<String>, String> {
    println!("Testing connection to {} server: {}", provider, server_url);
    
    match provider.as_str() {
        "ollama" => connect_ollama_internal(server_url).await,
        "lmstudio" => connect_lmstudio_internal(server_url, api_key).await,
        _ => Err(format!("Unsupported provider: {}", provider))
    }
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
            
            // LLM integration
            connect_ollama,
            connect_llm
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
