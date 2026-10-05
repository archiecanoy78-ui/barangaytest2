import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  StreamSubscription<String>? _tokenRefreshSubscription;
  String? _activeUid;

  Future<void> initialize(BuildContext context, String uid) async {
    if (_activeUid == uid) return;
    _activeUid = uid;

    try {
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        final token = await _fcm.getToken();
        if (token != null) {
          await _saveTokenToUserDoc(uid, token);
        }

        _tokenRefreshSubscription?.cancel();
        _tokenRefreshSubscription = _fcm.onTokenRefresh.listen((newToken) {
          _saveTokenToUserDoc(uid, newToken);
        });

        // Subscribe to residents topic for broadcasts
        await _fcm.subscribeToTopic('residents');
      }

      // Handle Foreground Messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (context.mounted && message.notification != null) {
          final title = message.notification?.title ?? 'New Notification';
          final body = message.notification?.body ?? '';

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                        ),
                        if (body.isNotEmpty)
                          Text(
                            body,
                            style: const TextStyle(fontSize: 11.5, color: Colors.white70),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF2563EB),
              duration: const Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      });
    } catch (e) {
      debugPrint('FCM NotificationService init notice: $e');
    }
  }

  Future<void> _saveTokenToUserDoc(String uid, String token) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  Future<void> removeTokenAndUnsubscribe(String uid) async {
    try {
      await _fcm.unsubscribeFromTopic('residents');
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'fcmToken': FieldValue.delete(),
      });
      _tokenRefreshSubscription?.cancel();
      _activeUid = null;
    } catch (_) {}
  }
}
