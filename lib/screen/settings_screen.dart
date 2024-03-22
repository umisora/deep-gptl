import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  TextEditingController apiTokenController = TextEditingController();
  String? defaultFromLanguage;
  String? defaultToLanguage;
  String? originalApiToken;
  String? chatGPTModel; // 追加
  bool apiTokenChanged = false; // 追加

  Future<void> saveApiToken() async {
    if (!apiTokenChanged) return; // 変更がなければ保存しない
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      prefs.setString('api_token', apiTokenController.text);
    });
  }

  Future<void> saveDefaultLanguages() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      prefs.setString('default_from_language', defaultFromLanguage ?? '');
      prefs.setString('default_to_language', defaultToLanguage ?? '');
      prefs.setString('chat_gpt_model', chatGPTModel ?? ''); // 追加
    });
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    String apiToken = prefs.getString('api_token') ?? '';

    setState(() {
      apiTokenController.text = maskApiToken(apiToken);
      originalApiToken = apiToken; // 保存しておく
      defaultFromLanguage = prefs.getString('default_from_language');
      defaultToLanguage = prefs.getString('default_to_language');
      chatGPTModel = prefs.getString('chat_gpt_model') ??
          'gpt-3.5-turbo-0125'; // デフォルト値を設定
    });
  }

  String maskApiToken(String token) {
    if (token.length < 8) return token;
    return token.substring(0, 3) + '****' + token.substring(token.length - 4);
  }

  @override
  void initState() {
    super.initState();
    loadSettings();
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text(
              'Application Name',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Description',
              style: TextStyle(fontSize: 18),
            ),
            Text('Your awesome translation app'),
            Text('HP URL: https://example.com'),
            SizedBox(height: 20),
            TextField(
              controller: apiTokenController,
              decoration: InputDecoration(
                labelText: 'API Token',
              ),
              onChanged: (value) {
                // ユーザーによる変更をチェック
                apiTokenChanged = value != originalApiToken;
              },
            ),
// From Language Dropdown
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'From',
              ),
              hint: Text('Default From Language'),
              value: defaultFromLanguage,
              items: ['Japanese', 'English'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  defaultFromLanguage = newValue;
                });
              },
            ),

// To Language Dropdown
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'To',
              ),
              hint: Text('Default To Language'),
              value: defaultToLanguage,
              items: ['Japanese', 'English'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  defaultToLanguage = newValue;
                });
              },
            ),
            // ChatGPT Model Dropdown
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'ChatGPT Model',
              ),
              hint: Text('Select ChatGPT Model'),
              value: chatGPTModel,
              items: ['gpt-3.5-turbo-0125', 'gpt-4-0125-preview']
                  .map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  chatGPTModel = newValue;
                });
              },
            ),
            SizedBox(height: 10),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await saveApiToken();
                await saveDefaultLanguages();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('Setting Saved'),
                      duration: Duration(milliseconds: 500)),
                );
                Navigator.pop(context, true);
              },
              child: Text('Save Settings'),
            ),
          ],
        ),
      ),
    );
  }
}
