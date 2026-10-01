import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../services/liveness_service.dart';

class CameraLivenessScreen extends StatefulWidget {
  final VoidCallback? onSuccess;
  final ValueChanged<Uint8List?>? onSuccessWithPhoto;

  const CameraLivenessScreen({
    super.key,
    this.onSuccess,
    this.onSuccessWithPhoto,
  });

  @override
  State<CameraLivenessScreen> createState() => _CameraLivenessScreenState();
}

class _CameraLivenessScreenState extends State<CameraLivenessScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  late final LivenessService _livenessService;
  bool _isCameraInitialized = false;
  bool _permissionDenied = false;
  bool _permissionPermanentlyDenied = false;
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _livenessService = LivenessService();
    _livenessService.addListener(_onLivenessStateChanged);
    _checkPermissionAndInitCamera();
  }

  void _onLivenessStateChanged() async {
    if (_livenessService.state == LivenessState.success) {
      Uint8List? capturedBytes;
      try {
        if (_cameraController != null && _cameraController!.value.isInitialized) {
          if (_cameraController!.value.isStreamingImages) {
            await _cameraController!.stopImageStream();
          }
          final xFile = await _cameraController!.takePicture();
          capturedBytes = await xFile.readAsBytes();
        }
      } catch (e) {
        debugPrint('Error taking face snapshot: $e');
      }

      if (mounted) {
        if (widget.onSuccessWithPhoto != null) {
          widget.onSuccessWithPhoto!(capturedBytes);
        } else if (widget.onSuccess != null) {
          widget.onSuccess!();
        }
      }
    }
    setState(() {});
  }

  Future<void> _checkPermissionAndInitCamera() async {
    if (kIsWeb) {
      setState(() {
        _permissionDenied = false;
        _permissionPermanentlyDenied = false;
      });
      await _initFrontCamera();
      return;
    }

    final status = await Permission.camera.request();
    if (status.isGranted) {
      setState(() {
        _permissionDenied = false;
        _permissionPermanentlyDenied = false;
      });
      await _initFrontCamera();
    } else if (status.isPermanentlyDenied) {
      setState(() {
        _permissionDenied = true;
        _permissionPermanentlyDenied = true;
      });
    } else {
      setState(() {
        _permissionDenied = true;
        _permissionPermanentlyDenied = false;
      });
    }
  }

  Future<void> _initFrontCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _permissionDenied = true);
        return;
      }

      final frontCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      final isAndroid = !kIsWeb && Platform.isAndroid;

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
      );

      await _cameraController!.initialize();
      if (!mounted) return;

      setState(() => _isCameraInitialized = true);

      _livenessService.startVerification();

      if (kIsWeb) {
        _startWebLivenessProgress();
      } else {
        _cameraController!.startImageStream((CameraImage image) async {
          if (_cameraController == null || !_cameraController!.value.isStreamingImages) return;
          if (_isBusy) return;

          _isBusy = true;
          try {
            final inputImage = _inputImageFromCameraImage(image, frontCamera);
            if (inputImage != null) {
              final screenSize = MediaQuery.of(context).size;
              await _livenessService.processImage(inputImage, screenSize);
            }
          } catch (e) {
            debugPrint('Error processing camera frame: $e');
          } finally {
            _isBusy = false;
          }
        });
      }
    } catch (e) {
      debugPrint('Camera init error: $e');
    }
  }

  void _startWebLivenessProgress() {
    Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!mounted || _livenessService.state != LivenessState.verifying) {
        timer.cancel();
        return;
      }
      _livenessService.advanceWebChallenge();
    });
  }

  InputImage? _inputImageFromCameraImage(CameraImage image, CameraDescription camera) {
    if (kIsWeb) return null;

    final sensorOrientation = camera.sensorOrientation;
    InputImageRotation rotation = InputImageRotationValue.fromRawValue(sensorOrientation) ??
        InputImageRotationValue.fromRawValue(_getAndroidRotationCompensation(sensorOrientation)) ??
        InputImageRotation.rotation270deg;

    InputImageFormat format = (!kIsWeb && Platform.isAndroid)
        ? InputImageFormat.nv21
        : InputImageFormat.bgra8888;

    if (image.planes.isEmpty) return null;

    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );
  }

  int _getAndroidRotationCompensation(int sensorOrientation) {
    final orientations = {
      DeviceOrientation.portraitUp: 0,
      DeviceOrientation.landscapeLeft: 90,
      DeviceOrientation.portraitDown: 180,
      DeviceOrientation.landscapeRight: 270,
    };

    int deviceOrientation = orientations[DeviceOrientation.portraitUp] ?? 0;
    int rotationCompensation = (sensorOrientation - deviceOrientation + 360) % 360;
    return rotationCompensation;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;

    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _cameraController?.dispose();
      setState(() => _isCameraInitialized = false);
    } else if (state == AppLifecycleState.resumed && !_permissionDenied) {
      _initFrontCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _livenessService.removeListener(_onLivenessStateChanged);
    _livenessService.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Human Liveness Verification', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: _permissionDenied
            ? _buildPermissionDeniedUI()
            : (!_isCameraInitialized
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : Stack(
                    children: [
                      // Camera Live Preview
                      CameraPreview(_cameraController!),

                      // Custom Oval Cutout Overlay
                      CustomPaint(
                        size: screenSize,
                        painter: OvalOverlayPainter(),
                      ),

                      // Live Feedback & Instruction Overlay
                      Positioned(
                        top: 24,
                        left: 20,
                        right: 20,
                        child: Column(
                          children: [
                            // Challenge Progress Counter & Timer
                            if (_livenessService.state == LivenessState.verifying) ...[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.7),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.white30),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.timer_outlined, color: Colors.amber, size: 18),
                                        const SizedBox(width: 6),
                                        Text(
                                          '${_livenessService.challengeSecondsRemaining}s',
                                          style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          'Step ${_livenessService.currentStep} of ${_livenessService.totalChallenges}',
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Guidance Message Pill
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              decoration: BoxDecoration(
                                color: _livenessService.state == LivenessState.success
                                    ? Colors.green.shade800
                                    : (_livenessService.state == LivenessState.failed || _livenessService.state == LivenessState.lockedOut)
                                        ? Colors.red.shade900
                                        : Colors.blue.shade900.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: const [
                                  BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 3)),
                                ],
                              ),
                              child: Text(
                                _livenessService.guidanceMessage,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Result / Retry / Lockout Overlay
                      if (_livenessService.state == LivenessState.failed ||
                          _livenessService.state == LivenessState.lockedOut ||
                          _livenessService.state == LivenessState.success)
                        Positioned(
                          bottom: 40,
                          left: 20,
                          right: 20,
                          child: Column(
                            children: [
                              if (_livenessService.state == LivenessState.success) ...[
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 40),
                                ),
                                const SizedBox(height: 12),
                                const Text('Human Verified Successfully!', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                              ] else if (_livenessService.state == LivenessState.lockedOut) ...[
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade900.withOpacity(0.95),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    children: [
                                      const Icon(Icons.lock_clock_rounded, color: Colors.white, size: 36),
                                      const SizedBox(height: 8),
                                      const Text('Verification Locked Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Too many failed attempts. Please wait ${_livenessService.lockoutSecondsRemaining} seconds.',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                              ] else ...[
                                ElevatedButton.icon(
                                  onPressed: () {
                                    _livenessService.startVerification();
                                  },
                                  icon: const Icon(Icons.refresh_rounded),
                                  label: const Text('Try Verification Again'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red.shade700,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                    ],
                  )),
      ),
    );
  }

  Widget _buildPermissionDeniedUI() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.camera_alt_outlined, color: Colors.redAccent, size: 64),
            const SizedBox(height: 20),
            const Text(
              'Camera Access Required',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'To prevent automated bots and fraud, human liveness verification requires access to your device camera.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: () async {
                if (_permissionPermanentlyDenied) {
                  await openAppSettings();
                } else {
                  await _checkPermissionAndInitCamera();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                _permissionPermanentlyDenied ? 'Open App Settings' : 'Grant Camera Permission',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OvalOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.65)
      ..style = PaintingStyle.fill;

    final ovalWidth = size.width * 0.72;
    final ovalHeight = size.height * 0.48;
    final ovalCenter = Offset(size.width / 2, size.height * 0.42);

    final ovalRect = Rect.fromCenter(center: ovalCenter, width: ovalWidth, height: ovalHeight);

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addOval(ovalRect);
    path.fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);

    // Oval Border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawOval(ovalRect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
