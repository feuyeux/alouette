use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::process::Command;
use std::path::PathBuf;
use tokio::fs::{File, create_dir_all};
use tokio::io::{AsyncReadExt, AsyncWriteExt};
use rodio::{Decoder, OutputStream, Sink};
use std::io::Cursor;
use sha2::{Digest, Sha256};

#[cfg(target_os = "android")]
use crate::android_tts::AndroidTTSEngine;

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
    #[cfg(target_os = "android")]
    android_tts: AndroidTTSEngine,
}

impl TTSEngine {
    pub fn new() -> Self {
        let cache_dir = Self::get_cache_dir();
        Self {
            voices: Self::init_voices(),
            cache_dir,
            #[cfg(target_os = "android")]
            android_tts: AndroidTTSEngine::new(),
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

    pub async fn synthesize_speech(&self, text: &str, language: &str) -> Result<Vec<u8>, String> {
        // On Android, use Android TTS instead of external commands
        #[cfg(target_os = "android")]
        {
            println!("Android TTS Debug - Using Android TTS engine");
            match self.android_tts.synthesize_speech(text, language).await {
                Ok(tts_command) => {
                    println!("Android TTS Debug - Generated command: {}", tts_command);
                    // Return the TTS command as JSON bytes for the frontend to handle
                    return Ok(tts_command.into_bytes());
                },
                Err(e) => {
                    println!("Android TTS Debug - Error: {}", e);
                    return Err(format!("Android TTS failed: {}", e));
                }
            }
        }

        // Desktop platform TTS implementation
        #[cfg(not(target_os = "android"))]
        {
            // Safe string truncation that respects UTF-8 character boundaries
            let display_text = Self::safe_truncate(text, 50);
            
            println!("TTS synthesis request: language={}, text_length={}, content='{}'", 
                     language, text.chars().count(), display_text);

            // Basic text validation
            if text.trim().is_empty() {
                return Err("Cannot synthesize empty text".to_string());
            }

            // Continue with existing desktop TTS logic...
            self.synthesize_speech_desktop(text, language).await
        }
    }

    #[cfg(not(target_os = "android"))]
    async fn synthesize_speech_desktop(&self, text: &str, language: &str) -> Result<Vec<u8>, String> {
        // Safe string truncation that respects UTF-8 character boundaries
        let display_text = Self::safe_truncate(text, 50);
        
        println!("TTS synthesis request: language={}, text_length={}, content='{}'", 
                 language, text.chars().count(), display_text);

        // Basic text validation
        if text.trim().is_empty() {
            return Err("Cannot synthesize empty text".to_string());
        }

        // Language validation and detection
        let final_language = if let Some(detected_script) = Self::detect_text_script(text) {
            if detected_script != language {
                println!("Warning: Language mismatch detected. Requested: {}, Text appears to be: {}", 
                        language, detected_script);
                // Use detected language if confidence is high
                if Self::is_script_confident(&detected_script, text) {
                    println!("Using detected language '{}' instead of requested '{}'", detected_script, language);
                    detected_script
                } else {
                    language.to_string()
                }
            } else {
                language.to_string()
            }
        } else {
            language.to_string()
        };

        // Use the determined language for voice selection
        let selected_voice = self.select_voice_for_language(&final_language)
            .ok_or_else(|| {
                let error_msg = format!("No voice configuration found for language '{}'. Available languages: English, French, Spanish, Italian, Russian, Greek, German, Hindi, Arabic, Japanese, Korean, Chinese", final_language);
                println!("{}", error_msg);
                error_msg
            })?;

        println!("Selected voice: {} ({}) for language: {}", selected_voice.edge_voice, selected_voice.display_name, final_language);

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
                match self.synthesize_with_local_tts(text, &selected_voice.locale).await {
                    Ok(audio_data) => {
                        println!("Local TTS synthesis successful, audio size: {} bytes", audio_data.len());
                        audio_data
                    },
                    Err(local_e) => {
                        println!("Local TTS also failed: {}", local_e);
                        return Err(format!("All TTS methods failed. Edge TTS: {}. Local TTS: {}", e, local_e));
                    }
                }
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
            let enhanced_error = if error_msg.contains("NoAudioReceived") {
                format!("Edge TTS failed to generate audio - this usually indicates a language/voice mismatch or network issue. Voice: {}, Text sample: '{}'. Error: {}", 
                        voice, Self::safe_truncate(text, 30), error_msg)
            } else {
                format!("edge-tts execution failed: {}", error_msg)
            };
            return Err(enhanced_error);
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

        // Enhanced locale to espeak voice mapping with better support
        let espeak_voice = match locale {
            "zh-CN" => "zh",
            "en-US" => "en-us",
            "ja-JP" => "ja", 
            "ko-KR" => "ko",
            "fr-FR" => "fr",
            "de-DE" => "de", 
            "es-ES" => "es",
            "it-IT" => "it",
            "ru-RU" => "ru",
            "ar-SA" => "ar",  // Arabic
            "el-GR" => "el",  // Greek
            "hi-IN" => "hi",  // Hindi
            _ => "en-us",
        };

        let temp_file_str = temp_file.to_str().unwrap();
        
        // Enhanced TTS commands with better parameters
        let tts_commands = vec![
            // espeak-ng with optimized settings for each language
            ("espeak-ng", vec![
                "-v", espeak_voice,
                "-s", "160",     // Slightly faster speech rate  
                "-a", "80",      // Reduced amplitude to prevent distortion
                "-g", "5",       // Small gap between words
                "-w", temp_file_str,
                text
            ]),
            // Fallback to basic espeak if espeak-ng fails
            ("espeak", vec![
                "-v", espeak_voice,
                "-s", "160",
                "-a", "80", 
                "-w", temp_file_str,
                text
            ]),
            // Festival as another fallback (English only)
            ("text2wave", vec![
                "-o", temp_file_str,
                text
            ]),
        ];

        let mut last_error = String::new();
        
        for (cmd, args) in &tts_commands {
            println!("Trying local TTS: {} with voice '{}' for locale '{}'", cmd, espeak_voice, locale);
            
            let output = Command::new(cmd)
                .args(args.iter())
                .output();
                
            match output {
                Ok(result) if result.status.success() => {
                    if temp_file.exists() {
                        match self.read_and_validate_audio_file(&temp_file).await {
                            Ok(audio_data) => {
                                let _ = tokio::fs::remove_file(&temp_file).await;
                                println!("Local TTS synthesis successful: {}, audio size: {} bytes", cmd, audio_data.len());
                                return Ok(audio_data);
                            },
                            Err(e) => {
                                last_error = format!("{} generated invalid audio: {}", cmd, e);
                                println!("{}", last_error);
                            }
                        }
                    } else {
                        last_error = format!("{} did not generate audio file", cmd);
                        println!("{}", last_error);
                    }
                },
                Ok(result) => {
                    let stderr = String::from_utf8_lossy(&result.stderr);
                    last_error = format!("{} failed (status: {}): {}", cmd, result.status, stderr);
                    println!("{}", last_error);
                },
                Err(e) => {
                    last_error = format!("{} command not available: {}", cmd, e);
                    println!("{}", last_error);
                }
            }
        }

        Err(format!("All local TTS engines failed. Last error: {}", last_error))
    }
    
    // Text preprocessing for better TTS results
    // Helper function to read and validate audio files
    async fn read_and_validate_audio_file(&self, file_path: &std::path::Path) -> Result<Vec<u8>, String> {
        let mut file = File::open(file_path).await
            .map_err(|e| format!("Failed to open audio file: {}", e))?;
        
        let mut audio_data = Vec::new();
        file.read_to_end(&mut audio_data).await
            .map_err(|e| format!("Failed to read audio file: {}", e))?;
        
        if audio_data.is_empty() {
            return Err("Generated audio file is empty".to_string());
        }
        
        // Basic audio file validation - check for common audio headers
        let is_valid_audio = audio_data.len() > 44 && (
            // WAV file
            audio_data.starts_with(b"RIFF") ||
            // MP3 file
            audio_data.starts_with(&[0xFF, 0xFB]) || audio_data.starts_with(&[0xFF, 0xFA]) ||
            // OGG file
            audio_data.starts_with(b"OggS") ||
            // Basic audio content check
            audio_data.len() > 1000
        );
        
        if !is_valid_audio {
            return Err(format!("Generated audio file appears invalid (size: {} bytes)", audio_data.len()));
        }
        
        Ok(audio_data)
    }

    /// Safely truncate a UTF-8 string to a maximum number of characters
    /// This prevents panics when dealing with multi-byte Unicode characters
    fn safe_truncate(text: &str, max_chars: usize) -> String {
        if text.chars().count() <= max_chars {
            text.to_string()
        } else {
            format!("{}...", text.chars().take(max_chars).collect::<String>())
        }
    }

    /// Detect the script/writing system of the text to help with language detection
    fn detect_text_script(text: &str) -> Option<String> {
        let chars: Vec<char> = text.chars().collect();
        let total_chars = chars.len();
        
        if total_chars == 0 {
            return None;
        }
        
        let mut chinese_chars = 0;
        let mut japanese_chars = 0;
        let mut korean_chars = 0;
        let mut arabic_chars = 0;
        let mut hindi_chars = 0;
        let mut cyrillic_chars = 0;
        let mut greek_chars = 0;
        
        for ch in chars {
            let code = ch as u32;
            match code {
                // CJK Unified Ideographs - could be Chinese or Japanese
                0x4E00..=0x9FFF => chinese_chars += 1,
                // Hiragana (Japanese)
                0x3040..=0x309F => japanese_chars += 1,
                // Katakana (Japanese)
                0x30A0..=0x30FF => japanese_chars += 1,
                // Hangul (Korean)
                0xAC00..=0xD7AF | 0x1100..=0x11FF | 0x3130..=0x318F => korean_chars += 1,
                // Arabic
                0x0600..=0x06FF | 0x0750..=0x077F => arabic_chars += 1,
                // Devanagari (Hindi)
                0x0900..=0x097F => hindi_chars += 1,
                // Cyrillic (Russian)
                0x0400..=0x04FF => cyrillic_chars += 1,
                // Greek
                0x0370..=0x03FF => greek_chars += 1,
                _ => {}
            }
        }
        
        let threshold = total_chars / 3; // At least 1/3 of characters should match
        
        if korean_chars > threshold {
            Some("Korean".to_string())
        } else if japanese_chars > 0 || (chinese_chars > 0 && japanese_chars >= chinese_chars / 4) {
            // If we have any Hiragana/Katakana, or significant Japanese markers, it's Japanese
            Some("Japanese".to_string())
        } else if chinese_chars > threshold {
            Some("Chinese".to_string())
        } else if arabic_chars > threshold {
            Some("Arabic".to_string())
        } else if hindi_chars > threshold {
            Some("Hindi".to_string())
        } else if cyrillic_chars > threshold {
            Some("Russian".to_string())
        } else if greek_chars > threshold {
            Some("Greek".to_string())
        } else {
            None // Latin-based or mixed scripts
        }
    }

    /// Check if the script detection is confident enough to override user input
    fn is_script_confident(detected: &str, text: &str) -> bool {
        let chars: Vec<char> = text.chars().collect();
        let total_chars = chars.len();
        
        if total_chars < 3 {
            return false; // Too short to be confident
        }
        
        match detected {
            "Chinese" | "Japanese" | "Korean" | "Arabic" | "Hindi" | "Russian" | "Greek" => {
                // For non-Latin scripts, if detected, we're quite confident
                true
            }
            _ => false
        }
    }

    pub async fn play_audio_from_bytes(&self, audio_data: &[u8]) -> Result<(), String> {
        if audio_data.is_empty() {
            return Err("Audio data is empty - nothing to play".to_string());
        }
        
        println!("Starting audio playback, data size: {} bytes", audio_data.len());
        
        // Use rodio to play audio
        let (_stream, stream_handle) = OutputStream::try_default()
            .map_err(|e| format!("Failed to create audio output stream: {}", e))?;

        let sink = Sink::try_new(&stream_handle)
            .map_err(|e| format!("Failed to create audio player: {}", e))?;

        // Copy data to Vec<u8> to avoid borrowing issues
        let audio_vec = audio_data.to_vec();
        let cursor = Cursor::new(audio_vec);
        let source = Decoder::new(cursor)
            .map_err(|e| {
                println!("Failed to decode audio data (size: {} bytes): {}", audio_data.len(), e);
                format!("Failed to decode audio data: {}. This might indicate corrupted audio or unsupported format.", e)
            })?;

        sink.append(source);
        
        // Add timeout to prevent hanging
        let play_duration = std::time::Duration::from_secs(30); // Max 30 seconds for any TTS
        let start_time = std::time::Instant::now();
        
        while !sink.empty() && start_time.elapsed() < play_duration {
            std::thread::sleep(std::time::Duration::from_millis(100));
        }
        
        if start_time.elapsed() >= play_duration {
            println!("TTS playback timeout - stopping playback");
            sink.stop();
            return Err("TTS playback timeout".to_string());
        }

        Ok(())
    }

    pub async fn play_tts(&self, text: &str, language: &str) -> Result<(), String> {
        let audio_data = self.synthesize_speech(text, language).await?;
        
        #[cfg(target_os = "android")]
        {
            // On Android, synthesize_speech returns a JSON command string as bytes
            // We need to parse it and return it to the frontend for handling
            if let Ok(json_str) = String::from_utf8(audio_data.clone()) {
                if let Ok(json_value) = serde_json::from_str::<serde_json::Value>(&json_str) {
                    if json_value.get("type").and_then(|v| v.as_str()) == Some("android_tts_command") {
                        println!("Android TTS command generated: {}", json_str);
                        // Return the JSON command to frontend via Tauri event
                        return Err(format!("ANDROID_TTS_COMMAND:{}", json_str));
                    }
                }
            }
            // If not a valid JSON command, treat as error
            return Err("Invalid Android TTS command format".to_string());
        }
        
        #[cfg(not(target_os = "android"))]
        {
            // On other platforms, treat as audio data
            self.play_audio_from_bytes(&audio_data).await?;
            println!("TTS playback completed");
        }
        
        Ok(())
    }
}
