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
        // (Germanic)
        'English', 'German',
        // (Romance) 
        'French', 'Spanish', 'Italian',
        // (Slavic)
        'Russian',
        // (Hellenic)
        'Greek',
        // (Indo-Aryan)
        'Hindi',
        // (Afro-Asiatic)
        'Arabic',
        // (Sino-Tibetan)
        'Chinese',
        // (Japonic)
        'Japanese',
        // (Koreanic)
        'Korean',
        'Select All'
      ],
      isTranslating: false,
      currentTranslation: null,

      // TTS playback state
      playingText: null, // Track currently playing text
      isPlayingAll: false, // Track if playing all translations
      showTauriWarning: false, // Show Tauri environment warning

      // LLM configuration
      showSettings: false,
      llmProvider: localStorage.getItem('llmProvider') || 'ollama',
      serverUrl: localStorage.getItem('serverUrl') || '',
      apiKey: localStorage.getItem('apiKey') || '',
      selectedModel: localStorage.getItem('selectedModel') || '',
      availableModels: [],
      isTestingConnection: false,
      connectionStatus: null,

      // Legacy support for existing Ollama configurations
      ollamaUrl: localStorage.getItem('ollamaUrl') || 'http://localhost:11434',

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

    // Migrate legacy Ollama configuration
    if (!localStorage.getItem('llmProvider') && localStorage.getItem('ollamaUrl')) {
      console.log('Migrating legacy Ollama configuration...')
      this.llmProvider = 'ollama'
      this.serverUrl = this.ollamaUrl
      localStorage.setItem('llmProvider', 'ollama')
      localStorage.setItem('serverUrl', this.ollamaUrl)
    } else if (!this.serverUrl) {
      // Set default URLs based on provider
      this.serverUrl = this.llmProvider === 'ollama' ? 'http://localhost:11434' : 'http://localhost:1234'
    }

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
      llmProvider: this.llmProvider,
      serverUrl: this.serverUrl,
      selectedModel: this.selectedModel,
      ttsSettings: this.ttsSettings
    })
  },

  computed: {
    /**
     * Check if LLM provider is properly configured
     * @returns {boolean} True if both server URL and model are configured
     */
    isConfigured() {
      return this.serverUrl && this.selectedModel;
    },

    /**
     * Check if all real languages are selected
     * @returns {boolean} True if all languages except 'Select All' are selected
     */
    isAllSelected() {
      const realLanguages = this.availableLanguages.filter(lang => lang !== 'Select All');
      const selectedRealLanguages = this.selectedLanguages.filter(lang => lang !== 'Select All');
      return selectedRealLanguages.length === realLanguages.length && realLanguages.length > 0;
    },

    /**
     * Get ordered languages based on user selection order
     * @returns {string[]} Languages ordered by selection order
     */
    orderedLanguages() {
      if (!this.currentTranslation || !this.currentTranslation.translations) {
        return [];
      }

      // Use the saved language order if available
      if (this.currentTranslation.selectedLanguageOrder) {
        return this.currentTranslation.selectedLanguageOrder.filter(lang =>
          this.currentTranslation.translations.hasOwnProperty(lang)
        );
      }

      // Fallback: use current selection order (for backward compatibility)
      const selectedRealLanguages = this.selectedLanguages.filter(lang => lang !== 'Select All');
      return selectedRealLanguages.filter(lang =>
        this.currentTranslation.translations.hasOwnProperty(lang)
      );
    }
  },
  methods: {
    /**
     * Handle provider change event
     */
    onProviderChange() {
      console.log('Provider changed to:', this.llmProvider);

      // Update default server URL based on provider
      if (this.llmProvider === 'ollama') {
        this.serverUrl = 'http://localhost:11434';
      } else if (this.llmProvider === 'lmstudio') {
        this.serverUrl = 'http://localhost:1234';
      }

      // Clear existing model selection and available models
      this.selectedModel = '';
      this.availableModels = [];
      this.connectionStatus = null;
    },

    /**
     * Format server URL for display
     * @param {string} url - Server URL
     * @returns {string} Formatted URL
     */
    formatServerUrl(url) {
      if (!url) return '';
      try {
        const urlObj = new URL(url);
        return `${urlObj.hostname}:${urlObj.port}`;
      } catch {
        return url;
      }
    },

    /**
     * Main translation function - translates input text to selected languages
     * Uses configured LLM provider (Ollama or LM Studio) for AI-powered translation
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
        console.error('Translation aborted: LLM provider not configured')
        alert('Please configure your LLM provider and model first');
        this.showSettings = true;
        return;
      }

      // Check Tauri environment
      if (!isTauriEnv()) {
        console.error('Translation aborted: not running in Tauri environment')
        alert('Please run this application through Tauri, not directly in a browser.\nExecute: npm run dev')
        return
      }

      // Set loading state
      this.isTranslating = true

      try {
        console.log('Sending translation request:', {
          text: this.inputText,
          targetLanguages: realSelectedLanguages,
          provider: this.llmProvider,
          serverUrl: this.serverUrl,
          modelName: this.selectedModel,
          apiKey: this.apiKey
        })

        // Call Tauri backend for translation
        const result = await invoke('translate_text', {
          request: {
            text: this.inputText,
            target_languages: realSelectedLanguages,
            provider: this.llmProvider,
            server_url: this.serverUrl,
            model_name: this.selectedModel,
            api_key: this.apiKey || null
          }
        })

        console.log('Translation completed successfully:', result)

        this.currentTranslation = {
          original: this.inputText,
          translations: result.translations,
          selectedLanguageOrder: [...realSelectedLanguages], // Preserve user's selected language order
          timestamp: new Date().toISOString()
        }

        // Keep input for potential re-translation with different settings
        // this.inputText = ''
        // this.selectedLanguages = []

      } catch (error) {
        console.error('Translation failed:', error)
        // Handle different types of errors more gracefully
        let errorMessage = 'Unknown error occurred'
        if (error && error.message) {
          errorMessage = error.message
        } else if (typeof error === 'string') {
          errorMessage = error
        } else if (error) {
          errorMessage = error.toString()
        }
        alert('Translation failed: ' + errorMessage)
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
        // Auto-detect language for original text
        const originalLanguage = this.detectLanguage(this.currentTranslation.original)
        console.log('Playing original text:', this.currentTranslation.original, 'Detected language:', originalLanguage)
        await this.playTTSPromise(this.currentTranslation.original, originalLanguage)

        // Use orderedLanguages to play translations in the same order as displayed
        for (const lang of this.orderedLanguages) {
          if (!this.isPlayingAll) break // User interrupted playback

          // Brief pause between languages
          await new Promise(resolve => setTimeout(resolve, this.ttsSettings.pauseBetweenLanguages))

          if (this.isPlayingAll && this.currentTranslation.translations[lang]) {
            console.log(`Playing ${lang}:`, this.currentTranslation.translations[lang])
            await this.playTTSPromise(this.currentTranslation.translations[lang], lang)
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
     * Test connection to LLM provider and fetch available models
     */
    async testConnection() {
      if (!this.serverUrl) {
        this.connectionStatus = { type: 'error', message: 'Please enter server address' };
        return;
      }

      console.log(`Testing connection to ${this.llmProvider} server:`, this.serverUrl)
      this.isTestingConnection = true;
      this.connectionStatus = { type: 'info', message: 'Testing connection...' };

      try {
        const models = await invoke('connect_llm', {
          provider: this.llmProvider,
          serverUrl: this.serverUrl,
          apiKey: this.apiKey || null
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
      if (!this.serverUrl || !this.selectedModel) {
        alert('Please fill in all configuration fields');
        return;
      }

      console.log('Saving application settings...')

      // Save LLM provider configuration to localStorage
      localStorage.setItem('llmProvider', this.llmProvider);
      localStorage.setItem('serverUrl', this.serverUrl);
      localStorage.setItem('selectedModel', this.selectedModel);
      if (this.apiKey) {
        localStorage.setItem('apiKey', this.apiKey);
      }

      // Save TTS settings to localStorage
      localStorage.setItem('ttsRate', this.ttsSettings.rate.toString());
      localStorage.setItem('ttsVolume', this.ttsSettings.volume.toString());
      localStorage.setItem('ttsPause', this.ttsSettings.pauseBetweenLanguages.toString());
      localStorage.setItem('ttsAutoSelect', this.ttsSettings.autoSelectVoice.toString());

      console.log('Settings saved successfully:', {
        llmProvider: this.llmProvider,
        serverUrl: this.serverUrl,
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
    },

    /**
     * Detect the language of input text using simple character analysis
     * @param {string} text - Text to analyze
     * @returns {string} Detected language name
     */
    detectLanguage(text) {
      if (!text || text.trim().length === 0) return 'English'

      const trimmedText = text.trim()

      // Chinese characters (CJK Unified Ideographs)
      if (/[\u4e00-\u9fff]/.test(trimmedText)) {
        return 'Chinese'
      }

      // Japanese characters (Hiragana, Katakana, and Kanji)
      if (/[\u3040-\u309f\u30a0-\u30ff\u4e00-\u9fff]/.test(trimmedText)) {
        return 'Japanese'
      }

      // Korean characters (Hangul)
      if (/[\uac00-\ud7af\u1100-\u11ff\u3130-\u318f]/.test(trimmedText)) {
        return 'Korean'
      }

      // Arabic characters
      if (/[\u0600-\u06ff\u0750-\u077f]/.test(trimmedText)) {
        return 'Arabic'
      }

      // Hindi characters (Devanagari)
      if (/[\u0900-\u097f]/.test(trimmedText)) {
        return 'Hindi'
      }

      // Russian/Cyrillic characters
      if (/[\u0400-\u04ff]/.test(trimmedText)) {
        return 'Russian'
      }

      // Greek characters
      if (/[\u0370-\u03ff]/.test(trimmedText)) {
        return 'Greek'
      }

      // For Latin-based languages, use simple heuristics
      const lowerText = trimmedText.toLowerCase()

      // French detection (common French words and accents)
      if (/[àâäçéèêëïîôöùûüÿ]/.test(lowerText) ||
        /\b(le|la|les|un|une|des|et|est|dans|pour|avec|sur|par|du|de|il|elle)\b/.test(lowerText)) {
        return 'French'
      }

      // German detection (common German words and characters)
      if (/[äöüß]/.test(lowerText) ||
        /\b(der|die|das|und|ist|in|zu|den|von|mit|auf|für|wird|eine|einem|einem)\b/.test(lowerText)) {
        return 'German'
      }

      // Spanish detection (common Spanish words and accents)
      if (/[áéíóúñü]/.test(lowerText) ||
        /\b(el|la|los|las|un|una|y|es|en|de|por|para|con|se|que|su|al)\b/.test(lowerText)) {
        return 'Spanish'
      }

      // Italian detection (common Italian words and accents)
      if (/[àèéìíîòóù]/.test(lowerText) ||
        /\b(il|la|lo|le|gli|un|una|e|è|in|di|per|con|da|su|del|della)\b/.test(lowerText)) {
        return 'Italian'
      }

      // Default to English for Latin scripts
      return 'English'
    },

    /**
     * Get CSS class for language-specific styling
     * @param {string} language - Language name
     * @returns {string} CSS class name for the language
     */
    getLanguageClass(language) {
      const langLower = language.toLowerCase();

      if (langLower.includes('hindi')) {
        return 'lang-hindi';
      } else if (langLower.includes('arabic')) {
        return 'lang-arabic';
      } else if (langLower.includes('russian')) {
        return 'lang-russian';
      }

      return '';
    },

    /**
     * Clear input text and selected languages
     */
    clearInput() {
      console.log('Clearing input text and selected languages')
      this.inputText = ''
      this.selectedLanguages = []
    },
  }
}
