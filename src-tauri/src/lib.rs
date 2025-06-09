use reqwest;
use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize)]
struct TranslationRequest {
    text: String,
    target_languages: Vec<String>,
}

#[derive(Debug, Serialize, Deserialize)]
struct TranslationResult {
    language: String,
    language_name: String,
    translated_text: String,
}

#[derive(Debug, Serialize, Deserialize)]
struct OllamaRequest {
    model: String,
    prompt: String,
    stream: bool,
}

#[derive(Debug, Serialize, Deserialize)]
struct OllamaResponse {
    response: String,
}

// Language mapping for display purposes
fn get_language_name(code: &str) -> String {
    match code {
        "en" => "English".to_string(),
        "fr" => "French".to_string(),
        "es" => "Spanish".to_string(),
        "de" => "German".to_string(),
        "ja" => "Japanese".to_string(),
        "ru" => "Russian".to_string(),
        "it" => "Italian".to_string(),
        "hi" => "Hindi".to_string(),
        "ar" => "Arabic".to_string(),
        "ko" => "Korean".to_string(),
        "zh" => "Chinese".to_string(),
        "el" => "Greek".to_string(),
        // 支持中文语言名称输入
        "英语" | "英文" => "English".to_string(),
        "法语" => "French".to_string(),
        "西班牙语" => "Spanish".to_string(),
        "德语" => "German".to_string(),
        "日语" => "Japanese".to_string(),
        "俄语" => "Russian".to_string(),
        "意大利语" => "Italian".to_string(),
        "印地语" => "Hindi".to_string(),
        "阿拉伯语" => "Arabic".to_string(),
        "韩语" => "Korean".to_string(),
        "中文" => "Chinese".to_string(),
        "希腊语" => "Greek".to_string(),
        _ => code.to_string(),
    }
}

fn clean_translation_response(response: &str) -> String {
    // Remove common AI model artifacts and keep only the translation
    let cleaned = response
        .trim()
        .replace("<think>", "")
        .replace("</think>", "")
        .replace("<|im_start|>", "")
        .replace("<|im_end|>", "");
    
    // Split by lines and take the last non-empty line as the translation
    let lines: Vec<&str> = cleaned.lines().collect();
    for line in lines.iter().rev() {
        let trimmed = line.trim();
        if !trimmed.is_empty() && 
           !trimmed.starts_with("Translation:") &&
           !trimmed.starts_with("Answer:") &&
           !trimmed.starts_with("Result:") &&
           !trimmed.contains("translate") {
            return trimmed.to_string();
        }
    }
    
    // Fallback to cleaned response
    cleaned
}

#[tauri::command]
async fn translate_text(request: TranslationRequest) -> Result<Vec<TranslationResult>, String> {
    let mut results = Vec::new();

    for lang_code in request.target_languages {
        let lang_name = get_language_name(&lang_code);

        // Create prompt for Ollama
        let prompt = format!(
            "Translate \"{}\" to {}: ",
            request.text,
            lang_name
        );

        // Make request to local Ollama
        let ollama_request = OllamaRequest {
            model: "qwen3:1.7b".to_string(), // 使用可用的qwen3:1.7b模型
            prompt,
            stream: false,
        };

        match call_ollama(ollama_request).await {
            Ok(response) => {
                let cleaned_response = clean_translation_response(&response);
                results.push(TranslationResult {
                    language: lang_code,
                    language_name: lang_name,
                    translated_text: cleaned_response,
                });
            }
            Err(e) => {
                // If translation fails, still add an entry with error message
                results.push(TranslationResult {
                    language: lang_code,
                    language_name: lang_name,
                    translated_text: format!("Translation failed: {}", e),
                });
            }
        }
    }

    Ok(results)
}

async fn call_ollama(request: OllamaRequest) -> Result<String, String> {
    let client = reqwest::Client::new();

    let response = client
        .post("http://localhost:11434/api/generate")
        .json(&request)
        .send()
        .await
        .map_err(|e| format!("Failed to connect to Ollama: {}", e))?;

    if !response.status().is_success() {
        return Err(format!("Ollama API returned status: {}", response.status()));
    }

    let ollama_response: OllamaResponse = response
        .json()
        .await
        .map_err(|e| format!("Failed to parse Ollama response: {}", e))?;

    Ok(ollama_response.response)
}

#[tauri::command]
async fn save_translation_file(content: String, filename: String) -> Result<String, String> {
    use std::fs;
    use std::path::Path;

    // Create translations directory if it doesn't exist
    let translations_dir = Path::new("translations");
    if !translations_dir.exists() {
        fs::create_dir_all(translations_dir)
            .map_err(|e| format!("Failed to create translations directory: {}", e))?;
    }

    let file_path = translations_dir.join(&filename);

    fs::write(&file_path, content)
        .map_err(|e| format!("Failed to write file: {}", e))?;

    Ok(file_path.to_string_lossy().to_string())
}

// Learn more about Tauri commands at https://tauri.app/develop/calling-rust/
#[tauri::command]
fn greet(name: &str) -> String {
    format!("Hello, {}! You've been greeted from Rust!", name)
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .invoke_handler(tauri::generate_handler![greet, translate_text, save_translation_file])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
