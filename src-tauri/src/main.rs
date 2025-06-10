use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::fs;
use std::path::Path;
use tauri::command;

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
    let client = reqwest::Client::new();
    
    // 将中文语言名称转换为英文用于更好的翻译效果
    let english_lang = match target_lang {
        "英语" | "英文" => "English",
        "日语" => "Japanese", 
        "韩语" => "Korean",
        "法语" => "French",
        "德语" => "German",
        "西班牙语" => "Spanish",
        "俄语" => "Russian",
        "意大利语" => "Italian",
        "印地语" => "Hindi",
        "希腊语" => "Greek",
        "阿拉伯语" => "Arabic",
        _ => target_lang,
    };
    
    let prompt = format!(
        "Translate the following text to {}. Return only the direct translation without any explanation, reasoning, or additional text:\n\n{}",
        english_lang, text
    );
    
    println!("翻译请求 - 目标语言: {} ({}), 文本: {}, 服务器: {}, 模型: {}", 
             target_lang, english_lang, text, ollama_url, model_name);
    
    let request_body = serde_json::json!({
        "model": model_name,
        "prompt": prompt,
        "stream": false,
        "options": {
            "temperature": 0.1,
            "top_p": 0.9,
            "top_k": 10,
            "repeat_penalty": 1.1,
            "num_predict": 50
        },
        "system": "You are a translation assistant. Provide only direct translations without explanations, reasoning, or additional commentary."
    });
    
    let api_url = format!("{}/api/generate", ollama_url.trim_end_matches('/'));
    
    let response = client
        .post(&api_url)
        .json(&request_body)
        .send()
        .await
        .map_err(|e| format!("请求 Ollama 失败: {}", e))?;
    
    let response_text = response
        .text()
        .await
        .map_err(|e| format!("读取响应失败: {}", e))?;
    
    let response_json: serde_json::Value = serde_json::from_str(&response_text)
        .map_err(|e| format!("解析响应失败: {}", e))?;
    
    let translation = response_json["response"]
        .as_str()
        .unwrap_or("")
        .trim();
    
    // Clean the response to remove any thinking process or explanations
    let cleaned_translation = clean_ollama_response(translation);
    
    Ok(cleaned_translation)
}

fn clean_ollama_response(response: &str) -> String {
    let response = response.trim();
    
    // Remove common prefixes that indicate explanations
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
    ];
    
    let mut cleaned = response.to_string();
    for prefix in &prefixes_to_remove {
        if cleaned.starts_with(prefix) {
            cleaned = cleaned[prefix.len()..].trim().to_string();
        }
    }
    
    // Remove thinking indicators
    let thinking_indicators = [
        "<think>", "</think>",
        "<thinking>", "</thinking>",
        "Let me think", "思考",
        "I need to", "我需要",
        "First,", "首先,",
        "However,", "然而,",
        "Actually,", "实际上,",
    ];
    
    for indicator in &thinking_indicators {
        if cleaned.contains(indicator) {
            // If we find thinking indicators, try to extract just the final result
            let lines: Vec<&str> = cleaned.lines().collect();
            for line in lines.iter().rev() {
                let line = line.trim();
                if !line.is_empty() && 
                   !thinking_indicators.iter().any(|&ind| line.contains(ind)) &&
                   line.len() > 2 {
                    return line.to_string();
                }
            }
        }
    }
    
    // Split by sentences and take the last meaningful one
    let sentences: Vec<&str> = cleaned.split(&['.', '。', '!', '?', '！', '？'][..]).collect();
    for sentence in sentences.iter().rev() {
        let sentence = sentence.trim();
        if !sentence.is_empty() && 
           !sentence.to_lowercase().contains("translat") &&
           !sentence.contains("解释") &&
           !sentence.contains("说明") &&
           sentence.len() > 2 {
            return sentence.to_string();
        }
    }
    
    cleaned
}

