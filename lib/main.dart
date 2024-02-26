import 'package:flutter/material.dart';
import 'package:ai_translation_gpt/service/translation_service.dart';
import 'package:ai_translation_gpt/screen/settings_screen.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clipboard/clipboard.dart';

void main() {
  runApp(MyTranslatorApp());
}

class MyTranslatorApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? fromLanguage = 'Japanese'; // Fromのデフォルト言語
  String? toLanguage = 'English'; // Toのデフォルト言語
  String translationResult = ''; // 翻訳結果を保持する変数
  TextEditingController textController = TextEditingController(); // テキスト入力を管理
  bool isLoading = false; // 翻訳中かどうかを追跡する変数
  bool hasError = false; // エラーが発生したかどうかを追跡する変数
  FocusNode _focusNode = FocusNode();

  Future<void> handleTranslation() async {
    setState(() {
      translationResult = ''; // 結果をクリア
      isLoading = true; // ローディング開始
      hasError = false; // エラーをクリア
    });

    final textToTranslate = textController.text;
    final translationService = TranslationService();

    try {
      final result = await translationService.translateText(
          textToTranslate, fromLanguage!, toLanguage!);
      setState(() {
        translationResult = result;
        isLoading = false; // ローディング終了
      });
    } catch (e) {
      print('Error during translation: $e');
      setState(() {
        isLoading = false; // ローディング終了
        hasError = true; // エラーをセット
      });
    }
  }

  Future<void> loadDefaultLanguages() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      fromLanguage = prefs.getString('default_from_language') ?? 'Japanese';
      toLanguage = prefs.getString('default_to_language') ?? 'English';
    });
  }

  @override
  void initState() {
    super.initState();
    loadDefaultLanguages();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AI Translator powered by GPT'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'From',
                      border: OutlineInputBorder(),
                    ),
                    child: DropdownButton<String>(
                      isExpanded: true, // 必要に応じて
                      hint: Text('Select language'),
                      value: fromLanguage,
                      items: ['Japanese', 'English'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          fromLanguage = newValue;
                        });
                      },
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.swap_horiz),
                  onPressed: () {
                    setState(() {
                      // FromとToの言語を切り替える
                      final temp = fromLanguage;
                      fromLanguage = toLanguage;
                      toLanguage = temp;
                    });
                  },
                ),
                Expanded(
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'To',
                      border: OutlineInputBorder(),
                    ),
                    child: DropdownButton<String>(
                      isExpanded: true, // 必要に応じて
                      hint: Text('Select language'),
                      value: toLanguage,
                      items: ['Japanese', 'English'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          toLanguage = newValue;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: handleTranslation, // Translateボタンの処理
              child: Text('Translate'),
            ),
            SizedBox(height: 16),
            Divider(
              thickness: 1, // 線の太さを設定できます
              color: Colors.grey, // 線の色を設定できます
            ),
            // 翻訳データのフィールドと翻訳結果フィールドを横並びにする
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: RawKeyboardListener(
                      focusNode: _focusNode,
                      onKey: (event) {
                        if (event.isShiftPressed &&
                            event.logicalKey == LogicalKeyboardKey.enter) {
                          handleTranslation(); // 翻訳処理を実行
                        }
                      },
                      child: TextField(
                        controller: textController,
                        decoration: InputDecoration(
                          hintText: 'Enter text to translate',
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.clear),
                                onPressed: () {
                                  textController.clear();
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.content_copy),
                                onPressed: () {
                                  FlutterClipboard.copy(textController.text)
                                      .then(
                                    (value) => ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      SnackBar(
                                          content: Text('Copied to clipboard')),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        minLines: 20, // 20行を最初から表示
                        maxLines: 20,
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: isLoading
                        ? Center(
                            child: SizedBox(
                              height: 32,
                              width: 32,
                              child: CircularProgressIndicator(),
                            ),
                          ) // ローディング中
                        : TextField(
                            readOnly: true,
                            controller:
                                TextEditingController(text: translationResult),
                            decoration: InputDecoration(
                              hintText: 'Translation result',
                              suffixIcon: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.clear),
                                    onPressed: () {
                                      setState(() {
                                        translationResult = '';
                                      });
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.content_copy),
                                    onPressed: () {
                                      FlutterClipboard.copy(translationResult)
                                          .then(
                                        (value) => ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content:
                                                  Text('Copied to clipboard')),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            minLines: 20, // 20行を最初から表示
                            maxLines: 20,
                          ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            hasError
                ? Text(
                    'An error occurred during translation. Please try again.',
                    style: TextStyle(color: Colors.red),
                  )
                : Container(),
            Container(
              color: Colors.white,
              padding: EdgeInsets.all(0.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '♥',
                    style: TextStyle(color: Colors.red, fontSize: 8),
                  ),
                  Text(" Suns' Up Product", style: TextStyle(fontSize: 8)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
