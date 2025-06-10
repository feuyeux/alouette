use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::process::Command;
use std::path::PathBuf;
use tokio::fs::{File, create_dir_all};
use tokio::io::{AsyncReadExt, AsyncWriteExt};
use rodio::{Decoder, OutputStream, Sink};
use std::io::Cursor;
use sha2::{Digest, Sha256};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct VoiceInfo {
    pub name: String,
    pub display_name: String,
    pub language: String,
    pub gender: String,
    pub locale: String,
    pub edge_voice: String,
}

impl VoiceInfo {
    pub fn new(name: &str, display_name: &str, language: &str, gender: &str, locale: &str, edge_voice: &str) -> Self {
        Self {
            name: name.to_string(),
            display_name: display_name.to_string(),
            language: language.to_string(),
            gender: gender.to_string(),
            locale: locale.to_string(),
            edge_voice: edge_voice.to_string(),
        }
    }
}

pub struct TTSEngine {
    voices: Vec<VoiceInfo>,
    cache_dir: PathBuf,
}

impl TTSEngine {
    pub fn new() -> Self {
        let cache_dir = Self::get_cache_dir();
        Self {
            voices: Self::init_voices(),
            cache_dir,
        }
    }

    fn get_cache_dir() -> PathBuf {
        // Use user cache directory
        if let Some(cache_dir) = dirs::cache_dir() {
            cache_dir.join("alouette").join("tts_cache")
        } else {
            // Fallback to temp directory
            std::env::temp_dir().join("alouette_tts_cache")
        }
    }

    async fn ensure_cache_dir(&self) -> Result<(), String> {
        create_dir_all(&self.cache_dir).await
            .map_err(|e| format!("Failed to create cache directory: {}", e))
    }

    fn generate_cache_key(&self, text: &str, voice: &str) -> String {
        let mut hasher = Sha256::new();
        hasher.update(text.as_bytes());
        hasher.update(voice.as_bytes());
        format!("{:x}.mp3", hasher.finalize())
    }

    async fn get_from_cache(&self, cache_key: &str) -> Option<Vec<u8>> {
        let cache_file = self.cache_dir.join(cache_key);
        
        if cache_file.exists() {
            match File::open(&cache_file).await {
                Ok(mut file) => {
                    let mut audio_data = Vec::new();
                    match file.read_to_end(&mut audio_data).await {
                        Ok(_) => {
                            println!("Reading TTS audio from cache: {}", cache_key);
                            Some(audio_data)
                        },
                        Err(e) => {
                            println!("Failed to read cache file: {}", e);
                            None
                        }
                    }
                },
                Err(e) => {
                    println!("Failed to open cache file: {}", e);
                    None
                }
            }
        } else {
            None
        }
    }

    async fn save_to_cache(&self, cache_key: &str, audio_data: &[u8]) -> Result<(), String> {
        self.ensure_cache_dir().await?;
        
        let cache_file = self.cache_dir.join(cache_key);
        let mut file = File::create(&cache_file).await
            .map_err(|e| format!("Failed to create cache file: {}", e))?;
        
        file.write_all(audio_data).await
            .map_err(|e| format!("Failed to write cache file: {}", e))?;
        
        println!("TTS audio cached: {}", cache_key);
        Ok(())
    }

    pub async fn clear_cache(&self) -> Result<u64, String> {
        let mut total_size = 0u64;
        let mut files_removed = 0u64;

        if !self.cache_dir.exists() {
            return Ok(0);
        }

        let mut entries = tokio::fs::read_dir(&self.cache_dir).await
            .map_err(|e| format!("Failed to read cache directory: {}", e))?;

        while let Some(entry) = entries.next_entry().await
            .map_err(|e| format!("Failed to iterate cache directory: {}", e))? {
            
            let path = entry.path();
            if path.is_file() {
                if let Ok(metadata) = tokio::fs::metadata(&path).await {
                    total_size += metadata.len();
                }
                
                if let Err(e) = tokio::fs::remove_file(&path).await {
                    println!("Failed to delete cache file: {} - {}", path.display(), e);
                } else {
                    files_removed += 1;
                }
            }
        }

        println!("TTS cache cleanup completed: deleted {} files, freed {} bytes", files_removed, total_size);
        Ok(total_size)
    }

