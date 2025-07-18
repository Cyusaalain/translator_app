import 'package:flutter/material.dart';
import 'package:translator/translator.dart';
import 'package:flutter_tts/flutter_tts.dart';

class ManualTranslationPage extends StatefulWidget {
  const ManualTranslationPage({super.key});

  @override
  State<ManualTranslationPage> createState() => _ManualTranslationPageState();
}

class _ManualTranslationPageState extends State<ManualTranslationPage> {
  final translator = GoogleTranslator();
  final TextEditingController _inputController = TextEditingController();
  final FlutterTts _flutterTts = FlutterTts();
  String _translatedText = '';
  bool _isTranslating = false;
  bool _isSpeaking = false;

  final Map<String, String> _languages = {
    '🇬🇧 English': 'en',
    '🇫🇷 French': 'fr',
    '🇪🇸 Spanish': 'es',
    '🇷🇼 Kinyarwanda': 'rw',
    '🇸🇿 Swahili': 'sw',
    '🇸🇦 Arabic': 'ar',
    '🇨🇳 Chinese': 'zh-cn',
  };
  String _inputLanguage = 'en';
  String _outputLanguage = 'fr';

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  Future<void> _initTts() async {
    await _flutterTts.awaitSpeakCompletion(true);
    _flutterTts.setStartHandler(() {
      setState(() => _isSpeaking = true);
    });
    _flutterTts.setCompletionHandler(() {
      setState(() => _isSpeaking = false);
    });
    _flutterTts.setErrorHandler((message) {
      setState(() => _isSpeaking = false);
    });
  }

  Future<void> _speak() async {
    if (_translatedText.isEmpty) return;

    await _flutterTts.setLanguage(_outputLanguage);
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.speak(_translatedText);
  }

  void _translate() async {
    if (_inputController.text.isEmpty) return;

    setState(() {
      _isTranslating = true;
      _translatedText = '';
    });

    try {
      final translation = await translator.translate(
        _inputController.text,
        from: _inputLanguage,
        to: _outputLanguage,
      );

      setState(() {
        _translatedText = translation.text;
        _isTranslating = false;
      });
    } catch (e) {
      setState(() {
        _translatedText = 'Translation failed';
        _isTranslating = false;
      });
    }
  }

  Widget _buildLanguageDropdown(
    String label,
    String value,
    ValueChanged<String?> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 5),
        DropdownButtonFormField<String>(
          value: value,
          onChanged: onChanged,
          items: _languages.entries.map((entry) {
            return DropdownMenuItem<String>(
              value: entry.value,
              child: Text(entry.key),
            );
          }).toList(),
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          ),
          isExpanded: true,
        ),
      ],
    );
  }

  @override
  void dispose() {
    _inputController.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manual Translation'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Language Selection
              Row(
                children: [
                  Expanded(
                    child: _buildLanguageDropdown(
                      'From',
                      _inputLanguage,
                      (val) => setState(() => _inputLanguage = val!),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildLanguageDropdown(
                      'To',
                      _outputLanguage,
                      (val) => setState(() => _outputLanguage = val!),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // Text Input
              TextField(
                controller: _inputController,
                decoration: InputDecoration(
                  labelText: 'Enter text to translate',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _inputController.clear();
                      setState(() => _translatedText = '');
                    },
                  ),
                ),
                maxLines: 5,
                minLines: 3,
              ),

              const SizedBox(height: 20),

              // Translate Button
              ElevatedButton.icon(
                onPressed: _isTranslating ? null : _translate,
                icon: const Icon(Icons.translate),
                label: Text(_isTranslating ? 'Translating...' : 'Translate'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),

              const SizedBox(height: 30),

              // Translation Result
              Card(
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Column(
                    children: [
                      const Text(
                        'TRANSLATION RESULT',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 15),
                      _isTranslating
                          ? const CircularProgressIndicator()
                          : Text(
                              _translatedText.isEmpty
                                  ? 'Translation will appear here'
                                  : _translatedText,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                      if (_translatedText.isNotEmpty && !_isTranslating)
                        Padding(
                          padding: const EdgeInsets.only(top: 15),
                          child: IconButton(
                            icon: Icon(
                              _isSpeaking ? Icons.volume_off : Icons.volume_up,
                              size: 30,
                            ),
                            color: _isSpeaking ? Colors.red : Colors.green,
                            onPressed: _isSpeaking ? _flutterTts.stop : _speak,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
