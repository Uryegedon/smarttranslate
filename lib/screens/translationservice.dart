import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../services/device_translation_service.dart';

const Duration _translationTimeout = Duration(seconds: 12);
final http.Client _translationClient = http.Client();

class TranslationBatchItem {
  const TranslationBatchItem({
    required this.text,
    required this.sourceLanguage,
    required this.targetLanguage,
  });

  final String text;
  final String sourceLanguage;
  final String targetLanguage;

  Map<String, String> toJson() => {
    'text': text,
    'source_language': sourceLanguage,
    'target_language': targetLanguage,
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
  if (localTranslation != null) {
    return localTranslation;
  }

  return _postTranslation({
    'text': text,
    'source_language': sourceLanguage,
    'target_language': targetLanguage,
  }, timeout: timeout);
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
    if (localTranslation != null) {
      return localTranslation;
    }
  }

  final payload = {'text': text};
  if (sourceLanguage != null && sourceLanguage.trim().isNotEmpty) {
    payload['source_language'] = sourceLanguage;
  }
  if (targetLanguage != null && targetLanguage.trim().isNotEmpty) {
    payload['target_language'] = targetLanguage;
  }
  return _postTranslation(payload, timeout: timeout);
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
    if (translated != null) {
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
          AppConfig.translationBatchUri,
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'items': remainingItems.map((item) => item.toJson()).toList(),
          }),
        )
        .timeout(timeout);

    if (response.statusCode != 200) {
      throw Exception(_serverErrorMessage(response));
    }

    final data = json.decode(response.body);
    if (data is! Map<String, dynamic> || data['translations'] is! List) {
      throw Exception('Invalid server response: missing "translations" list.');
    }

    final remoteTranslations = [
      for (final item in data['translations'] as List)
        item is Map<String, dynamic>
            ? item['translated_text'] as String?
            : null,
    ];

    for (var index = 0; index < remoteTranslations.length; index++) {
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

Future<String> _postTranslation(
  Map<String, String> payload, {
  required Duration timeout,
}) async {
  try {
    final response = await _translationClient
        .post(
          _translationUrl,
          headers: {'Content-Type': 'application/json'},
          body: json.encode(payload),
        )
        .timeout(timeout);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

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

Uri get _translationUrl => AppConfig.translationUri;

String _serverErrorMessage(http.Response response) {
  try {
    final data = json.decode(response.body);
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
