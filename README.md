# Alouette

A collection of Flutter applications for translation and text-to-speech functionality.

## Sub-projects

This repository contains three sub-projects:

### 1. [alouette-app](https://github.com/feuyeux/alouette-app)
The main Flutter application that combines translation and TTS functionality.

### 2. [alouette-translator](https://github.com/feuyeux/alouette-translator)
A Flutter application focused on translation services.

### 3. [alouette-tts](https://github.com/feuyeux/alouette-tts)
A Flutter application for text-to-speech functionality.

## Getting Started

Each sub-project has its own README with specific setup instructions. To work with all projects:

```bash
# Clone the main repository with submodules
git clone --recursive https://github.com/feuyeux/alouette.git

# Or if you've already cloned, initialize submodules
git submodule update --init --recursive
```

## Development

Each sub-project is a separate Flutter application that can be developed independently:

- Navigate to the specific project directory
- Follow the setup instructions in that project's README
- Use Flutter commands as normal (`flutter run`, `flutter build`, etc.)

## Architecture

- **alouette-app**: Main application combining features from both translator and TTS
- **alouette-translator**: Specialized translation service application
- **alouette-tts**: Specialized text-to-speech application

## License

This project is licensed under the MIT License - see the individual project LICENSE files for details.
