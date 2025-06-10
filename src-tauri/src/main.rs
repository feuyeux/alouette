use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::fs;
use std::path::Path;
use tauri::command;

mod tts;
use tts::TTSEngine;

#[derive(Debug, Deserialize)]
struct TranslationRequest {
    text: String,
    target_languages: Vec<String>,
    ollama_url: String,
    model_name: String,
}

#[derive(Debug, Serialize)]
struct TranslationResponse {
    translations: HashMap<String, String>,
}

#[derive(Debug, Serialize, Deserialize)]
struct SavedText {
    id: String,
    original: String,
    translations: HashMap<String, String>,
    timestamp: String,
}

#[derive(Debug, Serialize, Deserialize)]
struct EdgeTTSRequest {
    text: String,
    voice: String,
    output_format: String,
}

#[command]
async fn translate_text(request: TranslationRequest) -> Result<TranslationResponse, String> {
    let mut translations = HashMap::new();
    
    for lang in &request.target_languages {
        let translation = call_ollama_translate(&request.text, lang, &request.ollama_url, &request.model_name).await?;
        translations.insert(lang.clone(), translation);
    }
    
    Ok(TranslationResponse { translations })
}

async fn call_ollama_translate(text: &str, target_lang: &str, ollama_url: &str, model_name: &str) -> Result<String, String> {
    let client = reqwest::Client::builder()
        .timeout(std::time::Duration::from_secs(30))  // 30 seconds timeout
        .build()
        .map_err(|e| format!("Failed to create HTTP client: {}", e))?;
    
    // Convert Chinese language names to English for better translation results
    let english_lang = target_lang; // Frontend already uses English language names

    // Use direct prompts for better translation results
    let prompts = vec![
        format!("Translate '{}' to {}:", text, english_lang),
        format!("{} in {}:", text, english_lang),
        format!("{}=", text),
        format!("{} -> ", text),
    ];
    
    println!("Translation request - Target language: {}, Text: {}, Server: {}, Model: {}", 
             target_lang, text, ollama_url, model_name);

    for (i, prompt) in prompts.iter().enumerate() {
        println!("Trying prompt #{}: {}", i + 1, prompt);
        
        let request_body = serde_json::json!({
            "model": model_name,
            "prompt": prompt,
            "stream": false,
            "think": false,  // Disable thinking mode - critical fix!
            "options": {
                "temperature": 0.0,
                "num_predict": 15
            }
        });

        let api_url = format!("{}/api/generate", ollama_url.trim_end_matches('/'));
        
        let response = client
            .post(&api_url)
            .json(&request_body)
            .send()
            .await;
            
        match response {
            Ok(resp) if resp.status().is_success() => {
                let response_text = resp.text().await.map_err(|e| format!("Failed to read response: {}", e))?;
                let response_json: serde_json::Value = serde_json::from_str(&response_text)
                    .map_err(|e| format!("Failed to parse response: {}", e))?;
                
                let translation = response_json["response"]
                    .as_str()
                    .unwrap_or("")
                    .trim();
                
                println!("Raw response: {}", translation);
                let cleaned_translation = clean_ollama_response(translation, text, english_lang);
                
                if !cleaned_translation.is_empty() && cleaned_translation != text {
                    println!("Translation successful: {} -> {} ({})", text, cleaned_translation, target_lang);
                    return Ok(cleaned_translation);
                }
            }
            Ok(resp) => {
                println!("HTTP error: {}", resp.status());
            }
            Err(e) => {
                println!("Request failed: {}", e);
            }
        }
    }
    
    // If all prompts fail, return a dictionary-based fallback translation
    let fallback = get_fallback_translation(text, english_lang);
    if !fallback.is_empty() {
        println!("Using fallback translation: {} -> {}", text, fallback);
        return Ok(fallback);
    }
    
    Err(format!("All translation attempts failed. Original text: {}, Target language: {}", text, target_lang))
}

fn clean_ollama_response(response: &str, original_text: &str, _target_lang: &str) -> String {
    let binding = response.trim()
        .replace("<|im_start|>", "")
        .replace("<|im_end|>", "")
        .replace("\"", "");
    let cleaned = binding.trim();
    
    if cleaned.is_empty() {
        return String::new();
    }
    
    // If response is short and contains only letters, return directly
    if cleaned.len() < 20 && cleaned.chars().all(|c| c.is_alphabetic() || c.is_whitespace() || c == 'à' || c == 'ò' || c == 'ù' || c == 'è' || c == 'ì') {
        return cleaned.to_string();
    }
    
    // Process responses with explanations, extract the first translation word
    // Example: "Test in italiano è Test stesso." -> "Test"
    let words: Vec<&str> = cleaned.split_whitespace().collect();
    
    // Find the first reasonable translation word
    for word in &words {
        let clean_word = word.trim_matches(|c: char| !c.is_alphabetic() && c != 'à' && c != 'ò' && c != 'ù' && c != 'è' && c != 'ì');
        
        if clean_word.len() > 1 && clean_word.len() < 20 
            && clean_word.to_lowercase() != original_text.to_lowercase()
            && !clean_word.to_lowercase().contains("in")
            && !clean_word.to_lowercase().contains("is")
            && !clean_word.to_lowercase().contains("the")
            && !clean_word.to_lowercase().contains("word")
            && !clean_word.to_lowercase().contains("stesso")
            && !clean_word.to_lowercase().contains("italiano")
            && !clean_word.to_lowercase().contains("english")
        {
            return clean_word.to_string();
        }
    }
    
    // If no good word is found, return the first word
    if let Some(first_word) = words.first() {
        let clean_first = first_word.trim_matches(|c: char| !c.is_alphabetic() && c != 'à' && c != 'ò' && c != 'ù' && c != 'è' && c != 'ì');
        if clean_first.len() > 1 {
            return clean_first.to_string();
        }
    }
    
    cleaned.to_string()
}

