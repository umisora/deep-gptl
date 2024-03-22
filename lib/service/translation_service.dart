import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class TranslationService {
  Future<String> fetchApiToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('api_token') ?? '';
  }

  Future<String> fetchSelectedModel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('selected_model') ?? 'gpt-3.5-turbo-0125';
  }

  Future<String> translateText(String text, String from, String to) async {
    try {
      final apiToken = await fetchApiToken();
      final headers = {
        'Authorization': 'Bearer $apiToken',
        'Content-Type': 'application/json',
      };
      final selectedModel = await fetchSelectedModel(); // 追加
      final body = json.encode({
        'model': selectedModel,
        "messages": [
          {
            "role": "system",
            "content":
                "You are the translator. You translate the received message into the specified language. No explanations or supplements are required for the output results."
          },
          {
            "role": "user",
            "content": "Translate the following text from $from to $to: $text"
          }
        ],
        'max_tokens': 1000,
      });

      final response = await http.post(
        Uri.parse(
            'https://api.openai.com/v1/chat/completions'), // 適切なエンドポイントに変更
        headers: headers,
        body: body,
      );
      if (response.statusCode != 200) {
        print('Error response: ${response.body}');
        throw Exception('Failed to get translation');
      }
      print('Response headers: ${response.headers}');
      print(response.body);
      final responseBody = json.decode(utf8.decode(response.bodyBytes));
      final translation = responseBody['choices'][0]['message']['content'];
      return translation;
    } catch (e) {
      print('Error during translation: $e');
      if (e is http.ClientException) {
        print('ClientException message: ${e.message}');
      }
      throw Exception('Failed to translate text');
    }
  }
}


    // if (response.statusCode == 200) {

    // } else {
    //   throw Exception('Failed to translate text');
    // }