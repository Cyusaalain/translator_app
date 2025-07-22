import 'package:flutter/material.dart';

class TranslationDetailPage extends StatelessWidget {
  final Map<String, String> entry;
  final VoidCallback? onDelete;

  const TranslationDetailPage({super.key, required this.entry, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final fromLang = entry['fromLang'] ?? '';
    final toLang = entry['toLang'] ?? '';
    final inputText = entry['input'] ?? '';
    final translatedText = entry['translated'] ?? '';
    final timestamp = entry['timestamp'];
    final date = timestamp != null ? DateTime.tryParse(timestamp) : null;
    final formattedDate = date != null
        ? "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}"
        : "Unknown time";

    return Scaffold(
      appBar: AppBar(title: const Text("Translation Detail")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Language Pair:",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "$fromLang ➝ $toLang",
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Saved At:",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formattedDate,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const Divider(height: 30),
                  const Text(
                    "Original Text:",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(inputText, style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 16),
                  const Text(
                    "Translated Text:",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    translatedText,
                    style: const TextStyle(fontSize: 16, color: Colors.green),
                  ),
                  if (onDelete != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: Center(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          onPressed: onDelete,
                          icon: const Icon(Icons.delete),
                          label: const Text("Delete"),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
