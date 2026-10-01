import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

enum LivenessChallengeType {
  blink,
  turnLeft,
  turnRight,
  smile,
}

extension LivenessChallengeExtension on LivenessChallengeType {
  String get instruction {
    switch (this) {
      case LivenessChallengeType.blink:
        return 'Please blink your eyes';
      case LivenessChallengeType.turnLeft:
        return 'Turn your head slightly to the left';
      case LivenessChallengeType.turnRight:
        return 'Turn your head slightly to the right';
      case LivenessChallengeType.smile:
        return 'Please smile for the camera';
    }
  }
}

enum LivenessState {
  initial,
  checkingPermission,
  permissionDenied,
  ready,
  verifying,
  challengeSuccess,
  success,
  failed,
  lockedOut,
}

class LivenessService extends ChangeNotifier {
  late final FaceDetector _faceDetector;

  LivenessState _state = LivenessState.initial;
  LivenessState get state => _state;

  List<LivenessChallengeType> _activeChallenges = [];
  int _currentChallengeIndex = 0;
  LivenessChallengeType? get currentChallenge =>
      _activeChallenges.isNotEmpty && _currentChallengeIndex < _activeChallenges.length
          ? _activeChallenges[_currentChallengeIndex]
          : null;

  int get totalChallenges => _activeChallenges.length;
  int get currentStep => _currentChallengeIndex + 1;

  String _guidanceMessage = 'Align your face inside the oval';
  String get guidanceMessage => _guidanceMessage;

  int _failedAttempts = 0;
  int get failedAttempts => _failedAttempts;

  int _lockoutSecondsRemaining = 0;
  int get lockoutSecondsRemaining => _lockoutSecondsRemaining;
  Timer? _lockoutTimer;

  int _challengeSecondsRemaining = 10;
  int get challengeSecondsRemaining => _challengeSecondsRemaining;
  Timer? _challengeTimer;

  bool _isProcessingFrame = false;
  DateTime? _lastFrameProcessTime;

  // Challenge state tracking
  bool _blinkEyeWasOpen = false;
  bool _blinkEyeWasClosed = false;
  DateTime? _challengeStartTime;

