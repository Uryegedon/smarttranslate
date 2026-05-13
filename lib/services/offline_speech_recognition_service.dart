import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

class OfflineSpeechModelStatus {
  const OfflineSpeechModelStatus({
    required this.installed,
    this.encoderPath,
    this.decoderPath,
    this.tokensPath,
  });

  final bool installed;
  final String? encoderPath;
  final String? decoderPath;
  final String? tokensPath;
}

class OfflineSpeechDownloadProgress {
  const OfflineSpeechDownloadProgress({
    required this.message,
    this.value,
  });

  final String message;
  final double? value;
}

typedef OfflineSpeechDownloadProgressCallback =
    void Function(OfflineSpeechDownloadProgress progress);

class OfflineSpeechRecognitionService {
  static const String _modelArchiveUrl =
      'https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/'
      'sherpa-onnx-whisper-tiny.tar.bz2';
  static const String _modelRootName = 'offline_speech';
  static const String _modelVariant = 'whisper_tiny';

  static bool _bindingsInitialized = false;

  final AudioRecorder _recorder = AudioRecorder();
  final BytesBuilder _audioBuffer = BytesBuilder(copy: false);
  StreamSubscription<Uint8List>? _audioSubscription;
  bool _recording = false;

  static Future<OfflineSpeechModelStatus> loadModelStatus() async {
    final modelRoot = await _modelRootDirectory();
    if (!await modelRoot.exists()) {
      return const OfflineSpeechModelStatus(installed: false);
    }

    final files = await _findModelFiles(modelRoot);
    final encoder = files['encoder'];
    final decoder = files['decoder'];
    final tokens = files['tokens'];

    return OfflineSpeechModelStatus(
      installed: encoder != null && decoder != null && tokens != null,
      encoderPath: encoder,
      decoderPath: decoder,
      tokensPath: tokens,
    );
  }

  static Future<void> downloadModel({
    OfflineSpeechDownloadProgressCallback? onProgress,
  }) async {
    final existing = await loadModelStatus();
    if (existing.installed) {
      onProgress?.call(
        const OfflineSpeechDownloadProgress(
          message: 'Offline speech model already installed',
          value: 1,
        ),
      );
      return;
    }

    final modelRoot = await _modelRootDirectory();
    if (await modelRoot.exists()) {
      await modelRoot.delete(recursive: true);
    }
    await modelRoot.create(recursive: true);

    final archiveFile = File(path.join(modelRoot.path, 'whisper_tiny.tar.bz2'));
    if (await archiveFile.exists()) {
      await archiveFile.delete();
    }

    final client = http.Client();
    var downloaded = false;
    try {
      final request = http.Request('GET', Uri.parse(_modelArchiveUrl));
      final response = await client.send(request);

      if (response.statusCode != HttpStatus.ok) {
        throw StateError(
          'Speech model download failed with HTTP ${response.statusCode}.',
        );
      }

      final contentLength = response.contentLength ?? 0;
      var received = 0;
      final sink = archiveFile.openWrite();
      await for (final chunk in response.stream) {
        received += chunk.length;
        sink.add(chunk);
        onProgress?.call(
          OfflineSpeechDownloadProgress(
            message: 'Downloading offline speech model',
            value: contentLength > 0 ? received / contentLength * 0.85 : null,
          ),
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

    onProgress?.call(
      const OfflineSpeechDownloadProgress(
        message: 'Installing offline speech model',
        value: null,
      ),
    );
    final archivePath = archiveFile.path;
    final modelRootPath = modelRoot.path;
    try {
      await Isolate.run(() => extractFileToDisk(archivePath, modelRootPath));
    } finally {
      if (await archiveFile.exists()) {
        await archiveFile.delete();
      }
    }

    final installed = await loadModelStatus();
    if (!installed.installed) {
      throw StateError(
        'Speech model archive extracted, but required model files were not found.',
      );
    }
    onProgress?.call(
      const OfflineSpeechDownloadProgress(
        message: 'Offline speech model installed',
        value: 1,
      ),
    );
  }

  Future<bool> canRecord() {
    return _recorder.hasPermission();
  }

  Future<void> startRecording() async {
    if (_recording) {
      return;
    }

    _audioBuffer.clear();
    final stream = await _recorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
      ),
    );

    _audioSubscription = stream.listen(_audioBuffer.add);
    _recording = true;
  }

  Future<String> stopAndTranscribe({required String languageCode}) async {
    if (!_recording) {
      return '';
    }

    await _audioSubscription?.cancel();
    _audioSubscription = null;
    await _recorder.stop();
    _recording = false;

    final bytes = _audioBuffer.takeBytes();
    if (bytes.isEmpty) {
      return '';
    }

    final modelStatus = await loadModelStatus();
    if (!modelStatus.installed) {
      throw StateError('Offline speech model is not downloaded.');
    }

    final samples = _pcm16ToFloat32(bytes);
    if (samples.isEmpty) {
      return '';
    }

    _ensureBindings();
    final whisperConfig = sherpa.OfflineWhisperModelConfig(
      encoder: modelStatus.encoderPath!,
      decoder: modelStatus.decoderPath!,
      language: languageCode,
      task: 'transcribe',
    );
    final modelConfig = sherpa.OfflineModelConfig(
      tokens: modelStatus.tokensPath!,
      whisper: whisperConfig,
      debug: false,
    );
    final recognizer = sherpa.OfflineRecognizer(
      sherpa.OfflineRecognizerConfig(model: modelConfig),
    );
    final stream = recognizer.createStream();
    try {
      stream.acceptWaveform(samples: samples, sampleRate: 16000);
      recognizer.decode(stream);
      final result = recognizer.getResult(stream);
      return result.text.trim();
    } finally {
      stream.free();
      recognizer.free();
    }
  }

  Future<void> cancel() async {
    await _audioSubscription?.cancel();
    _audioSubscription = null;
    await _recorder.cancel();
    _recording = false;
    _audioBuffer.clear();
  }

  Future<void> dispose() async {
    await cancel();
    await _recorder.dispose();
  }

  static Future<Directory> _modelRootDirectory() async {
    final support = await getApplicationSupportDirectory();
    return Directory(path.join(support.path, _modelRootName, _modelVariant));
  }

  static Future<Map<String, String>> _findModelFiles(Directory root) async {
    final matches = <String, String>{};
    await for (final entity in root.list(recursive: true, followLinks: false)) {
      if (entity is! File) {
        continue;
      }

      final name = path.basename(entity.path);
      if (name == 'tiny-encoder.int8.onnx') {
        matches['encoder'] = entity.path;
      } else if (name == 'tiny-decoder.int8.onnx') {
        matches['decoder'] = entity.path;
      } else if (name == 'tiny-tokens.txt') {
        matches['tokens'] = entity.path;
      }
    }
    return matches;
  }

  static void _ensureBindings() {
    if (_bindingsInitialized) {
      return;
    }
    sherpa.initBindings();
    _bindingsInitialized = true;
  }

  static Float32List _pcm16ToFloat32(Uint8List bytes) {
    final sampleCount = bytes.lengthInBytes ~/ 2;
    final samples = Float32List(sampleCount);
    final byteData = ByteData.sublistView(bytes);

    for (var index = 0; index < sampleCount; index++) {
      final sample = byteData.getInt16(index * 2, Endian.little);
      samples[index] = sample / 32768.0;
    }

    return samples;
  }
}
