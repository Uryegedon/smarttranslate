import 'dart:async';
import 'dart:io';

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
    this.modelPath,
    this.tokensPath,
    this.dataDir,
    this.lexiconPath,
  });

  final String language;
  final bool supported;
  final bool installed;
  final String? modelPath;
  final String? tokensPath;
  final String? dataDir;
  final String? lexiconPath;
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

class _OfflineTtsVoiceDefinition {
  const _OfflineTtsVoiceDefinition({
    required this.archiveName,
    required this.modelFileName,
  });

  final String archiveName;
  final String modelFileName;

  String get archiveUrl =>
      'https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models/'
      '$archiveName.tar.bz2';
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
    'Russian': _OfflineTtsVoiceDefinition(
      archiveName: 'vits-piper-ru_RU-irina-medium',
      modelFileName: 'ru_RU-irina-medium.onnx',
    ),
  };

  final AudioPlayer _player = AudioPlayer();

  static bool supportsLanguage(String language) =>
      _voices.containsKey(language);

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
          (dataDir != null || lexicon != null),
      modelPath: model,
      tokensPath: tokens,
      dataDir: dataDir,
      lexiconPath: lexicon,
    );
  }

  static Future<OfflineTtsDownloadResult> downloadLanguages(
    Iterable<String> languages,
  ) async {
    final downloaded = <String>[];
    final alreadyInstalled = <String>[];
    final unsupported = <String>[];
    final failed = <String>[];

    for (final language in languages.toSet()) {
      final voice = _voices[language];
      if (voice == null) {
        unsupported.add(language);
        continue;
      }

      try {
        final status = await loadVoiceStatus(language);
        if (status.installed) {
          alreadyInstalled.add(language);
          continue;
        }

        await _downloadVoice(language, voice);
        final installed = await loadVoiceStatus(language);
        if (installed.installed) {
          downloaded.add(language);
        } else {
          failed.add(language);
        }
      } catch (_) {
        failed.add(language);
      }
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

    final config = sherpa.OfflineTtsConfig(
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

    final tts = sherpa.OfflineTts(config);
    try {
      final audio = tts.generate(text: trimmed);
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

  Future<void> stop() async {
    await _player.stop();
  }

  Future<void> dispose() async {
    await _player.dispose();
  }

  static Future<void> _downloadVoice(
    String language,
    _OfflineTtsVoiceDefinition voice,
  ) async {
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

      final sink = archiveFile.openWrite();
      await sink.addStream(response.stream);
      await sink.flush();
      await sink.close();
      downloaded = true;
    } finally {
      client.close();
      if (!downloaded && await archiveFile.exists()) {
        await archiveFile.delete();
      }
    }

    try {
      await extractFileToDisk(archiveFile.path, root.path);
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
