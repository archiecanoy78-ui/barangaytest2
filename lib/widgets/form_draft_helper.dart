import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'form_draft_stub.dart'
    if (dart.library.js_interop) 'form_draft_web.dart';

class FormDraftHelper {
  final String formKey;
  final String uid;
  Timer? _debounceTimer;
  bool _hasUnsavedChanges = false;

  FormDraftHelper({
    required this.formKey,
    required this.uid,
  }) {
    if (kIsWeb) {
      setupBeforeUnload(() => _hasUnsavedChanges);
    }
  }

  String get _storageKey => 'draft_${formKey}_$uid';

  void onFieldChanged(Map<String, dynamic> formData) {
    _hasUnsavedChanges = true;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      saveDraft(formData);
    });
  }

  Future<void> saveDraft(Map<String, dynamic> formData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cleanData = <String, dynamic>{};
      formData.forEach((key, value) {
        if (!key.toLowerCase().contains('password') &&
            !key.toLowerCase().contains('image') &&
            !key.toLowerCase().contains('file') &&
            value is! List<int>) {
          cleanData[key] = value;
        }
      });

      await prefs.setString(_storageKey, jsonEncode(cleanData));
    } catch (e) {
      debugPrint('Error saving draft: $e');
    }
  }

  Future<Map<String, dynamic>?> loadDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        return jsonDecode(raw) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Error loading draft: $e');
    }
    return null;
  }

  Future<void> clearDraft() async {
    _hasUnsavedChanges = false;
    _debounceTimer?.cancel();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (e) {
      debugPrint('Error clearing draft: $e');
    }
  }

  static Future<bool> showDiscardConfirmationDialog(
      BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard changes?',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: const Text(
          'Your entered information will be lost. Are you sure you want to discard these changes?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep editing'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void dispose() {
    _debounceTimer?.cancel();
    if (kIsWeb) {
      removeBeforeUnload();
    }
  }
}
