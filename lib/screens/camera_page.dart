import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'dart:io';
import 'dart:async';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CameraOcrPage extends StatefulWidget {
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
    return Scaffold(
      body: _cameraController == null || !_cameraController!.value.isInitialized
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              fit: StackFit.expand,
              children: [
                // Camera Preview full background
                CameraPreview(_cameraController!),

                // Recognized text in center
                if (_recognizedText.isNotEmpty)
                  Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(16),
                      height: MediaQuery.of(context).size.height * 0.3,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SingleChildScrollView(
                        child: Text(
                          _recognizedText,
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ),
                  ),

                // Bottom buttons
                Positioned(
                  bottom: 30,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Gallery button
                      CircleAvatar(
                        backgroundColor: Colors.black54,
                        child: IconButton(
                          icon: const Icon(Icons.photo, color: Colors.white),
                          onPressed: _pickImageFromGallery,
                        ),
                      ),
                      const SizedBox(width: 20),
                      // Capture button
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.teal,
                        child: IconButton(
                          icon: const Icon(Icons.camera, color: Colors.white, size: 30),
                          onPressed: _captureAndExtractText,
                        ),
                      ),
                      const SizedBox(width: 20),
                      // Flash button (next to capture)
                      CircleAvatar(
                        backgroundColor: Colors.black54,
                        child: IconButton(
                          icon: Icon(
                            _isFlashOn ? Icons.flash_on : Icons.flash_off,
                            color: Colors.white,
                          ),
                          onPressed: _toggleFlash,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.blue[300],
        selectedItemColor: Colors.black,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/translate');
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/camera');
              break;
            case 2:
              Navigator.pushReplacementNamed(context, '/minigames');
              break;
            case 3:
              Navigator.pushReplacementNamed(context, '/profile');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.translate),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.extension),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: CircleAvatar(
              radius: 14,
              backgroundColor: Colors.greenAccent,
              child: Icon(Icons.person, color: Colors.white),
            ),
            label: '',
          ),
        ],
      ),
    );
  }
}
