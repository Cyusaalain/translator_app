import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:translator/translator.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'TranslationHistoryPage.dart';
import 'dart:convert';

class ManualTranslationPage extends StatefulWidget {
  const ManualTranslationPage({super.key});

  @override
  State<ManualTranslationPage> createState() => _ManualTranslationPageState();
}

class TranslationEntry {
  final String original;
  final String translated;
  final String fromLang;
  final String toLang;

  TranslationEntry({
    required this.original,
    required this.translated,
    required this.fromLang,
    required this.toLang,
  });

  Map<String, dynamic> toJson() => {
    'original': original,
    'translated': translated,
    'fromLang': fromLang,
    'toLang': toLang,
  };

  factory TranslationEntry.fromJson(Map<String, dynamic> json) {
    return TranslationEntry(
      original: json['original'],
      translated: json['translated'],
      fromLang: json['fromLang'],
      toLang: json['toLang'],
    );
  }
}

class TranslationDetailPage extends StatelessWidget {
  final TranslationEntry entry;

  const TranslationDetailPage({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Full Translation")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "From (${entry.fromLang}):",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(entry.original),
                const SizedBox(height: 20),
                Text(
                  "To (${entry.toLang}):",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(entry.translated),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ManualTranslationPageState extends State<ManualTranslationPage> {
  final translator = GoogleTranslator();
  final TextEditingController _inputController = TextEditingController();
  final FlutterTts _flutterTts = FlutterTts();
  String _translatedText = '';
  bool _isTranslating = false;
  bool _isSpeaking = false;
  List<Map<String, String>> _translationHistory = [];

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
    _loadHistory();
  }

  Future<void> _initTts() async {
    await _flutterTts.awaitSpeakCompletion(true);
    _flutterTts.setStartHandler(() => setState(() => _isSpeaking = true));
    _flutterTts.setCompletionHandler(() => setState(() => _isSpeaking = false));
    _flutterTts.setErrorHandler((_) => setState(() => _isSpeaking = false));
  }

  Future<void> _speak() async {
    if (_translatedText.isEmpty) return;
    await _flutterTts.setLanguage(_outputLanguage);
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.8);
    await _flutterTts.speak(_translatedText);
  }

  Future<void> _translate() async {
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

      _saveToHistory(_inputController.text, translation.text);
    } catch (e) {
      setState(() {
        _translatedText = 'Translation failed';
        _isTranslating = false;
      });
    }
  }

  Future<void> saveTranslationToFirestore(String input, String output) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('translations');

    await docRef.add({
      'input': input,
      'output': output,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<List<Map<String, dynamic>>>
  loadTranslationHistoryFromFirestore() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('translations')
        .orderBy('timestamp', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {'input': data['input'] ?? '', 'output': data['output'] ?? ''};
    }).toList();
  }

  void _saveToHistory(String original, String translated) async {
    final entry = {'from': original, 'to': translated};
    _translationHistory.add(entry);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'translation_history',
      jsonEncode(_translationHistory),
    );
    setState(() {});
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('translation_history');
    if (jsonStr != null) {
      try {
        final decoded = json.decode(jsonStr);
        if (decoded is List) {
          setState(() {
            _translationHistory = List<Map<String, String>>.from(
              decoded.map((e) => Map<String, String>.from(e)),
            );
          });
        }
      } catch (e) {
        print("⚠️ Error loading history: $e");
      }
    } else {
      print("ℹ️ No history found.");
    }
  }

  Future<void> _clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('translation_history');
    setState(() => _translationHistory.clear());
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
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  "Translation History",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: _translationHistory.isEmpty
                    ? const Center(child: Text("No history yet"))
                    : ListView.builder(
                      itemCount: history.length,
                      itemBuilder: (context, index) {
                        final entry = history[index];
                        final firstTwoWords = entry.translated.split(' ').take(2).join(' ') + '...';
                        return ListTile(
                          title: Text(firstTwoWords),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TranslationDetailPage(entry: entry),
                              ),
                            );
                          },
                        );
                      },
                    )
              ),
            ],
              TextButton.icon(
                onPressed: _clearHistory,
                icon: const Icon(Icons.delete, color: Colors.red),
                label: const Text(
                  "Clear History",
                  style: TextStyle(color: Colors.red),
                ),
              ),
              const SizedBox(height: 10),
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
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.history),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
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
              ElevatedButton.icon(
                onPressed: _isTranslating ? null : _translate,
                icon: const Icon(Icons.translate),
                label: Text(_isTranslating ? 'Translating...' : 'Translate'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
              const SizedBox(height: 30),
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
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: Icon(
                                  _isSpeaking
                                      ? Icons.volume_off
                                      : Icons.volume_up,
                                ),
                                color: _isSpeaking ? Colors.red : Colors.green,
                                onPressed: _isSpeaking
                                    ? _flutterTts.stop
                                    : _speak,
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy),
                                onPressed: () {
                                  Clipboard.setData(
                                    ClipboardData(text: _translatedText),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Copied to clipboard"),
                                    ),
                                  );
                                },
                              ),
                            ],
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
