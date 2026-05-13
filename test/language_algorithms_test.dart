import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smarttranslate_app/services/language_algorithms.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LanguageAlgorithms', () {
    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
      await LanguageAlgorithms.loadVocabulary(force: true);
    });

    test('uses trie prefix search for autocomplete', () {
      final suggestions = LanguageAlgorithms.autocomplete(
        prefix: 'ba',
        language: 'Filipino',
      );

      expect(suggestions, contains('bahay'));
    });

    test('uses phrase context for current-word autocomplete', () {
      final suggestions = LanguageAlgorithms.autocompleteText(
        text: 'i wou',
        language: 'English',
      );

      expect(suggestions, contains('would'));
      expect(suggestions, isNot(contains('i would like to order')));
    });

    test('autocompletes only the active word inside a phrase', () {
      final suggestions = LanguageAlgorithms.autocompleteText(
        text: 'i would li',
        language: 'English',
      );

      expect(suggestions, contains('like'));
    });

    test('uses local vocabulary for shopping active-word autocomplete', () {
      final suggestions = LanguageAlgorithms.autocompleteText(
        text: 'i need cha',
        language: 'English',
      );

      expect(suggestions.first, 'charger');
    });

    test('uses local vocabulary for travel active-word autocomplete', () {
      final suggestions = LanguageAlgorithms.autocompleteText(
        text: 'where is the sta',
        language: 'English',
      );

      expect(suggestions.first, 'station');
    });

    test('uses local vocabulary for food active-word autocomplete', () {
      final suggestions = LanguageAlgorithms.autocompleteText(
        text: 'i want wat',
        language: 'English',
      );

      expect(suggestions.first, 'water');
    });

    test('uses nearby context words for natural active-word autocomplete', () {
      final suggestions = LanguageAlgorithms.autocompleteText(
        text: 'phone cha',
        language: 'English',
      );

      expect(suggestions.first, 'charger');
    });

    test('uses local vocabulary for Spanish autocomplete', () {
      final suggestions = LanguageAlgorithms.autocompleteText(
        text: 'necesito carg',
        language: 'Spanish',
      );

      expect(suggestions.first, 'cargador');
    });

    test('uses local vocabulary for Filipino autocomplete', () {
      final suggestions = LanguageAlgorithms.autocompleteText(
        text: 'kailangan ko charg',
        language: 'Filipino',
      );

      expect(suggestions.first, 'charger');
    });

    test('uses local vocabulary for Japanese autocomplete', () {
      final suggestions = LanguageAlgorithms.autocompleteText(
        text: '充電',
        language: 'Japanese',
      );

      expect(suggestions.first, '充電器');
    });

    test('uses local vocabulary for Russian autocomplete', () {
      final suggestions = LanguageAlgorithms.autocompleteText(
        text: 'мне нужно зар',
        language: 'Russian',
      );

      expect(suggestions.first, 'зарядка');
    });

    test('does not return whole phrases from active-word autocomplete', () {
      final suggestions = LanguageAlgorithms.autocompleteText(
        text: 'thank',
        language: 'English',
      );

      expect(suggestions, isNot(contains('thank you')));
      expect(
        suggestions.any((suggestion) => suggestion.contains(' ')),
        isFalse,
      );
    });

    test('does not autocomplete short standalone words from vocabulary', () {
      final suggestions = LanguageAlgorithms.autocompleteText(
        text: 'he',
        language: 'English',
      );

      expect(suggestions, isNot(contains('help')));
    });

    test('autocompletes broader frequent vocabulary words', () {
      final suggestions = LanguageAlgorithms.autocompleteText(
        text: 'where is the hosp',
        language: 'English',
      );

      expect(suggestions.first, 'hospital');
    });

    test('uses phrase slot templates for phrase suggestions', () {
      final suggestion = LanguageAlgorithms.suggestPhraseCompletion(
        text: 'where is the sta',
        language: 'English',
      );

      expect(suggestion, 'Where is the station?');
    });

    test('uses expanded phrase slots to generate common phrases', () {
      final suggestion = LanguageAlgorithms.suggestPhraseCompletion(
        text: 'how much is the tick',
        language: 'English',
      );

      expect(suggestion, 'How much is the ticket?');
    });

    test('uses 5w starter templates for phrase suggestions', () {
      expect(
        LanguageAlgorithms.suggestPhraseCompletion(
          text: 'what is the pri',
          language: 'English',
        ),
        'What is the price?',
      );
      expect(
        LanguageAlgorithms.suggestPhraseCompletion(
          text: 'when is the next tra',
          language: 'English',
        ),
        'When is the next train?',
      );
      expect(
        LanguageAlgorithms.suggestPhraseCompletion(
          text: 'who can help with pass',
          language: 'English',
        ),
        'Who can help with passport?',
      );
      expect(
        LanguageAlgorithms.suggestPhraseCompletion(
          text: 'why is this bro',
          language: 'English',
        ),
        'Why is this broken?',
      );
      expect(
        LanguageAlgorithms.suggestPhraseCompletion(
          text: 'how can i canc',
          language: 'English',
        ),
        'How can I cancel?',
      );
    });

    test('does not expand complete single words into phrase suggestions', () {
      final suggestion = LanguageAlgorithms.suggestPhraseCompletion(
        text: 'Hello',
        language: 'English',
      );

      expect(suggestion, isNull);
    });

    test('does not force unrelated sentence into help phrase suggestion', () {
      final suggestion = LanguageAlgorithms.suggestPhraseCompletion(
        text: 'What did he say',
        language: 'English',
      );

      expect(suggestion, isNull);
    });

    test('uses dynamic programming edit distance for typo correction', () {
      final suggestion = LanguageAlgorithms.suggestCorrection(
        word: 'bahy',
        language: 'Filipino',
      );

      expect(suggestion, 'bahay');
    });

    test('uses keyboard-aware typo correction for vocabulary words', () {
      final suggestion = LanguageAlgorithms.suggestCorrection(
        word: 'chargwr',
        language: 'English',
      );

      expect(suggestion, 'charger');
    });

    test('corrects misspelled question words before short nouns', () {
      final suggestion = LanguageAlgorithms.suggestCorrection(
        word: 'wyat',
        language: 'English',
      );

      expect(suggestion, 'what');
    });

    test('boosts accepted autocomplete suggestions locally', () async {
      for (var index = 0; index < 8; index++) {
        await LanguageAlgorithms.recordAcceptedAutocomplete(
          word: 'change',
          language: 'English',
        );
      }

      final suggestions = LanguageAlgorithms.autocompleteText(
        text: 'cha',
        language: 'English',
      );

      expect(suggestions.first, 'change');
    });

    test('uses greedy scoring to rank the direct translation first', () {
      final alternatives = LanguageAlgorithms.rankAlternativeTranslations(
        originalText: 'house',
        translatedText: 'Casa',
        sourceLanguage: 'English',
        targetLanguage: 'Filipino',
      );

      expect(alternatives.first, 'bahay');
    });

    test('suggests contextual phrases for words outside the dictionary', () {
      final suggestion = LanguageAlgorithms.suggestPhraseCompletion(
        text: 'i need charger',
        language: 'English',
      );

      expect(suggestion, 'I need charger.');
    });

    test('ranks intent-based alternatives with translated slot objects', () {
      final alternatives = LanguageAlgorithms.rankAlternativeTranslations(
        originalText: 'i need charger',
        translatedText: 'necesito un cargador',
        sourceLanguage: 'English',
        targetLanguage: 'Spanish',
      );

      expect(alternatives, contains('¿Dónde puedo comprar cargador?'));
    });

    test('does not show help alternatives for unrelated question', () {
      final alternatives = LanguageAlgorithms.rankAlternativeTranslations(
        originalText: 'What did he say',
        translatedText: '¿Qué dijo?',
        sourceLanguage: 'English',
        targetLanguage: 'Spanish',
      );

      expect(alternatives, isEmpty);
    });

    test('supports Russian direct translations', () {
      final translation = LanguageAlgorithms.findDirectTranslation(
        text: 'hello',
        sourceLanguage: 'English',
        targetLanguage: 'Russian',
      );

      expect(translation, 'привет');
    });

    test('supports Japanese to Russian direct translations', () {
      final translation = LanguageAlgorithms.findDirectTranslation(
        text: 'こんにちは',
        sourceLanguage: 'Japanese',
        targetLanguage: 'Russian',
      );

      expect(translation, 'привет');
    });

    test('supports expanded direct dictionary translations', () {
      final translation = LanguageAlgorithms.findDirectTranslation(
        text: 'hospital',
        sourceLanguage: 'English',
        targetLanguage: 'Spanish',
      );

      expect(translation, 'hospital');
    });
  });
}
