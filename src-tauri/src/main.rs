use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::fs;
use std::path::Path;
use tauri::command;

#[derive(Debug, Deserialize)]
struct TranslationRequest {
    text: String,
    target_languages: Vec<String>,
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
        let translation = call_ollama_translate(&request.text, lang).await?;
        translations.insert(lang.clone(), translation);
    }
    
    Ok(TranslationResponse { translations })
}

async fn call_ollama_translate(text: &str, target_lang: &str) -> Result<String, String> {
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
        "请将以下中文文本翻译成{}，只返回翻译结果，不要其他解释：\n{}",
        english_lang, text
    );
    
    println!("翻译请求 - 目标语言: {} ({}), 文本: {}", target_lang, english_lang, text);
    
    let request_body = serde_json::json!({
        "model": "qwen3:1.7b",
        "prompt": prompt,
        "stream": false
    });
    
    let response = client
        .post("http://localhost:11434/api/generate")
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
        .trim()
        .to_string();
    
    Ok(translation)
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
            play_tts
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}