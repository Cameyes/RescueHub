import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class GoogleVisionService {
  static const String _apiKey = "AIzaSyBCFbsbrm2eQVAsYVBInjZyTHeA2vxMW_E";

  static Future<String> extractTextFromImage(File imageFile) async {
    final uri = Uri.parse("https://vision.googleapis.com/v1/images:annotate?key=$_apiKey");

    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    final requestPayload = {
      "requests": [
        {
          "image": {"content": base64Image},
          "features": [
            {"type": "TEXT_DETECTION"}
          ]
        }
      ]
    };

    final response = await http.post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(requestPayload),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["responses"][0]["textAnnotations"][0]["description"] ?? "";
    } else {
      throw Exception("Google Vision API Error: ${response.body}");
    }
  }
}
