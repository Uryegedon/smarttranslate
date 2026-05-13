import 'package:flutter/material.dart';

import '../services/device_translation_service.dart';
import '../services/offline_speech_recognition_service.dart';
import '../services/offline_text_to_speech_service.dart';
import '../services/settings_service.dart';

class OfflineDownloadsPage extends StatefulWidget {
  const OfflineDownloadsPage({super.key});

  @override
  State<OfflineDownloadsPage> createState() => _OfflineDownloadsPageState();
}

class _OfflineDownloadsPageState extends State<OfflineDownloadsPage> {
  DeviceTranslationModelStatus? _status;
  OfflineSpeechModelStatus? _speechStatus;
  Map<String, OfflineTtsVoiceStatus> _ttsVoiceStatuses = const {};
  String _sourceLanguage = SettingsService.defaultSourceLanguage;
  String _targetLanguage = SettingsService.defaultTargetLanguage;
  bool _loading = true;
  bool _downloading = false;
  bool _downloadingSpeech = false;
  String? _message;

  List<String> get _languages => DeviceTranslationService.supportedLanguages;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _message = null;
    });

    try {
      final status = await DeviceTranslationService.loadModelStatus();
      final speechStatus =
          await OfflineSpeechRecognitionService.loadModelStatus();
      final ttsVoiceStatuses =
          await OfflineTextToSpeechService.loadVoiceStatuses(_languages);
      if (!mounted) return;
      setState(() {
        _status = status;
        _speechStatus = speechStatus;
        _ttsVoiceStatuses = ttsVoiceStatuses;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _message = 'Unable to load local model status: $e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _downloadSelected() async {
    await _download({_sourceLanguage, _targetLanguage});
  }

  Future<void> _downloadAll() async {
    await _download(_languages);
  }

  Future<void> _download(Iterable<String> languages) async {
    setState(() {
      _downloading = true;
      _message = null;
    });

    try {
      final result = await DeviceTranslationService.downloadLanguages(
        languages,
      );
      final ttsResult = await OfflineTextToSpeechService.downloadLanguages(
        languages,
      );
      if (!mounted) return;
      setState(() => _message = _summaryFor(result, ttsResult));
      await _load();
    } catch (e) {
      if (!mounted) return;
      setState(() => _message = 'Download failed: $e');
    } finally {
      if (mounted) {
        setState(() => _downloading = false);
      }
    }
  }

  Future<void> _downloadSpeechModel() async {
    setState(() {
      _downloadingSpeech = true;
      _message = null;
    });

    try {
      await OfflineSpeechRecognitionService.downloadModel();
      if (!mounted) return;
      setState(() => _message = 'Offline speech model downloaded.');
      await _load();
    } catch (e) {
      if (!mounted) return;
      setState(() => _message = 'Speech model download failed: $e');
    } finally {
      if (mounted) {
        setState(() => _downloadingSpeech = false);
      }
    }
  }

  String _summaryFor(
    DeviceTranslationDownloadResult result,
    OfflineTtsDownloadResult ttsResult,
  ) {
    final parts = <String>[];

    if (result.downloaded.isNotEmpty || ttsResult.downloaded.isNotEmpty) {
      final languageDownloads =
          result.downloaded.toSet()..addAll(ttsResult.downloaded);
      parts.add('Downloaded ${languageDownloads.join(', ')}.');
    }

    if (ttsResult.unsupported.isNotEmpty) {
      parts.add(
        'No bundled local TTS voice yet for ${ttsResult.unsupported.join(', ')}.',
      );
    }

    if (result.failed.isNotEmpty || ttsResult.failed.isNotEmpty) {
      final failed = result.failed.toSet()..addAll(ttsResult.failed);
      parts.add('Some downloads failed: ${failed.join(', ')}.');
    }

    if (parts.isNotEmpty) {
      return parts.join(' ');
    }

    if (result.alreadyInstalled.isNotEmpty ||
        ttsResult.alreadyInstalled.isNotEmpty) {
      return 'Selected model(s) are already installed on this phone.';
    }

    return 'No model changes were needed.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final downloaded = _status?.downloadedLanguages ?? const [];
    final missing = _status?.missingLanguages ?? const [];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  _iconButton(
                    theme: theme,
                    icon: Icons.arrow_back_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Offline Downloads',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  _iconButton(
                    theme: theme,
                    icon: Icons.refresh_rounded,
                    onTap:
                        _loading || _downloading || _downloadingSpeech
                            ? null
                            : _load,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child:
                  _loading
                      ? Center(child: CircularProgressIndicator(color: primary))
                      : ListView(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                        children: [
                          _statusBand(
                            theme: theme,
                            primary: primary,
                            downloadedCount: downloaded.length,
                            missingCount: missing.length,
                          ),
                          const SizedBox(height: 20),
                          _sectionLabel('DOWNLOAD MODELS', theme),
                          const SizedBox(height: 10),
                          _downloadCard(theme, primary),
                          const SizedBox(height: 20),
                          _sectionLabel('OFFLINE SPEECH', theme),
                          const SizedBox(height: 10),
                          _speechModelCard(theme, primary),
                          const SizedBox(height: 20),
                          _sectionLabel('ON THIS PHONE', theme),
                          const SizedBox(height: 10),
                          _modelsCard(
                            theme: theme,
                            primary: primary,
                            downloaded: downloaded,
                            missing: missing,
                          ),
                          if (_message != null) ...[
                            const SizedBox(height: 16),
                            Text(
                              _message!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color:
                                    _message!.startsWith('Download failed') ||
                                            _message!.startsWith('Unable') ||
                                            _message!.startsWith(
                                              'Speech model download failed',
                                            ) ||
                                            _message!.contains(
                                              'downloads failed',
                                            )
                                        ? theme.colorScheme.error
                                        : theme.colorScheme.onSurface
                                            .withOpacity(0.72),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _speechModelCard(ThemeData theme, Color primary) {
    final installed = _speechStatus?.installed ?? false;

    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  installed
                      ? Icons.graphic_eq_rounded
                      : Icons.record_voice_over_outlined,
                  color: installed ? primary : theme.hintColor,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    installed
                        ? 'Offline speech recognizer ready'
                        : 'Download offline speech recognizer',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              installed
                  ? 'The app-owned speech model is stored on this phone and can transcribe without internet.'
                  : 'This installs a local speech model used when the app records voice fully offline.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.hintColor,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed:
                    installed || _downloadingSpeech || _downloading
                        ? null
                        : _downloadSpeechModel,
                icon:
                    _downloadingSpeech
                        ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : Icon(
                          installed
                              ? Icons.check_circle_rounded
                              : Icons.download_rounded,
                        ),
                label: Text(installed ? 'Installed' : 'Download Speech Model'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBand({
    required ThemeData theme,
    required Color primary,
    required int downloadedCount,
    required int missingCount,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: primary.withOpacity(0.09),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primary.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.phone_android_rounded, color: primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$downloadedCount translation model(s) ready',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  missingCount == 0
                      ? 'All supported app languages are stored on this phone'
                      : '$missingCount language model(s) still need download',
                  style: TextStyle(fontSize: 12, color: theme.hintColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _downloadCard(ThemeData theme, Color primary) {
    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _languageDropdown(
                    value: _sourceLanguage,
                    primary: primary,
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _sourceLanguage = value);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Icon(Icons.arrow_forward_rounded, color: theme.hintColor),
                const SizedBox(width: 10),
                Expanded(
                  child: _languageDropdown(
                    value: _targetLanguage,
                    primary: primary,
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _targetLanguage = value);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Downloads the translation model and the bundled local TTS voice when one is available for the selected language.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.hintColor,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed:
                        _downloading || _downloadingSpeech
                            ? null
                            : _downloadSelected,
                    icon: const Icon(Icons.download_rounded),
                    label: const Text('Selected'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed:
                        _downloading || _downloadingSpeech
                            ? null
                            : _downloadAll,
                    icon:
                        _downloading
                            ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Icon(Icons.cloud_download_rounded),
                    label: const Text('All'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _modelsCard({
    required ThemeData theme,
    required Color primary,
    required List<String> downloaded,
    required List<String> missing,
  }) {
    return Container(
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
      child: Column(
        children: [
          for (var index = 0; index < _languages.length; index++) ...[
            Builder(
              builder: (context) {
                final language = _languages[index];
                final isReady = downloaded.contains(language);
                final ttsStatus = _ttsVoiceStatuses[language];
                final ttsText =
                    ttsStatus == null
                        ? 'Checking TTS voice'
                        : !ttsStatus.supported
                        ? 'No bundled local TTS voice yet'
                        : ttsStatus.installed
                        ? 'Local TTS voice stored'
                        : 'Local TTS voice not downloaded';
                return ListTile(
                  leading: Icon(
                    isReady
                        ? Icons.check_circle_rounded
                        : Icons.download_for_offline_outlined,
                    color: isReady ? primary : theme.hintColor,
                  ),
                  title: Text(language),
                  subtitle: Text(
                    '${isReady ? 'Translation stored locally' : 'Translation not downloaded'} - $ttsText',
                  ),
                  dense: true,
                );
              },
            ),
            if (index < _languages.length - 1)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Divider(height: 1, color: theme.dividerColor),
              ),
          ],
        ],
      ),
    );
  }

  Widget _languageDropdown({
    required String value,
    required Color primary,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        icon: Icon(Icons.keyboard_arrow_down_rounded, color: primary),
        items:
            _languages.map((language) {
              return DropdownMenuItem<String>(
                value: language,
                child: Text(language, overflow: TextOverflow.ellipsis),
              );
            }).toList(),
        onChanged: _downloading || _downloadingSpeech ? null : onChanged,
      ),
    );
  }

  Widget _iconButton({
    required ThemeData theme,
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: theme.colorScheme.onSurface),
      ),
    );
  }

  Widget _sectionLabel(String text, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: theme.hintColor,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
