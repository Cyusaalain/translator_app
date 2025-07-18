import 'dart:math';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:translator/translator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'manual_translation_page.dart';

class LiveTranslationPage extends StatefulWidget {
  const LiveTranslationPage({super.key});

  @override
  State<LiveTranslationPage> createState() => _LiveTranslationPageState();
}

class _LiveTranslationPageState extends State<LiveTranslationPage>
    with SingleTickerProviderStateMixin {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _spokenText = '';
  String _translatedText = '';
  final translator = GoogleTranslator();
  final FlutterTts _flutterTts = FlutterTts();
  final Random _random = Random();

  // Animation variables
  late AnimationController _animationController;
  List<double> _animationValues = [];
  final int _waveformBars = 15;

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
    _speech = stt.SpeechToText();
    _initAnimation();
    _requestPermission();
    _initTts();
  }

  void _initAnimation() {
    _animationController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 300),
        )..addListener(() {
          setState(() {
            _animationValues = List.generate(_waveformBars, (index) {
              final baseHeight =
                  0.3 +
                  sin(_animationController.value * 2 * pi + index * 0.5).abs() *
                      0.7;
              return baseHeight * (0.8 + _random.nextDouble() * 0.2);
            });
          });
        });
  }

  Future<void> _initTts() async {
    await _flutterTts.awaitSpeakCompletion(true);
  }

  Future<void> _requestPermission() async {
    final status = await Permission.microphone.request();
    if (status.isPermanentlyDenied) {
      openAppSettings();
    }
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _animationController.repeat();
        _speech.listen(
          onResult: (val) {
            setState(() => _spokenText = val.recognizedWords);
            _translate(_spokenText);
          },
        );
      }
    } else {
      setState(() => _isListening = false);
      _animationController.stop();
      _speech.stop();
    }
  }

  void _translate(String text) async {
    if (text.isEmpty) return;

    setState(() => _translatedText = "Translating...");

    try {
      final translation = await translator.translate(
        text,
        from: _inputLanguage,
        to: _outputLanguage,
      );
      setState(() => _translatedText = translation.text);
    } catch (e) {
      setState(() => _translatedText = "Translation failed");
    }
  }

  Future<void> _speak() async {
    if (_translatedText.isEmpty) return;
    await _flutterTts.setLanguage(_outputLanguage);
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.4);
    await _flutterTts.speak(_translatedText);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _speech.stop();
    _flutterTts.stop();
    super.dispose();
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Translation'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.text_fields),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ManualTranslationPage(),
                ),
              );
            },
            tooltip: 'Manual Translation',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
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

            // Speech Input Card
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(15.0),
                child: Column(
                  children: [
                    const Text(
                      'SPEECH INPUT',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 15),

                    if (_isListening)
                      SizedBox(
                        height: 40,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: List.generate(
                            _waveformBars,
                            (index) => AnimatedContainer(
                              duration: const Duration(milliseconds: 100),
                              width: 4,
                              height: _animationValues.isNotEmpty
                                  ? _animationValues[index] * 30
                                  : 10,
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              decoration: BoxDecoration(
                                color: Colors.blueAccent,
                                borderRadius: BorderRadius.circular(2),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF42A5F5),
                                    Color(0xFF1976D2),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      Text(
                        _spokenText.isEmpty
                            ? 'Tap mic to start speaking'
                            : _spokenText,
                        style: const TextStyle(fontSize: 16),
                      ),

                    const SizedBox(height: 20),
                    FloatingActionButton(
                      onPressed: _listen,
                      backgroundColor: _isListening ? Colors.red : Colors.blue,
                      child: Icon(
                        _isListening ? Icons.mic_off : Icons.mic,
                        size: 30,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Translation Output Card
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(15.0),
                child: Column(
                  children: [
                    const Text(
                      'TRANSLATION',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      _translatedText.isEmpty
                          ? 'Translation will appear here'
                          : _translatedText,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    if (_translatedText.isNotEmpty &&
                        _translatedText != "Translating...") ...[
                      const SizedBox(height: 20),
                      IconButton(
                        icon: const Icon(Icons.volume_up, size: 30),
                        color: Colors.green,
                        onPressed: _speak,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
