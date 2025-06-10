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
    #[serde(skip_serializing_if = "Option::is_none")]
    system: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    options: Option<serde_json::Value>,
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
    // Remove common AI model artifacts and thinking indicators
    let mut cleaned = response
        .trim()
        .replace("<think>", "")
        .replace("</think>", "")
        .replace("<thinking>", "")
        .replace("</thinking>", "")
        .replace("<|im_start|>", "")
        .replace("<|im_end|>", "");

    // Remove common explanation prefixes
    let prefixes_to_remove = [
        "Translation:",
        "翻译结果:",
        "翻译:",
        "Result:",
        "答案:",
        "Answer:",
        "The translation is:",
        "Here is the translation:",
        "这个翻译是:",
        "翻译如下:",
        "Direct translation:",
        "Translation result:",
    ];
    
    for prefix in &prefixes_to_remove {
        if cleaned.trim().starts_with(prefix) {
            cleaned = cleaned.trim()[prefix.len()..].trim().to_string();
        }
    }

    // Remove lines containing thinking processes
    let lines: Vec<&str> = cleaned.lines().collect();
    let mut final_lines = Vec::new();
    
    for line in &lines {
        let line_lower = line.to_lowercase();
        let is_thinking_line = line_lower.contains("let me think") ||
                              line_lower.contains("first,") ||
                              line_lower.contains("however,") ||
                              line_lower.contains("actually,") ||
                              line_lower.contains("i need to") ||
                              line_lower.contains("思考") ||
                              line_lower.contains("首先") ||
                              line_lower.contains("然而") ||
                              line_lower.contains("实际上") ||
                              line_lower.contains("我需要") ||
                              (line_lower.contains("translate") && line_lower.contains("to")) ||
                              line_lower.contains("explanation") ||
                              line_lower.contains("reasoning");
        
        if !is_thinking_line && !line.trim().is_empty() {
            final_lines.push(line.trim());
        }
    }

    // If we have multiple lines, take the last meaningful one
    if final_lines.len() > 1 {
        for line in final_lines.iter().rev() {
            if line.len() > 2 && !line.ends_with(':') {
                return line.to_string();
            }
        }
    }

    // If we still have content, return the cleaned version
    if !final_lines.is_empty() {
        return final_lines.join(" ").trim().to_string();
    }

    // Fallback to cleaned response
    cleaned.trim().to_string()
}

#[tauri::command]
async fn translate_text(request: TranslationRequest) -> Result<Vec<TranslationResult>, String> {
    let mut results = Vec::new();

    for lang_code in request.target_languages {
        let lang_name = get_language_name(&lang_code);

        // Create prompt for Ollama
        let prompt = format!(
            "Translate \"{}\" to {}. Return only the direct translation without any explanation or reasoning: ",
            request.text,
            lang_name
        );

        // Make request to local Ollama
        let ollama_request = OllamaRequest {
            model: "qwen3:1.7b".to_string(), // 使用可用的qwen3:1.7b模型
            prompt,
            stream: false,
            system: Some("You are a translation assistant. Provide only direct translations without explanations, reasoning, or additional commentary.".to_string()),
            options: Some(serde_json::json!({
                "temperature": 0.1,
                "top_p": 0.9,
                "top_k": 10,
                "repeat_penalty": 1.1,
                "num_predict": 50
            })),
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
