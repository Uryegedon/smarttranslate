import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive_io.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

class OfflineTtsVoiceStatus {
  const OfflineTtsVoiceStatus({
    required this.language,
    required this.supported,
    required this.installed,
    this.supertonic = false,
    this.modelPath,
    this.tokensPath,
    this.dataDir,
    this.lexiconPath,
    this.durationPredictorPath,
    this.textEncoderPath,
    this.vectorEstimatorPath,
    this.vocoderPath,
    this.ttsJsonPath,
    this.unicodeIndexerPath,
    this.voiceStylePath,
  });

  final String language;
  final bool supported;
  final bool installed;
  final bool supertonic;
  final String? modelPath;
  final String? tokensPath;
  final String? dataDir;
  final String? lexiconPath;
  final String? durationPredictorPath;
  final String? textEncoderPath;
  final String? vectorEstimatorPath;
  final String? vocoderPath;
  final String? ttsJsonPath;
  final String? unicodeIndexerPath;
  final String? voiceStylePath;
}

class OfflineTtsDownloadResult {
  const OfflineTtsDownloadResult({
    required this.downloaded,
    required this.alreadyInstalled,
    required this.unsupported,
    required this.failed,
  });

  final List<String> downloaded;
  final List<String> alreadyInstalled;
  final List<String> unsupported;
  final List<String> failed;
}

class OfflineTtsDownloadProgress {
  const OfflineTtsDownloadProgress({
    required this.language,
    required this.completed,
    required this.total,
    required this.message,
    this.fileProgress,
  });

  final String language;
  final int completed;
  final int total;
  final String message;
  final double? fileProgress;

  double? get value {
    if (total == 0) return 0;
    if (fileProgress == null) return completed / total;
    return (completed + fileProgress!.clamp(0.0, 1.0)) / total;
  }
}

typedef OfflineTtsDownloadProgressCallback =
    void Function(OfflineTtsDownloadProgress progress);

class _OfflineTtsVoiceDefinition {
  const _OfflineTtsVoiceDefinition({
    required this.archiveName,
    this.modelFileName,
    this.archiveUrlOverride = '',
    this.useSherpaReleaseArchive = true,
    this.requiresLexiconOrData = true,
    this.supertonic = false,
  });

  final String archiveName;
  final String? modelFileName;
  final String archiveUrlOverride;
  final bool useSherpaReleaseArchive;
  final bool requiresLexiconOrData;
  final bool supertonic;

  String get archiveUrl =>
      archiveUrlOverride.isNotEmpty
          ? archiveUrlOverride
          : useSherpaReleaseArchive
          ? 'https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models/'
              '$archiveName.tar.bz2'
          : '';
}

class OfflineTextToSpeechService {
  OfflineTextToSpeechService();

  static const String _rootName = 'offline_tts';
  static bool _bindingsInitialized = false;

  static const Map<String, _OfflineTtsVoiceDefinition> _voices = {
    'English': _OfflineTtsVoiceDefinition(
      archiveName: 'vits-piper-en_US-amy-low',
      modelFileName: 'en_US-amy-low.onnx',
    ),
    'Spanish': _OfflineTtsVoiceDefinition(
      archiveName: 'vits-piper-es_ES-carlfm-x_low',
      modelFileName: 'es_ES-carlfm-x_low.onnx',
    ),
    'Filipino': _OfflineTtsVoiceDefinition(
      archiveName: 'vits-mms-tgl',
      modelFileName: 'model.onnx',
      archiveUrlOverride: String.fromEnvironment('FILIPINO_TTS_ARCHIVE_URL'),
      useSherpaReleaseArchive: false,
      requiresLexiconOrData: false,
    ),
    'Russian': _OfflineTtsVoiceDefinition(
      archiveName: 'vits-piper-ru_RU-irina-medium',
      modelFileName: 'ru_RU-irina-medium.onnx',
    ),
    'Japanese': _OfflineTtsVoiceDefinition(
      archiveName: 'sherpa-onnx-supertonic-3-tts-int8-2026-05-11',
      supertonic: true,
    ),
  };

