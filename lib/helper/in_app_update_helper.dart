import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';

class InAppUpdateHelper {
  InAppUpdateHelper._();

  static bool _isChecking = false;

  static Future<void> checkAndForceImmediateUpdate() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }
    if (_isChecking) {
      return;
    }

    _isChecking = true;
    try {
      final AppUpdateInfo updateInfo = await InAppUpdate.checkForUpdate();

      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        await InAppUpdate.performImmediateUpdate();
      }
    } catch (e) {
      debugPrint('In-app update check failed: $e');
    } finally {
      _isChecking = false;
    }
  }
}
