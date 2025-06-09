<template>
  <div id="app">
    <header>
      <h1>🐦 Alouette - 翻译与朗读</h1>
    </header>
    
    <main>
      <!-- 翻译输入区域 -->
      <section class="translation-section">
        <h2>文本翻译</h2>
        <div class="input-group">
          <textarea 
            v-model="inputText" 
            placeholder="请输入要翻译的文本..."
            rows="4"
          ></textarea>
        </div>
        
        <div class="language-selection">
          <h3>选择翻译语言：</h3>
          <div class="language-checkboxes">
            <label v-for="lang in availableLanguages" :key="lang" class="checkbox-label">
              <input 
                type="checkbox" 
                :value="lang" 
                v-model="selectedLanguages"
              />
              {{ lang }}
            </label>
          </div>
        </div>
        
        <button 
          @click="translateText" 
          :disabled="!inputText || selectedLanguages.length === 0 || isTranslating"
          class="translate-btn"
        >
          {{ isTranslating ? '翻译中...' : '开始翻译' }}
        </button>
      </section>
      
      <!-- 翻译结果区域 -->
      <section v-if="currentTranslation" class="results-section">
        <h2>翻译结果</h2>
        <div class="original-text">
          <h3>原文：</h3>
          <p>{{ currentTranslation.original }}</p>
          <button @click="playTTS(currentTranslation.original, '中文')" class="play-btn">🔊 播放原文</button>
        </div>
        
        <div class="translations">
          <div v-for="(translation, lang) in currentTranslation.translations" :key="lang" class="translation-item">
            <h4>{{ lang }}：</h4>
            <p>{{ translation }}</p>
            <button @click="playTTS(translation, lang)" class="play-btn">🔊 播放</button>
          </div>
        </div>
        
        <button @click="saveCurrentTranslation" class="save-btn">💾 保存翻译</button>
      </section>
      
      <!-- 历史记录区域 -->
      <section class="history-section">
        <h2>翻译历史</h2>
        <button @click="loadHistory" class="refresh-btn">🔄 刷新历史</button>
        
        <div v-if="history.length === 0" class="no-history">
          暂无翻译历史
        </div>
        
        <div v-for="item in history" :key="item.id" class="history-item">
          <div class="history-header">
            <span class="timestamp">{{ formatTimestamp(item.timestamp) }}</span>
          </div>
          <div class="history-original">
            <strong>原文：</strong>{{ item.original }}
            <button @click="playTTS(item.original, '中文')" class="play-btn-small">🔊</button>
          </div>
          <div class="history-translations">
            <div v-for="(translation, lang) in item.translations" :key="lang" class="history-translation">
              <strong>{{ lang }}：</strong>{{ translation }}
              <button @click="playTTS(translation, lang)" class="play-btn-small">🔊</button>
            </div>
          </div>
        </div>
      </section>
    </main>
  </div>
</template>

<script>
import { invoke } from '@tauri-apps/api/tauri'

export default {
  name: 'App',
  data() {
    return {
      inputText: '',
      selectedLanguages: [],
      availableLanguages: [
        '英文', '日语', '韩语', '法语', '德语', '西班牙语', '俄语', '意大利语'
      ],
      isTranslating: false,
      currentTranslation: null,
      history: []
    }
  },
  mounted() {
    this.loadHistory()
  },
  methods: {
    async translateText() {
      if (!this.inputText || this.selectedLanguages.length === 0) return
      
      this.isTranslating = true
      try {
        const result = await invoke('translate_text', {
          request: {
            text: this.inputText,
            target_languages: this.selectedLanguages
          }
        })
        
        this.currentTranslation = {
          original: this.inputText,
          translations: result.translations,
          timestamp: new Date().toISOString()
        }
      } catch (error) {
        alert('翻译失败: ' + error)
      } finally {
        this.isTranslating = false
      }
    },
    
    async saveCurrentTranslation() {
      if (!this.currentTranslation) return
      
      const savedText = {
        id: Date.now().toString(),
        original: this.currentTranslation.original,
        translations: this.currentTranslation.translations,
        timestamp: this.currentTranslation.timestamp
      }
      
      try {
        await invoke('save_translation', { text: savedText })
        alert('翻译已保存！')
        this.loadHistory()
        this.inputText = ''
        this.selectedLanguages = []
        this.currentTranslation = null
      } catch (error) {
        alert('保存失败: ' + error)
      }
    },
    
    async loadHistory() {
      try {
        this.history = await invoke('load_saved_texts')
      } catch (error) {
        console.error('加载历史失败:', error)
      }
    },
    
    async playTTS(text, lang) {
      try {
        await invoke('play_tts', { text, lang })
      } catch (error) {
        alert('播放失败: ' + error)
      }
    },
    
    formatTimestamp(timestamp) {
      return new Date(timestamp).toLocaleString('zh-CN')
    }
  }
}
</script>