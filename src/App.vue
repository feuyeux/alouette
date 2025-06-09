<template>
  <div id="app">
    <!-- Tauri 环境警告 -->
    <div v-if="showTauriWarning" class="tauri-warning">
      <h3>⚠️ 环境错误</h3>
      <p>请通过 Tauri 应用运行此程序，而不是直接在浏览器中打开。</p>
      <p>正确的启动方式：</p>
      <code>npm run dev</code>
      <p>然后使用弹出的应用窗口，而不是浏览器标签页。</p>
      <div class="debug-info">
        <details>
          <summary>调试信息 (点击展开)</summary>
          <pre>{{ debugInfo }}</pre>
        </details>
      </div>
    </div>
    
    <!-- 调试面板 -->
    <div class="debug-panel">
      <h4>环境状态:</h4>
      <div :class="{ 'status-good': !showTauriWarning, 'status-bad': showTauriWarning }">
        {{ showTauriWarning ? '❌ 浏览器环境' : '✅ Tauri 应用环境' }}
      </div>
    </div>
    
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
          <div class="language-controls">
            <button @click="selectAllLanguages" class="select-all-btn" type="button">
              {{ isAllSelected ? '取消全选' : '全选' }}
            </button>
            <span class="selected-count">已选择: {{ selectedLanguages.length }}/{{ availableLanguages.length }}</span>
          </div>
          <div class="language-checkboxes">
            <label v-for="lang in filteredLanguages" :key="lang" class="checkbox-label">
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
          <div class="play-controls">
            <button @click="playTTS(currentTranslation.original, '中文')" 
                    :class="{ playing: playingText === currentTranslation.original }"
                    class="play-btn-small">
              {{ playingText === currentTranslation.original ? '🔊 播放中...' : '🔊 播放原文' }}
            </button>
            <button @click="playAll" 
                    :disabled="isPlayingAll"
                    class="play-all-btn">
              {{ isPlayingAll ? '🔊 播放全部中...' : '🔊 播放全部' }}
            </button>
            <button @click="stopPlayAll" 
                    v-if="isPlayingAll"
                    class="stop-btn">
              ⏹️ 停止
            </button>
          </div>
        </div>
        
        <div class="translations">
          <div v-for="(translation, lang) in currentTranslation.translations" :key="lang" class="translation-item">
            <div class="translation-header">
              <h4>{{ lang }}：</h4>
              <button @click="playTTS(translation, lang)" 
                      :class="{ playing: playingText === translation }"
                      class="play-btn-small">
                {{ playingText === translation ? '🔊 播放中...' : '🔊 播放' }}
              </button>
            </div>
            <p>{{ translation }}</p>
          </div>
        </div>
      </section>
    </main>
  </div>
</template>

<script>
import { invoke } from '@tauri-apps/api/core'

