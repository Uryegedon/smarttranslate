import 'package:flutter_test/flutter_test.dart';
import 'package:smarttranslate_app/services/language_algorithms.dart';

void main() {
  group('LanguageAlgorithms', () {
    test('uses trie prefix search for autocomplete', () {
      final suggestions = LanguageAlgorithms.autocomplete(
        prefix: 'ba',
        language: 'Filipino',
      );

      expect(suggestions, contains('bahay'));
    });

    test('uses dynamic programming edit distance for typo correction', () {
      final suggestion = LanguageAlgorithms.suggestCorrection(
        word: 'bahy',
        language: 'Filipino',
      );

      expect(suggestion, 'bahay');
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
  });
}
