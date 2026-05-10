import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'dart:io';
import 'dart:async';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'themeawarewidget.dart';
import '../widgets/app_bottom_nav_bar.dart';

class CameraScreen extends StatefulWidget {
  const CameraOcrPage({super.key});

  @override
  _CameraOcrPageState createState() => _CameraOcrPageState();
}

class _CameraOcrPageState extends State<CameraOcrPage> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isFlashOn = false;
  String _recognizedText = '';

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }


  Future<String> detectAndTranslate(String text) async {
  // Basic Spanish word check (you can replace with a proper language detection API)
  final isLikelySpanish = RegExp(r'\b(hola|gracias|por|favor|usted|qué|cómo|estás)\b', caseSensitive: false).hasMatch(text);
  
  if (isLikelySpanish) {
    try {
      final Uri url = Uri.parse('http://100.119.152.32:8000/translate/');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'text': text}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['translated_text'] ?? text;
      } else {
        return 'Translation failed: ${response.statusCode}';
      }
    } catch (e) {
      return 'Error: $e';
    }
  }

  return text; // Return original if not Spanish
}

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    if (_cameras != null && _cameras!.isNotEmpty) {
      _cameraController = CameraController(
        _cameras![0],
        ResolutionPreset.max,
      );
      await _cameraController!.initialize();
      setState(() {});
    } else {
      debugPrint('No cameras available');
    }
  }

  Future<void> _captureAndExtractText() async {
  if (_cameraController == null || !_cameraController!.value.isInitialized) {
    debugPrint('Camera not initialized');
    return;
  }

  try {
    setState(() {
      _recognizedText = 'Processing...';
    });

    final image = await _cameraController!.takePicture();
    final imageFile = File(image.path);

    if (!await imageFile.exists()) {
      throw Exception('Captured image file does not exist');
    }

    final inputImage = InputImage.fromFile(imageFile);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    final recognizedTextResult = await textRecognizer.processImage(inputImage);
    final rawText = recognizedTextResult.text;

    final resultText = await detectAndTranslate(rawText);

    setState(() {
      _recognizedText = resultText.isEmpty ? 'No text recognized' : resultText;
    });

    textRecognizer.close();
  } catch (e) {
    debugPrint('Error in text recognition: $e');
    setState(() {
      _recognizedText = 'Error: ${e.toString()}';
    });
  }
}


  Future<void> _pickImageFromGallery() async {
  try {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return;

    setState(() {
      _recognizedText = 'Processing...';
    });

    final inputImage = InputImage.fromFilePath(pickedFile.path);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    final recognizedTextResult = await textRecognizer.processImage(inputImage);
    final rawText = recognizedTextResult.text;

    final resultText = await detectAndTranslate(rawText);

    setState(() {
      _recognizedText = resultText.isEmpty ? 'No text recognized' : resultText;
    });

    textRecognizer.close();
  } catch (e) {
    debugPrint('Gallery image error: $e');
    setState(() {
      _recognizedText = 'Error processing image';
    });
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.black,
      body: _cameraController == null || !_cameraController!.value.isInitialized
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
                        onTap: () => Navigator.pushNamed(context, '/ocrsettings'),
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
                                Icon(Icons.text_snippet_rounded, size: 18, color: primary),
                                const SizedBox(width: 8),
                                Text(
                                  'Recognized Text',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: primary,
                                  ),
                                ),
                                const Spacer(),
                                GestureDetector(
                                  onTap: () => setState(() => _recognizedText = ''),
                                  child: Icon(Icons.close_rounded, size: 20, color: theme.hintColor),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _recognizedText,
                              style: TextStyle(
                                color: theme.colorScheme.onSurface,
                                fontSize: 15,
                                height: 1.5,
                              ),
                            ),
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
                        icon: _isFlashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
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
          color: isActive
              ? Colors.white.withOpacity(0.3)
              : Colors.white.withOpacity(0.15),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}
