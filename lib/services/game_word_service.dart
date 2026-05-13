import '../screens/translationservice.dart';
import 'language_algorithms.dart';
import 'translation_history_service.dart';

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

  static Future<List<GameWord>> loadWords({
    List<String>? languages,
    int maxBaseWords = _defaultMaxBaseWords,
  }) {
    final selectedLanguages =
        languages ?? LanguageAlgorithms.supportedLanguages;
    return _buildWords(selectedLanguages, maxBaseWords);
  }

  static Future<List<GameWord>> _buildWords(
    List<String> languages,
    int maxBaseWords,
  ) async {
    final historyWords = await _historyWords(languages, maxBaseWords);
    final usedBaseWords =
        historyWords
            .map((word) => word.baseWord.trim().toLowerCase())
            .where((word) => word.isNotEmpty)
            .toSet();
    final remainingBaseWords =
        (maxBaseWords - usedBaseWords.length).clamp(0, maxBaseWords).toInt();
    final entries =
        LanguageAlgorithms.dictionary
            .where(
              (entry) => !usedBaseWords.contains(entry.english.toLowerCase()),
            )
            .take(remainingBaseWords)
            .toList();
    final fallbackWords = _fallbackWords(entries, languages);
    final words = [...historyWords, ...fallbackWords];
    final fallbackStartIndex = historyWords.length;
    final requests = <TranslationBatchItem>[];
    final requestIndexes = <int>[];

    for (
      var wordIndex = fallbackStartIndex;
      wordIndex < words.length;
      wordIndex++
    ) {
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

  static Future<List<GameWord>> _historyWords(
    List<String> languages,
    int maxBaseWords,
  ) async {
    final words = <GameWord>[];
    final usedRows = <String>{};
    final usedBaseWords = <String>{};

    final accountWords = await TranslationHistoryService.loadGameWords(
      languages: languages,
      maxBaseWords: maxBaseWords,
    );
    for (final item in accountWords) {
      _addHistoryWord(
        words: words,
        usedRows: usedRows,
        usedBaseWords: usedBaseWords,
        languages: languages,
        baseWord: item.baseWord,
        language: item.language,
        word: item.word,
      );
      if (usedBaseWords.length >= maxBaseWords) return words;
    }

    try {
      final items = await fetchGameWordsFromHistory(
        languages: languages,
        maxBaseWords: maxBaseWords,
      );

      for (final item in items) {
        _addHistoryWord(
          words: words,
          usedRows: usedRows,
          usedBaseWords: usedBaseWords,
          languages: languages,
          baseWord: item['base_word'] as String? ?? '',
          language: item['language'] as String? ?? '',
          word: item['word'] as String? ?? '',
        );
        if (usedBaseWords.length >= maxBaseWords) break;
      }
    } catch (_) {
      // The account history above is still useful if the server is absent.
    }

    return words;
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

  static void _addHistoryWord({
    required List<GameWord> words,
    required Set<String> usedRows,
    required Set<String> usedBaseWords,
    required List<String> languages,
    required String baseWord,
    required String language,
    required String word,
  }) {
    final cleanedBaseWord = _cleanWord(baseWord);
    final cleanedWord = _cleanWord(word);
    if (cleanedBaseWord.isEmpty ||
        language.isEmpty ||
        cleanedWord.isEmpty ||
        !languages.contains(language)) {
      return;
    }

    final baseKey = cleanedBaseWord.toLowerCase();
    final rowKey = '$baseKey|$language|${cleanedWord.toLowerCase()}';
    if (!usedRows.add(rowKey)) return;

    usedBaseWords.add(baseKey);
    words.add(
      GameWord(
        baseWord: cleanedBaseWord,
        language: language,
        word: cleanedWord,
      ),
    );
  }
}
