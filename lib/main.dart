import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:translator/translator.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(LiveTranslatorApp());
}

class LiveTranslatorApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Live Translator',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: TranslatorHomePage(),
    );
  }
}

class TranslatorHomePage extends StatefulWidget {
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
    await Permission.microphone.request();
  }

  void _listen() async {
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

  void _translate(String input) async {
    if (input.trim().isEmpty) return;
    final translation = await translator.translate(
      input,
      from: _inputLanguage,
      to: _outputLanguage,
    );
    setState(() {
      _translatedText = translation.text;
    });
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
            Text(_spokenText),
            SizedBox(height: 20),
            Text('Translation:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(
              _translatedText,
              style: TextStyle(fontSize: 18, color: Colors.blue),
            ),
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