  final AudioPlayer _player = AudioPlayer();

  static bool supportsLanguage(String language) =>
      _voices.containsKey(language);

  static bool needsDownloadConfiguration(String language) {
    final voice = _voices[language];
    return voice != null && voice.archiveUrl.isEmpty;
  }

  static Future<Map<String, OfflineTtsVoiceStatus>> loadVoiceStatuses(
    Iterable<String> languages,
  ) async {
    final statuses = <String, OfflineTtsVoiceStatus>{};
    for (final language in languages) {
      statuses[language] = await loadVoiceStatus(language);
    }
    return statuses;
  }

  static Future<OfflineTtsVoiceStatus> loadVoiceStatus(String language) async {
    final voice = _voices[language];
    if (voice == null) {
      return OfflineTtsVoiceStatus(
        language: language,
        supported: false,
        installed: false,
      );
    }

    final root = await _voiceDirectory(language, voice);
    if (!await root.exists()) {
      return OfflineTtsVoiceStatus(
        language: language,
        supported: true,
        installed: false,
      );
    }

    final files = await _findVoiceFiles(root, voice);
    if (voice.supertonic) {
      final durationPredictor = files['durationPredictor'];
      final textEncoder = files['textEncoder'];
      final vectorEstimator = files['vectorEstimator'];
      final vocoder = files['vocoder'];
      final ttsJson = files['ttsJson'];
      final unicodeIndexer = files['unicodeIndexer'];
      final voiceStyle = files['voiceStyle'];

      return OfflineTtsVoiceStatus(
        language: language,
        supported: true,
        installed:
            durationPredictor != null &&
            textEncoder != null &&
            vectorEstimator != null &&
            vocoder != null &&
            ttsJson != null &&
            unicodeIndexer != null &&
            voiceStyle != null,
        supertonic: true,
        durationPredictorPath: durationPredictor,
        textEncoderPath: textEncoder,
        vectorEstimatorPath: vectorEstimator,
        vocoderPath: vocoder,
        ttsJsonPath: ttsJson,
        unicodeIndexerPath: unicodeIndexer,
        voiceStylePath: voiceStyle,
      );
    }

    final model = files['model'];
    final tokens = files['tokens'];
    final dataDir = files['dataDir'];
    final lexicon = files['lexicon'];

    return OfflineTtsVoiceStatus(
      language: language,
      supported: true,
      installed:
          model != null &&
          tokens != null &&
          (!voice.requiresLexiconOrData || dataDir != null || lexicon != null),
      modelPath: model,
      tokensPath: tokens,
      dataDir: dataDir,
      lexiconPath: lexicon,
    );
  }