// 检查是否在 Tauri 环境中运行
const isTauriEnv = () => {
  if (typeof window === 'undefined') return false
  
  // 检查多个可能的 Tauri 全局变量
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
      inputText: '',
      selectedLanguages: [],
      languageFilter: '', // 语言搜索过滤器
      availableLanguages: [
        '英语', '日语', '韩语', '法语', '德语', '西班牙语', '俄语', '意大利语',
        '印地语', '希腊语', '阿拉伯语'
      ],
      isTranslating: false,
      currentTranslation: null,
      playingText: null, // 追踪当前正在播放的文本
      isPlayingAll: false, // 追踪是否正在播放全部
      showTauriWarning: false, // 显示 Tauri 环境警告
      debugInfo: '' // 调试信息
    }
  },
  mounted() {
    // 收集调试信息
    this.debugInfo = JSON.stringify({
      hasWindow: typeof window !== 'undefined',
      hasTauri: !!window.__TAURI__,
      hasTauriInternals: !!window.__TAURI_INTERNALS__,
      hasTauriMetadata: !!window.__TAURI_METADATA__,
      userAgent: navigator.userAgent,
      location: window.location.href,
      isTauriEnv: isTauriEnv()
    }, null, 2)
    
    // 调试信息
    console.log('Window object keys:', Object.keys(window))
    console.log('__TAURI__:', window.__TAURI__)
    console.log('__TAURI_INTERNALS__:', window.__TAURI_INTERNALS__)
    console.log('__TAURI_METADATA__:', window.__TAURI_METADATA__)
    console.log('User Agent:', navigator.userAgent)
    console.log('Is Tauri Env:', isTauriEnv())
    
    // 检查 Tauri 环境
    if (!isTauriEnv()) {
      this.showTauriWarning = true
      console.warn('Not running in Tauri environment!')
    } else {
      console.log('✅ Running in Tauri environment')
    }
  },
  computed: {
    filteredLanguages() {
      if (!this.languageFilter) {
        return this.availableLanguages
      }
      return this.availableLanguages.filter(lang => 
        lang.toLowerCase().includes(this.languageFilter.toLowerCase())
      )
    },
    isAllSelected() {
      return this.selectedLanguages.length === this.availableLanguages.length
    }
  },
  methods: {
    async translateText() {
      if (!this.inputText || this.selectedLanguages.length === 0) return
      
      // 检查 Tauri 环境
      if (!isTauriEnv()) {
        alert('请通过 Tauri 应用运行此程序，而不是直接在浏览器中打开。\n请运行: npm run dev')
        return
      }
      
      this.isTranslating = true
      try {
        // 使用本地Ollama进行翻译
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
        
        // 清空输入
        this.inputText = ''
        this.selectedLanguages = []
      } catch (error) {
        console.error('翻译错误:', error)
        alert('翻译失败: ' + error.message)
      } finally {
        this.isTranslating = false
      }
    },
    
    async playTTS(text, lang) {
      // 检查 Tauri 环境
      if (!isTauriEnv()) {
        alert('请通过 Tauri 应用运行此程序，而不是直接在浏览器中打开。\n请运行: npm run dev')
        return
      }
      
      try {
        // 设置播放状态
        this.playingText = text
        console.log(`准备播放TTS - 文本: "${text}", 语言: ${lang}`)
        
        // 使用系统TTS
        await invoke('play_tts', { text, lang })
        
        this.playingText = null
      } catch (error) {
        console.error('播放错误:', error)
        this.playingText = null
        alert('播放失败: ' + error.message)
      }
    },

    async playAll() {
      if (!this.currentTranslation || this.isPlayingAll) return
      
      this.isPlayingAll = true
      
      try {
        // 首先播放原文
        if (this.isPlayingAll) {
          await this.playTTSPromise(this.currentTranslation.original, '中文')
        }
        
        // 然后依次播放所有翻译
        for (const [lang, translation] of Object.entries(this.currentTranslation.translations)) {
          if (!this.isPlayingAll) break // 如果用户中断了播放
          
          // 在每个语音之间添加短暂停顿
          await new Promise(resolve => setTimeout(resolve, 500))
          if (this.isPlayingAll) {
            await this.playTTSPromise(translation, lang)
          }
        }
      } catch (error) {
        console.error('播放全部失败:', error)
        alert('播放全部失败: ' + error.message)
      } finally {
        this.isPlayingAll = false
        this.playingText = null
      }
    },

    stopPlayAll() {
      this.isPlayingAll = false
      this.playingText = null
      // Note: Tauri TTS stopping would need to be implemented in the backend
      console.log('停止播放全部')
    },

    // Promise版本的TTS播放，用于串行播放
    playTTSPromise(text, lang) {
      return new Promise(async (resolve, reject) => {
        try {
          this.playingText = text
          await invoke('play_tts', { text, lang })
          this.playingText = null
          resolve()
        } catch (error) {
          this.playingText = null
          reject(new Error(`语音播放失败 (${lang}): ${error.message}`))
        }
      })
    },
    
    selectAllLanguages() {
      if (this.isAllSelected) {
        // 如果全部已选中，则取消全选
        this.selectedLanguages = []
      } else {
        // 否则选择全部语言
        this.selectedLanguages = [...this.availableLanguages]
      }
    }
  }
}
</script>