fn get_fallback_translation(text: &str, target_lang: &str) -> String {
    // Simple dictionary-based fallback for common English words
    match (text.to_lowercase().as_str(), target_lang) {
        ("test", "Italian") => "test".to_string(),
        ("hello", "Italian") => "ciao".to_string(),
        ("thank you", "Italian") => "grazie".to_string(),
        ("goodbye", "Italian") => "ciao".to_string(),
        ("yes", "Italian") => "sì".to_string(),
        ("no", "Italian") => "no".to_string(),
        ("test", "French") => "test".to_string(),
        ("hello", "French") => "bonjour".to_string(),
        ("thank you", "French") => "merci".to_string(),
        ("test", "Spanish") => "prueba".to_string(),
        ("hello", "Spanish") => "hola".to_string(),
        ("thank you", "Spanish") => "gracias".to_string(),
        ("test", "German") => "test".to_string(),
        ("hello", "German") => "hallo".to_string(),
        ("thank you", "German") => "danke".to_string(),
        _ => String::new(),
    }
}

#[command]
async fn save_translation(text: SavedText) -> Result<String, String> {
    let data_dir = "data";
    if !Path::new(data_dir).exists() {
        fs::create_dir_all(data_dir).map_err(|e| format!("Failed to create directory: {}", e))?;
    }
    
    let filename = format!("{}/{}.json", data_dir, text.id);
    let json_content = serde_json::to_string_pretty(&text)
        .map_err(|e| format!("Serialization failed: {}", e))?;
    
    fs::write(&filename, json_content)
        .map_err(|e| format!("Failed to save file: {}", e))?;
    
    Ok(filename)
}

#[command]
async fn load_saved_texts() -> Result<Vec<SavedText>, String> {
    let data_dir = "data";
    if !Path::new(data_dir).exists() {
        return Ok(vec![]);
    }
    
    let mut texts = Vec::new();
    let entries = fs::read_dir(data_dir)
        .map_err(|e| format!("Failed to read directory: {}", e))?;
    
    for entry in entries {
        let entry = entry.map_err(|e| format!("Failed to read file entry: {}", e))?;
        let path = entry.path();
        
        if path.extension().and_then(|s| s.to_str()) == Some("json") {
            let content = fs::read_to_string(&path)
                .map_err(|e| format!("Failed to read file: {}", e))?;
            
            let text: SavedText = serde_json::from_str(&content)
                .map_err(|e| format!("Failed to parse file: {}", e))?;
            
            texts.push(text);
        }
    }
    
    // Sort by timestamp
    texts.sort_by(|a, b| b.timestamp.cmp(&a.timestamp));
    
    Ok(texts)
}

#[command]
async fn play_tts(text: String, lang: String) -> Result<(), String> {
    let tts_engine = TTSEngine::new();
    tts_engine.play_tts(&text, &lang).await
}

#[command]
async fn play_tts_with_settings(
    text: String, 
    lang: String, 
    _rate: f32, 
    _volume: f32, 
    _auto_select_voice: bool
) -> Result<(), String> {
    let tts_engine = TTSEngine::new();
    // Simplified version, mainly uses lang parameter to select voice
    tts_engine.play_tts(&text, &lang).await
}

#[command]
async fn connect_ollama(ollama_url: String) -> Result<Vec<String>, String> {
    let client = reqwest::Client::new();
    let api_url = format!("{}/api/tags", ollama_url.trim_end_matches('/'));
    
    println!("Testing Ollama connection: {}", api_url);
    
    let response = client
        .get(&api_url)
        .send()
        .await
        .map_err(|e| format!("Connection failed: {}", e))?;
    
    let response_text = response
        .text()
        .await
        .map_err(|e| format!("Failed to read response: {}", e))?;
    
    let response_json: serde_json::Value = serde_json::from_str(&response_text)
        .map_err(|e| format!("Failed to parse response: {}", e))?;
    
    let models = response_json["models"]
        .as_array()
        .unwrap_or(&vec![])
        .iter()
        .filter_map(|model| model["name"].as_str())
        .map(|name| name.to_string())
        .collect();
    
    Ok(models)
}

#[command]
fn greet(name: &str) -> String {
    format!("Hello, {}! You've been greeted from Rust!", name)
}

#[command]
async fn get_edge_tts_voices() -> Result<HashMap<String, Vec<String>>, String> {
    let tts_engine = TTSEngine::new();
    Ok(tts_engine.get_voices_by_language())
}

#[command]
fn get_available_tts_voices() -> Result<Vec<serde_json::Value>, String> {
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
    
    Ok(voice_list)
}

// TTS Cache management commands
#[command]
async fn clear_tts_cache() -> Result<u64, String> {
    let tts_engine = TTSEngine::new();
    tts_engine.clear_cache().await
}

#[command]
async fn get_tts_cache_info() -> Result<serde_json::Value, String> {
    let tts_engine = TTSEngine::new();
    let (file_count, total_size) = tts_engine.get_cache_info().await?;
    
    Ok(serde_json::json!({
        "file_count": file_count,
        "total_size": total_size,
        "total_size_mb": (total_size as f64) / (1024.0 * 1024.0)
    }))
}

fn main() {
    tauri::Builder::default()
        .invoke_handler(tauri::generate_handler![
            greet,
            translate_text,
            save_translation,
            load_saved_texts,
            play_tts,
            play_tts_with_settings,
            get_available_tts_voices,
            get_edge_tts_voices,
            clear_tts_cache,
            get_tts_cache_info,
            connect_ollama
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}