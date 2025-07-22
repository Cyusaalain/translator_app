import 'package:flutter/material.dart';
import 'package:translator/translator.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:translator_app/pages/TranslationHistoryPage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ManualTranslationPage extends StatefulWidget {
  const ManualTranslationPage({super.key});

  @override
  State<ManualTranslationPage> createState() => _ManualTranslationPageState();
}

class _ManualTranslationPageState extends State<ManualTranslationPage> {
  List<Map<String, String>> _history = [];
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
    _loadHistory();
    super.initState();
    _initTts();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('translation_history');
    if (data != null) {
      final List<dynamic> decoded = jsonDecode(data);
      setState(() {
        _history = decoded.map<Map<String, String>>((item) {
          return Map<String, String>.from(item);
        }).toList();
      });
    }
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

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_history);
    await prefs.setString('translation_history', encoded);
  }

  Future<void> _speak() async {
    if (_translatedText.isEmpty) return;

    await _flutterTts.setLanguage(_outputLanguage);
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.8);
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
        _history.add({
          'input': _inputController.text,
          'translated': translation.text,
          'fromLang': _inputLanguage,
          'toLang': _outputLanguage,
        });
      });
      await _saveHistory();
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
      endDrawer: Drawer(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  "Translation History",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: _history.isEmpty
                    ? const Center(child: Text("No history found."))
                    : ListView.builder(
                        itemCount: _history.length,
                        itemBuilder: (context, index) {
                          final entry = _history[index];
                          final preview =
                              entry['translated']!
                                  .split(' ')
                                  .take(2)
                                  .join(' ') +
                              '...';

                          return ListTile(
                            title: Text(preview),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      TranslationDetailPage(entry: entry),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
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
