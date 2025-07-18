import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:translator/translator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'pages/home.dart';
import 'pages/manual_translation.dart';
import 'pages/tts.dart';

void main() {
  runApp(LiveTranslatorApp());
}

class LiveTranslatorApp extends StatelessWidget {
  const LiveTranslatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Live Translator',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const TranslatorHomePage(),
    );
  }
}

class TranslatorHomePage extends StatefulWidget {
  const TranslatorHomePage({super.key});

  @override
  _TranslatorHomePageState createState() => _TranslatorHomePageState();
}

class _TranslatorHomePageState extends State<TranslatorHomePage> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _spokenText = '';
  String _translatedText = '';
  final translator = GoogleTranslator();

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _requestPermission();
  }

  Future<void> _requestPermission() async {
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      await Permission.microphone.request();
    }
    if (await Permission.microphone.isPermanentlyDenied) {
      openAppSettings(); // opens system settings so user can re-enable mic
    }
  }

  void _listen() async {
    var micStatus = await Permission.microphone.status;

    if (!micStatus.isGranted) {
      micStatus = await Permission.microphone.request();
    }
    if (!micStatus.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Microphone permission is required.')),
      );
      return;
    }
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => print('STATUS: $val'),
        onError: (val) => print('ERROR: $val'),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) {
            setState(() {
              _spokenText = val.recognizedWords;
            });
            _translate(_spokenText);
          },
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  final Map<String, String> _languages = {
    '🇬🇧 English': 'en',
    '🇫🇷 French': 'fr',
    '🇪🇸 Spanish': 'es',
    '🇷🇼 Kinyarwanda': 'rw',
    '🇸🇿 Swahili': 'sw',
    '🇸🇦 Arabic': 'ar',
    '🇨🇳 Chinese (Simplified)': 'zh-cn',
  };
  String _inputLanguage = 'en'; // Default input language (for UI only)
  String _outputLanguage = 'fr'; // Default translation language

  void _translate([String? input]) async {
    String text = input ?? _textController.text.trim();
    if (text.isEmpty) return;

    final translation = await translator.translate(
      text,
      from: _inputLanguage,
      to: _outputLanguage,
    );

    setState(() {
      _translatedText = translation.text;
    });
  }

  final TextEditingController _textController = TextEditingController();

  Future<void> _speak(String text) async {
    if (text.isEmpty) return;
    // Set language
    await _flutterTts.setLanguage(getTtsLanguageCode(_outputLanguage));

    // Set optional speech settings
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.5);

    await _flutterTts.speak(text);
  }

  final FlutterTts _flutterTts = FlutterTts();
  String getTtsLanguageCode(String code) {
    switch (code) {
      case 'en':
        return 'en-US';
      case 'fr':
        return 'fr-FR';
      case 'es':
        return 'es-ES';
      case 'sw':
        return 'sw'; // Swahili
      case 'ar':
        return 'ar-SA';
      case 'zh-cn':
        return 'zh-CN';
      case 'rw':
        return 'en-US'; // fallback, since Kinyarwanda TTS isn’t widely supported
      default:
        return 'en-US';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Live Translator')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Spoken:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(_spokenText.isEmpty ? 'No speech input yet.' : _spokenText),
            SizedBox(height: 20),
            Text(
              'Manual Text Input:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: 'Try something...',
                border: OutlineInputBorder(),
              ),
              minLines: 1,
              maxLines: 3,
            ),
            SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _translate,
              icon: Icon(Icons.translate),
              label: Text('Translate Text'),
            ),
            SizedBox(height: 20),
            Text('Translation:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(
              _translatedText.isEmpty ? 'No translation yet.' : _translatedText,
              style: TextStyle(fontSize: 18, color: Colors.blue),
            ),
            SizedBox(height: 20),
            if (_translatedText.isNotEmpty)
              ElevatedButton.icon(
                onPressed: () => _speak(_translatedText),
                icon: Icon(Icons.volume_up),
                label: Text('Speak Translation'),
              ),
            // SEARCH ERROR
            Divider(height: 40),

            Text('Select Input Language:'),
            DropdownButton<String>(
              value: _inputLanguage,
              onChanged: (newValue) {
                setState(() {
                  _inputLanguage = newValue!;
                });
              },
              items: _languages.entries.map((entry) {
                return DropdownMenuItem<String>(
                  value: entry.value,
                  child: Text(entry.key),
                );
              }).toList(),
            ),

            SizedBox(height: 10),

            Text('Select Output Language:'),
            DropdownButton<String>(
              value: _outputLanguage,
              onChanged: (newValue) {
                setState(() {
                  _outputLanguage = newValue!;
                });
              },
              items: _languages.entries.map((entry) {
                return DropdownMenuItem<String>(
                  value: entry.value,
                  child: Text(entry.key),
                );
              }).toList(),
            ),

            Spacer(),
            ElevatedButton.icon(
              onPressed: _listen,
              icon: Icon(_isListening ? Icons.mic_off : Icons.mic),
              label: Text(_isListening ? 'Stop Listening' : 'Start Listening'),
            ),
          ],
        ),
      ),
    );
  }
}
