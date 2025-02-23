import 'package:http/http.dart' as http;
import 'dart:convert';

class TranslationService {
  final String apiKey = 'AIzaSyBCFbsbrm2eQVAsYVBInjZyTHeA2vxMW_E';

  Future<String> translateText(String text, String targetLanguage) async {
    final url = Uri.parse(
      'https://translation.googleapis.com/language/translate/v2?key=$apiKey'
    );

    try {
      final response = await http.post(
          url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'q': text,
          'target': targetLanguage,
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return jsonResponse['data']['translations'][0]['translatedText'];
      } else {
        print('Translation error: ${response.body}');
        return text; // Fallback to original text
      }
    } catch (e) {
      print('Translation exception: $e');
      return text;
    }
  }
}