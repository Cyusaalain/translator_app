import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:translator/translator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'manual_translation_page.dart';
import 'package:flutter/services.dart';
import 'theme_provider.dart';

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
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _currentUser;

  late AnimationController _animationController;
  List<double> _animationValues = [];
  final int _waveformBars = 15;
  final Random _random = Random();

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
    _currentUser = _auth.currentUser;
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

  Future<void> _logout() async {
    await _auth.signOut();
    Navigator.pushReplacementNamed(context, '/');
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
    } catch (_) {
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

  void _showOptionsSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        height: MediaQuery.of(context).size.height * 0.5,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: const Icon(Icons.translate),
              title: const Text("Manual Translation"),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ManualTranslationPage(),
                ),
              ),
            ),
            const Spacer(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text("Logout", style: TextStyle(color: Colors.red)),
              onTap: _logout,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _speech.stop();
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
                  "Settings",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              RadioListTile<AppTheme>(
                title: const Text("Light Theme"),
                value: AppTheme.light,
                groupValue: context.watch<ThemeProvider>().currentTheme,
                onChanged: (theme) =>
                    context.read<ThemeProvider>().setTheme(theme!),
              ),
              RadioListTile<AppTheme>(
                title: const Text("Dark Theme"),
                value: AppTheme.dark,
                groupValue: context.watch<ThemeProvider>().currentTheme,
                onChanged: (theme) =>
                    context.read<ThemeProvider>().setTheme(theme!),
              ),
              RadioListTile<AppTheme>(
                title: const Text("Blue Theme"),
                value: AppTheme.blue,
                groupValue: context.watch<ThemeProvider>().currentTheme,
                onChanged: (theme) =>
                    context.read<ThemeProvider>().setTheme(theme!),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.translate),
                title: const Text("Manual Translation"),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ManualTranslationPage(),
                  ),
                ),
              ),
              const Spacer(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  "Logout",
                  style: TextStyle(color: Colors.red),
                ),
                onTap: _logout,
              ),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        title: const Text('Live Translation'),
        centerTitle: true,
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
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
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(15.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'SPEECH INPUT',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (_isListening)
                            SizedBox(
                              height: 40,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: List.generate(
                                  _waveformBars,
                                  (index) => AnimatedContainer(
                                    duration: const Duration(milliseconds: 100),
                                    width: 4,
                                    height: _animationValues.isNotEmpty
                                        ? _animationValues[index] * 30
                                        : 10,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blueAccent,
                                      borderRadius: BorderRadius.circular(2),
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
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _isListening ? Icons.mic_off : Icons.mic,
                        size: 30,
                        color: Colors.white,
                      ),
                      onPressed: _listen,
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.all(
                          _isListening ? Colors.red : Colors.blue,
                        ),
                        shape: WidgetStateProperty.all(const CircleBorder()),
                        padding: WidgetStateProperty.all(
                          const EdgeInsets.all(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(15.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TRANSLATION',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      _translatedText.isEmpty
                          ? 'Translation will appear here'
                          : _translatedText,
                    ),
                    if (_translatedText.isNotEmpty &&
                        _translatedText != "Translating...") ...[
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.volume_up, size: 30),
                            color: Colors.green,
                            onPressed: _speak,
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy, size: 28),
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
