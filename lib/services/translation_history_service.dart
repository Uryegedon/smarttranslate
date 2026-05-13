import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TranslationHistoryGameWord {
  const TranslationHistoryGameWord({
    required this.baseWord,
    required this.language,
    required this.word,
  });

  final String baseWord;
  final String language;
  final String word;
}

class TranslationHistoryService {
  const TranslationHistoryService._();

  static const int _queryLimit = 200;

  static Future<void> recordTranslation({
    required String sourceText,
    required String translatedText,
    required String sourceLanguage,
    required String targetLanguage,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    final cleanedSourceText = sourceText.trim();
    final cleanedTranslatedText = translatedText.trim();
    final sourceKey = _languageKey(sourceLanguage);
    final targetKey = _languageKey(targetLanguage);
    if (user == null ||
        cleanedSourceText.isEmpty ||
        cleanedTranslatedText.isEmpty ||
        sourceKey == targetKey) {
      return;
    }

    final docId = _historyDocId(
      sourceText: cleanedSourceText,
      translatedText: cleanedTranslatedText,
      sourceLanguage: sourceKey,
      targetLanguage: targetKey,
    );

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('translation_history')
          .doc(docId)
          .set({
            'sourceText': cleanedSourceText,
            'translatedText': cleanedTranslatedText,
            'sourceLanguage': sourceLanguage,
            'targetLanguage': targetLanguage,
            'sourceLanguageKey': sourceKey,
            'targetLanguageKey': targetKey,
            'usedForGames': _canUseForGames(
              sourceText: cleanedSourceText,
              translatedText: cleanedTranslatedText,
              sourceLanguageKey: sourceKey,
              targetLanguageKey: targetKey,
            ),
            'uses': FieldValue.increment(1),
            'updatedAt': FieldValue.serverTimestamp(),
            'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } catch (_) {
      // Translation should not fail because account history could not sync.
    }
  }

  static Future<List<TranslationHistoryGameWord>> loadGameWords({
    required List<String> languages,
    required int maxBaseWords,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const [];
    }

    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('translation_history')
              .orderBy('updatedAt', descending: true)
              .limit(_queryLimit)
              .get();

      final records =
          snapshot.docs
              .map((doc) => doc.data())
              .where((data) => data['usedForGames'] == true)
              .toList();

      final requested = languages.map(_languageKey).toSet();
      final usedBaseWords = <String>{};
      final usedRows = <String>{};
      final words = <TranslationHistoryGameWord>[];

      for (final data in records) {
        final gameWord = _gameWordFromRecord(data, requested);
        if (gameWord == null) continue;

        final baseKey = _normalize(gameWord.baseWord);
        final rowKey = '$baseKey|${_languageKey(gameWord.language)}';
        if (baseKey.isEmpty || !usedRows.add(rowKey)) continue;

        usedBaseWords.add(baseKey);
        words.add(gameWord);
        if (usedBaseWords.length >= maxBaseWords) {
          break;
        }
      }

      return words;
    } catch (_) {
      return const [];
    }
  }

  static TranslationHistoryGameWord? _gameWordFromRecord(
    Map<String, dynamic> data,
    Set<String> requestedLanguages,
  ) {
    final sourceText = data['sourceText'] as String? ?? '';
    final translatedText = data['translatedText'] as String? ?? '';
    final sourceLanguage = data['sourceLanguage'] as String? ?? '';
    final targetLanguage = data['targetLanguage'] as String? ?? '';
    final sourceKey =
        data['sourceLanguageKey'] as String? ?? _languageKey(sourceLanguage);
    final targetKey =
        data['targetLanguageKey'] as String? ?? _languageKey(targetLanguage);

    if (sourceKey == 'english' && requestedLanguages.contains(targetKey)) {
      return TranslationHistoryGameWord(
        baseWord: _cleanGameText(sourceText),
        language: _displayLanguage(targetKey),
        word: _cleanGameText(translatedText),
      );
    }

    if (targetKey == 'english' && requestedLanguages.contains(sourceKey)) {
      return TranslationHistoryGameWord(
        baseWord: _cleanGameText(translatedText),
        language: _displayLanguage(sourceKey),
        word: _cleanGameText(sourceText),
      );
    }

    return null;
  }

  static bool _canUseForGames({
    required String sourceText,
    required String translatedText,
    required String sourceLanguageKey,
    required String targetLanguageKey,
  }) {
    return (sourceLanguageKey == 'english' || targetLanguageKey == 'english') &&
        _isGameSizedText(sourceText) &&
        _isGameSizedText(translatedText);
  }

  static String _historyDocId({
    required String sourceText,
    required String translatedText,
    required String sourceLanguage,
    required String targetLanguage,
  }) {
    final raw = [
      sourceLanguage,
      targetLanguage,
      _normalize(sourceText),
      _normalize(translatedText),
    ].join('|');
    return '${raw.length}-${_hash(raw)}';
  }

  static String _hash(String value) {
    var hash = 0x811c9dc5;
    for (final byte in utf8.encode(value)) {
      hash ^= byte;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }

  static String _cleanGameText(String value) {
    return value.trim().replaceAll(RegExp(r'[.!?]+$'), '');
  }

  static bool _isGameSizedText(String value) {
    final words =
        value.trim().split(RegExp(r'\s+')).where((word) {
          return word.trim().isNotEmpty;
        }).length;
    return words >= 1 && words <= 6 && value.trim().length <= 80;
  }

  static String _displayLanguage(String key) {
    return switch (key) {
      'spanish' => 'Spanish',
      'filipino' || 'tagalog' => 'Filipino',
      'japanese' => 'Japanese',
      'russian' => 'Russian',
      'english' => 'English',
      _ => key,
    };
  }

  static String _languageKey(String language) {
    return language.trim().toLowerCase();
  }

  static String _normalize(String text) {
    return text.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }
}
