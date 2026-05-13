import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../services/settings_service.dart';
import '../widgets/app_bottom_nav_bar.dart';
import 'translationservice.dart';

class CameraOcrPage extends StatefulWidget {
  const CameraOcrPage({super.key});

  @override
  State<CameraOcrPage> createState() => _CameraOcrPageState();
}

class _CameraOcrPageState extends State<CameraOcrPage> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isFlashOn = false;
  bool _isProcessing = false;
  bool _isTranslating = false;
  bool _isTranslated = false;
  bool _ocrAutoTranslate = true;
  String _ocrSourceLanguage = SettingsService.defaultOcrSourceLanguage;
  String _ocrTargetLanguage = SettingsService.defaultOcrTargetLanguage;
  double _ocrTextSize = SettingsService.defaultOcrTextSize;
  String _recognizedText = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _initializeCamera();
  }

  Future<void> _loadSettings() async {
    final settings = await SettingsService.load();
    if (!mounted) return;
    setState(() {
      _ocrAutoTranslate = settings.ocrAutoTranslate;
      _ocrSourceLanguage = settings.ocrSourceLanguage;
      _ocrTargetLanguage = settings.ocrTargetLanguage;
      _ocrTextSize = settings.ocrTextSize;
    });
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (!mounted) return;

      if (_cameras != null && _cameras!.isNotEmpty) {
        final controller = CameraController(_cameras![0], ResolutionPreset.max);
        _cameraController = controller;
        await controller.initialize();
        if (!mounted) {
          await controller.dispose();
          return;
        }
        setState(() {});
      } else {
        debugPrint('No cameras available');
      }
    } catch (e) {
      debugPrint('Camera initialization failed: $e');
      if (mounted) {
        setState(() {
          _recognizedText = 'Camera unavailable';
        });
      }
    }
  }

  Future<void> _captureAndExtractText() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      debugPrint('Camera not initialized');
      return;
    }
    if (_isProcessing) return;

    try {
      setState(() {
        _isProcessing = true;
        _isTranslated = false;
        _recognizedText = 'Processing...';
      });

      final image = await _cameraController!.takePicture();
      final imageFile = File(image.path);

      if (!await imageFile.exists()) {
        throw Exception('Captured image file does not exist');
      }

      await _extractText(imageFile.path);
    } catch (e) {
      debugPrint('Error in text recognition: $e');
      if (!mounted) return;
      setState(() {
        _recognizedText = 'Error: ${e.toString()}';
        _isTranslated = false;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      } else {
        _isProcessing = false;
      }
    }
  }

  Future<void> _pickImageFromGallery() async {
    if (_isProcessing) return;

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile == null) return;

      setState(() {
        _isProcessing = true;
        _isTranslated = false;
        _recognizedText = 'Processing...';
      });

      await _extractText(pickedFile.path);
    } catch (e) {
      debugPrint('Gallery image error: $e');
      if (!mounted) return;
      setState(() {
        _recognizedText = 'Error processing image';
        _isTranslated = false;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      } else {
        _isProcessing = false;
      }
    }
  }

  Future<void> _extractText(String imagePath) async {
    final recognizedText = await FlutterTesseractOcr.extractText(
      imagePath,
      language: _tesseractLanguages,
      args: const {'preserve_interword_spaces': '1'},
    );
    final extractedText =
        recognizedText.trim().isEmpty ? 'No text recognized' : recognizedText;

    if (!mounted) return;
    setState(() {
      _recognizedText = extractedText;
      _isTranslated = false;
    });

    if (_ocrAutoTranslate && extractedText != 'No text recognized') {
      await _translateRecognizedText();
    }
  }

  Future<void> _translateRecognizedText() async {
    final text = _recognizedText.trim();
    if (text.isEmpty ||
        text == 'Processing...' ||
        text == 'No text recognized' ||
        text.startsWith('Error:')) {
      return;
    }

    setState(() => _isTranslating = true);

    try {
      final translated = await translateDetectedText(
        text,
        sourceLanguage: _ocrSourceLanguage,
        targetLanguage: _ocrTargetLanguage,
      );

      if (!mounted) return;
      setState(() {
        _recognizedText = translated.isEmpty ? text : translated;
        _isTranslated = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _recognizedText = 'Error: $e';
        _isTranslated = false;
      });
    } finally {
      if (mounted) {
        setState(() => _isTranslating = false);
      }
    }
  }

  void _toggleFlash() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      debugPrint('Camera not initialized');
      return;
    }

    try {
      _isFlashOn = !_isFlashOn;
      await _cameraController!.setFlashMode(
        _isFlashOn ? FlashMode.torch : FlashMode.off,
      );
      setState(() {});
    } catch (e) {
      debugPrint('Error toggling flash: $e');
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  String get _tesseractLanguages => 'eng+spa+tgl+rus';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final canTranslate =
        _recognizedText.trim().isNotEmpty &&
        !_isTranslated &&
        !_isProcessing &&
        !_isTranslating &&
        _recognizedText != 'Processing...' &&
        _recognizedText != 'No text recognized' &&
        !_recognizedText.startsWith('Error:');

    return Scaffold(
      backgroundColor: Colors.black,
      body:
          _cameraController == null || !_cameraController!.value.isInitialized
              ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(primary),
                ),
              )
              : Stack(
                fit: StackFit.expand,
                children: [
                  // Camera Preview
                  CameraPreview(_cameraController!),

                  // Top gradient overlay
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 120,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.5),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Top bar with title
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 12,
                    left: 20,
                    right: 20,
                    child: Row(
                      children: [
                        Text(
                          'Camera OCR',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        // Settings icon
                        GestureDetector(
                          onTap: () async {
                            await Navigator.pushNamed(context, '/ocrsettings');
                            if (mounted) {
                              await _loadSettings();
                            }
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.settings_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Recognized text overlay
                  if (_recognizedText.isNotEmpty)
                    Center(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        padding: const EdgeInsets.all(20),
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.3,
                        ),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.text_snippet_rounded,
                                    size: 18,
                                    color: primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _isTranslated
                                        ? 'Translated Text'
                                        : 'Extracted Text',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: primary,
                                    ),
                                  ),
                                  const Spacer(),
                                  GestureDetector(
                                    onTap:
                                        () => setState(
                                          () => _recognizedText = '',
                                        ),
                                    child: Icon(
                                      Icons.close_rounded,
                                      size: 20,
                                      color: theme.hintColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _recognizedText,
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface,
                                  fontSize: _ocrTextSize,
                                  height: 1.5,
                                ),
                              ),
                              if (canTranslate || _isTranslating) ...[
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed:
                                        _isTranslating
                                            ? null
                                            : _translateRecognizedText,
                                    icon:
                                        _isTranslating
                                            ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                            : const Icon(
                                              Icons.translate_rounded,
                                            ),
                                    label: Text(
                                      _isTranslating
                                          ? 'Translating...'
                                          : 'Translate',
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),

                  // Bottom gradient overlay
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 200,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.6),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Bottom camera controls
                  Positioned(
                    bottom: 100,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Gallery button
                        _buildControlButton(
                          icon: Icons.photo_library_rounded,
                          onTap: _pickImageFromGallery,
                          size: 50,
                        ),
                        const SizedBox(width: 28),
                        // Capture button
                        GestureDetector(
                          onTap: _captureAndExtractText,
                          child: Container(
                            width: 76,
                            height: 76,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                            ),
                            child: Container(
                              margin: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: primary,
                              ),
                              child: const Icon(
                                Icons.camera_rounded,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 28),
                        // Flash button
                        _buildControlButton(
                          icon:
                              _isFlashOn
                                  ? Icons.flash_on_rounded
                                  : Icons.flash_off_rounded,
                          onTap: _toggleFlash,
                          size: 50,
                          isActive: _isFlashOn,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      bottomNavigationBar: const AppBottomNavBar(currentTab: AppTab.camera),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onTap,
    double size = 50,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color:
              isActive
                  ? Colors.white.withOpacity(0.3)
                  : Colors.white.withOpacity(0.15),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}