<style scoped>
#app {
  max-width: 800px;
  margin: 0 auto;
  padding: 20px;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  min-height: 100vh;
  position: relative;
}

#app::before {
  content: '';
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background: radial-gradient(circle at 30% 20%, rgba(255, 255, 255, 0.1) 0%, transparent 50%),
              radial-gradient(circle at 70% 80%, rgba(255, 255, 255, 0.05) 0%, transparent 50%);
  pointer-events: none;
  z-index: -1;
}

header {
  text-align: center;
  margin-bottom: 30px;
  padding: 25px;
  background: rgba(255, 255, 255, 0.08);
  backdrop-filter: blur(20px);
  -webkit-backdrop-filter: blur(20px);
  border: 1px solid rgba(255, 255, 255, 0.15);
  border-radius: 20px;
  box-shadow: 
    0 8px 32px rgba(0, 0, 0, 0.1),
    inset 0 1px 0 rgba(255, 255, 255, 0.2);
}

.logo-container {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 15px;
  margin-bottom: 10px;
}

.header-logo {
  width: 64px;
  height: 64px;
  filter: drop-shadow(0 8px 24px rgba(0, 0, 0, 0.15));
  transition: all 0.4s cubic-bezier(0.4, 0, 0.2, 1);
  background: rgba(255, 255, 255, 0.02);
  border-radius: 12px;
  padding: 6px;
  backdrop-filter: blur(10px);
  -webkit-backdrop-filter: blur(10px);
  border: 1px solid rgba(255, 255, 255, 0.1);
}

.header-logo:hover {
  transform: scale(1.08) translateY(-2px);
  filter: drop-shadow(0 12px 36px rgba(0, 0, 0, 0.2));
  background: rgba(255, 255, 255, 0.05);
  border: 1px solid rgba(255, 255, 255, 0.2);
}

header h1 {
  color: #2c3e50;
  margin: 0;
  font-size: 2.2em;
  font-weight: 700;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
  text-shadow: none;
}

.subtitle {
  color: #7f8c8d;
  font-size: 14px;
  margin: 8px 0 0 0;
  font-weight: normal;
}

.translation-section, .results-section {
  background: rgba(255, 255, 255, 0.1);
  backdrop-filter: blur(20px);
  -webkit-backdrop-filter: blur(20px);
  border: 1px solid rgba(255, 255, 255, 0.2);
  padding: 25px;
  border-radius: 20px;
  margin-bottom: 20px;
  box-shadow: 
    0 8px 32px rgba(0, 0, 0, 0.1),
    inset 0 1px 0 rgba(255, 255, 255, 0.2);
}

.input-group textarea {
  width: 100%;
  padding: 15px;
  border: 2px solid #e1e8ed;
  border-radius: 8px;
  font-size: 16px;
  resize: vertical;
  font-family: inherit;
}

.input-group textarea:focus {
  outline: none;
  border-color: #3498db;
}

.language-controls {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 15px;
  padding: 10px;
  background: #f8f9fa;
  border-radius: 6px;
  border: 1px solid #e1e8ed;
}

.select-all-btn {
  background: #3498db;
  color: white;
  border: none;
  padding: 8px 16px;
  border-radius: 6px;
  cursor: pointer;
  font-size: 14px;
  font-weight: bold;
  transition: all 0.3s;
}

.select-all-btn:hover {
  background: #2980b9;
  transform: translateY(-1px);
}

.selected-count {
  color: #7f8c8d;
  font-size: 14px;
  font-weight: bold;
}

.language-checkboxes {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(120px, 1fr));
  gap: 10px;
  margin: 15px 0;
  padding: 15px;
  border: 1px solid #e1e8ed;
  border-radius: 8px;
  background: #fafbfc;
}

.checkbox-label {
  display: flex;
  align-items: center;
  gap: 8px;
  cursor: pointer;
  padding: 8px 12px;
  border-radius: 6px;
  transition: background-color 0.2s;
}

.checkbox-label:hover {
  background-color: #e8f4f8;
}

.translate-btn {
  background: #27ae60;
  color: white;
  border: none;
  padding: 12px 30px;
  border-radius: 8px;
  font-size: 16px;
  font-weight: bold;
  cursor: pointer;
  transition: all 0.3s;
}