  LivenessService() {
    // Note: Disabling landmarks & contours eliminates 'ThickFaceDetector: Unknown landmark type' logcat spam from Google ML Kit.
    // Any remaining ThickFaceDetector logs in Logcat are harmless info output from Google Play Services. Use Logcat filter 'level:info -tag:ThickFaceDetector' to suppress them.
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableClassification: true, // Eye open & smiling probabilities
        enableTracking: true,
        enableLandmarks: false,
        enableContours: false,
        performanceMode: FaceDetectorMode.fast,
        minFaceSize: 0.3,
      ),
    );
  }

  void startVerification() {
    if (_state == LivenessState.lockedOut) return;

    _failedAttempts++;
    _generateRandomChallenges();
    _currentChallengeIndex = 0;
    _resetChallengeState();
    _state = LivenessState.verifying;
    _guidanceMessage = 'Position your face in the oval guide';
    _startChallengeTimer();
    notifyListeners();
  }

  void _generateRandomChallenges() {
    final all = List<LivenessChallengeType>.from(LivenessChallengeType.values);
    all.shuffle(Random());
    _activeChallenges = all.take(2).toList();
  }

  void _startChallengeTimer() {
    _challengeTimer?.cancel();
    _challengeSecondsRemaining = 10;
    _challengeStartTime = DateTime.now();

    _challengeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_challengeSecondsRemaining > 1) {
        _challengeSecondsRemaining--;
        notifyListeners();
      } else {
        _challengeTimer?.cancel();
        _handleFailure('Challenge timed out. Please try again.');
      }
    });
  }

  Future<void> processImage(InputImage inputImage, Size overlaySize) async {
    if (_state != LivenessState.verifying || _isProcessingFrame) return;

    // Throttle frame processing to max 10 fps (100ms interval)
    final now = DateTime.now();
    if (_lastFrameProcessTime != null &&
        now.difference(_lastFrameProcessTime!).inMilliseconds < 100) {
      return;
    }
    _lastFrameProcessTime = now;
    _isProcessingFrame = true;

    try {
      final faces = await _faceDetector.processImage(inputImage);
      _evaluateFaces(faces, overlaySize);
    } catch (e) {
      debugPrint('Face detection error: $e');
    } finally {
      _isProcessingFrame = false;
    }
  }

  void _evaluateFaces(List<Face> faces, Size overlaySize) {
    if (faces.isEmpty) {
      _guidanceMessage = 'No face detected. Align inside oval.';
      _resetChallengeState();
      notifyListeners();
      return;
    }

    if (faces.length > 1) {
      _guidanceMessage = 'Multiple faces detected! Only 1 person allowed.';
      _resetChallengeState();
      notifyListeners();
      return;
    }

    final face = faces.first;
    final box = face.boundingBox;

    // Relative normalization based on image dimensions or overlay size
    final imgW = overlaySize.width > 0 ? overlaySize.width : 720.0;
    final imgH = overlaySize.height > 0 ? overlaySize.height : 1280.0;

    final relativeCenterX = box.center.dx / imgW;
    final relativeCenterY = box.center.dy / imgH;
    final relativeWidth = box.width / imgW;

    if (relativeWidth < 0.12) {
      _guidanceMessage = 'Move closer to the camera';
      notifyListeners();
      return;
    }

    if ((relativeCenterX - 0.5).abs() > 0.38 || (relativeCenterY - 0.5).abs() > 0.38) {
      _guidanceMessage = 'Center your face in the oval guide';
      notifyListeners();
      return;
    }

    // Face is well-positioned, evaluate current challenge
    final challenge = currentChallenge;
    if (challenge == null) return;

    _guidanceMessage = challenge.instruction;
    notifyListeners();

    _evaluateChallenge(face, challenge);
  }

  void advanceWebChallenge() {
    if (_state != LivenessState.verifying) return;
    _advanceChallenge();
  }

  void _evaluateChallenge(Face face, LivenessChallengeType challenge) {
    final now = DateTime.now();
    // Anti-spoofing: enforce minimum 250ms elapsed before completing challenge
    if (_challengeStartTime != null &&
        now.difference(_challengeStartTime!).inMilliseconds < 250) {
      return;
    }

    bool completed = false;

    switch (challenge) {
      case LivenessChallengeType.blink:
        final left = face.leftEyeOpenProbability ?? 1.0;
        final right = face.rightEyeOpenProbability ?? 1.0;
        final avgProb = (left + right) / 2;

        if (avgProb > 0.7) {
          _blinkEyeWasOpen = true;
        }
        if (_blinkEyeWasOpen && avgProb < 0.3) {
          _blinkEyeWasClosed = true;
        }
        if (_blinkEyeWasOpen && _blinkEyeWasClosed && avgProb > 0.7) {
          completed = true;
        }
        break;

      case LivenessChallengeType.turnLeft:
        final angleY = face.headEulerAngleY ?? 0.0;
        if (angleY > 18.0) {
          completed = true;
        }
        break;

      case LivenessChallengeType.turnRight:
        final angleY = face.headEulerAngleY ?? 0.0;
        if (angleY < -18.0) {
          completed = true;
        }
        break;

      case LivenessChallengeType.smile:
        final smileProb = face.smilingProbability ?? 0.0;
        if (smileProb > 0.65) {
          completed = true;
        }
        break;
    }

    if (completed) {
      _advanceChallenge();
    }
  }

  void _advanceChallenge() {
    _resetChallengeState();
    _currentChallengeIndex++;

    if (_currentChallengeIndex >= _activeChallenges.length) {
      _handleSuccess();
    } else {
      _startChallengeTimer();
      notifyListeners();
    }
  }

  void _handleSuccess() {
    _challengeTimer?.cancel();
    _state = LivenessState.success;
    _guidanceMessage = 'Verification successful!';
    notifyListeners();
  }

  void _handleFailure(String reason) {
    _challengeTimer?.cancel();
    _guidanceMessage = reason;

    if (_failedAttempts >= 3) {
      _state = LivenessState.lockedOut;
      _startLockoutTimer();
    } else {
      _state = LivenessState.failed;
    }
    notifyListeners();
  }

  void _startLockoutTimer() {
    _lockoutTimer?.cancel();
    _lockoutSecondsRemaining = 60;

    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_lockoutSecondsRemaining > 1) {
        _lockoutSecondsRemaining--;
        notifyListeners();
      } else {
        _lockoutTimer?.cancel();
        _failedAttempts = 0;
        _state = LivenessState.ready;
        _guidanceMessage = 'Lockout expired. You can try again.';
        notifyListeners();
      }
    });
  }

  void _resetChallengeState() {
    _blinkEyeWasOpen = false;
    _blinkEyeWasClosed = false;
    _challengeStartTime = DateTime.now();
  }

  void reset() {
    _challengeTimer?.cancel();
    _state = LivenessState.ready;
    _activeChallenges.clear();
    _currentChallengeIndex = 0;
    _guidanceMessage = 'Align your face inside the oval';
    notifyListeners();
  }

  @override
  void dispose() {
    _challengeTimer?.cancel();
    _lockoutTimer?.cancel();
    _faceDetector.close();
    super.dispose();
  }
}
