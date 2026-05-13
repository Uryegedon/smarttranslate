import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../services/device_translation_service.dart';
import '../services/settings_service.dart';
import '../services/translation_history_service.dart';

const Duration _translationTimeout = Duration(seconds: 45);
const Duration _alternativesTimeout = Duration(seconds: 5);
const Map<String, String> _translationHeaders = {
  'Content-Type': 'application/json',
  'ngrok-skip-browser-warning': 'true',
};
final http.Client _translationClient = http.Client();

class TranslationBatchItem {
  const TranslationBatchItem({
    required this.text,
    required this.sourceLanguage,
    required this.targetLanguage,
    this.record = false,
  });

  final String text;
  final String sourceLanguage;
  final String targetLanguage;
  final bool record;

  Map<String, dynamic> toJson() => {
    'text': text,
    'source_language': sourceLanguage,
    'target_language': targetLanguage,
    'record': record,
  };
}

Future<String> translateText(
  String text,
  String sourceLanguage,
  String targetLanguage, {
  Duration timeout = _translationTimeout,
}) async {
  final localTranslation = await DeviceTranslationService.translateIfReady(
    text: text,
    sourceLanguage: sourceLanguage,
    targetLanguage: targetLanguage,
  );
  final usableLocalTranslation =
      _isUsableTranslation(localTranslation, targetLanguage)
          ? localTranslation
          : null;
  if (usableLocalTranslation != null) {
    unawaited(
      _recordTranslationHistory(
        originalText: text,
        translatedText: usableLocalTranslation,
        sourceLanguage: sourceLanguage,
        targetLanguage: targetLanguage,
      ),
    );
    _recordAccountTranslationIfReady(
      originalText: text,
      translatedText: usableLocalTranslation,
      sourceLanguage: sourceLanguage,
      targetLanguage: targetLanguage,
    );
    return usableLocalTranslation;
  }

  final translatedText = await _postTranslation({
    'text': text,
    'source_language': sourceLanguage,
    'target_language': targetLanguage,
  }, timeout: timeout);
  _recordAccountTranslationIfReady(
    originalText: text,
    translatedText: translatedText,
    sourceLanguage: sourceLanguage,
    targetLanguage: targetLanguage,
  );
  return translatedText;
}

Future<String> translateDetectedText(
  String text, {
  String? sourceLanguage,
  String? targetLanguage,
  Duration timeout = _translationTimeout,
}) async {
  if (sourceLanguage != null &&
      sourceLanguage.trim().isNotEmpty &&
      targetLanguage != null &&
      targetLanguage.trim().isNotEmpty) {
    final localTranslation = await DeviceTranslationService.translateIfReady(
      text: text,
      sourceLanguage: sourceLanguage,
      targetLanguage: targetLanguage,
    );
    final usableLocalTranslation =
        _isUsableTranslation(localTranslation, targetLanguage)
            ? localTranslation
            : null;
    if (usableLocalTranslation != null) {
      unawaited(
        _recordTranslationHistory(
          originalText: text,
          translatedText: usableLocalTranslation,
          sourceLanguage: sourceLanguage,
          targetLanguage: targetLanguage,
        ),
      );
      _recordAccountTranslationIfReady(
        originalText: text,
        translatedText: usableLocalTranslation,
        sourceLanguage: sourceLanguage,
        targetLanguage: targetLanguage,
      );
      return usableLocalTranslation;
    }
  }

  final payload = {'text': text};
  if (sourceLanguage != null && sourceLanguage.trim().isNotEmpty) {
    payload['source_language'] = sourceLanguage;
  }
  if (targetLanguage != null && targetLanguage.trim().isNotEmpty) {
    payload['target_language'] = targetLanguage;
  }
  final translatedText = await _postTranslation(payload, timeout: timeout);
  _recordAccountTranslationIfReady(
    originalText: text,
    translatedText: translatedText,
    sourceLanguage: sourceLanguage,
    targetLanguage: targetLanguage,
  );
  return translatedText;
}

Future<List<String?>> translateBatch(
  List<TranslationBatchItem> items, {
  Duration timeout = _translationTimeout,
}) async {
  if (items.isEmpty) return const [];

  final localTranslations = List<String?>.filled(items.length, null);
  final remainingItems = <TranslationBatchItem>[];
  final remainingIndexes = <int>[];

  for (var index = 0; index < items.length; index++) {
    final item = items[index];
    final translated = await DeviceTranslationService.translateIfReady(
      text: item.text,
      sourceLanguage: item.sourceLanguage,
      targetLanguage: item.targetLanguage,
    );
    if (_isUsableTranslation(translated, item.targetLanguage)) {
      localTranslations[index] = translated;
    } else {
      remainingItems.add(item);
      remainingIndexes.add(index);
    }
  }

  if (remainingItems.isEmpty) {
    return localTranslations;
  }

  try {
    final response = await _translationClient
        .post(
          await _translationBatchUri(),
          headers: _translationHeaders,
          body: json.encode({
            'items': remainingItems.map((item) => item.toJson()).toList(),
          }),
        )
        .timeout(timeout);

    if (response.statusCode != 200) {
      throw Exception(_serverErrorMessage(response));
    }

    final data = _decodeJsonResponse(response);
    if (data is! Map<String, dynamic> || data['translations'] is! List) {
      throw Exception('Invalid server response: missing "translations" list.');
    }

    final remoteTranslations = [
      for (final item in data['translations'] as List)
        item is Map<String, dynamic>
            ? item['translated_text'] as String?
            : null,
    ];

    final resultCount = remoteTranslations.length;
    if (resultCount != remainingIndexes.length) {
      throw Exception(
        'Invalid server response: expected ${remainingIndexes.length} translations, got $resultCount.',
      );
    }

    for (var index = 0; index < resultCount; index++) {
      localTranslations[remainingIndexes[index]] = remoteTranslations[index];
    }

    return localTranslations;
  } catch (e) {
    if (localTranslations.any((item) => item != null)) {
      return localTranslations;
    }
    throw Exception('Batch translation failed: $e');
  }
}

