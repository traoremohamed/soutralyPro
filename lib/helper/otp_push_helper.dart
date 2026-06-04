import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OtpPushHelper {
  static const String _pendingOtpKey = 'pending_otp_from_push';
  static final StreamController<String> _otpStreamController =
      StreamController<String>.broadcast();

  static Stream<String> get otpStream => _otpStreamController.stream;

  static bool isOtpMessage(Map<String, dynamic> data) {
    return (data['type']?.toString() ?? '') == 'OTP_VERIFICATION';
  }

  static Future<void> captureRemoteMessage(RemoteMessage message) async {
    await captureData(message.data);
  }

  static Future<void> captureData(Map<String, dynamic> data) async {
    if (!isOtpMessage(data)) {
      return;
    }

    final String otpCode = (data['code']?.toString() ?? '').trim();
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
