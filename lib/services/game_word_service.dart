import '../screens/translationservice.dart';
import 'language_algorithms.dart';

class GameWord {
  const GameWord({
    required this.baseWord,
    required this.language,
    required this.word,
  });

  final String baseWord;
  final String language;
  final String word;
}

class GameWordService {
  const GameWordService._();

  static const int _defaultMaxBaseWords = 18;
  static const Duration _gameTranslationTimeout = Duration(seconds: 6);
  static final Map<String, Future<List<GameWord>>> _cache = {};

  static Future<List<GameWord>> loadWords({
    List<String>? languages,
    int maxBaseWords = _defaultMaxBaseWords,
  }) {
    final selectedLanguages =
        languages ?? LanguageAlgorithms.supportedLanguages;
    final key = '${selectedLanguages.join('|')}:$maxBaseWords';
    return _cache.putIfAbsent(
      key,
      () => _buildWords(selectedLanguages, maxBaseWords),
    );
  }

  static Future<List<GameWord>> _buildWords(
    List<String> languages,
    int maxBaseWords,
  ) async {
    final entries = LanguageAlgorithms.dictionary.take(maxBaseWords).toList();
    final words = _fallbackWords(entries, languages);
    final requests = <TranslationBatchItem>[];
    final requestIndexes = <int>[];

    for (var wordIndex = 0; wordIndex < words.length; wordIndex++) {
      final word = words[wordIndex];
      if (word.language == 'English') continue;

      requestIndexes.add(wordIndex);
      requests.add(
        TranslationBatchItem(
          text: word.baseWord,
          sourceLanguage: 'English',
          targetLanguage: word.language,
        ),
      );
    }

    if (requests.isEmpty) {
      return List.unmodifiable(words);
    }

    try {
      final translatedWords = await translateBatch(
        requests,
        timeout: _gameTranslationTimeout,
      );
      for (var i = 0; i < translatedWords.length; i++) {
        final wordIndex = requestIndexes[i];
        if (wordIndex < 0 || wordIndex >= words.length) continue;

        final cleaned = _cleanWord(translatedWords[i] ?? '');
        if (cleaned.isEmpty) continue;

        final current = words[wordIndex];
        words[wordIndex] = GameWord(
          baseWord: current.baseWord,
          language: current.language,
          word: cleaned,
        );
      }
    } catch (_) {
      // Keep the local word list responsive when the translation server is slow.
    }

    return List.unmodifiable(words);
  }

  static List<GameWord> _fallbackWords(
    List<DictionaryEntry> entries,
    List<String> languages,
  ) {
    final words = <GameWord>[];
    for (final entry in entries) {
      for (final language in languages) {
        final cleaned = _cleanWord(entry.valueFor(language));
        if (cleaned.isEmpty) continue;

        words.add(
          GameWord(baseWord: entry.english, language: language, word: cleaned),
        );
      }
    }
    return words;
  }

  static String _cleanWord(String word) {
    return word.trim().replaceAll(RegExp(r'[.!?]+$'), '');
  }
}