    pub async fn get_cache_info(&self) -> Result<(u64, u64), String> {
        let mut total_size = 0u64;
        let mut file_count = 0u64;

        if !self.cache_dir.exists() {
            return Ok((0, 0));
        }

        let mut entries = tokio::fs::read_dir(&self.cache_dir).await
            .map_err(|e| format!("Failed to read cache directory: {}", e))?;

        while let Some(entry) = entries.next_entry().await
            .map_err(|e| format!("Failed to iterate cache directory: {}", e))? {
            
            let path = entry.path();
            if path.is_file() {
                if let Ok(metadata) = tokio::fs::metadata(&path).await {
                    total_size += metadata.len();
                    file_count += 1;
                }
            }
        }

        Ok((file_count, total_size))
    }

    fn init_voices() -> Vec<VoiceInfo> {
        vec![
            // English
            VoiceInfo::new("en-US-AriaNeural", "Aria", "English", "Female", "en-US", "en-US-AriaNeural"),
            VoiceInfo::new("en-US-AndrewNeural", "Andrew", "English", "Male", "en-US", "en-US-AndrewNeural"),
            
            // French
            VoiceInfo::new("fr-FR-DeniseNeural", "Denise", "French", "Female", "fr-FR", "fr-FR-DeniseNeural"),
            VoiceInfo::new("fr-FR-HenriNeural", "Henri", "French", "Male", "fr-FR", "fr-FR-HenriNeural"),
            
            // Spanish
            VoiceInfo::new("es-ES-ElviraNeural", "Elvira", "Spanish", "Female", "es-ES", "es-ES-ElviraNeural"),
            VoiceInfo::new("es-ES-AlvaroNeural", "Alvaro", "Spanish", "Male", "es-ES", "es-ES-AlvaroNeural"),
            
            // Italian
            VoiceInfo::new("it-IT-ElsaNeural", "Elsa", "Italian", "Female", "it-IT", "it-IT-ElsaNeural"),
            VoiceInfo::new("it-IT-DiegoNeural", "Diego", "Italian", "Male", "it-IT", "it-IT-DiegoNeural"),
            
            // Russian
            VoiceInfo::new("ru-RU-SvetlanaNeural", "Svetlana", "Russian", "Female", "ru-RU", "ru-RU-SvetlanaNeural"),
            VoiceInfo::new("ru-RU-DmitryNeural", "Dmitry", "Russian", "Male", "ru-RU", "ru-RU-DmitryNeural"),
            
            // Greek
            VoiceInfo::new("el-GR-AthinaNeural", "Athina", "Greek", "Female", "el-GR", "el-GR-AthinaNeural"),
            VoiceInfo::new("el-GR-NestorNeural", "Nestor", "Greek", "Male", "el-GR", "el-GR-NestorNeural"),
            
            // German
            VoiceInfo::new("de-DE-KatjaNeural", "Katja", "German", "Female", "de-DE", "de-DE-KatjaNeural"),
            VoiceInfo::new("de-DE-ConradNeural", "Conrad", "German", "Male", "de-DE", "de-DE-ConradNeural"),
            
            // Hindi
            VoiceInfo::new("hi-IN-SwaraNeural", "Swara", "Hindi", "Female", "hi-IN", "hi-IN-SwaraNeural"),
            VoiceInfo::new("hi-IN-MadhurNeural", "Madhur", "Hindi", "Male", "hi-IN", "hi-IN-MadhurNeural"),
            
            // Arabic
            VoiceInfo::new("ar-SA-ZariyahNeural", "Zariyah", "Arabic", "Female", "ar-SA", "ar-SA-ZariyahNeural"),
            VoiceInfo::new("ar-SA-HamedNeural", "Hamed", "Arabic", "Male", "ar-SA", "ar-SA-HamedNeural"),
            
            // Japanese
            VoiceInfo::new("ja-JP-NanamiNeural", "Nanami", "Japanese", "Female", "ja-JP", "ja-JP-NanamiNeural"),
            VoiceInfo::new("ja-JP-KeitaNeural", "Keita", "Japanese", "Male", "ja-JP", "ja-JP-KeitaNeural"),
            
            // Korean
            VoiceInfo::new("ko-KR-SunHiNeural", "Sun-Hi", "Korean", "Female", "ko-KR", "ko-KR-SunHiNeural"),
            VoiceInfo::new("ko-KR-InJoonNeural", "InJoon", "Korean", "Male", "ko-KR", "ko-KR-InJoonNeural"),

            // Chinese
            VoiceInfo::new("zh-CN-XiaoxiaoNeural", "Xiaoxiao", "Chinese", "Female", "zh-CN", "zh-CN-XiaoxiaoNeural"),
            VoiceInfo::new("zh-CN-YunxiNeural", "Yunxi", "Chinese", "Male", "zh-CN", "zh-CN-YunxiNeural"),
        ]
    }

