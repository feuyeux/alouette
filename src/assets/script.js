import { invoke } from '@tauri-apps/api/core'

/**
 * Check if the application is running in Tauri environment
 * @returns {boolean} True if running in Tauri, false otherwise
 */
const isTauriEnv = () => {
  if (typeof window === 'undefined') return false
  
  // Check for multiple possible Tauri global variables
  return !!(
    window.__TAURI__ || 
    window.__TAURI_INTERNALS__ || 
    window.__TAURI_METADATA__ ||
    (window.navigator && window.navigator.userAgent && window.navigator.userAgent.includes('Tauri'))
  )
}

export default {
  name: 'App',
  data() {
    return {
      // Translation input and output
      inputText: '',
      selectedLanguages: [],
      availableLanguages: [
        'English', 'Japanese', 'Korean', 'French', 'German', 'Spanish', 'Russian', 'Italian',
        'Hindi', 'Greek', 'Arabic', 'Select All'
      ],
      isTranslating: false,
      currentTranslation: null,
      
      // TTS playback state
      playingText: null, // Track currently playing text
      isPlayingAll: false, // Track if playing all translations
      showTauriWarning: false, // Show Tauri environment warning
      
      // Ollama configuration
      showSettings: false,
      ollamaUrl: localStorage.getItem('ollamaUrl') || 'http://localhost:11434',
      selectedModel: localStorage.getItem('selectedModel') || '',
      availableModels: [],
      isTestingConnection: false,
      connectionStatus: null,
      
      // TTS settings with default values
      isTesting: false,
      ttsSettings: {
        rate: parseFloat(localStorage.getItem('ttsRate')) || 0.8,
        volume: parseFloat(localStorage.getItem('ttsVolume')) || 0.9,
        pauseBetweenLanguages: parseInt(localStorage.getItem('ttsPause')) || 500,
        autoSelectVoice: localStorage.getItem('ttsAutoSelect') !== 'false' // Default to true
      },
      
      // TTS cache management
      cacheInfo: null,
      isRefreshingCache: false,
      isClearingCache: false
    }
  },
  
  mounted() {
    console.log('Alouette application initializing...')
    
    // Check Tauri environment
    if (!isTauriEnv()) {
      this.showTauriWarning = true
      console.warn('Application not running in Tauri environment - some features may be limited')
    } else {
      console.log('✅ Tauri environment detected')
      // Initialize cache information
      this.refreshCacheInfo()
    }
    
    console.log('Configuration loaded:', {
      ollamaUrl: this.ollamaUrl,
      selectedModel: this.selectedModel,
      ttsSettings: this.ttsSettings
    })
  },
  
  computed: {
    /**
     * Check if Ollama is properly configured
     * @returns {boolean} True if both URL and model are configured
     */
    isConfigured() {
      return this.ollamaUrl && this.selectedModel;
    },
    
    /**
     * Check if all real languages are selected
     * @returns {boolean} True if all languages except 'Select All' are selected
     */
    isAllSelected() {
      const realLanguages = this.availableLanguages.filter(lang => lang !== 'Select All');
      const selectedRealLanguages = this.selectedLanguages.filter(lang => lang !== 'Select All');
      return selectedRealLanguages.length === realLanguages.length && realLanguages.length > 0;
    }
  },
  methods: {
    /**
     * Main translation function - translates input text to selected languages
     * Uses configured Ollama server and model for AI-powered translation
     */
    async translateText() {
      console.log('Starting translation process...')
      
      // Filter out "Select All" option, keep only real languages
      const realSelectedLanguages = this.selectedLanguages.filter(lang => lang !== 'Select All');
      
      // Validation
      if (!this.inputText || realSelectedLanguages.length === 0) {
        console.warn('Translation aborted: missing input text or target languages')
        return
      }
      
      // Check configuration
      if (!this.isConfigured) {
        console.error('Translation aborted: Ollama not configured')
        alert('Please configure Ollama server and model first');
        this.showSettings = true;
        return;
      }
      
      // Check Tauri environment
      if (!isTauriEnv()) {
        console.error('Translation aborted: not running in Tauri environment')
        alert('Please run this application through Tauri, not directly in a browser.\nExecute: npm run dev')
        return
      }
      
      this.isTranslating = true
      
      try {
        console.log('Sending translation request:', {
          text: this.inputText,
          targetLanguages: realSelectedLanguages,
          ollamaUrl: this.ollamaUrl,
          modelName: this.selectedModel
        })
        
        // Call Tauri backend for translation
        const result = await invoke('translate_text', {
          request: {
            text: this.inputText,
            target_languages: realSelectedLanguages,
            ollama_url: this.ollamaUrl,
            model_name: this.selectedModel
          }
        })
        
        console.log('Translation completed successfully:', result)
        
        this.currentTranslation = {
          original: this.inputText,
          translations: result.translations,
          timestamp: new Date().toISOString()
        }
        
        // Clear input for next translation
        this.inputText = ''
        this.selectedLanguages = []
        
      } catch (error) {
        console.error('Translation failed:', error)
        alert('Translation failed: ' + error.message)
      } finally {
        this.isTranslating = false
      }
    },
    
    /**
     * Play text-to-speech for a specific text and language
     * @param {string} text - Text to synthesize
     * @param {string} lang - Target language for voice selection
     */
    async playTTS(text, lang) {
      // Check Tauri environment
      if (!isTauriEnv()) {
        console.error('TTS playback failed: not running in Tauri environment')
        alert('Please run this application through Tauri, not directly in a browser.\nExecute: npm run dev')
        return
      }
      
      try {
        // Set playback state
        this.playingText = text
        console.log(`Starting TTS playback - Text: "${text}", Language: ${lang}`)
        
        // Call Tauri backend for TTS
        await invoke('play_tts', { 
          text: text, 
          lang: lang
        })
        
        console.log('TTS playback completed successfully')
        this.playingText = null
        
      } catch (error) {
        console.error('TTS playback failed:', error)
        this.playingText = null
        
        // Display specific error message
        const errorMsg = error.message || error.toString() || 'Unknown error'
        alert(`TTS playback failed: ${errorMsg}`)
      }
    },

    /**
     * Play all translations sequentially with pauses between languages
     */
    async playAll() {
      if (!this.currentTranslation || this.isPlayingAll) return
      
      console.log('Starting sequential playback of all translations')
      this.isPlayingAll = true
      
      try {
        // First, play the original text
        console.log('Playing original text:', this.currentTranslation.original)
        await this.playTTSPromise(this.currentTranslation.original, 'Chinese')
        
        // Then play all translations sequentially
        for (const [lang, translation] of Object.entries(this.currentTranslation.translations)) {
          if (!this.isPlayingAll) break // User interrupted playback
          
          // Brief pause between languages
          await new Promise(resolve => setTimeout(resolve, this.ttsSettings.pauseBetweenLanguages))
          
          if (this.isPlayingAll) {
            console.log(`Playing ${lang}:`, translation)
            await this.playTTSPromise(translation, lang)
          }
        }
        
        console.log('Sequential playback completed')
        
      } catch (error) {
        console.error('Sequential playback failed:', error)
        alert('Sequential playback failed: ' + (error.message || error))
      } finally {
        this.isPlayingAll = false
        this.playingText = null
      }
    },

    /**
     * Stop all TTS playback
     */
    stopPlayAll() {
      console.log('Stopping all TTS playback')
      this.isPlayingAll = false
      this.playingText = null
      // Note: Actual TTS stopping would need to be implemented in the Rust backend
    },

    /**
     * Promise-based TTS playback for sequential execution
     * @param {string} text - Text to synthesize
     * @param {string} lang - Target language
     * @returns {Promise} Promise that resolves when TTS completes
     */
    async playTTSPromise(text, lang) {
      try {
        this.playingText = text
        await invoke('play_tts', { text: text, lang: lang })
        this.playingText = null
      } catch (error) {
        this.playingText = null
        throw new Error(`TTS playback failed (${lang}): ${error.message || error}`)
      }
    },
    
    /**
     * Test connection to Ollama server and fetch available models
     */
    async testConnection() {
      if (!this.ollamaUrl) {
        this.connectionStatus = { type: 'error', message: 'Please enter server address' };
        return;
      }
      
      console.log('Testing connection to Ollama server:', this.ollamaUrl)
      this.isTestingConnection = true;
      this.connectionStatus = { type: 'info', message: 'Testing connection...' };
      
      try {
        const models = await invoke('connect_ollama', {
          ollamaUrl: this.ollamaUrl
        });
        
        console.log('Connection successful, available models:', models)
        this.availableModels = models;
        this.connectionStatus = { 
          type: 'success', 
          message: `Connection successful! Found ${models.length} models` 
        };
        
        // Auto-select first model if none selected previously
        if (!this.selectedModel && models.length > 0) {
          this.selectedModel = models[0];
          console.log('Auto-selected first available model:', this.selectedModel)
        }
        
      } catch (error) {
        console.error('Connection failed:', error)
        this.connectionStatus = { 
          type: 'error', 
          message: `Connection failed: ${error}` 
        };
        this.availableModels = [];
      } finally {
        this.isTestingConnection = false;
      }
    },

    /**
     * Save application settings to localStorage
     */
    saveSettings() {
      if (!this.ollamaUrl || !this.selectedModel) {
        alert('Please fill in all configuration fields');
        return;
      }
      
      console.log('Saving application settings...')
      
      // Save Ollama configuration to localStorage
      localStorage.setItem('ollamaUrl', this.ollamaUrl);
      localStorage.setItem('selectedModel', this.selectedModel);
      
      // Save TTS settings to localStorage
      localStorage.setItem('ttsRate', this.ttsSettings.rate.toString());
      localStorage.setItem('ttsVolume', this.ttsSettings.volume.toString());
      localStorage.setItem('ttsPause', this.ttsSettings.pauseBetweenLanguages.toString());
      localStorage.setItem('ttsAutoSelect', this.ttsSettings.autoSelectVoice.toString());
      
      console.log('Settings saved successfully:', {
        ollamaUrl: this.ollamaUrl,
        selectedModel: this.selectedModel,
        ttsSettings: this.ttsSettings
      })
      
      this.showSettings = false;
      this.connectionStatus = null;
      
      alert('Settings saved successfully!');
    },

    /**
     * Reset all settings to default values
     */
    resetSettings() {
      if (confirm('Are you sure you want to reset all settings to default values?')) {
        console.log('Resetting settings to defaults...')
        
        // Reset TTS settings to defaults
        this.ttsSettings = {
          rate: 0.8,
          volume: 0.9,
          pauseBetweenLanguages: 500,
          autoSelectVoice: true
        };
        
        // Clear from localStorage
        localStorage.removeItem('ttsRate');
        localStorage.removeItem('ttsVolume');
        localStorage.removeItem('ttsPause');
        localStorage.removeItem('ttsAutoSelect');
        
        console.log('Settings reset to defaults')
        alert('Settings have been reset to default values!');
      }
    },

    async testTTS() {
      if (!isTauriEnv()) {
        alert('TTS functionality requires running in Tauri application');
        return;
      }

      this.isTesting = true;
      
      try {
        console.log('Starting TTS test...')
        
        // Use English for testing  
        const testText = 'Hello, this is a text-to-speech test'
        const testLang = 'English'
        
        await this.playTTS(testText, testLang)
        
        console.log('TTS test completed successfully')
      } catch (error) {
        console.error('TTS test failed:', error);
        alert('TTS test failed: ' + (error.message || error));
      } finally {
        this.isTesting = false;
      }
    },
    
    /**
     * Select or deselect all available languages
     */
    selectAllLanguages() {
      const realLanguages = this.availableLanguages.filter(lang => lang !== 'Select All');
      if (this.isAllSelected) {
        // If all selected, deselect all
        console.log('Deselecting all languages')
        this.selectedLanguages = []
      } else {
        // Otherwise select all languages (except "Select All" option itself)
        console.log('Selecting all languages')
        this.selectedLanguages = [...realLanguages]
      }
    },
    
    /**
     * Toggle select all functionality
     * @param {Event} event - Click event
     */
    toggleSelectAll(event) {
      event.preventDefault();
      const realLanguages = this.availableLanguages.filter(lang => lang !== 'Select All');
      const selectedRealLanguages = this.selectedLanguages.filter(lang => lang !== 'Select All');
      
      if (selectedRealLanguages.length === realLanguages.length) {
        // If all selected, deselect all
        this.selectedLanguages = this.selectedLanguages.filter(lang => !realLanguages.includes(lang));
      } else {
        // Otherwise select all languages
        const newSelections = [...this.selectedLanguages.filter(lang => !realLanguages.includes(lang)), ...realLanguages];
        this.selectedLanguages = newSelections;
      }
    },

    /**
     * Refresh TTS cache information
     */
    async refreshCacheInfo() {
      if (!isTauriEnv()) {
        console.error('Cannot refresh cache info: not running in Tauri environment')
        alert('Please run this application through Tauri, not directly in a browser.\nExecute: npm run dev')
        return
      }
      
      this.isRefreshingCache = true
      try {
        console.log('Refreshing TTS cache information...')
        this.cacheInfo = await invoke('get_tts_cache_info')
        console.log('Cache information refreshed:', this.cacheInfo)
      } catch (error) {
        console.error('Failed to get cache information:', error)
        alert('Failed to get cache information: ' + (error.message || error))
      } finally {
        this.isRefreshingCache = false
      }
    },

    /**
     * Clear all TTS cache files
     */
    async clearCache() {
      if (!isTauriEnv()) {
        console.error('Cannot clear cache: not running in Tauri environment')
        alert('Please run this application through Tauri, not directly in a browser.\nExecute: npm run dev')
        return
      }
      
      if (!confirm('Are you sure you want to clear all TTS cache? This will delete all cached voice files.')) {
        return
      }

      console.log('Starting TTS cache cleanup...')
      this.isClearingCache = true
      
      try {
        const clearedSize = await invoke('clear_tts_cache')
        const clearedMB = (clearedSize / (1024 * 1024)).toFixed(2)
        
        console.log(`Cache cleared successfully. Freed ${clearedMB} MB of disk space.`)
        alert(`Cache cleared successfully! Freed ${clearedMB} MB of disk space.`)
        
        // Refresh cache information
        await this.refreshCacheInfo()
        
      } catch (error) {
        console.error('Failed to clear cache:', error)
        alert('Failed to clear cache: ' + (error.message || error))
      } finally {
        this.isClearingCache = false
      }
    },

    /**
     * Format server URL for display
     * @param {string} url - Full server URL
     * @returns {string} Formatted URL for display
     */
    formatServerUrl(url) {
      if (!url) return 'Not Set'
      
      try {
        const urlObj = new URL(url)
        // Show host and port, hide protocol for cleaner display
        return urlObj.host
      } catch (error) {
        // If URL parsing fails, return the original but truncated
        return url.length > 30 ? url.substring(0, 27) + '...' : url
      }
    }
  }
}
