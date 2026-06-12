import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/features/auth/controllers/auth_controller.dart';
import 'package:ride_sharing_user_app/features/dashboard/controllers/bottom_menu_controller.dart';
import 'package:ride_sharing_user_app/features/dashboard/screens/dashboard_screen.dart';
import 'package:ride_sharing_user_app/features/profile/controllers/profile_controller.dart';
import 'package:ride_sharing_user_app/features/wallet/controllers/wallet_controller.dart';

class DeepLinkService {
  DeepLinkService._();
  static final DeepLinkService instance = DeepLinkService._();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  bool _initialized = false;
  String? _pendingPaymentState;
  Timer? _retryTimer;
  Timer? _hardLockTimer;
  int _retryCount = 0;
  int _hardLockCount = 0;
  static const int _maxRetries = 15;
  static const int _maxHardLockPasses = 12;

  Future<void> initDeepLinks() async {
    if (_initialized) {
      return;
    }
    _initialized = true;

    try {
      final Uri? initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleUri(initialUri);
      }
    } catch (e) {
      debugPrint('DeepLink initial error: $e');
    }

    _linkSubscription = _appLinks.uriLinkStream.listen(
      _handleUri,
      onError: (Object err) {
        debugPrint('DeepLink stream error: $err');
      },
    );
  }

  void _handleUri(Uri uri) {
    if (uri.scheme.toLowerCase() != 'soutralyvtc') {
      return;
    }

    final String host = uri.host.toLowerCase();
    if (host == 'payment-success') {
      _pendingPaymentState = 'success';
      _retryCount = 0;
      _startHardLock(showError: false);
      _attemptPendingRedirect();
      return;
    }

    if (host == 'payment-error') {
      _pendingPaymentState = 'error';
      _retryCount = 0;
      _startHardLock(showError: true);
      _attemptPendingRedirect();
      return;
    }

    debugPrint('DeepLink host inconnu: $host');
  }

  Future<void> _goToWallet({bool showError = false}) async {
    await Get.offAll(() => const DashboardScreen());

    if (Get.isRegistered<BottomMenuController>()) {
      Get.find<BottomMenuController>().setTabIndex(3);
    }

    if (Get.isRegistered<WalletController>()) {
      final WalletController wallet = Get.find<WalletController>();
      wallet.setWalletTypeIndex(0, isUpdate: true);
      wallet.setSelectedHistoryIndex(3, true);
      wallet.getCashCollectHistoryList(1);
      wallet.getWalletHistoryList(1);
    }

    if (Get.isRegistered<ProfileController>()) {
      await Get.find<ProfileController>().getProfileInfo();
    }

    if (showError) {
      Get.snackbar('Paiement', 'Le paiement a échoué ou a été annulé.');
    } else {
      Get.snackbar('Paiement', 'Rechargement en cours de confirmation...');
    }
  }

  void _startHardLock({required bool showError}) {
    _hardLockTimer?.cancel();
    _hardLockTimer = null;
    _hardLockCount = 0;
    _runHardLock(showError: showError, showMessage: true);
  }

  Future<void> _runHardLock(
      {required bool showError, required bool showMessage}) async {
    if (!Get.isRegistered<AuthController>()) {
      _scheduleHardLock(showError: showError);
      return;
    }

    final AuthController authController = Get.find<AuthController>();
    final bool hasSession =
        authController.isLoggedIn() || authController.getUserToken().isNotEmpty;

    if (!hasSession) {
      if (Get.currentRoute != '/sign-in') {
        Get.offAllNamed('/sign-in');
      }
      return;
    }

    await Get.offAll(() => const DashboardScreen());

    if (Get.isRegistered<BottomMenuController>()) {
      Get.find<BottomMenuController>().setTabIndex(3);
    }

    if (Get.isRegistered<WalletController>()) {
      final WalletController wallet = Get.find<WalletController>();
      wallet.setWalletTypeIndex(0, isUpdate: true);
      wallet.setSelectedHistoryIndex(3, true);
      wallet.getCashCollectHistoryList(1);
      wallet.getWalletHistoryList(1);
    }

    if (Get.isRegistered<ProfileController>()) {
      await Get.find<ProfileController>().getProfileInfo();
    }

    if (showMessage) {
      if (showError) {
        Get.snackbar('Paiement', 'Le paiement a échoué ou a été annulé.');
      } else {
        Get.snackbar('Paiement', 'Rechargement en cours de confirmation...');
      }
    }

    _scheduleHardLock(showError: showError);
  }

  void _scheduleHardLock({required bool showError}) {
    if (_hardLockCount >= _maxHardLockPasses) {
      _hardLockTimer?.cancel();
      _hardLockTimer = null;
      return;
    }

    _hardLockCount++;
    _hardLockTimer?.cancel();
    _hardLockTimer = Timer(const Duration(milliseconds: 450), () {
      _runHardLock(showError: showError, showMessage: false);
    });
  }

  Future<void> _attemptPendingRedirect() async {
    final String? state = _pendingPaymentState;
    if (state == null) {
      return;
    }

    if (!Get.isRegistered<AuthController>()) {
      _scheduleRetry();
      return;
    }

    final AuthController authController = Get.find<AuthController>();
    final bool loggedIn =
        authController.isLoggedIn() || authController.getUserToken().isNotEmpty;

    if (!loggedIn) {
      if (authController.getUserToken().isNotEmpty) {
        _scheduleRetry();
        return;
      }

      if (Get.currentRoute != '/sign-in') {
        Get.offAllNamed('/sign-in');
      }
      return;
    }

    if (Get.currentRoute == '/splash') {
      _scheduleRetry();
      return;
    }

    _retryTimer?.cancel();
    _retryTimer = null;
    _retryCount = 0;
    _pendingPaymentState = null;

    await _goToWallet(showError: state == 'error');
  }

  Future<void> processPendingRedirect() async {
    await _attemptPendingRedirect();
  }

  void _scheduleRetry() {
    if (_retryCount >= _maxRetries) {
      return;
    }

    _retryCount++;
    _retryTimer?.cancel();
    _retryTimer = Timer(const Duration(milliseconds: 700), () {
      _attemptPendingRedirect();
    });
  }

  void dispose() {
    _hardLockTimer?.cancel();
    _hardLockTimer = null;
    _retryTimer?.cancel();
    _retryTimer = null;
    _linkSubscription?.cancel();
    _linkSubscription = null;
    _initialized = false;
    _pendingPaymentState = null;
    _retryCount = 0;
    _hardLockCount = 0;
  }
}
