# Alouette - Multilingual Text-to-Speech Tool

A powerful web-based multilingual text-to-speech application built with Tauri that supports reading text in multiple languages with AI-powered translation capabilities.

## Setup

### Prerequisites
- [Node.js](https://nodejs.org/) (v16 or higher)
- [Rust](https://rustup.rs/) (latest stable version)
- [Ollama](https://ollama.ai/) with qwen2.5:7b model installed

### Installation

```bash
npm config set registry https://registry.npmmirror.com
# Or
npm config delete registry
npm config set proxy http://localhost:7897
npm config set https-proxy http://localhost:7897

npm install
```

## Run

### Development
```bash
# Start Ollama server
ollama serve

# Run in development mode
npm run tauri dev
```

### Production
```bash
# Build for production
npm run tauri build
```