Future<List<String>> fetchAlternativeTranslations({
  required String originalText,
  required String translatedText,
  required String sourceLanguage,
  required String targetLanguage,
  Duration timeout = _alternativesTimeout,
}) async {
  final response = await _translationClient
      .post(
        await _alternativesUri(),
        headers: _translationHeaders,
        body: json.encode({
          'text': originalText,
          'translated_text': translatedText,
          'source_language': sourceLanguage,
          'target_language': targetLanguage,
          'limit': 3,
        }),
      )
      .timeout(timeout);

  if (response.statusCode != 200) {
    throw Exception(_serverErrorMessage(response));
  }

  final data = _decodeJsonResponse(response);
  if (data is! Map<String, dynamic> || data['alternatives'] is! List) {
    throw Exception('Invalid server response: missing "alternatives" list.');
  }

  return [
    for (final alternative in data['alternatives'] as List)
      if (alternative is String && alternative.trim().isNotEmpty) alternative,
  ];
}

Future<List<Map<String, dynamic>>> fetchGameWordsFromHistory({
  required List<String> languages,
  required int maxBaseWords,
  Duration timeout = const Duration(seconds: 5),
}) async {
  final uri = (await _gameWordsUri()).replace(
    queryParameters: {
      'languages': languages.join(','),
      'limit': '$maxBaseWords',
    },
  );
  final response = await _translationClient
      .get(uri, headers: {'ngrok-skip-browser-warning': 'true'})
      .timeout(timeout);

  if (response.statusCode != 200) {
    throw Exception(_serverErrorMessage(response));
  }

  final data = _decodeJsonResponse(response);
  if (data is! Map<String, dynamic> || data['words'] is! List) {
    throw Exception('Invalid server response: missing "words" list.');
  }

  return [
    for (final item in data['words'] as List)
      if (item is Map<String, dynamic>) item,
  ];
}

bool _isUsableTranslation(String? text, String targetLanguage) {
  final value = text?.trim() ?? '';
  if (value.isEmpty) {
    return false;
  }

  return switch (targetLanguage.trim().toLowerCase()) {
    'japanese' => RegExp(r'[\u3040-\u30ff\u3400-\u9fff]').hasMatch(value),
    'russian' => RegExp(r'[\u0400-\u04ff]').hasMatch(value),
    _ => true,
  };
}

Future<String> _postTranslation(
  Map<String, String> payload, {
  required Duration timeout,
}) async {
  try {
    final response = await _translationClient
        .post(
          await _translationUri(),
          headers: _translationHeaders,
          body: json.encode(payload),
        )
        .timeout(timeout);

    if (response.statusCode == 200) {
      final data = _decodeJsonResponse(response);

      if (data is Map<String, dynamic> && data.containsKey('translated_text')) {
        return data['translated_text'] ?? '';
      } else {
        throw Exception(
          'Invalid server response: missing "translated_text" key.',
        );
      }
    } else {
      throw Exception(_serverErrorMessage(response));
    }
  } catch (e) {
    throw Exception('Translation failed: $e');
  }
}

Future<void> _recordTranslationHistory({
  required String originalText,
  required String translatedText,
  required String sourceLanguage,
  required String targetLanguage,
}) async {
  try {
    await _translationClient
        .post(
          await _translationHistoryUri(),
          headers: _translationHeaders,
          body: json.encode({
            'text': originalText,
            'translated_text': translatedText,
            'source_language': sourceLanguage,
            'target_language': targetLanguage,
          }),
        )
        .timeout(const Duration(seconds: 3));
  } catch (_) {
    // Local/offline translations should still succeed when the server is absent.
  }
}

void _recordAccountTranslationIfReady({
  required String originalText,
  required String translatedText,
  required String? sourceLanguage,
  required String? targetLanguage,
}) {
  if (sourceLanguage == null ||
      targetLanguage == null ||
      sourceLanguage.trim().isEmpty ||
      targetLanguage.trim().isEmpty) {
    return;
  }

  unawaited(
    TranslationHistoryService.recordTranslation(
      sourceText: originalText,
      translatedText: translatedText,
      sourceLanguage: sourceLanguage,
      targetLanguage: targetLanguage,
    ),
  );
}

Future<Uri> _translationUri() async {
  final override = await SettingsService.loadTranslationApiUrlOverride();
  return Uri.parse(override ?? AppConfig.translationApiUrl);
}

Future<Uri> _translationBatchUri() async {
  final translationUri = await _translationUri();
  return translationUri.resolve('/translate/batch/');
}

Future<Uri> _alternativesUri() async {
  final translationUri = await _translationUri();
  return translationUri.resolve('/alternatives/');
}

Future<Uri> _translationHistoryUri() async {
  final translationUri = await _translationUri();
  return translationUri.resolve('/translation-history/');
}

Future<Uri> _gameWordsUri() async {
  final translationUri = await _translationUri();
  return translationUri.resolve('/game-words/');
}

String _serverErrorMessage(http.Response response) {
  try {
    final data = _decodeJsonResponse(response);
    if (data is Map<String, dynamic>) {
      final detail = data['detail'];
      if (detail is String && detail.trim().isNotEmpty) {
        return detail;
      }
    }
  } catch (_) {
    // Fall back to the HTTP status below when the response is not JSON.
  }

  return 'Server returned status code: ${response.statusCode}';
}

Object? _decodeJsonResponse(http.Response response) {
  return json.decode(utf8.decode(response.bodyBytes));
}
