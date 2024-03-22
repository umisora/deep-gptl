import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class TranslationService {
  Future<String> fetchApiToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('api_token') ?? '';
  }

  Future<String> fetchAnthropicApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('anthropic_api_key') ?? '';
  }

  Future<String> fetchSelectedModel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('selected_model') ?? 'gpt-3.5-turbo-0125';
  }

  Future<String> translateText(String text, String from, String to) async {
    try {
      final apiToken = await fetchApiToken();
      final selectedModel = await fetchSelectedModel();
      Uri endpointUri;
      Map<String, String> headers;
      String body;
      if (selectedModel.contains('gpt')) {
        // OpenAI GPTモデルの設定
        endpointUri = Uri.parse('https://api.openai.com/v1/chat/completions');
        headers = {
          'Authorization': 'Bearer $apiToken',
          'Content-Type': 'application/json',
        };
        body = json.encode({
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
        print('OpenAI APIリクエスト: $selectedModel');
      } else if (selectedModel.contains('claude')) {
        // Anthropic Claudeモデルの設定
        final anthropicApiKey = await fetchAnthropicApiKey();
        endpointUri = Uri.parse('https://api.anthropic.com/v1/messages');
        headers = {
          'x-api-key': '$anthropicApiKey',
          'anthropic-version': '2023-06-01',
          'Content-Type': 'application/json',
        };
        body = json.encode({
          // Anthropic APIに特有のリクエストボディの形式
          'model': selectedModel,
          'system':
              "You are the translator. You translate the received message into the specified language. No explanations or supplements are required for the output results.",
          'messages': [
            {
              "role": "user",
              "content": "Translate the following text from $from to $to: $text"
            }
          ],
          'max_tokens': 1024,
        });
        print('Anthropic APIリクエスト: $selectedModel');
      } else {
        throw Exception('Unsupported model');
      }

      final startTime = DateTime.now();
      final response = await http.post(
        endpointUri,
        headers: headers,
        body: body,
      );
      final endTime = DateTime.now();
      print('レスポンス時間: ${endTime.difference(startTime)}');

      if (response.statusCode != 200) {
        print('Error response: ${response.body}');
        throw Exception('Failed to get translation');
      }

      final responseBody = json.decode(utf8.decode(response.bodyBytes));
      // APIの応答形式に応じて適切に変更
      String translation;
      if (selectedModel.contains('gpt')) {
        translation = responseBody['choices'][0]['message']['content'];
      } else if (selectedModel.contains('claude')) {
        // Anthropicの応答形式に合わせた処理
        translation = responseBody['content'][0]['text']; // 仮のパス
      } else {
        throw Exception('Unsupported model response');
      }

      return translation;
    } catch (e) {
      print('Error during translation: $e');
      throw Exception('Failed to translate text');
    }
  }
}