  static Future<OfflineTtsDownloadResult> downloadLanguages(
    Iterable<String> languages, {
    OfflineTtsDownloadProgressCallback? onProgress,
  }) async {
    final downloaded = <String>[];
    final alreadyInstalled = <String>[];
    final unsupported = <String>[];
    final failed = <String>[];
    final selectedLanguages = languages.toSet().toList();
    final total = selectedLanguages.length;
    var completed = 0;

    for (final language in selectedLanguages) {
      onProgress?.call(
        OfflineTtsDownloadProgress(
          language: language,
          completed: completed,
          total: total,
          message: 'Preparing $language voice',
        ),
      );

      final voice = _voices[language];
      if (voice == null) {
        unsupported.add(language);
        completed++;
        onProgress?.call(
          OfflineTtsDownloadProgress(
            language: language,
            completed: completed,
            total: total,
            message: 'No bundled local voice for $language',
          ),
        );
        continue;
      }

      if (voice.archiveUrl.isEmpty) {
        failed.add(language);
        completed++;
        onProgress?.call(
          OfflineTtsDownloadProgress(
            language: language,
            completed: completed,
            total: total,
            message: 'No download URL configured for $language voice',
          ),
        );
        continue;
      }

      try {
        final status = await loadVoiceStatus(language);
        if (status.installed) {
          alreadyInstalled.add(language);
          completed++;
          onProgress?.call(
            OfflineTtsDownloadProgress(
              language: language,
              completed: completed,
              total: total,
              message: '$language voice already installed',
            ),
          );
          continue;
        }

        await _downloadVoice(
          language,
          voice,
          onProgress: (fileProgress, message) {
            onProgress?.call(
              OfflineTtsDownloadProgress(
                language: language,
                completed: completed,
                total: total,
                message: message,
                fileProgress: fileProgress,
              ),
            );
          },
        );
        final installed = await loadVoiceStatus(language);
        if (installed.installed) {
          downloaded.add(language);
        } else {
          failed.add(language);
        }
      } catch (_) {
        failed.add(language);
      }

      completed++;
      onProgress?.call(
        OfflineTtsDownloadProgress(
          language: language,
          completed: completed,
          total: total,
          message: '$language voice checked',
        ),
      );
    }

    return OfflineTtsDownloadResult(
      downloaded: List.unmodifiable(downloaded),
      alreadyInstalled: List.unmodifiable(alreadyInstalled),
      unsupported: List.unmodifiable(unsupported),
      failed: List.unmodifiable(failed),
    );
  }

  Future<Duration?> speak({
    required String text,
    required String language,
    required double volume,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return Duration.zero;
    }

    final status = await loadVoiceStatus(language);
    if (!status.installed) {
      return null;
    }

    await stop();
    _ensureBindings();

    final config =
        status.supertonic
            ? sherpa.OfflineTtsConfig(
              model: sherpa.OfflineTtsModelConfig(
                supertonic: sherpa.OfflineTtsSupertonicModelConfig(
                  durationPredictor: status.durationPredictorPath!,
                  textEncoder: status.textEncoderPath!,
                  vectorEstimator: status.vectorEstimatorPath!,
                  vocoder: status.vocoderPath!,
                  ttsJson: status.ttsJsonPath!,
                  unicodeIndexer: status.unicodeIndexerPath!,
                  voiceStyle: status.voiceStylePath!,
                ),
                numThreads: 2,
                debug: false,
              ),
            )
            : sherpa.OfflineTtsConfig(
              model: sherpa.OfflineTtsModelConfig(
                vits: sherpa.OfflineTtsVitsModelConfig(
                  model: status.modelPath!,
                  tokens: status.tokensPath!,
                  dataDir: status.dataDir ?? '',
                  lexicon: status.lexiconPath ?? '',
                ),
                numThreads: 2,
                debug: false,
              ),
            );

    final generationConfig =
        status.supertonic
            ? sherpa.OfflineTtsGenerationConfig(
              sid: 0,
              numSteps: 8,
              speed: 1.0,
              extra: {'lang': _supertonicLanguageFor(language)},
            )
            : sherpa.OfflineTtsGenerationConfig(sid: 0, speed: 1.0);

    final tts = sherpa.OfflineTts(config);
    try {
      final audio = tts.generateWithConfig(
        text: trimmed,
        config: generationConfig,
      );
      if (audio.samples.isEmpty || audio.sampleRate <= 0) {
        return null;
      }

      final outputFile = await _outputFile();
      final wrote = sherpa.writeWave(
        filename: outputFile.path,
        samples: audio.samples,
        sampleRate: audio.sampleRate,
      );
      if (!wrote) {
        return null;
      }

      await _player.setVolume(volume.clamp(0.0, 1.0));
      await _player.play(DeviceFileSource(outputFile.path));
      final milliseconds =
          (audio.samples.length / audio.sampleRate * 1000).ceil();
      return Duration(milliseconds: milliseconds);
    } finally {
      tts.free();
    }
  }

  static String _supertonicLanguageFor(String language) {
    return switch (language) {
      'Japanese' => 'ja',
      _ => language.toLowerCase(),
    };
  }

  Future<void> stop() async {
    await _player.stop();
  }