    pub fn get_available_voices(&self) -> &Vec<VoiceInfo> {
        &self.voices
    }

    pub fn get_voices_by_language(&self) -> HashMap<String, Vec<String>> {
        let mut voices_map = HashMap::new();
        
        voices_map.insert("English".to_string(), vec![
            "en-US-AriaNeural (Aria, Female, Confident & Positive)".to_string(),
            "en-US-AndrewNeural (Andrew, Male, Warm & Confident)".to_string(),
        ]);
        
        voices_map.insert("French".to_string(), vec![
            "fr-FR-DeniseNeural (Denise, Female, Elegant)".to_string(),
            "fr-FR-HenriNeural (Henri, Male, Steady)".to_string(),
        ]);

        voices_map.insert("Spanish".to_string(), vec![
            "es-ES-ElviraNeural (Elvira, Female, Lively)".to_string(),
            "es-ES-AlvaroNeural (Alvaro, Male, Mature)".to_string(),
        ]);

        voices_map.insert("Italian".to_string(), vec![
            "it-IT-ElsaNeural (Elsa, Female, Warm)".to_string(),
            "it-IT-DiegoNeural (Diego, Male, Friendly)".to_string(),
        ]);

        voices_map.insert("Russian".to_string(), vec![
            "ru-RU-SvetlanaNeural (Svetlana, Female, Gentle)".to_string(),
            "ru-RU-DmitryNeural (Dmitry, Male, Deep)".to_string(),
        ]);

        voices_map.insert("Greek".to_string(), vec![
            "el-GR-AthinaNeural (Athina, Female, Clear)".to_string(),
            "el-GR-NestorNeural (Nestor, Male, Authoritative)".to_string(),
        ]);

        voices_map.insert("German".to_string(), vec![
            "de-DE-KatjaNeural (Katja, Female, Professional)".to_string(),
            "de-DE-ConradNeural (Conrad, Male, Reliable)".to_string(),
        ]);

        voices_map.insert("Hindi".to_string(), vec![
            "hi-IN-SwaraNeural (Swara, Female, Sweet)".to_string(),
            "hi-IN-MadhurNeural (Madhur, Male, Magnetic)".to_string(),
        ]);

        voices_map.insert("Arabic".to_string(), vec![
            "ar-SA-ZariyahNeural (Zariyah, Female, Elegant)".to_string(),
            "ar-SA-HamedNeural (Hamed, Male, Steady)".to_string(),
        ]);

        voices_map.insert("Japanese".to_string(), vec![
            "ja-JP-NanamiNeural (Nanami, Female, Gentle)".to_string(),
            "ja-JP-KeitaNeural (Keita, Male, Natural)".to_string(),
        ]);

        voices_map.insert("Korean".to_string(), vec![
            "ko-KR-SunHiNeural (Sun-Hi, Female, Bright)".to_string(),
            "ko-KR-InJoonNeural (InJoon, Male, Mature)".to_string(),
        ]);

        voices_map.insert("Chinese".to_string(), vec![
            "zh-CN-XiaoxiaoNeural (Xiaoxiao, Female, Warm)".to_string(),
            "zh-CN-YunxiNeural (Yunxi, Male, Lively)".to_string(),
        ]);

        voices_map
    }

    pub fn select_voice_for_language(&self, language_name: &str) -> Option<&VoiceInfo> {
        // Map language names to locale codes
        let locale = match language_name {
            "English" => "en-US",
            "French" => "fr-FR",
            "Spanish" => "es-ES",
            "Italian" => "it-IT",
            "Russian" => "ru-RU",
            "Greek" => "el-GR",
            "German" => "de-DE",
            "Hindi" => "hi-IN",
            "Arabic" => "ar-SA",
            "Japanese" => "ja-JP",
            "Korean" => "ko-KR",
            "Chinese" => "zh-CN",
            _ => {
                // If the input is already in locale format
                if language_name.contains("-") {
                    language_name
                } else {
                    "en-US" // Default
                }
            }
        };

        // Find matching voice (prefer female voices)
        self.voices.iter()
            .filter(|voice| voice.locale == locale)
            .find(|voice| voice.gender == "Female")
            .or_else(|| {
                // If no female voice, select the first matching voice
                self.voices.iter()
                    .find(|voice| voice.locale == locale)
            })
    }

