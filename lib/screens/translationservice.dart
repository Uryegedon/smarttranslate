import 'dart:convert';
import 'package:http/http.dart' as http;

Future<String> translateText(String text) async {
  final Uri url = Uri.parse('http://100.119.152.32:8000/translate/');

  try {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'text': text}),
    );

    print('Server response: ${response.body}'); // For debug

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data is Map<String, dynamic> && data.containsKey('translated_text')) {
        return data['translated_text'] ?? '';
      } else {
        throw Exception('Invalid server response: missing "translated_text" key.');
      }
    } else {
      throw Exception('Server returned status code: ${response.statusCode}');
    }
  } catch (e) {
    print('Request failed: $e');
    // Optional: Retry once
    await Future.delayed(Duration(milliseconds: 500)); // small wait
    try {
      final retryResponse = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'text': text}),
      );

      if (retryResponse.statusCode == 200) {
        final data = json.decode(retryResponse.body);
        if (data is Map<String, dynamic> && data.containsKey('translated_text')) {
          return data['translated_text'] ?? '';
        }
      }
      throw Exception('Retry failed: Server error ${retryResponse.statusCode}');
    } catch (retryError) {
      throw Exception('Translation failed after retry: $retryError');
    }
  }
}
