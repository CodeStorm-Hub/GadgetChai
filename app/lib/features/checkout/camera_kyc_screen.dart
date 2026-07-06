import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../core/theme.dart';

class CameraKycScreen extends StatefulWidget {
  final String cameraType; // 'front' or 'back' (nid_front, nid_back vs selfie)
  final void Function(String path) onCapture;

  const CameraKycScreen({
    super.key,
    required this.cameraType,
    required this.onCapture,
  });

  @override
  State<CameraKycScreen> createState() => _CameraKycScreenState();
}

class _CameraKycScreenState extends State<CameraKycScreen> {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;
  bool _hasError = false;
  // ignore: unused_field
  String _errorMsg = "";

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _initCamera();
    } else {
      // Direct Web ImagePicker fallback
      setState(() {
        _hasError = true;
      });
    }
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        throw Exception("No cameras available on this device.");
      }

      // Filter camera based on type
      CameraDescription selectedCamera = _cameras.first;
      if (widget.cameraType == 'front') {
        selectedCamera = _cameras.firstWhere(
          (cam) => cam.lensDirection == CameraLensDirection.front,
          orElse: () => _cameras.first,
        );
      } else {
        selectedCamera = _cameras.firstWhere(
          (cam) => cam.lensDirection == CameraLensDirection.back,
          orElse: () => _cameras.first,
        );
      }

      _controller = CameraController(
        selectedCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _controller!.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMsg = e.toString();
        });
      }
    }
  }

  @override
  void dispose() {
    // Explicitly dispose of camera controller to prevent memory leaks
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      final XFile image = await _controller!.takePicture();
      widget.onCapture(image.path);
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to take photo: $e')),
      );
    }
  }

  // Fallback to ImagePicker for Web / Simulator / Permission Issues
  Future<void> _pickImageFallback() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: widget.cameraType == 'front' ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null) {
        widget.onCapture(image.path);
        Navigator.of(context).pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking file: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = context.colors;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.cameraType == 'front' ? 'Selfie Capture' : 'NID Document Capture'),
        backgroundColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          // Black background for capture screen
          Container(color: Colors.black),

          // Camera Viewport
          if (_isInitialized && _controller != null)
            Center(
              child: AspectRatio(
                aspectRatio: 1 / _controller!.value.aspectRatio,
                child: CameraPreview(_controller!),
              ),
            )
          else if (_hasError)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.no_photography, size: 64, color: scheme.onSurfaceVariant),
                    const SizedBox(height: 16),
                    Text(
                      'Camera Initialisation Failed',
                      style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Web/Simulator or permissions restricted. Tap below to use the standard system image picker.',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _pickImageFallback,
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Open System Picker'),
                      style: ElevatedButton.styleFrom(backgroundColor: scheme.primary),
                    ),
                  ],
                ),
              ),
            )
          else
            const Center(child: CircularProgressIndicator()),

          // Overlay Guideline (Circular for selfie, rectangular for NID)
          if (_isInitialized)
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final double w = constraints.maxWidth;
                  final double h = constraints.maxHeight;

                  if (widget.cameraType == 'front') {
                    // Face Oval Guide
                    return CustomPaint(
                      painter: _SelfieGuidePainter(width: w, height: h, accentColor: scheme.primary),
                    );
                  } else {
                    // NID Rectangular Frame Guide
                    return CustomPaint(
                      painter: _NidGuidePainter(width: w, height: h, accentColor: scheme.primary),
                    );
                  }
                },
              ),
            ),

          // Capture Control HUD at the bottom
          if (_isInitialized)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(Icons.photo_library, color: Colors.white, size: 28),
                    onPressed: _pickImageFallback,
                  ),
                  GestureDetector(
                    onTap: _takePicture,
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(color: scheme.primary, width: 4),
                      ),
                      child: Center(
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // Balancing spacing
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// Painter for drawing a transparent mask with a rectangular NID cutout
class _NidGuidePainter extends CustomPainter {
  final double width;
  final double height;
  final Color accentColor;
  _NidGuidePainter({required this.width, required this.height, required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    final double rectWidth = width * 0.85;
    final double rectHeight = rectWidth * 0.63; // NID standard aspect ratio
    final double left = (width - rectWidth) / 2;
    final double top = (height - rectHeight) / 2;

    final RRect cardRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, rectWidth, rectHeight),
      const Radius.circular(16),
    );

    // Semi-transparent background mask
    final Paint maskPaint = Paint()
      ..color = Colors.black.withOpacity(0.65)
      ..style = PaintingStyle.fill;

    // Outer border guide
    final Paint borderPaint = Paint()
      ..color = accentColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    Path path = Path()
      ..addRect(Rect.fromLTWH(0, 0, width, height))
      ..addRRect(cardRect);

    canvas.drawPath(path, maskPaint);
    canvas.drawRRect(cardRect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Painter for drawing a transparent mask with a circular/oval selfie cutout
class _SelfieGuidePainter extends CustomPainter {
  final double width;
  final double height;
  final Color accentColor;
  _SelfieGuidePainter({required this.width, required this.height, required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    final double ovalWidth = width * 0.70;
    final double ovalHeight = ovalWidth * 1.3;
    final double left = (width - ovalWidth) / 2;
    final double top = (height - ovalHeight) / 2.3;

    final Rect ovalRect = Rect.fromLTWH(left, top, ovalWidth, ovalHeight);

    final Paint maskPaint = Paint()
      ..color = Colors.black.withOpacity(0.65)
      ..style = PaintingStyle.fill;

    final Paint borderPaint = Paint()
      ..color = accentColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    Path path = Path()
      ..addRect(Rect.fromLTWH(0, 0, width, height))
      ..addOval(ovalRect);

    canvas.drawPath(path, maskPaint);
    canvas.drawOval(ovalRect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
