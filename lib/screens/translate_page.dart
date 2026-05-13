import 'dart:async';

import 'package:flutter/material.dart';
import 'package:clipboard/clipboard.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'translationservice.dart';
import 'themeawarewidget.dart';
import '../services/language_algorithms.dart';
import '../services/native_on_device_speech_service.dart';
import '../services/offline_speech_recognition_service.dart';
import '../services/offline_text_to_speech_service.dart';
import '../services/settings_service.dart';
import '../widgets/app_bottom_nav_bar.dart';

enum _SpeechInputMode { offlineModel, nativeOnDevice, platformFallback }

class TranslatorScreen extends StatefulWidget {
  const TranslatorScreen({super.key});

  @override
  State<TranslatorScreen> createState() => _TranslatorScreenState();
}

class _TranslatorScreenState extends State<TranslatorScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _inputController = TextEditingController();
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  final OfflineSpeechRecognitionService _offlineSpeech =
      OfflineSpeechRecognitionService();
  final OfflineTextToSpeechService _offlineTts = OfflineTextToSpeechService();
  final FlutterTts _flutterTts = FlutterTts();
  String _translatedText = "";
  List<String> _alternativeTranslations = [];
  List<String> _autocompleteSuggestions = [];
  String? _typoSuggestion;
  String? _phraseSuggestion;
  String _sourceLanguage = 'English';
  String _targetLanguage = 'Spanish';
  String? _voiceStatus;
  final List<String> _availableLanguages = SettingsService.translatorLanguages;
  late AnimationController _swapController;
  Timer? _translationDebounce;
  Timer? _offlineTtsCompletionTimer;
  Timer? _offlineSpeechAutoStopTimer;
  StreamSubscription<NativeSpeechEvent>? _nativeSpeechSubscription;
  int _translationRequestId = 0;
  bool _speechAvailable = false;
  bool _offlineSpeechModelAvailable = false;
  bool _nativeOnDeviceSpeechAvailable = false;
  bool _isListening = false;
  bool _isSpeaking = false;
  double _ttsVolume = SettingsService.defaultSoundVolume;
  _SpeechInputMode? _activeSpeechInputMode;

  @override
  void initState() {
    super.initState();
    _swapController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _loadLanguageSettings();
    _initializeVoiceTools();
  }

  Future<void> _loadLanguageSettings() async {
    final settings = await SettingsService.load();
    if (!mounted) return;
    setState(() {
      _sourceLanguage = settings.defaultSourceLanguage;
      _targetLanguage = settings.defaultTargetLanguage;
      _ttsVolume = settings.soundVolume;
    });
  }

  Future<void> _initializeVoiceTools() async {
    final offlineSpeechStatus =
        await OfflineSpeechRecognitionService.loadModelStatus();
    final nativeOnDeviceAvailable =
        await NativeOnDeviceSpeechService.isAvailable();
    final speechAvailable = await _speechToText.initialize(
      onStatus: _handleSpeechStatus,
      onError: (error) {
        if (!mounted) return;
        setState(() {
          _isListening = false;
          _voiceStatus = error.errorMsg;
        });
      },
    );

    await _flutterTts.setSpeechRate(0.45);
    await _flutterTts.setVolume(_ttsVolume);
    _flutterTts.setCompletionHandler(() {
      if (mounted) {
        setState(() => _isSpeaking = false);
      }
    });
    _flutterTts.setCancelHandler(() {
      if (mounted) {
        setState(() => _isSpeaking = false);
      }
    });
    _flutterTts.setErrorHandler((message) {
      if (mounted) {
        setState(() {
          _isSpeaking = false;
          _voiceStatus = message;
        });
      }
    });

    if (!mounted) return;
    setState(() {
      _offlineSpeechModelAvailable = offlineSpeechStatus.installed;
      _nativeOnDeviceSpeechAvailable = nativeOnDeviceAvailable;
      _speechAvailable =
          offlineSpeechStatus.installed ||
          nativeOnDeviceAvailable ||
          speechAvailable;
      _voiceStatus = _speechAvailable ? null : 'Speech recognition unavailable';
    });

    _nativeSpeechSubscription ??= NativeOnDeviceSpeechService.events().listen(
      _handleNativeSpeechEvent,
      onError: (_) {},
    );
  }

  Future<void> _refreshLocalSpeechAvailability() async {
    final offlineSpeechStatus =
        await OfflineSpeechRecognitionService.loadModelStatus();
    final nativeOnDeviceAvailable =
        await NativeOnDeviceSpeechService.isAvailable();

    if (!mounted) return;
    setState(() {
      _offlineSpeechModelAvailable = offlineSpeechStatus.installed;
      _nativeOnDeviceSpeechAvailable = nativeOnDeviceAvailable;
      _speechAvailable =
          _speechAvailable ||
          offlineSpeechStatus.installed ||
          nativeOnDeviceAvailable;
      if (_speechAvailable &&
          _voiceStatus == 'Speech recognition unavailable') {
        _voiceStatus = null;
      }
    });
  }

  @override
  void dispose() {
    _translationDebounce?.cancel();
    _offlineTtsCompletionTimer?.cancel();
    _offlineSpeechAutoStopTimer?.cancel();
    _nativeSpeechSubscription?.cancel();
    unawaited(NativeOnDeviceSpeechService.cancel());
    unawaited(_offlineSpeech.dispose());
    unawaited(_offlineTts.dispose());
    _speechToText.cancel();
    _flutterTts.stop();
    _swapController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  void _translate(String text, {bool immediate = false}) {
    _translationDebounce?.cancel();

    final activeWord = _activeWordFrom(text);
    final suggestions =
        LanguageAlgorithms.autocomplete(
          prefix: activeWord,
          language: _sourceLanguage,
        ).where((suggestion) {
          return !suggestion.contains(' ') &&
              suggestion.toLowerCase() != activeWord.toLowerCase();
        }).toList();
    final typoSuggestion = LanguageAlgorithms.suggestCorrection(
      word: activeWord,
      language: _sourceLanguage,
    );
    final phraseSuggestion = LanguageAlgorithms.suggestPhraseCompletion(
      text: text,
      language: _sourceLanguage,
    );

    if (text.trim().isEmpty) {
      _translationRequestId++;
      setState(() {
        _translatedText = "";
        _alternativeTranslations = [];
        _autocompleteSuggestions = suggestions;
        _typoSuggestion = typoSuggestion;
        _phraseSuggestion = phraseSuggestion;
      });
      return;
    }

    setState(() {
      _autocompleteSuggestions = suggestions;
      _typoSuggestion = typoSuggestion;
      _phraseSuggestion = phraseSuggestion;
    });

    final requestId = ++_translationRequestId;
    void runTranslation() {
      _runTranslation(text, requestId);
    }

    if (immediate) {
      runTranslation();
    } else {
      _translationDebounce = Timer(
        const Duration(milliseconds: 450),
        runTranslation,
      );
    }
  }

  Future<void> _runTranslation(String text, int requestId) async {
    try {
      final translated = await translateText(
        text,
        _sourceLanguage,
        _targetLanguage,
      );

      final alternatives = await _loadAlternativeTranslations(
        originalText: text,
        translatedText: translated,
        sourceLanguage: _sourceLanguage,
        targetLanguage: _targetLanguage,
      );

      if (!mounted ||
          requestId != _translationRequestId ||
          text != _inputController.text) {
        return;
      }

      setState(() {
        _translatedText = translated;
        _alternativeTranslations = alternatives;
      });
    } catch (e) {
      if (!mounted ||
          requestId != _translationRequestId ||
          text != _inputController.text) {
        return;
      }

      setState(() {
        _translatedText = "Translation failed: $e";
        _alternativeTranslations = [];
      });
    }
  }

  Future<List<String>> _loadAlternativeTranslations({
    required String originalText,
    required String translatedText,
    required String sourceLanguage,
    required String targetLanguage,
  }) async {
    final localAlternatives = LanguageAlgorithms.rankAlternativeTranslations(
      originalText: originalText,
      translatedText: translatedText,
      sourceLanguage: sourceLanguage,
      targetLanguage: targetLanguage,
    );

    try {
      final serverAlternatives = await fetchAlternativeTranslations(
        originalText: originalText,
        translatedText: translatedText,
        sourceLanguage: sourceLanguage,
        targetLanguage: targetLanguage,
      );
      return serverAlternatives.isEmpty
          ? localAlternatives
          : serverAlternatives;
    } catch (_) {
      return localAlternatives;
    }
  }

  String _activeWordFrom(String text) {
    final words = text.trimRight().split(RegExp(r'\s+'));
    return words.isEmpty ? '' : words.last;
  }

  void _replaceActiveWord(String replacement) {
    final currentText = _inputController.text.trimRight();
    final lastSpace = currentText.lastIndexOf(RegExp(r'\s'));
    final newText =
        lastSpace == -1
            ? replacement
            : '${currentText.substring(0, lastSpace + 1)}$replacement';

    _inputController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
    _translate(newText, immediate: true);
  }

  void _acceptAutocompleteSuggestion() {
    final suggestion = _inlineAutocompleteSuggestion();
    if (suggestion == null) return;
    _replaceActiveWord(suggestion);
  }

  String? _inlineAutocompleteSuggestion() {
    final activeWord = _activeWordFrom(_inputController.text);
    if (activeWord.trim().length < 2) {
      return null;
    }

    final normalizedActiveWord = activeWord.toLowerCase();
    for (final suggestion in _autocompleteSuggestions) {
      final normalizedSuggestion = suggestion.toLowerCase();
      if (normalizedSuggestion != normalizedActiveWord &&
          normalizedSuggestion.startsWith(normalizedActiveWord)) {
        return suggestion;
      }
    }

    return null;
  }

  String? _inlineAutocompleteSuffix() {
    final suggestion = _inlineAutocompleteSuggestion();
    if (suggestion == null) return null;

    final activeWord = _activeWordFrom(_inputController.text);
    if (activeWord.length >= suggestion.length) return null;
    return suggestion.substring(activeWord.length);
  }

  void _onSourceLanguageChanged(String? newValue) {
    if (newValue != null) {
      setState(() {
        _sourceLanguage = newValue;
      });
      SettingsService.saveDefaultSourceLanguage(newValue);
      if (_inputController.text.isNotEmpty) {
        _translate(_inputController.text, immediate: true);
      }
    }
  }

  void _onTargetLanguageChanged(String? newValue) {
    if (newValue != null) {
      setState(() {
        _targetLanguage = newValue;
      });
      SettingsService.saveDefaultTargetLanguage(newValue);
      if (_inputController.text.isNotEmpty) {
        _translate(_inputController.text, immediate: true);
      }
    }
  }

  void _swapLanguages() {
    _swapController.forward(from: 0);
    setState(() {
      final temp = _sourceLanguage;
      _sourceLanguage = _targetLanguage;
      _targetLanguage = temp;
    });
    SettingsService.saveDefaultSourceLanguage(_sourceLanguage);
    SettingsService.saveDefaultTargetLanguage(_targetLanguage);
    if (_inputController.text.isNotEmpty) {
      _translate(_inputController.text, immediate: true);
    }
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _stopActiveSpeechInput();
      return;
    }

    if (!_speechAvailable) {
      await _initializeVoiceTools();
    } else {
      await _refreshLocalSpeechAvailability();
    }

    if (!_speechAvailable) {
      _showVoiceMessage('Speech recognition is not available on this device.');
      return;
    }

    await _flutterTts.stop();

    if (_offlineSpeechModelAvailable) {
      final hasPermission = await _offlineSpeech.canRecord();
      if (!hasPermission) {
        _showVoiceMessage(
          'Microphone permission is required for offline speech.',
        );
        return;
      }

      await _offlineSpeech.startRecording();
      if (!mounted) return;
      setState(() {
        _activeSpeechInputMode = _SpeechInputMode.offlineModel;
        _isSpeaking = false;
        _isListening = true;
        _voiceStatus = 'Listening offline... speak now';
      });
      _scheduleOfflineSpeechAutoStop();
      return;
    }

    if (_nativeOnDeviceSpeechAvailable) {
      final started = await NativeOnDeviceSpeechService.start(
        localeId: _localeForLanguage(_sourceLanguage),
      );
      if (started) {
        if (!mounted) return;
        setState(() {
          _activeSpeechInputMode = _SpeechInputMode.nativeOnDevice;
          _isSpeaking = false;
          _isListening = true;
          _voiceStatus = 'Listening on device...';
        });
        return;
      }
    }

    if (mounted) {
      setState(() {
        _activeSpeechInputMode = _SpeechInputMode.platformFallback;
        _isSpeaking = false;
        _isListening = true;
        _voiceStatus = 'Listening...';
      });
    }

    await _speechToText.listen(
      localeId: _localeForLanguage(_sourceLanguage),
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      onResult: (result) {
        final recognized = result.recognizedWords.trim();
        if (recognized.isEmpty) return;

        _applyRecognizedSpeech(recognized, immediate: result.finalResult);
      },
    );
  }

  Future<void> _speakTranslation() async {
    final text = _translatedText.trim();
    if (text.isEmpty || text.startsWith('Translation failed:')) {
      _showVoiceMessage('Nothing to read yet.');
      return;
    }

    if (_isSpeaking) {
      _offlineTtsCompletionTimer?.cancel();
      await _offlineTts.stop();
      await _flutterTts.stop();
      if (mounted) {
        setState(() {
          _isSpeaking = false;
          _voiceStatus = null;
        });
      }
      return;
    }

    await _stopActiveSpeechInput(clearFinalStatus: false);

    if (mounted) {
      setState(() {
        _isListening = false;
        _isSpeaking = true;
        _voiceStatus = 'Preparing offline voice...';
      });
    }

    try {
      final offlineDuration = await _offlineTts.speak(
        text: text,
        language: _targetLanguage,
        volume: _ttsVolume,
      );
      if (offlineDuration != null) {
        if (!mounted) return;
        setState(() => _voiceStatus = null);
        _offlineTtsCompletionTimer?.cancel();
        _offlineTtsCompletionTimer = Timer(
          offlineDuration + const Duration(milliseconds: 400),
          () {
            if (mounted) {
              setState(() => _isSpeaking = false);
            }
          },
        );
        return;
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _voiceStatus = 'Offline voice failed, using system TTS.',
        );
      }
    }

    try {
      await _flutterTts.setLanguage(_localeForLanguage(_targetLanguage));
      await _flutterTts.setVolume(_ttsVolume);
      if (mounted) {
        setState(() => _voiceStatus = null);
      }

      final result = await _flutterTts.speak(text);
      if (result != 1 && mounted) {
        setState(() {
          _isSpeaking = false;
          _voiceStatus = 'System text to speech is unavailable.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSpeaking = false;
        _voiceStatus = 'System text to speech failed: $e';
      });
    }
  }

  void _handleSpeechStatus(String status) {
    if (!mounted) return;
    final listening = status == 'listening';
    final done = status == 'done' || status == 'notListening';
    setState(() {
      _isListening = listening;
      if (done && _voiceStatus == 'Listening...') {
        _voiceStatus = null;
      }
    });
  }

  Future<void> _stopActiveSpeechInput({bool clearFinalStatus = true}) async {
    final activeMode = _activeSpeechInputMode;
    _offlineSpeechAutoStopTimer?.cancel();
    _offlineSpeechAutoStopTimer = null;

    switch (activeMode) {
      case _SpeechInputMode.offlineModel:
        if (mounted) {
          setState(() => _voiceStatus = 'Transcribing offline...');
        }
        try {
          final recognized = await _offlineSpeech.stopAndTranscribe(
            languageCode: _whisperLanguageFor(_sourceLanguage),
          );
          if (!mounted) return;
          if (recognized.isEmpty) {
            _showVoiceMessage('No speech was detected.');
          } else {
            _applyRecognizedSpeech(recognized, immediate: true);
          }
        } catch (e) {
          _showVoiceMessage('Offline speech failed: $e');
        }
        break;
      case _SpeechInputMode.nativeOnDevice:
        await NativeOnDeviceSpeechService.stop();
        break;
      case _SpeechInputMode.platformFallback:
        await _speechToText.stop();
        break;
      case null:
        break;
    }

    if (!mounted) return;
    setState(() {
      _activeSpeechInputMode = null;
      _isListening = false;
      if (clearFinalStatus && _isTransientSpeechStatus(_voiceStatus)) {
        _voiceStatus = null;
      }
    });
  }

  void _scheduleOfflineSpeechAutoStop() {
    _offlineSpeechAutoStopTimer?.cancel();
    _offlineSpeechAutoStopTimer = Timer(const Duration(seconds: 5), () async {
      if (!mounted ||
          !_isListening ||
          _activeSpeechInputMode != _SpeechInputMode.offlineModel) {
        return;
      }

      await _stopActiveSpeechInput();
    });
  }

  void _applyRecognizedSpeech(String recognized, {required bool immediate}) {
    final cleaned = recognized.trim();
    if (cleaned.isEmpty) return;

    _inputController.value = TextEditingValue(
      text: cleaned,
      selection: TextSelection.collapsed(offset: cleaned.length),
    );
    _translate(cleaned, immediate: immediate);
  }

  bool _isTransientSpeechStatus(String? status) {
    return status == 'Listening...' ||
        status == 'Listening offline...' ||
        status == 'Listening offline... speak now' ||
        status == 'Listening on device...' ||
        status == 'Transcribing offline...' ||
        status == 'Processing speech...';
  }

  void _handleNativeSpeechEvent(NativeSpeechEvent event) {
    if (!mounted) return;

    if (event.type == 'result') {
      final recognized = event.text?.trim() ?? '';
      if (recognized.isEmpty) {
        return;
      }

      _applyRecognizedSpeech(recognized, immediate: event.isFinal);
      return;
    }

    if (event.type == 'error') {
      setState(() {
        _activeSpeechInputMode = null;
        _isListening = false;
        _voiceStatus = event.message ?? 'On-device speech failed.';
      });
      return;
    }

    if (event.type == 'status') {
      final value = event.value;
      setState(() {
        if (value == 'done' || value == 'cancelled') {
          _activeSpeechInputMode = null;
          _isListening = false;
          _voiceStatus = null;
        } else if (value == 'processing') {
          _voiceStatus = 'Processing speech...';
        } else if (value == 'ready' || value == 'listening') {
          _voiceStatus = 'Listening on device...';
        }
      });
    }
  }

  String _localeForLanguage(String language) {
    return switch (language) {
      'Spanish' => 'es-ES',
      'Filipino' => 'fil-PH',
      'Japanese' => 'ja-JP',
      'Russian' => 'ru-RU',
      _ => 'en-US',
    };
  }

  String _whisperLanguageFor(String language) {
    return switch (language) {
      'Spanish' => 'es',
      'Filipino' => 'tl',
      'Japanese' => 'ja',
      'Russian' => 'ru',
      _ => 'en',
    };
  }

  void _showVoiceMessage(String message) {
    if (!mounted) return;
    setState(() => _voiceStatus = message);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return ThemeAwareScaffold(
      appBar: ThemeAwareAppBar(
        leading: const SizedBox(),
        title: ThemeAwareText(
          'SmartPath Translator',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ── Language Selector ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildLanguageChip(
                      value: _sourceLanguage,
                      onChanged: _onSourceLanguageChanged,
                    ),
                  ),
                  GestureDetector(
                    onTap: _swapLanguages,
                    child: RotationTransition(
                      turns: Tween(begin: 0.0, end: 0.5).animate(
                        CurvedAnimation(
                          parent: _swapController,
                          curve: Curves.easeInOut,
                        ),
                      ),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.swap_horiz_rounded,
                          color: theme.colorScheme.secondary,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: _buildLanguageChip(
                      value: _targetLanguage,
                      onChanged: _onTargetLanguageChanged,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── Input card (fills ~40% of remaining height) ──
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildTextCardFull(
                child: _buildAutocompleteInput(theme),
                icon: Icons.edit_note_rounded,
                iconColor: primary,
                trailing: _buildHeaderIconButton(
                  icon: _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                  color: _isListening ? theme.colorScheme.error : primary,
                  onTap: _toggleListening,
                ),
              ),
            ),
          ),

          if (_voiceStatus != null) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _voiceStatus!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color:
                        _isListening
                            ? primary
                            : theme.colorScheme.onSurface.withOpacity(0.65),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 10),

          // ── Output card ──
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildTextCardFull(
                child: SingleChildScrollView(
                  child: Text(
                    _translatedText.isEmpty
                        ? 'Translation will appear here'
                        : _translatedText,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontSize: 16,
                      color:
                          _translatedText.isEmpty
                              ? theme.hintColor
                              : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                icon: Icons.translate_rounded,
                iconColor: theme.colorScheme.secondary,
                backgroundColor: primary.withOpacity(0.03),
                trailing:
                    _translatedText.isNotEmpty
                        ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildHeaderIconButton(
                              icon:
                                  _isSpeaking
                                      ? Icons.stop_rounded
                                      : Icons.volume_up_rounded,
                              color:
                                  _isSpeaking
                                      ? theme.colorScheme.error
                                      : primary,
                              onTap: _speakTranslation,
                            ),
                            const SizedBox(width: 8),
                            _buildHeaderIconButton(
                              icon: Icons.content_copy_rounded,
                              color: primary,
                              onTap: () {
                                FlutterClipboard.copy(_translatedText);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Copied to clipboard'),
                                  ),
                                );
                              },
                            ),
                          ],
                        )
                        : null,
              ),
            ),
          ),

          // ── Alternative Translations (compact, bottom strip) ──
          if (_alternativeTranslations.isNotEmpty) ...[
            const SizedBox(height: 10),
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.alt_route_rounded,
                            size: 14,
                            color: primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Alternative Translations',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.separated(
                        itemCount: _alternativeTranslations.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final alt = _alternativeTranslations[i];
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: theme.cardColor,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: theme.dividerColor),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.subdirectory_arrow_right_rounded,
                                  size: 16,
                                  color: theme.hintColor,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    alt,
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    FlutterClipboard.copy(alt);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Copied')),
                                    );
                                  },
                                  child: Icon(
                                    Icons.content_copy_rounded,
                                    size: 15,
                                    color: primary,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 12),
        ],
      ),
      bottomNavigationBar: const AppBottomNavBar(currentTab: AppTab.translate),
    );
  }

  Widget _buildAutocompleteInput(ThemeData theme) {
    final inputStyle =
        theme.textTheme.bodyLarge?.copyWith(fontSize: 16) ??
        const TextStyle(fontSize: 16);
    final suffix = _inlineAutocompleteSuffix();
    final currentText = _inputController.text;

    return Column(
      children: [
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              TextField(
                controller: _inputController,
                onChanged: _translate,
                expands: true,
                maxLines: null,
                minLines: null,
                decoration: InputDecoration(
                  hintText: 'Type something to translate...',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                  hintStyle: TextStyle(color: theme.hintColor, fontSize: 16),
                ),
                style: inputStyle,
              ),
              if (suffix != null)
                Positioned.fill(
                  child: IgnorePointer(
                    ignoring: false,
                    child: RichText(
                      text: TextSpan(
                        style: inputStyle,
                        children: [
                          TextSpan(
                            text: currentText,
                            style: const TextStyle(color: Colors.transparent),
                          ),
                          WidgetSpan(
                            alignment: PlaceholderAlignment.baseline,
                            baseline: TextBaseline.alphabetic,
                            child: GestureDetector(
                              behavior: HitTestBehavior.translucent,
                              onTap: _acceptAutocompleteSuggestion,
                              child: Text(
                                suffix,
                                style: inputStyle.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.28),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (_phraseSuggestion != null || _typoSuggestion != null) ...[
          const SizedBox(height: 8),
          _buildInlineSuggestion(theme),
        ],
      ],
    );
  }

  void _acceptInlineSuggestion() {
    final phraseSuggestion = _phraseSuggestion;
    if (phraseSuggestion != null) {
      _inputController.value = TextEditingValue(
        text: phraseSuggestion,
        selection: TextSelection.collapsed(offset: phraseSuggestion.length),
      );
      _translate(phraseSuggestion, immediate: true);
      return;
    }

    final typoSuggestion = _typoSuggestion;
    if (typoSuggestion != null) {
      _replaceActiveWord(typoSuggestion);
    }
  }

  Widget _buildInlineSuggestion(ThemeData theme) {
    final suggestion = _phraseSuggestion ?? _typoSuggestion ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.14)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.auto_fix_high_rounded,
            color: theme.colorScheme.primary,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Did you mean "$suggestion"?',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _acceptInlineSuggestion,
            child: Text(
              'Use',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageChip({
    required String value,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 20,
            color: Theme.of(context).hintColor,
          ),
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          items:
              _availableLanguages.map((String language) {
                return DropdownMenuItem<String>(
                  value: language,
                  child: Text(language),
                );
              }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildHeaderIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }

  /// Full-height card — fills whatever space its parent Expanded gives it
  Widget _buildTextCardFull({
    required Widget child,
    required IconData icon,
    required Color iconColor,
    Color? backgroundColor,
    Widget? trailing,
  }) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor ?? theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const Spacer(),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 8),
          Expanded(child: child),
        ],
      ),
    );
  }
}
