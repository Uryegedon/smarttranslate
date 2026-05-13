import 'package:google_ml_kit/google_ml_kit.dart';

class DeviceTranslationModelStatus {
  const DeviceTranslationModelStatus({
    required this.downloadedLanguages,
    required this.missingLanguages,
  });

  final List<String> downloadedLanguages;
  final List<String> missingLanguages;
}

class DeviceTranslationDownloadResult {
  const DeviceTranslationDownloadResult({
    required this.downloaded,
    required this.alreadyInstalled,
    required this.failed,
  });

  final List<String> downloaded;
  final List<String> alreadyInstalled;
  final List<String> failed;
}

class DeviceTranslationDownloadProgress {
  const DeviceTranslationDownloadProgress({
    required this.language,
    required this.completed,
    required this.total,
    required this.message,
  });

  final String language;
  final int completed;
  final int total;
  final String message;

  double get value => total == 0 ? 0 : completed / total;
}

typedef DeviceTranslationDownloadProgressCallback =
    void Function(DeviceTranslationDownloadProgress progress);

class DeviceTranslationService {
  DeviceTranslationService._();

  static final OnDeviceTranslatorModelManager _modelManager =
      OnDeviceTranslatorModelManager();
  static final Map<String, bool> _modelAvailabilityCache = {};

  static const List<String> supportedLanguages = [
    'English',
    'Spanish',
    'Filipino',
    'Japanese',
    'Russian',
  ];

  static Future<DeviceTranslationModelStatus> loadModelStatus() async {
    _modelAvailabilityCache.clear();
    final downloaded = <String>[];
    final missing = <String>[];

    for (final language in supportedLanguages) {
      final model = _translateLanguage(language);
      if (model == null) continue;

      final isDownloaded = await _isDownloaded(model);
      if (isDownloaded) {
        downloaded.add(language);
      } else {
        missing.add(language);
      }
    }

    return DeviceTranslationModelStatus(
      downloadedLanguages: List.unmodifiable(downloaded),
      missingLanguages: List.unmodifiable(missing),
    );
  }

  static Future<DeviceTranslationDownloadResult> downloadLanguages(
    Iterable<String> languages, {
    DeviceTranslationDownloadProgressCallback? onProgress,
  }) async {
    final downloaded = <String>[];
    final alreadyInstalled = <String>[];
    final failed = <String>[];
    final selectedLanguages = languages.toSet().toList();
    final total = selectedLanguages.length;
    var completed = 0;

    for (final language in selectedLanguages) {
      onProgress?.call(
        DeviceTranslationDownloadProgress(
          language: language,
          completed: completed,
          total: total,
          message: 'Downloading $language translation model',
        ),
      );

      final model = _translateLanguage(language);
      if (model == null) {
        failed.add(language);
        completed++;
        onProgress?.call(
          DeviceTranslationDownloadProgress(
            language: language,
            completed: completed,
            total: total,
            message: '$language translation is not supported',
          ),
        );
        continue;
      }

      try {
        final isDownloaded = await _isDownloaded(model);
        if (isDownloaded) {
          alreadyInstalled.add(language);
          completed++;
          onProgress?.call(
            DeviceTranslationDownloadProgress(
              language: language,
              completed: completed,
              total: total,
              message: '$language translation already installed',
            ),
          );
          continue;
        }

        final success = await _modelManager.downloadModel(
          model.bcpCode,
          isWifiRequired: false,
        );
        if (success) {
          _modelAvailabilityCache[model.bcpCode] = true;
          downloaded.add(language);
        } else {
          failed.add(language);
        }
      } catch (_) {
        failed.add(language);
      }

      completed++;
      onProgress?.call(
        DeviceTranslationDownloadProgress(
          language: language,
          completed: completed,
          total: total,
          message: '$language translation checked',
        ),
      );
    }

    return DeviceTranslationDownloadResult(
      downloaded: List.unmodifiable(downloaded),
      alreadyInstalled: List.unmodifiable(alreadyInstalled),
      failed: List.unmodifiable(failed),
    );
  }

  static Future<String?> translateIfReady({
    required String text,
    required String sourceLanguage,
    required String targetLanguage,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return '';
    if (sourceLanguage == targetLanguage) return trimmed;

    final source = _translateLanguage(sourceLanguage);
    final target = _translateLanguage(targetLanguage);
    if (source == null || target == null) {
      return null;
    }

    final sourceReady = await _isDownloaded(source);
    final targetReady = await _isDownloaded(target);
    if (!sourceReady || !targetReady) {
      return null;
    }

    final translator = OnDeviceTranslator(
      sourceLanguage: source,
      targetLanguage: target,
    );

    try {
      return await translator.translateText(trimmed);
    } finally {
      translator.close();
    }
  }

  static TranslateLanguage? _translateLanguage(String language) {
    return switch (language) {
      'English' => TranslateLanguage.english,
      'Spanish' => TranslateLanguage.spanish,
      'Filipino' => TranslateLanguage.tagalog,
      'Japanese' => TranslateLanguage.japanese,
      'Russian' => TranslateLanguage.russian,
      _ => null,
    };
  }

  static Future<bool> _isDownloaded(TranslateLanguage language) async {
    final cached = _modelAvailabilityCache[language.bcpCode];
    if (cached != null) {
      return cached;
    }

    final downloaded = await _modelManager.isModelDownloaded(language.bcpCode);
    _modelAvailabilityCache[language.bcpCode] = downloaded;
    return downloaded;
  }
}
