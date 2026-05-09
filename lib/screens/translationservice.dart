import 'dart:convert';
import 'package:http/http.dart' as http;

Future<String> translateText(
  String text,
  String sourceLanguage,
  String targetLanguage,
) async {
  final Uri url = Uri.parse('http://100.119.152.32:8000/translate/');

  try {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'text': text,
        'source_language': sourceLanguage,
        'target_language': targetLanguage,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data is Map<String, dynamic> && data.containsKey('translated_text')) {
        return data['translated_text'] ?? '';
      } else {
        throw Exception(
          'Invalid server response: missing "translated_text" key.',
        );
      }
    } else {
      throw Exception('Server returned status code: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Translation failed: $e');
  }
}