  Future<void> dispose() async {
    await _player.dispose();
  }

  static Future<void> _downloadVoice(
    String language,
    _OfflineTtsVoiceDefinition voice, {
    void Function(double? progress, String message)? onProgress,
  }) async {
    final root = await _voiceDirectory(language, voice);
    if (await root.exists()) {
      await root.delete(recursive: true);
    }
    await root.create(recursive: true);

    final archiveFile = File(
      path.join(root.path, '${voice.archiveName}.tar.bz2'),
    );
    if (await archiveFile.exists()) {
      await archiveFile.delete();
    }

    final client = http.Client();
    var downloaded = false;

    try {
      final request = http.Request('GET', Uri.parse(voice.archiveUrl));
      final response = await client.send(request);
      if (response.statusCode != HttpStatus.ok) {
        throw StateError(
          'TTS voice download failed with HTTP ${response.statusCode}.',
        );
      }

      final contentLength = response.contentLength ?? 0;
      var received = 0;
      final sink = archiveFile.openWrite();
      await for (final chunk in response.stream) {
        received += chunk.length;
        sink.add(chunk);
        onProgress?.call(
          contentLength > 0 ? received / contentLength : null,
          'Downloading $language voice',
        );
      }
      await sink.flush();
      await sink.close();
      downloaded = true;
    } finally {
      client.close();
      if (!downloaded && await archiveFile.exists()) {
        await archiveFile.delete();
      }
    }

    onProgress?.call(null, 'Installing $language voice');
    final archivePath = archiveFile.path;
    final rootPath = root.path;
    try {
      await Isolate.run(() => extractFileToDisk(archivePath, rootPath));
    } finally {
      if (await archiveFile.exists()) {
        await archiveFile.delete();
      }
    }
  }

  static Future<Directory> _voiceDirectory(
    String language,
    _OfflineTtsVoiceDefinition voice,
  ) async {
    final support = await getApplicationSupportDirectory();
    final slug = language.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    return Directory(
      path.join(support.path, _rootName, slug, voice.archiveName),
    );
  }

  static Future<Map<String, String>> _findVoiceFiles(
    Directory root,
    _OfflineTtsVoiceDefinition voice,
  ) async {
    final matches = <String, String>{};
    await for (final entity in root.list(recursive: true, followLinks: false)) {
      if (entity is Directory &&
          path.basename(entity.path) == 'espeak-ng-data') {
        matches['dataDir'] = entity.path;
        continue;
      }

      if (entity is! File) {
        continue;
      }

      final name = path.basename(entity.path);
      if (voice.supertonic) {
        if (name == 'duration_predictor.int8.onnx') {
          matches['durationPredictor'] = entity.path;
        } else if (name == 'text_encoder.int8.onnx') {
          matches['textEncoder'] = entity.path;
        } else if (name == 'vector_estimator.int8.onnx') {
          matches['vectorEstimator'] = entity.path;
        } else if (name == 'vocoder.int8.onnx') {
          matches['vocoder'] = entity.path;
        } else if (name == 'tts.json') {
          matches['ttsJson'] = entity.path;
        } else if (name == 'unicode_indexer.bin') {
          matches['unicodeIndexer'] = entity.path;
        } else if (name == 'voice.bin') {
          matches['voiceStyle'] = entity.path;
        }
        continue;
      }

      if (name == voice.modelFileName) {
        matches['model'] = entity.path;
      } else if (name == 'tokens.txt') {
        matches['tokens'] = entity.path;
      } else if (name == 'lexicon.txt') {
        matches['lexicon'] = entity.path;
      }
    }
    return matches;
  }

  static Future<File> _outputFile() async {
    final cache = await getTemporaryDirectory();
    return File(path.join(cache.path, 'smarttranslate-offline-tts.wav'));
  }

  static void _ensureBindings() {
    if (_bindingsInitialized) {
      return;
    }
    sherpa.initBindings();
    _bindingsInitialized = true;
  }
}
