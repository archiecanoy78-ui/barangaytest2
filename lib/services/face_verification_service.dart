import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'liveness_service.dart';

abstract class FaceVerificationService {
  Future<void> initialize();
  Future<void> startLivenessCheck();
  Future<void> dispose();
}

class UniversalFaceVerificationService {
  static Future<void> logVerificationAttempt({
    required String uid,
    required bool isSuccess,
    required double confidence,
    Uint8List? capturedImageBytes,
  }) async {
    try {
      String? photoUrl;
      if (capturedImageBytes != null && capturedImageBytes.isNotEmpty) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('verification_photos')
            .child(uid)
            .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

        final metadata = SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {'uid': uid, 'verified': '$isSuccess'},
        );

        final uploadTask = await storageRef.putData(capturedImageBytes, metadata);
        photoUrl = await uploadTask.ref.getDownloadURL();
      }

      await FirebaseFirestore.instance.collection('verification_logs').add({
        'uid': uid,
        'timestamp': FieldValue.serverTimestamp(),
        'result': isSuccess ? 'MATCH_SUCCESS' : 'MATCH_FAILED',
        'confidence': confidence,
        'photoUrl': photoUrl,
        'platform': kIsWeb ? 'web' : 'mobile',
      });
    } catch (e) {
      debugPrint('Error logging verification attempt: $e');
    }
  }
}
