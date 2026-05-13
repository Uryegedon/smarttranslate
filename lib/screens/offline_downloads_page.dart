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
  double? _progressValue;
  String? _progressLabel;

  List<String> get _languages => DeviceTranslationService.supportedLanguages;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool clearMessage = true}) async {
    setState(() {
      _loading = true;
      if (clearMessage) {
        _message = null;
      }
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
      _progressValue = 0;
      _progressLabel = 'Preparing downloads';
    });

    try {
      final selectedLanguages = languages.toSet().toList();
      final result = await DeviceTranslationService.downloadLanguages(
        selectedLanguages,
        onProgress: (progress) {
          if (!mounted) return;
          setState(() {
            _progressValue = progress.value;
            _progressLabel = progress.message;
          });
        },
      );
      final ttsResult = await OfflineTextToSpeechService.downloadLanguages(
        selectedLanguages,
        onProgress: (progress) {
          if (!mounted) return;
          setState(() {
            _progressValue = progress.value;
            _progressLabel = progress.message;
          });
        },
      );
      if (!mounted) return;
      setState(() => _message = _summaryFor(result, ttsResult));
      await _load(clearMessage: false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _message = 'Download failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          _downloading = false;
          _progressValue = null;
          _progressLabel = null;
        });
      }
    }
  }

  Future<void> _downloadSpeechModel() async {
    setState(() {
      _downloadingSpeech = true;
      _message = null;
      _progressValue = 0;
      _progressLabel = 'Preparing offline speech model';
    });

    try {
      await OfflineSpeechRecognitionService.downloadModel(
        onProgress: (progress) {
          if (!mounted) return;
          setState(() {
            _progressValue = progress.value;
            _progressLabel = progress.message;
          });
        },
      );
      if (!mounted) return;
      setState(() => _message = 'Offline speech model downloaded.');
      await _load(clearMessage: false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _message = 'Speech model download failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          _downloadingSpeech = false;
          _progressValue = null;
          _progressLabel = null;
        });
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

      final unconfiguredTts =
          ttsResult.failed
              .where(OfflineTextToSpeechService.needsDownloadConfiguration)
              .toList();
      if (unconfiguredTts.isNotEmpty) {
        parts.add(
          'Build with FILIPINO_TTS_ARCHIVE_URL to download ${unconfiguredTts.join(', ')} TTS.',
        );
      }
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
                    icon: Icons.link_rounded,
                    onTap: _showServerUrlDialog,
                  ),
                  const SizedBox(width: 10),
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
                          if (_progressLabel != null) ...[
                            const SizedBox(height: 12),
                            _progressBar(theme, primary),
                          ],
                          const SizedBox(height: 16),
                          _sectionLabel('DOWNLOAD MODELS', theme),
                          const SizedBox(height: 10),
                          _downloadCard(theme, primary),
                          const SizedBox(height: 16),
                          _sectionLabel('OFFLINE SPEECH', theme),
                          const SizedBox(height: 10),
                          _speechModelCard(theme, primary),
                          const SizedBox(height: 16),
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
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
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
            const SizedBox(height: 8),
            Text(
              installed
                  ? 'The app-owned speech model is stored on this phone and can transcribe without internet.'
                  : 'This installs a local speech model used when the app records voice fully offline.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.hintColor,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: primary.withOpacity(0.09),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primary.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
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

  Widget _progressBar(ThemeData theme, Color primary) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor.withOpacity(0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  value: _progressValue,
                  color: primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _progressLabel ?? 'Downloading',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (_progressValue != null)
                Text(
                  '${(_progressValue!.clamp(0.0, 1.0) * 100).round()}%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.hintColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 6,
              value: _progressValue,
              color: primary,
              backgroundColor: primary.withOpacity(0.12),
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
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
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
            const SizedBox(height: 10),
            Text(
              'Downloads the translation model and the bundled local TTS voice when one is available for the selected language.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.hintColor,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
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
        borderRadius: BorderRadius.circular(16),
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
                  visualDensity: VisualDensity.compact,
                  leading: Icon(
                    isReady
                        ? Icons.check_circle_rounded
                        : Icons.download_for_offline_outlined,
                    color: isReady ? primary : theme.hintColor,
                  ),
                  title: Text(language),
                  subtitle: Text(
                    '${isReady ? 'Translation stored locally' : 'Translation not downloaded'} - $ttsText',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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

  Future<void> _showServerUrlDialog() async {
    final override = await SettingsService.loadTranslationApiUrlOverride();
    if (!mounted) return;

    final controller = TextEditingController(text: override ?? '');

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        return AlertDialog(
          title: const Text('Translation Server'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              hintText: 'abc123 or https://abc123.ngrok-free.app',
              labelText: 'Ngrok code or API URL',
              helperText:
                  'Short code becomes https://code.ngrok-free.app/translate/',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await SettingsService.clearTranslationApiUrlOverride();
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
                if (!mounted) return;
                setState(
                  () => _message = 'Translation server override removed.',
                );
              },
              child: const Text('Reset'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final normalised = SettingsService.normaliseTranslationApiUrl(
                  controller.text,
                );
                if (normalised == null) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: const Text('Enter a valid server URL.'),
                      backgroundColor: theme.colorScheme.error,
                    ),
                  );
                  return;
                }

                await SettingsService.saveTranslationApiUrlOverride(normalised);
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
                if (!mounted) return;
                setState(() => _message = 'Translation server saved.');
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    controller.dispose();
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