#[command]
async fn save_translation(text: SavedText) -> Result<String, String> {
    let data_dir = "data";
    if !Path::new(data_dir).exists() {
        fs::create_dir_all(data_dir).map_err(|e| format!("创建目录失败: {}", e))?;
    }
    
    let filename = format!("{}/{}.json", data_dir, text.id);
    let json_content = serde_json::to_string_pretty(&text)
        .map_err(|e| format!("序列化失败: {}", e))?;
    
    fs::write(&filename, json_content)
        .map_err(|e| format!("保存文件失败: {}", e))?;
    
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
        .map_err(|e| format!("读取目录失败: {}", e))?;
    
    for entry in entries {
        let entry = entry.map_err(|e| format!("读取文件项失败: {}", e))?;
        let path = entry.path();
        
        if path.extension().and_then(|s| s.to_str()) == Some("json") {
            let content = fs::read_to_string(&path)
                .map_err(|e| format!("读取文件失败: {}", e))?;
            
            let text: SavedText = serde_json::from_str(&content)
                .map_err(|e| format!("解析文件失败: {}", e))?;
            
            texts.push(text);
        }
    }
    
    // 按时间戳排序
    texts.sort_by(|a, b| b.timestamp.cmp(&a.timestamp));
    
    Ok(texts)
}

#[command]
async fn play_tts(text: String, lang: String) -> Result<(), String> {
    // 语言映射 - 支持中文语言名称并映射到espeak可用的语音
    let command = match lang.as_str() {
        "中文" | "Chinese" => format!("espeak -v zh \"{}\"", text),
        "英语" | "英文" | "English" => format!("espeak -v en \"{}\"", text),
        "日语" | "Japanese" => {
            // 日语不直接支持，使用英语作为fallback
            format!("espeak -v en \"{}\"", text)
        },
        "韩语" | "Korean" => {
            // 韩语不直接支持，使用英语作为fallback
            format!("espeak -v en \"{}\"", text)
        },
        "法语" | "French" => format!("espeak -v fr \"{}\"", text),
        "德语" | "German" => format!("espeak -v de \"{}\"", text),
        "西班牙语" | "Spanish" => format!("espeak -v es \"{}\"", text),
        "俄语" | "Russian" => format!("espeak -v ru \"{}\"", text),
        "意大利语" | "Italian" => format!("espeak -v it \"{}\"", text),
        "印地语" | "Hindi" => format!("espeak -v hi \"{}\"", text),
        "希腊语" | "Greek" => format!("espeak -v el \"{}\"", text),
        "阿拉伯语" | "Arabic" => {
            // 阿拉伯语espeak不支持，使用英语作为fallback
            println!("警告: espeak不支持阿拉伯语，使用英语语音");
            format!("espeak -v en \"{}\"", text)
        },
        _ => {
            println!("未知语言 '{}', 使用默认语音", lang);
            format!("espeak \"{}\"", text)
        },
    };
    
    println!("执行TTS命令: {}", command);
    
    let output = tokio::process::Command::new("sh")
        .arg("-c")
        .arg(&command)
        .output()
        .await
        .map_err(|e| format!("TTS 播放失败: {}", e))?;
    
    if !output.status.success() {
        let stderr = String::from_utf8_lossy(&output.stderr);
        println!("TTS 错误输出: {}", stderr);
        return Err(format!("TTS 命令执行失败: {}", stderr));
    }
    
    println!("TTS 播放成功");
    Ok(())
}

#[command]
async fn test_ollama_connection(ollama_url: String) -> Result<Vec<String>, String> {
    let client = reqwest::Client::new();
    let api_url = format!("{}/api/tags", ollama_url.trim_end_matches('/'));
    
    println!("测试Ollama连接: {}", api_url);
    
    let response = client
        .get(&api_url)
        .send()
        .await
        .map_err(|e| format!("连接失败: {}", e))?;
    
    let response_text = response
        .text()
        .await
        .map_err(|e| format!("读取响应失败: {}", e))?;
    
    let response_json: serde_json::Value = serde_json::from_str(&response_text)
        .map_err(|e| format!("解析响应失败: {}", e))?;
    
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

fn main() {
    tauri::Builder::default()
        .invoke_handler(tauri::generate_handler![
            greet,
            translate_text,
            save_translation,
            load_saved_texts,
            play_tts,
            test_ollama_connection
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}