    pub fn detect_language(&self, text: &str) -> String {
        // Detect Chinese characters
        let chinese_chars: Vec<char> = text.chars().filter(|c| '\u{4e00}' <= *c && *c <= '\u{9fff}').collect();
        if !chinese_chars.is_empty() {
            return "zh-CN".to_string();
        }

        // Detect Japanese characters (Hiragana, Katakana)
        let japanese_chars: Vec<char> = text.chars().filter(|c| 
            ('\u{3040}' <= *c && *c <= '\u{309f}') || // Hiragana
            ('\u{30a0}' <= *c && *c <= '\u{30ff}')    // Katakana
        ).collect();
        if !japanese_chars.is_empty() {
            return "ja-JP".to_string();
        }

        // Detect Korean characters
        let korean_chars: Vec<char> = text.chars().filter(|c| '\u{ac00}' <= *c && *c <= '\u{d7af}').collect();
        if !korean_chars.is_empty() {
            return "ko-KR".to_string();
        }

        // Detect Arabic characters
        let arabic_chars: Vec<char> = text.chars().filter(|c| '\u{0600}' <= *c && *c <= '\u{06ff}').collect();
        if !arabic_chars.is_empty() {
            return "ar-SA".to_string();
        }

        // Detect Greek characters
        let greek_chars: Vec<char> = text.chars().filter(|c| '\u{0370}' <= *c && *c <= '\u{03ff}').collect();
        if !greek_chars.is_empty() {
            return "el-GR".to_string();
        }

        // Detect Cyrillic characters (Russian)
        let cyrillic_chars: Vec<char> = text.chars().filter(|c| '\u{0400}' <= *c && *c <= '\u{04ff}').collect();
        if !cyrillic_chars.is_empty() {
            return "ru-RU".to_string();
        }

        // Default to English
        "en-US".to_string()
    }

    pub async fn synthesize_speech(&self, text: &str, language: &str) -> Result<Vec<u8>, String> {
        println!("TTS synthesis request: language={}, text_length={}, content='{}'", 
                 language, text.len(), 
                 if text.len() > 50 { format!("{}...", &text[..50]) } else { text.to_string() });

        // If no voice configuration is found, try auto-detecting the language
        let final_language = if self.select_voice_for_language(language).is_none() {
            let detected = self.detect_language(text);
            println!("Language '{}' not found in configuration, auto-detected language: {}", language, detected);
            detected
        } else {
            language.to_string()
        };

        // Select voice
        let selected_voice = self.select_voice_for_language(&final_language)
            .ok_or_else(|| format!("No voice configuration found for language '{}'", final_language))?;

        println!("Selected voice: {} ({}) - Final language: {}", selected_voice.edge_voice, selected_voice.display_name, final_language);

        // Generate cache key
        let cache_key = self.generate_cache_key(text, &selected_voice.edge_voice);
        
        // Try to get from cache first
        if let Some(cached_audio) = self.get_from_cache(&cache_key).await {
            println!("Using cached TTS audio, audio size: {} bytes", cached_audio.len());
            return Ok(cached_audio);
        }

        // Cache miss, perform TTS synthesis
        println!("Cache miss, starting TTS synthesis...");
        
        // First try Edge TTS
        let audio_data = match self.synthesize_with_edge_tts(text, &selected_voice.edge_voice).await {
            Ok(audio_data) => {
                println!("Edge TTS synthesis successful, audio size: {} bytes", audio_data.len());
                audio_data
            },
            Err(e) => {
                println!("Edge TTS failed: {}, trying local TTS", e);
                self.synthesize_with_local_tts(text, &selected_voice.locale).await?
            }
        };

        // Save result to cache
        if let Err(e) = self.save_to_cache(&cache_key, &audio_data).await {
            println!("Failed to save TTS cache: {}", e);
            // Cache failure doesn't affect main functionality, continue returning audio data
        }

        Ok(audio_data)
    }

