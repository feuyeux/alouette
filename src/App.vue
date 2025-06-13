<template>
  <div id="app">
    <!-- Settings Panel -->
    <div class="settings-panel" v-if="showSettings">
      <div class="settings-overlay" @click="showSettings = false"></div>
      <div class="settings-content">
        <h3>🔧 Application Settings</h3>

        <!-- LLM Provider Settings -->
        <div class="settings-section">
          <h4>🤖 LLM Service Configuration</h4>

          <div class="setting-group">
            <label>Provider:</label>
            <select
              v-model="llmProvider"
              class="setting-select"
              @change="onProviderChange"
            >
              <option value="ollama">Ollama</option>
              <option value="lmstudio">LM Studio</option>
            </select>
            <small
              >Choose between Ollama or LM Studio as your LLM provider</small
            >
          </div>

          <div class="setting-group">
            <label
              >{{ llmProvider === "ollama" ? "Ollama" : "LM Studio" }} Server
              Address:</label
            >
            <input
              v-model="serverUrl"
              type="url"
              :placeholder="
                llmProvider === 'ollama'
                  ? 'http://localhost:11434'
                  : 'http://localhost:1234'
              "
              class="setting-input"
            />
            <small v-if="llmProvider === 'ollama'"
              >Example: http://192.168.1.100:11434 or
              https://your-domain.com</small
            >
            <small v-else
              >Example: http://localhost:1234 (LM Studio default port)</small
            >
          </div>

          <div class="setting-group" v-if="llmProvider === 'lmstudio'">
            <label>API Key (optional):</label>
            <input
              v-model="apiKey"
              type="password"
              placeholder="Your LM Studio API key (if required)"
              class="setting-input"
            />
            <small
              >Only needed if LM Studio has API key authentication
              enabled</small
            >
          </div>

          <div class="setting-group">
            <label>AI Model:</label>
            <div class="model-selection">
              <select
                v-model="selectedModel"
                class="setting-select"
                :disabled="!availableModels.length"
              >
                <option value="">
                  {{
                    availableModels.length
                      ? "Please select a model"
                      : "Test connection first"
                  }}
                </option>
                <option
                  v-for="model in availableModels"
                  :key="model"
                  :value="model"
                >
                  {{ model }}
                </option>
              </select>
              <button
                @click="testConnection"
                class="btn-secondary btn-medium"
                :disabled="!serverUrl || isTestingConnection"
              >
                {{ isTestingConnection ? "Testing..." : "Test Connection" }}
              </button>
            </div>
            <div v-if="connectionStatus" :class="connectionStatus.type">
              {{ connectionStatus.message }}
            </div>
          </div>
        </div>

        <!-- TTS Settings -->
        <div class="settings-section">
          <h4>🔊 Text-to-Speech Settings</h4>

          <div class="setting-group">
            <label>Speech Rate:</label>
            <div class="range-setting">
              <input
                v-model="ttsSettings.rate"
                type="range"
                min="0.1"
                max="2"
                step="0.1"
                class="range-input"
              />
              <span class="range-value">{{ ttsSettings.rate }}x</span>
            </div>
          </div>

          <div class="setting-group">
            <label>Volume:</label>
            <div class="range-setting">
              <input
                v-model="ttsSettings.volume"
                type="range"
                min="0"
                max="1"
                step="0.1"
                class="range-input"
              />
              <span class="range-value"
                >{{ Math.round(ttsSettings.volume * 100) }}%</span
              >
            </div>
          </div>

          <div class="setting-group">
            <label>Pause Between Languages:</label>
            <div class="range-setting">
              <input
                v-model="ttsSettings.pauseBetweenLanguages"
                type="range"
                min="0"
                max="2000"
                step="100"
                class="range-input"
              />
              <span class="range-value"
                >{{ ttsSettings.pauseBetweenLanguages }}ms</span
              >
            </div>
          </div>

          <div class="setting-group">
            <label class="checkbox-label">
              <input
                v-model="ttsSettings.autoSelectVoice"
                type="checkbox"
                class="checkbox-input"
              />
              Auto-select matching voice
            </label>
            <small
              >Attempt to automatically select appropriate voice for each
              language</small
            >
          </div>

          <div class="setting-group">
            <button
              @click="testTTS"
              class="btn-secondary btn-medium"
              :disabled="isTesting"
            >
              {{ isTesting ? "Testing..." : "Test Speech" }}
            </button>
          </div>
        </div>

        <!-- TTS Cache Management -->
        <div class="settings-section">
          <h4>💾 Voice Cache Management</h4>

          <div class="setting-group">
            <div class="cache-info" v-if="cacheInfo">
              <p>📊 Cache Statistics:</p>
              <ul>
                <li>Cache files: {{ cacheInfo.file_count }}</li>
                <li>Disk usage: {{ cacheInfo.total_size_mb.toFixed(2) }} MB</li>
              </ul>
            </div>
            <div class="cache-buttons btn-group-tight">
              <button
                @click="refreshCacheInfo"
                class="btn-info btn-small"
                :disabled="isRefreshingCache"
              >
                {{ isRefreshingCache ? "Refreshing..." : "🔄 Refresh Info" }}
              </button>
              <button
                @click="clearCache"
                class="btn-danger btn-small"
                :disabled="isClearingCache"
              >
                {{ isClearingCache ? "Clearing..." : "🗑️ Clear Cache" }}
              </button>
            </div>
            <small
              >Cache accelerates speech synthesis for repeated texts but uses
              disk space</small
            >
          </div>
        </div>

        <div class="settings-footer btn-group">
          <button @click="saveSettings" class="btn-primary btn-medium">
            Save Settings
          </button>
          <button @click="showSettings = false" class="btn-danger btn-medium">
            Close
          </button>
        </div>
      </div>
    </div>

    <!-- Main Interface -->
    <header>
      <img
        src="./assets/alouette_circle_small.png"
        alt="Alouette Logo"
        class="header-logo"
      />
      <h1>Alouette</h1>
      <button @click="showSettings = true" class="btn-light btn-small">
        ⚙️ Settings
      </button>
    </header>

    <!-- LLM Service Status -->
    <div class="llm-status-bar">
      <div class="llm-info">
        <div class="status-section">
          <span class="status-label">🤖 LLM Service:</span>
          <span
            :class="[
              'status-value',
              {
                'status-connected': isConfigured,
                'status-disconnected': !isConfigured,
              },
            ]"
          >
            {{ isConfigured ? "Connected" : "Not Configured" }}
          </span>
        </div>
        <div class="status-section" v-if="llmProvider">
          <span class="status-label">🔧 Provider:</span>
          <span class="status-value">{{
            llmProvider === "ollama" ? "Ollama" : "LM Studio"
          }}</span>
        </div>
        <div class="status-section" v-if="serverUrl">
          <span class="status-label">🌐 Server:</span>
          <span class="status-value">{{ formatServerUrl(serverUrl) }}</span>
        </div>
        <div class="status-section" v-if="selectedModel">
          <span class="status-label">🧠 Model:</span>
          <span class="status-value">{{ selectedModel }}</span>
        </div>
        <div class="status-section" v-if="availableModels.length > 0">
          <span class="status-label">📊 Available Models:</span>
          <span class="status-value">{{ availableModels.length }}</span>
        </div>
      </div>
    </div>

    <!-- Warning Notice -->
    <div v-if="showTauriWarning" class="warning-card">
      <div class="warning-content">
        <span class="warning-icon">⚠️</span>
        <div class="warning-text">
          <strong>Notice:</strong> Currently running in web mode, speech
          features may be limited. <br />Recommended to download the desktop
          version for full functionality.
        </div>
        <button
          @click="showTauriWarning = false"
          class="btn-danger btn-mini btn-icon-only"
        >
          ×
        </button>
      </div>
    </div>

    <!-- Translation Input Section -->
    <div class="translation-section">
      <h3>🌐 Enter Text to Translate</h3>
      <div class="input-group">
        <textarea
          v-model="inputText"
          placeholder="Enter text to translate..."
          rows="3"
        ></textarea>
      </div>

      <!-- Language Selection -->
      <div class="language-container">
        <h4>📋 Select Target Languages</h4>

        <!-- Language List -->
        <div class="language-grid">
          <label
            v-for="language in availableLanguages"
            :key="language"
            class="checkbox-label"
            :class="{ 'select-all-option': language === 'Select All' }"
          >
            <input
              type="checkbox"
              :value="language"
              v-model="selectedLanguages"
              :checked="
                language === 'Select All'
                  ? isAllSelected
                  : selectedLanguages.includes(language)
              "
              @change="
                language === 'Select All' ? toggleSelectAll($event) : null
              "
            />
            <span v-if="language === 'Select All'">
              Select All ({{
                selectedLanguages.filter((lang) => lang !== "Select All")
                  .length
              }}/{{
                availableLanguages.filter((lang) => lang !== "Select All")
                  .length
              }})
            </span>
            <span v-else>{{ language }}</span>
          </label>
        </div>
      </div>

      <div class="translate-button-container">
        <button
          @click="translateText"
          :disabled="
            !inputText.trim() || selectedLanguages.length === 0 || isTranslating
          "
          class="btn-primary btn-large"
        >
          {{ isTranslating ? "🔄 Translating..." : "🚀 Start Translation" }}
        </button>
      </div>
    </div>

    <!-- Translation Results Section -->
    <div v-if="currentTranslation" class="results-section">
      <div class="results-header">
        <h3>📚 Translation Results</h3>
        <div class="control-buttons btn-group-tight">
          <button
            @click="playAll"
            :disabled="isPlayingAll || playingText"
            class="btn-primary btn-medium"
          >
            {{ isPlayingAll ? "⏸️ Pause Playback" : "🎵 Play All" }}
          </button>
          <button
            @click="stopPlayAll"
            :disabled="!playingText && !isPlayingAll"
            class="btn-danger btn-medium"
          >
            🛑 Stop
          </button>
        </div>
      </div>

      <!-- Original Text Display -->
      <div class="original-text">
        <span class="original-label">Original:</span>
        <span class="original-content">{{ currentTranslation.original }}</span>
      </div>

      <!-- Translation Results List -->
      <div class="translations">
        <div
          v-for="language in orderedLanguages"
          :key="language"
          class="translation-row"
        >
          <div class="language-name">{{ language }}</div>
          <div class="translation-text" :class="getLanguageClass(language)">
            {{ currentTranslation.translations[language] }}
          </div>
          <button
            @click="
              playTTS(currentTranslation.translations[language], language)
            "
            :disabled="
              playingText === currentTranslation.translations[language]
            "
            :class="[
              'btn-primary',
              'btn-small',
              {
                'btn-playing':
                  playingText === currentTranslation.translations[language],
              },
            ]"
          >
            {{
              playingText === currentTranslation.translations[language]
                ? "🔊"
                : "▶️"
            }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import AppScript from "./assets/script.js";
export default AppScript;
</script>

<style>
@import "./assets/styles.css";
</style>
