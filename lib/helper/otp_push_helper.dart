import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OtpPushHelper {
  static const String _pendingOtpKey = 'pending_otp_from_push';
  static final StreamController<String> _otpStreamController =
      StreamController<String>.broadcast();
  static final RegExp _sixDigitsRegExp = RegExp(r'\b\d{6}\b');

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
    await captureData(message.data);
  }

  static Future<void> captureData(Map<String, dynamic> data) async {
    final String rawText =
        '${data['body']?.toString() ?? ''} ${data['message']?.toString() ?? ''} ${data['title']?.toString() ?? ''}';
    final bool hasOtpKeyword = rawText.toLowerCase().contains('otp');

    if (!isOtpMessage(data) && !hasOtpKeyword) {
      return;
    }

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

    if (otpCode.length != 6) {
      return;
    }

    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setString(_pendingOtpKey, otpCode);
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