    async fn synthesize_with_edge_tts(&self, text: &str, voice: &str) -> Result<Vec<u8>, String> {
        use std::process::Stdio;
        use tokio::process::Command as TokioCommand;

        // Check if edge-tts is available
        let check_output = TokioCommand::new("edge-tts")
            .arg("--list-voices")
            .stdout(Stdio::null())
            .stderr(Stdio::null())
            .output()
            .await;

        if check_output.is_err() {
            return Err("edge-tts not available".to_string());
        }

        // Create temporary file
        let temp_dir = std::env::temp_dir();
        let temp_file = temp_dir.join(format!("edge_tts_{}.mp3", uuid::Uuid::new_v4()));

        // Call edge-tts
        let output = TokioCommand::new("edge-tts")
            .arg("--voice")
            .arg(voice)
            .arg("--text")
            .arg(text)
            .arg("--write-media")
            .arg(&temp_file)
            .output()
            .await
            .map_err(|e| format!("Failed to execute edge-tts command: {}", e))?;

        if !output.status.success() {
            let error_msg = String::from_utf8_lossy(&output.stderr);
            return Err(format!("edge-tts execution failed: {}", error_msg));
        }

        // Check if file was generated
        if !temp_file.exists() {
            return Err("edge-tts did not generate audio file".to_string());
        }

        // Read audio file
        let mut file = File::open(&temp_file).await
            .map_err(|e| format!("Failed to open audio file: {}", e))?;

        let mut audio_data = Vec::new();
        file.read_to_end(&mut audio_data).await
            .map_err(|e| format!("Failed to read audio file: {}", e))?;

        // Delete temporary file
        let _ = tokio::fs::remove_file(&temp_file).await;

        if audio_data.is_empty() {
            return Err("Generated audio file is empty".to_string());
        }

        Ok(audio_data)
    }

    async fn synthesize_with_local_tts(&self, text: &str, locale: &str) -> Result<Vec<u8>, String> {
        let temp_dir = std::env::temp_dir();
        let temp_file = temp_dir.join(format!("local_tts_{}.wav", uuid::Uuid::new_v4()));

        // Map locale to espeak voice
        let espeak_voice = match locale {
            "zh-CN" => "zh",
            "en-US" => "en",
            "ja-JP" => "ja",
            "ko-KR" => "ko",
            "fr-FR" => "fr",
            "de-DE" => "de",
            "es-ES" => "es",
            "it-IT" => "it",
            "ru-RU" => "ru",
            "ar-SA" => "ar",
            "el-GR" => "el",
            "hi-IN" => "hi",
            _ => "en",
        };

        // Try different TTS engines
        let temp_file_str = temp_file.to_str().unwrap();
        let tts_commands = vec![
            ("espeak-ng", vec![
                "-v", espeak_voice,
                "-s", "150",
                "-a", "100",
                "-w", temp_file_str,
                text
            ]),
            ("flite", vec![
                "-t", text,
                "-o", temp_file_str
            ]),
        ];

        for (cmd, args) in &tts_commands {
            println!("Trying local TTS: {} {:?}", cmd, args);
            
            let output = Command::new(cmd)
                .args(args.iter())
                .output();
                
            match output {
                Ok(result) if result.status.success() => {
                    if temp_file.exists() {
                        let mut file = File::open(&temp_file).await
                            .map_err(|e| format!("Failed to open audio file: {}", e))?;
                        
                        let mut audio_data = Vec::new();
                        file.read_to_end(&mut audio_data).await
                            .map_err(|e| format!("Failed to read audio file: {}", e))?;
                        
                        let _ = tokio::fs::remove_file(&temp_file).await;
                        
                        if !audio_data.is_empty() {
                            println!("Local TTS synthesis successful: {}, audio size: {} bytes", cmd, audio_data.len());
                            return Ok(audio_data);
                        }
                    }
                },
                Ok(result) => {
                    println!("TTS command failed: {} (status: {})", cmd, result.status);
                },
                Err(e) => {
                    println!("TTS command not available: {} ({})", cmd, e);
                }
            }
        }

        Err("All TTS engines are unavailable".to_string())
    }

    pub async fn play_audio_from_bytes(&self, audio_data: &[u8]) -> Result<(), String> {
        // Use rodio to play audio
        let (_stream, stream_handle) = OutputStream::try_default()
            .map_err(|e| format!("Failed to create audio output stream: {}", e))?;

        let sink = Sink::try_new(&stream_handle)
            .map_err(|e| format!("Failed to create audio player: {}", e))?;

        // Copy data to Vec<u8> to avoid borrowing issues
        let audio_vec = audio_data.to_vec();
        let cursor = Cursor::new(audio_vec);
        let source = Decoder::new(cursor)
            .map_err(|e| format!("Failed to decode audio data: {}", e))?;

        sink.append(source);
        sink.sleep_until_end();

        Ok(())
    }

    pub async fn play_tts(&self, text: &str, language: &str) -> Result<(), String> {
        let audio_data = self.synthesize_speech(text, language).await?;
        self.play_audio_from_bytes(&audio_data).await?;
        println!("TTS playback completed");
        Ok(())
    }
}
