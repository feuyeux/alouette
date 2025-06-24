/**
 * Android-compatible TTS module
 * Uses Android's built-in TTS capabilities instead of external commands
 */

use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AndroidTTSEngine {
    pub available_voices: Vec<AndroidVoice>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AndroidVoice {
    pub name: String,
    pub language: String,
    pub country: String,
    pub locale: String,
}

impl AndroidTTSEngine {
    pub fn new() -> Self {
        Self {
            available_voices: Self::init_android_voices(),
        }
    }

    fn init_android_voices() -> Vec<AndroidVoice> {
        vec![
            AndroidVoice {
                name: "en-US-default".to_string(),
                language: "English".to_string(),
                country: "US".to_string(),
                locale: "en-US".to_string(),
            },
            AndroidVoice {
                name: "es-ES-default".to_string(),
                language: "Spanish".to_string(),
                country: "ES".to_string(),
                locale: "es-ES".to_string(),
            },
            AndroidVoice {
                name: "fr-FR-default".to_string(),
                language: "French".to_string(),
                country: "FR".to_string(),
                locale: "fr-FR".to_string(),
            },
            AndroidVoice {
                name: "de-DE-default".to_string(),
                language: "German".to_string(),
                country: "DE".to_string(),
                locale: "de-DE".to_string(),
            },
            AndroidVoice {
                name: "it-IT-default".to_string(),
                language: "Italian".to_string(),
                country: "IT".to_string(),
                locale: "it-IT".to_string(),
            },
            AndroidVoice {
                name: "ru-RU-default".to_string(),
                language: "Russian".to_string(),
                country: "RU".to_string(),
                locale: "ru-RU".to_string(),
            },
            AndroidVoice {
                name: "zh-CN-default".to_string(),
                language: "Chinese".to_string(),
                country: "CN".to_string(),
                locale: "zh-CN".to_string(),
            },
            AndroidVoice {
                name: "ja-JP-default".to_string(),
                language: "Japanese".to_string(),
                country: "JP".to_string(),
                locale: "ja-JP".to_string(),
            },
            AndroidVoice {
                name: "ko-KR-default".to_string(),
                language: "Korean".to_string(),
                country: "KR".to_string(),
                locale: "ko-KR".to_string(),
            },
            AndroidVoice {
                name: "ar-SA-default".to_string(),
                language: "Arabic".to_string(),
                country: "SA".to_string(),
                locale: "ar-SA".to_string(),
            },
            AndroidVoice {
                name: "hi-IN-default".to_string(),
                language: "Hindi".to_string(),
                country: "IN".to_string(),
                locale: "hi-IN".to_string(),
            },
        ]
    }

    pub fn find_voice_for_language(&self, language: &str) -> Option<&AndroidVoice> {
        // First try exact language match
        if let Some(voice) = self.available_voices.iter().find(|v| v.language.eq_ignore_ascii_case(language)) {
            return Some(voice);
        }

        // Then try locale-based matching
        let locale = self.language_to_locale(language);
        self.available_voices.iter().find(|v| v.locale == locale)
    }

    fn language_to_locale<'a>(&self, language: &'a str) -> &'a str {
        match language.to_lowercase().as_str() {
            "english" => "en-US",
            "spanish" => "es-ES", 
            "french" => "fr-FR",
            "italian" => "it-IT",
            "russian" => "ru-RU",
            "greek" => "el-GR",
            "german" => "de-DE",
            "hindi" => "hi-IN",
            "arabic" => "ar-SA",
            "japanese" => "ja-JP",
            "korean" => "ko-KR",
            "chinese" => "zh-CN",
            _ => {
                if language.contains("-") {
                    language
                } else {
                    "en-US"
                }
            }
        }
    }

    /// Android-compatible TTS synthesis
    /// This will be called from the frontend using Android WebView's TTS capabilities
    pub async fn synthesize_speech(&self, text: &str, language: &str) -> Result<String, String> {
        println!("Android TTS Debug - Text: '{}'", text);
        println!("Android TTS Debug - Language: '{}'", language);

        if text.trim().is_empty() {
            return Err("Cannot synthesize empty text".to_string());
        }

        let voice = self.find_voice_for_language(language)
            .ok_or_else(|| format!("No voice available for language: {}", language))?;

        println!("Android TTS Debug - Selected voice: {} ({})", voice.name, voice.locale);

        // For Android, we return a special marker followed by TTS command 
        // The frontend will recognize this and use Android's WebView speechSynthesis API
        let tts_command = serde_json::json!({
            "type": "android_tts_command",
            "text": text,
            "voice": voice.name,
            "locale": voice.locale,
            "language": voice.language
        });

        Ok(tts_command.to_string())
    }
}
