
# 🌍 Manual Translation App

A multilingual text translator Flutter app that allows users to manually input text, select source and target languages, translate content using Google's translator API, and listen to the translated output via text-to-speech (TTS). The app also stores a history of translations with detail view support.

---

## ✨ Features

- 🔤 Manual text input for translation
- 🌐 Supports multiple languages (English, French, Spanish, Kinyarwanda, Swahili, Arabic, Chinese)
- 🗣️ Text-to-Speech support for translated text
- 🕘 Translation history with preview
- 📜 Detail view for each translation
- 🎨 Simple, clean, and responsive UI

---

## 🧪 Technologies Used

- Flutter (Dart)
- [google_translator](https://pub.dev/packages/translator) – for translations
- [flutter_tts](https://pub.dev/packages/flutter_tts) – for speech output

---

## 📂 Project Structure

```
lib/
├── main.dart
├── pages/
│   ├── manual_translation_page.dart   # Main UI and logic
│   └── translation_detail_page.dart   # Full history detail view
```

---

## Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/cyusaalain/translation_app.git
cd translation_app
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Run the App

```bash
flutter run
```

---

## 🛠️ Setup Notes

- Ensure you have Flutter SDK installed. You can verify it by running:

```bash
flutter doctor
```

- This app does **not require Firebase** or any external API key since the `google_translator` package uses public access.
- If you're testing on Android, ensure microphone/speaker permissions are handled in `AndroidManifest.xml` (for TTS to work reliably).

---

## 🧩 Design Considerations

- **Dropdowns for Language Selection:** Designed to reduce user errors with clear country flags and language labels.
- **Drawer-Based History:** Allows quick access to recent translations without cluttering the main interface.
- **State Management:** Uses `setState()` for simplicity, but can be scaled using `Provider` or `Riverpod` if needed.
- **Accessibility:** Basic support for visual clarity, contrast, and readable fonts. TTS helps visually impaired users.

---

## 📌 Future Improvements

- 🔒 Save history persistently using `SharedPreferences` or SQLite
- 🌐 Add language auto-detect
- 🎤 Add speech input for source text
- 🧠 Integrate with AI-based context-aware translation models

---

## 📃 License

still waiting

---

## 🙌 Author

Made with ❤️ by [UMUHIRE Cyusa Alain]
