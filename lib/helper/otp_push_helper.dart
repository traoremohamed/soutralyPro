import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OtpPushHelper {
  static const String _pendingOtpKey = 'pending_otp_from_push';
  static final StreamController<String> _otpStreamController =
      StreamController<String>.broadcast();
  static final RegExp _sixDigitsRegExp = RegExp(r'\b\d{6}\b');
  static final List<String> _otpKeywords = <String>[
    'otp',
    'code',
    'verification',
    'verification code',
    'verif',
    'verif code',
    'vérification',
    'code de verification',
    'code de vérification',
  ];

  static Stream<String> get otpStream => _otpStreamController.stream;

  static bool isOtpMessage(Map<String, dynamic> data) {
    final String type = (data['type']?.toString() ?? '').trim().toUpperCase();
    final String action =
        (data['action']?.toString() ?? '').trim().toUpperCase();

    return type == 'OTP_VERIFICATION' ||
        type == 'OTP' ||
        action == 'OTP_VERIFICATION' ||
        action == 'OTP';
  }

  static Future<void> captureRemoteMessage(RemoteMessage message) async {
    final Map<String, dynamic> merged = Map<String, dynamic>.from(message.data);

    if ((merged['title']?.toString().trim().isEmpty ?? true) &&
        (message.notification?.title?.trim().isNotEmpty ?? false)) {
      merged['title'] = message.notification?.title;
    }
    if ((merged['body']?.toString().trim().isEmpty ?? true) &&
        (message.notification?.body?.trim().isNotEmpty ?? false)) {
      merged['body'] = message.notification?.body;
    }

    debugPrint('[OTP_TRACE][push] captureRemoteMessage data=${message.data} notifTitle=${message.notification?.title} notifBody=${message.notification?.body}');
    await captureData(merged);
  }

  static Future<void> captureData(Map<String, dynamic> data) async {
    debugPrint('[OTP_TRACE][push] captureData start action=${data['action']} type=${data['type']} status=${data['status']}');
    final String rawText =
        '${data['body']?.toString() ?? ''} ${data['message']?.toString() ?? ''} ${data['title']?.toString() ?? ''}';
    final String loweredRaw = rawText.toLowerCase();
    final bool hasOtpKeyword =
        _otpKeywords.any((keyword) => loweredRaw.contains(keyword));
    debugPrint('[OTP_TRACE][push] raw_has_otp_keyword=$hasOtpKeyword raw="$rawText"');

    String otpCode = (data['code']?.toString() ?? '').trim();
    if (otpCode.isEmpty) {
      otpCode = (data['otp']?.toString() ?? '').trim();
    }
    if (otpCode.isEmpty) {
      otpCode = (data['otp_code']?.toString() ?? '').trim();
    }
    if (otpCode.isEmpty) {
      otpCode = (data['otpCode']?.toString() ?? '').trim();
    }

    if (otpCode.isEmpty) {
      final Match? match = _sixDigitsRegExp.firstMatch(rawText);
      otpCode = match?.group(0) ?? '';
    }

    debugPrint('[OTP_TRACE][push] extracted_code="$otpCode" length=${otpCode.length}');

    final bool looksLikeOtpMessage = isOtpMessage(data) || hasOtpKeyword;

    if (otpCode.length != 6 || !looksLikeOtpMessage) {
      debugPrint('[OTP_TRACE][push] ignored: invalid otp candidate (length=${otpCode.length}, looksLikeOtpMessage=$looksLikeOtpMessage)');
      return;
    }

    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setString(_pendingOtpKey, otpCode);
    debugPrint('[OTP_TRACE][push] stored pending otp and emitted stream');
    _otpStreamController.add(otpCode);
  }

  static Future<String?> getPendingOtp() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    return preferences.getString(_pendingOtpKey);
  }

  static Future<void> clearPendingOtp() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.remove(_pendingOtpKey);
  }
}