.translate-btn:hover:not(:disabled) {
  background: #219a52;
  transform: translateY(-2px);
}

.translate-btn:disabled {
  background: #bdc3c7;
  cursor: not-allowed;
  transform: none;
}

.original-text, .translation-item {
  background: white;
  padding: 20px;
  border-radius: 8px;
  margin-bottom: 15px;
  border-left: 4px solid #3498db;
}

.translation-item {
  border-left-color: #27ae60;
}

.play-btn-small {
  background: #e74c3c;
  color: white;
  border: none;
  padding: 6px 12px;
  border-radius: 6px;
  cursor: pointer;
  font-size: 12px;
  transition: all 0.3s;
  margin-right: 8px;
}

.play-btn-small:hover {
  background: #c0392b;
  transform: translateY(-1px);
}

.play-btn-small.playing {
  background: #f39c12;
  animation: pulse 1.5s infinite;
}

.play-all-btn {
  background: #8e44ad;
  color: white;
  border: none;
  padding: 6px 12px;
  border-radius: 6px;
  cursor: pointer;
  font-size: 12px;
  transition: all 0.3s;
}

.play-all-btn:hover:not(:disabled) {
  background: #732d91;
  transform: translateY(-1px);
}

.play-all-btn:disabled {
  background: #bdc3c7;
  cursor: not-allowed;
  transform: none;
  animation: pulse 1.5s infinite;
}

.stop-btn {
  background: #e74c3c;
  color: white;
  border: none;
  padding: 6px 12px;
  border-radius: 6px;
  cursor: pointer;
  font-size: 12px;
  transition: all 0.3s;
}

.stop-btn:hover {
  background: #c0392b;
  transform: translateY(-1px);
}

.play-controls {
  display: flex;
  align-items: center;
  margin-top: 10px;
  gap: 8px;
}

.translation-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 8px;
}

.translation-header h4 {
  margin: 0;
}

@keyframes pulse {
  0% { opacity: 1; }
  50% { opacity: 0.7; }
  100% { opacity: 1; }
}

h2, h3, h4 {
  color: #2c3e50;
  margin-top: 0;
}

p {
  line-height: 1.6;
  color: #34495e;
}

.tauri-warning {
  background: rgba(231, 76, 60, 0.9);
  color: white;
  padding: 20px;
  border-radius: 12px;
  margin-bottom: 20px;
  backdrop-filter: blur(10px);
  -webkit-backdrop-filter: blur(10px);
  border: 1px solid rgba(255, 255, 255, 0.2);
  text-align: center;
}

.tauri-warning h3 {
  color: white;
  margin: 0 0 15px 0;
  font-size: 1.2em;
}

.tauri-warning p {
  color: rgba(255, 255, 255, 0.9);
  margin: 8px 0;
}

.tauri-warning code {
  background: rgba(0, 0, 0, 0.3);
  padding: 4px 8px;
  border-radius: 4px;
  font-family: 'Courier New', monospace;
  color: #ffd700;
  font-weight: bold;
}

.debug-info {
  margin-top: 15px;
  text-align: left;
}

.debug-info details {
  background: rgba(0, 0, 0, 0.2);
  padding: 10px;
  border-radius: 6px;
}

.debug-info pre {
  font-size: 12px;
  color: #f8f8f2;
  margin: 5px 0;
  overflow-x: auto;
}

.debug-panel {
  background: rgba(255, 255, 255, 0.1);
  padding: 15px;
  border-radius: 8px;
  margin-bottom: 20px;
  text-align: center;
  backdrop-filter: blur(10px);
  -webkit-backdrop-filter: blur(10px);
  border: 1px solid rgba(255, 255, 255, 0.2);
}

.debug-panel h4 {
  margin: 0 0 10px 0;
  color: #2c3e50;
}

.status-good {
  color: #27ae60;
  font-weight: bold;
  font-size: 16px;
}

.status-bad {
  color: #e74c3c;
  font-weight: bold;
  font-size: 16px;
}
</style>