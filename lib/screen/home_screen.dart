import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:deep_gptl/service/translation_service.dart';
import 'package:deep_gptl/screen/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clipboard/clipboard.dart';

const platform = MethodChannel('com.example.deep_gptl/activate');

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? fromLanguage = 'Japanese';
  String? toLanguage = 'English';
  String translationResult = '';
  TextEditingController textController = TextEditingController();
  bool isLoading = false;
  bool hasError = false;
  FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _initPlatformState();
    _loadDefaultLanguages();
  }

  Future<void> _initPlatformState() async {
    platform.setMethodCallHandler(_handleMethod);
  }

  Future<void> _loadDefaultLanguages() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      fromLanguage = prefs.getString('default_from_language') ?? 'Japanese';
      toLanguage = prefs.getString('default_to_language') ?? 'English';
    });
  }

  Future<void> _handleMethod(MethodCall call) async {
    if (call.method == 'activate') {
      final clipboardContent = await Clipboard.getData('text/plain');
      String clipboardText = clipboardContent?.text ?? '';
      textController.text = clipboardText;
      await _handleTranslation();
    } else {
      throw PlatformException(
        code: 'Unimplemented',
        details: 'deep_gptl for macOS not implemented: ${call.method}',
      );
    }
  }

  Future<void> _handleTranslation() async {
    if (textController.text.isEmpty) return;
    setState(() => _startLoading());
    try {
      final translationService = TranslationService();
      final result = await translationService.translateText(
          textController.text, fromLanguage!, toLanguage!);
      setState(() => _updateTranslationResult(result));
    } catch (e) {
      setState(() => _setErrorState());
    }
  }

  void _startLoading() {
    translationResult = '';
    isLoading = true;
    hasError = false;
  }

  void _updateTranslationResult(String result) {
    translationResult = result;
    isLoading = false;
  }

  void _setErrorState() {
    isLoading = false;
    hasError = true;
  }

  Future<String> _fetchSelectedModel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('chat_gpt_model') ?? 'gpt-3.5-turbo-0125';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Deep-GPTL'),
        actions: [_settingsButton()],
      ),
      body: _buildBody(),
    );
  }

  Widget _settingsButton() {
    return IconButton(
      icon: Icon(Icons.settings),
      onPressed: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SettingsScreen()),
        );
        if (result == true) {
          setState(() {});
        }
      },
    );
  }

  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildLanguageSelectors(),
          SizedBox(height: 16),
          _buildTranslateButton(),
          SizedBox(height: 16),
          Divider(thickness: 1, color: Colors.grey),
          _buildTranslationFields(),
          SizedBox(height: 16),
          _buildErrorText(),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildLanguageSelectors() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _languageDropdown('From', fromLanguage, (newValue) {
          setState(() => fromLanguage = newValue);
        }),
        _swapLanguagesButton(),
        _languageDropdown('To', toLanguage, (newValue) {
          setState(() => toLanguage = newValue);
        }),
      ],
    );
  }

  Widget _languageDropdown(
      String label, String? value, ValueChanged<String?> onChanged) {
    return Expanded(
      child: InputDecorator(
        decoration:
            InputDecoration(labelText: label, border: OutlineInputBorder()),
        child: DropdownButton<String>(
          isExpanded: true,
          hint: Text('Select language'),
          value: value,
          items: ['Japanese', 'English'].map((String value) {
            return DropdownMenuItem<String>(value: value, child: Text(value));
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _swapLanguagesButton() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(Icons.swap_horiz),
          onPressed: () {
            setState(() {
              final temp = fromLanguage;
              fromLanguage = toLanguage;
              toLanguage = temp;
            });
          },
        ),
        Text(
          '⇧+⇔',
          style: TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildTranslateButton() {
    return ElevatedButton(
      onPressed: _handleTranslation,
      child: Text('Translate(⇧+⏎)'),
    );
  }

  Widget _buildTranslationFields() {
    return Expanded(
      child: Row(
        children: [
          _buildTextInputField(),
          SizedBox(width: 16),
          _buildTranslationResultField(),
        ],
      ),
    );
  }

  Widget _buildTextInputField() {
    return Expanded(
      child: RawKeyboardListener(
        focusNode: _focusNode,
        onKey: (event) {
          if (event.isShiftPressed &&
              event.logicalKey == LogicalKeyboardKey.enter) {
            _handleTranslation();
          }
        },
        child: TextField(
          controller: textController,
          decoration: InputDecoration(
            hintText: 'Enter text to translate',
            suffixIcon: _textFieldIcons(textController, false),
          ),
          minLines: 20,
          maxLines: 20,
        ),
      ),
    );
  }

  Widget _buildTranslationResultField() {
    return Expanded(
      child: isLoading
          ? Center(child: CircularProgressIndicator())
          : TextField(
              readOnly: true,
              controller: TextEditingController(text: translationResult),
              decoration: InputDecoration(
                hintText: 'Translation result',
                suffixIcon: _textFieldIcons(textController, true),
              ),
              minLines: 20,
              maxLines: 20,
            ),
    );
  }

  Widget _textFieldIcons(TextEditingController controller, bool isResultField) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(Icons.clear),
          onPressed: () {
            if (isResultField) {
              setState(() => translationResult = '');
            } else {
              controller.clear();
            }
          },
        ),
        IconButton(
          icon: Icon(Icons.content_copy),
          onPressed: () {
            FlutterClipboard.copy(
                    isResultField ? translationResult : controller.text)
                .then(
              (value) => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Copied to clipboard')),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildErrorText() {
    return hasError
        ? const Text(
            'An error occurred during translation. Please try again.',
            style: TextStyle(color: Colors.red),
          )
        : Container();
  }

  Widget _buildFooter() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(0.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          FutureBuilder<String>(
            future: _fetchSelectedModel(),
            builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              } else {
                return Text(
                  'Model: ${snapshot.data}',
                  style: TextStyle(fontSize: 8),
                );
              }
            },
          ),
          Row(
            children: [
              Text(
                '♥',
                style: TextStyle(color: Colors.red, fontSize: 8),
              ),
              Text(" Suns' Up Product", style: TextStyle(fontSize: 8)),
            ],
          ),
        ],
      ),
    );
  }
}
