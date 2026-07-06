import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
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
    debugPrint('[OTP_TRACE][push] captureRemoteMessage data=${message.data}');
    await captureData(message.data);
  }

  static Future<void> captureData(Map<String, dynamic> data) async {
    debugPrint('[OTP_TRACE][push] captureData start action=${data['action']} type=${data['type']} status=${data['status']}');
    final String rawText =
        '${data['body']?.toString() ?? ''} ${data['message']?.toString() ?? ''} ${data['title']?.toString() ?? ''}';
    final bool hasOtpKeyword = rawText.toLowerCase().contains('otp');
    debugPrint('[OTP_TRACE][push] raw_has_otp_keyword=$hasOtpKeyword raw="$rawText"');

    if (!isOtpMessage(data) && !hasOtpKeyword) {
      debugPrint('[OTP_TRACE][push] ignored: not an otp message');
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

    debugPrint('[OTP_TRACE][push] extracted_code="$otpCode" length=${otpCode.length}');

    if (otpCode.length != 6) {
      debugPrint('[OTP_TRACE][push] ignored: invalid otp length');
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
