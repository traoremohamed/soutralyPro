import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ride_sharing_user_app/common_widgets/expandable_bottom_sheet.dart';
import 'package:ride_sharing_user_app/data/api_checker.dart';
import 'package:ride_sharing_user_app/features/location/controllers/location_controller.dart';
import 'package:ride_sharing_user_app/features/map/controllers/otp_time_count_controller.dart';
import 'package:ride_sharing_user_app/features/ride/domain/services/ride_service_interface.dart';
import 'package:ride_sharing_user_app/features/safety_setup/controllers/safety_alert_controller.dart';
import 'package:ride_sharing_user_app/features/splash/controllers/splash_controller.dart';
import 'package:ride_sharing_user_app/features/trip/controllers/trip_controller.dart';
import 'package:ride_sharing_user_app/helper/display_helper.dart';
import 'package:ride_sharing_user_app/helper/dynamic_translation_helper.dart';
import 'package:ride_sharing_user_app/helper/pusher_helper.dart';
import 'package:ride_sharing_user_app/features/map/controllers/map_controller.dart';
import 'package:ride_sharing_user_app/features/profile/controllers/profile_controller.dart';
import 'package:ride_sharing_user_app/features/ride/domain/models/final_fare_model.dart';
import 'package:ride_sharing_user_app/features/ride/domain/models/on_going_trip_model.dart';
import 'package:ride_sharing_user_app/features/ride/domain/models/parcel_list_model.dart';
import 'package:ride_sharing_user_app/features/ride/domain/models/pending_ride_request_model.dart';
import 'package:ride_sharing_user_app/features/ride/domain/models/remaining_distance_model.dart';
import 'package:ride_sharing_user_app/features/ride/domain/models/trip_details_model.dart';
import 'package:ride_sharing_user_app/features/trip/screens/payment_received_screen.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class RideController extends GetxController implements GetxService {
  final RideServiceInterface rideServiceInterface;
  RideController({required this.rideServiceInterface});
  final FlutterTts _flutterTts = FlutterTts();
  DateTime? _lastTripCanceledAlertAt;

  void _traceDispatch(String message) {
    customPrint('[TRACE_DRIVER][RIDE] $message');
  }

  /// Safe update that avoids setState() during build phase.
  /// If called during build, defers the update to next frame.
  void _safeUpdate() {
    try {
      if (SchedulerBinding.instance.schedulerPhase ==
          SchedulerPhase.persistentCallbacks) {
        // Called during build - defer to next frame
        SchedulerBinding.instance.addPostFrameCallback((_) {
          try {
            update();
          } catch (e) {
            customPrint(
              '[TRACE_DRIVER][RIDE] _safeUpdate deferred update error: $e',
            );
          }
        });
      } else {
        // Safe to update immediately
        update();
      }
    } catch (e) {
      customPrint('[TRACE_DRIVER][RIDE] _safeUpdate error: $e');
    }
  }

  int _orderStatusSelectedIndex = 0;
  int get orderStatusSelectedIndex => _orderStatusSelectedIndex;
  bool isLoading = false;
  bool isPinVerificationLoading = false;
  bool _hasArrivedAtPickup = false;
  bool get hasArrivedAtPickup => _hasArrivedAtPickup;
  DateTime? arrivedAt;
  double gracePeriodMinutes = 0;
  double waitingFeePerMin = 0;
  String? _pickupWaitingTripId;
  Timer? _pendingRideDecisionTimer;
  String? _pendingRideDecisionTripId;
  int _pendingRideDecisionRemainingSeconds = 60;
  bool get pendingDecisionTimerActive => _pendingRideDecisionTimer != null;
  int get pendingRideDecisionRemainingSeconds =>
      _pendingRideDecisionRemainingSeconds;
  String? get pendingRideDecisionTripId => _pendingRideDecisionTripId;

  void resetPickupWaitingState({bool notify = false}) {
    _hasArrivedAtPickup = false;
    arrivedAt = null;
    gracePeriodMinutes = 0;
    waitingFeePerMin = 0;
    _pickupWaitingTripId = null;

    if (notify) {
      update();
    }
  }

  void cancelPendingRideDecisionTimer({int resetToSeconds = 0}) {
    final int sanitized = resetToSeconds.clamp(0, 300);
    _traceDispatch(
      'cancelPendingRideDecisionTimer tripId=$_pendingRideDecisionTripId resetTo=$sanitized',
    );
    _pendingRideDecisionTimer?.cancel();
    _pendingRideDecisionTimer = null;
    _pendingRideDecisionRemainingSeconds = sanitized;
    _pendingRideDecisionTripId = null;
    _safeUpdate();
  }

  int _resolvePendingDecisionInitialSeconds({
    required String tripId,
    int? initialRemainingSeconds,
  }) {
    final int fallback = 60;
    if (initialRemainingSeconds == null) {
      return fallback;
    }

    final int sanitized = initialRemainingSeconds.clamp(1, 300);
    _traceDispatch(
      'pending decision initial seconds tripId=$tripId fromServer=$sanitized',
    );
    return sanitized;
  }

  int? _computeServerRemainingSeconds(TripDetail? trip) {
    final String? raw = trip?.dispatchOfferExpiresAt;
    if (raw == null || raw.isEmpty) {
      return null;
    }

    final DateTime? expiresAt = DateTime.tryParse(raw)?.toLocal();
    if (expiresAt == null) {
      return null;
    }

    final int seconds = expiresAt.difference(DateTime.now()).inSeconds;
    return seconds > 0 ? seconds : 1;
  }

  void startPendingRideDecisionTimer(
    String tripId, {
    int? initialRemainingSeconds,
  }) {
    if (tripId.isEmpty) {
      _traceDispatch('startPendingRideDecisionTimer ignored empty tripId');
      return;
    }

    _traceDispatch(
      'startPendingRideDecisionTimer tripId=$tripId currentRoute=${Get.currentRoute}',
    );

    if (_pendingRideDecisionTripId == tripId &&
        _pendingRideDecisionTimer != null) {
      _traceDispatch(
        'startPendingRideDecisionTimer skipped already active tripId=$tripId',
      );
      return;
    }

    cancelPendingRideDecisionTimer(resetToSeconds: 0);
    _pendingRideDecisionTripId = tripId;
    _pendingRideDecisionRemainingSeconds =
        _resolvePendingDecisionInitialSeconds(
          tripId: tripId,
          initialRemainingSeconds: initialRemainingSeconds,
        );
    _traceDispatch('startPendingRideDecisionTimer started tripId=$tripId');
    _pendingRideDecisionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_pendingRideDecisionTripId != tripId) {
        return;
      }

      if (_pendingRideDecisionRemainingSeconds <= 1) {
        _traceDispatch('pending ride decision timer expired tripId=$tripId');
        _pendingRideDecisionTimer?.cancel();
        _pendingRideDecisionTimer = null;
        _pendingRideDecisionRemainingSeconds = 0;
        update();
        _handlePendingRideDecisionTimeout(tripId);
      } else {
        _pendingRideDecisionRemainingSeconds--;
        _traceDispatch(
          'pending ride decision countdown tripId=$tripId remaining=$_pendingRideDecisionRemainingSeconds',
        );
        update();
      }
    });
    _safeUpdate();
  }

  Future<void> _handlePendingRideDecisionTimeout(String tripId) async {
    if (_pendingRideDecisionTripId != tripId) {
      return;
    }

    _pendingRideDecisionTripId = null;
    update();

    TripDetail? pendingTrip;
    for (final trip in (pendingRideRequestModel?.data ?? <TripDetail>[])) {
      if (trip.id == tripId) {
        pendingTrip = trip;
        break;
      }
    }

    customPrint(
      '[TRACE_DRIVER][RIDE] pending ride decision timed out tripId=$tripId',
    );
    showCustomSnackBar(
      'La course a expiré et a été réaffectée à un autre chauffeur.',
      isError: false,
      seconds: 4,
    );

    await tripAcceptOrRejected(
      tripId,
      'rejected',
      pendingTrip?.type ?? tripDetail?.type ?? '',
      pendingTrip?.parcelInformation?.weight?.toString() ?? '0',
      showSuccess: false,
      autoTimeout: true,
    );
  }

  void _bindWaitingStateToTrip(String? tripId) {
    if (tripId == null || tripId.isEmpty) {
      return;
    }

    if (_pickupWaitingTripId != tripId) {
      resetPickupWaitingState();
      _pickupWaitingTripId = tripId;
    }
  }

  DateTime? pauseStartedAt;
  Timer? pauseTimer;
  String displayPauseElapsedTime = '00:00:00';

  double getDisplayFareFromTripDetail(TripDetail? trip) {
    if (trip == null) {
      return 0;
    }

    final discountedFare = trip.discountActualFare ?? 0;
    if (discountedFare > 0) {
      return discountedFare;
    }

    final estimatedFare =
        double.tryParse((trip.estimatedFare ?? '0').toString()) ?? 0;
    final couponAmount = trip.couponAmount ?? 0;
    final discountAmount = trip.discountAmount ?? 0;
    final calculatedDiscounted = estimatedFare - couponAmount - discountAmount;

    if ((couponAmount > 0 || discountAmount > 0) && calculatedDiscounted > 0) {
      return calculatedDiscounted;
    }

    return estimatedFare;
  }

  String? _rideId;
  String? get rideId => _rideId;
  TripDetail? tripDetail;
  List<String>? _thumbnailPaths;
  List<String>? get thumbnailPaths => _thumbnailPaths;
  double totalParcelWeight = 0;
  int totalParcelCount = 0;
  JustTheController justTheController = JustTheController();

  void setRideId(String id) {
    _rideId = id;
  }

  Future<void> playIncomingRideAlert({TripDetail? incomingTrip}) async {
    AudioPlayer audio = AudioPlayer();
    await audio.play(AssetSource('notification.wav'));

    final String categoryLabel = (incomingTrip?.vehicleCategory?.name ?? '')
        .trim();
    final int orderPriority = incomingTrip?.vehicleCategory?.orderPriority ?? 1;

    if (categoryLabel.isNotEmpty) {
      await _flutterTts.setLanguage('fr-FR');
      await _flutterTts.setSpeechRate(0.46);
      await _flutterTts.setPitch(1.0);
      final String speech;
      if (orderPriority == 3) {
        speech =
            'Vous avez une commande $categoryLabel. Veuillez mettre la climatisation en marche avant d\'arriver chez le client.';
      } else if (orderPriority == 2) {
        speech =
            'Vous avez une commande $categoryLabel. Veuillez mettre la climatisation en marche.';
      } else {
        speech = 'Vous avez une commande $categoryLabel.';
      }
      await _flutterTts.speak(speech);
    }
  }

  Future<void> playTripCanceledAlert() async {
    final now = DateTime.now();
    if (_lastTripCanceledAlertAt != null &&
        now.difference(_lastTripCanceledAlertAt!) <
            const Duration(seconds: 4)) {
      return;
    }
    _lastTripCanceledAlertAt = now;

    try {
      final AudioPlayer audio = AudioPlayer();
      await audio.play(AssetSource('notification.wav'));
    } catch (_) {}

    try {
      await _flutterTts.stop();
      await _flutterTts.setLanguage('fr-FR');
      await _flutterTts.setSpeechRate(0.46);
      await _flutterTts.setPitch(1.0);
      await _flutterTts.speak(
        'Attention, la course a ete annulee par le client.',
      );
    } catch (_) {}
  }

  bool get isForfaitCurrentlyActive {
    final profileController = Get.find<ProfileController>();
    final String mode = (profileController.driverPricingMode).toLowerCase();
    if (mode != 'forfait') {
      return false;
    }
    final expiry = DateTime.tryParse(profileController.forfaitExpiresAt ?? '');
    if (expiry == null) {
      return false;
    }
    return expiry.toLocal().isAfter(DateTime.now());
  }

  bool canAcceptTripWithWalletGuard(
    TripDetail? requestTrip, {
    bool showDialog = true,
  }) {
    final profileController = Get.find<ProfileController>();
    if (isForfaitCurrentlyActive) {
      return true;
    }

    final double walletBalance =
        profileController.profileInfo?.wallet?.walletBalance ?? 0;
    final double requiredCommission = requestTrip?.adminCommission ?? 0;

    if (walletBalance <= 0) {
      if (showDialog) {
        profileController.checkZeroWalletPopup(forceShow: true);
      }
      return false;
    }

    if (requiredCommission <= 0) {
      return true;
    }

    if (walletBalance >= requiredCommission) {
      return true;
    }

    if (showDialog) {
      profileController.checkZeroWalletPopup(forceShow: true);
    }

    return false;
  }

  void setOrderStatusTypeIndex(int index) {
    _orderStatusSelectedIndex = index;
    update();
  }

  Future<Response> bidding(String tripId, String amount) async {
    isLoading = true;
    update();
    Response response = await rideServiceInterface.bidding(tripId, amount);
    if (response.statusCode == 200) {
      Get.back();
      isLoading = false;
      showCustomSnackBar('bid_submitted_successfully'.tr, isError: false);
      getPendingRideRequestList(1);
    } else {
      isLoading = false;
      ApiChecker.checkApi(response);
    }
    update();
    return response;
  }

  bool notSplashRoute = false;
  void updateRoute(bool showHideIcon, {bool notify = false}) {
    notSplashRoute = showHideIcon;
    if (notify) {
      update();
    }
  }

  Future<Response> getRideDetails(
    String tripId, {
    bool fromHomeScreen = false,
  }) async {
    final ProfileController profileController = Get.find<ProfileController>();
    if (profileController.isWalletBlockedForTripActions) {
      profileController.checkZeroWalletPopup(forceShow: true);
      return Response(statusCode: 403, statusText: 'wallet_blocked');
    }

    isLoading = true;
    _thumbnailPaths = null;
    if (kDebugMode) {
      print('details api call-====> $tripId');
    }
    Response response = await rideServiceInterface.getRideDetails(tripId);
    if (response.statusCode == 200) {
      tripDetail = TripDetailsModel.fromJson(response.body).data!;
      polyline = tripDetail!.encodedPolyline!;
      isLoading = false;

      _bindWaitingStateToTrip(tripDetail?.id);

      // Gérer le timer de pause
      if (tripDetail?.isPaused == true) {
        startPauseTimer();
      } else {
        stopPauseTimer();
      }

      if (tripDetail?.currentStatus == 'out_for_pickup') {
        final waitingTime =
            double.tryParse((tripDetail?.waitingTime ?? '0').toString()) ?? 0;
        final delayFee = tripDetail?.delayFee ?? 0;
        final bool hasServerWaitingState = waitingTime > 0 || delayFee > 0;
        final bool hasLocalArrivalForCurrentTrip =
            _pickupWaitingTripId == tripDetail?.id &&
            (_hasArrivedAtPickup || arrivedAt != null);

        // Preserve local arrival state for the same trip. The backend can
        // still return waiting=0 immediately after marking arrival.
        _hasArrivedAtPickup =
            hasServerWaitingState || hasLocalArrivalForCurrentTrip;
      } else {
        resetPickupWaitingState();
      }

      List<Attachments> attachments =
          tripDetail?.parcelRefund?.attachments ?? [];
      _thumbnailPaths = List.filled(attachments.length, '');

      Future.forEach(attachments, (element) async {
        if (element.file?.contains('.mp4') ?? false) {
          String? path = await generateThumbnail(element.file!);
          _thumbnailPaths?[tripDetail!.parcelRefund!.attachments!.indexOf(
                element,
              )] =
              path ?? '';

          update();
        }
      });
    } else if (response.statusCode == 403) {
      isLoading = false;
    } else {
      isLoading = false;
      fromHomeScreen ? null : ApiChecker.checkApi(response);
    }
    update();
    return response;
  }

  Future<Response> uploadScreenShots(String tripId, XFile file) async {
    Response response = await rideServiceInterface.uploadScreenShots(
      tripId,
      file,
    );
    if (response.statusCode == 200) {}
    update();
    return response;
  }

  String polyline = '';

  Future<Response> getRideDetailBeforeAccept(String tripId) async {
    final ProfileController profileController = Get.find<ProfileController>();
    if (profileController.isWalletBlockedForTripActions) {
      profileController.checkZeroWalletPopup(forceShow: true);
      return Response(statusCode: 403, statusText: 'wallet_blocked');
    }

    isLoading = true;
    update();
    await Get.find<LocationController>().getCurrentLocation(callZone: false);
    Response response = await rideServiceInterface.getRideDetailBeforeAccept(
      tripId,
    );
    if (response.statusCode == 200) {
      tripDetail = TripDetailsModel.fromJson(response.body).data!;
      final int? serverRemaining = _computeServerRemainingSeconds(tripDetail);
      _traceDispatch(
        'getRideDetailBeforeAccept success tripId=$tripId currentStatus=${tripDetail?.currentStatus} offeredDriver=${tripDetail?.currentOfferedDriverId} expiresAt=${tripDetail?.dispatchOfferExpiresAt} remainingFromServer=$serverRemaining',
      );
      startPendingRideDecisionTimer(
        tripId,
        initialRemainingSeconds: serverRemaining,
      );
      isLoading = false;
      polyline = tripDetail?.encodedPolyline ?? '';
      Get.find<RideController>().remainingDistance(tripId, mapBound: true);
      if (kDebugMode) {
        print('polyline is ====> $polyline');
      }
    } else {
      if (_pendingRideDecisionTripId == tripId) {
        // Do not keep a stale countdown when the backend no longer serves this offer.
        cancelPendingRideDecisionTimer(resetToSeconds: 0);
      }
      _traceDispatch(
        'getRideDetailBeforeAccept failed tripId=$tripId status=${response.statusCode} body=${response.body}',
      );
      isLoading = false;

      final dynamic responseCode = response.body is Map<String, dynamic>
          ? response.body['response_code']
          : null;
      if (response.statusCode == 403 && responseCode == 'trip_request_403') {
        // This can happen when an offer expires/reassigned between push reception and detail fetch.
        _traceDispatch(
          'getRideDetailBeforeAccept suppressed user popup for transient trip_request_403 tripId=$tripId',
        );
      } else {
        ApiChecker.checkApi(response);
      }
    }

    update();
    return response;
  }

  List<TripDetail>? ongoingTrip, lastRideDetails;
  List<TripDetail>? get ongoingRideList => ongoingTrip;

  Future<Response> ongoingTripList() async {
    Response response = await rideServiceInterface.ongoingTripList();
    if (response.statusCode == 200) {
      ongoingTrip = [];
      if (response.body['data'] != null) {
        ongoingTrip!.addAll(OngoingTripModel.fromJson(response.body).data!);
      }
      if ((ongoingTrip ?? []).isEmpty) {
        resetPickupWaitingState();
      } else {
        // Driver has an ongoing trip: clear any pending-offer countdown.
        cancelPendingRideDecisionTimer(resetToSeconds: 0);
      }
    } else {
      ApiChecker.checkApi(response);
    }
    update();
    return response;
  }

  Future<void> getLastRideDetail() async {
    Response response = await rideServiceInterface.lastRideDetail();
    if (response.statusCode == 200) {
      lastRideDetails = [];
      if (response.body['data'] != null) {
        lastRideDetails!.addAll(OngoingTripModel.fromJson(response.body).data!);
      }
    } else {
      ApiChecker.checkApi(response);
    }
    update();
  }

  bool accepting = false;
  String? onPressedTripId;
  Future<Response> tripAcceptOrRejected(
    String tripId,
    String action,
    String type,
    String parcelWeight, {
    bool showSuccess = true,
    bool autoTimeout = false,
  }) async {
    // Any explicit driver decision should clear the pending timer state.
    cancelPendingRideDecisionTimer(resetToSeconds: 0);

    if (action == 'accepted') {
      TripDetail? pendingTrip;
      for (final trip in (pendingRideRequestModel?.data ?? <TripDetail>[])) {
        if (trip.id == tripId) {
          pendingTrip = trip;
          break;
        }
      }
      if (!canAcceptTripWithWalletGuard(pendingTrip)) {
        return Response(
          statusCode: 403,
          body: {
            'response_code': 'insufficient_wallet_balance_403',
            'message': 'insufficient_wallet_balance_for_trip'.tr,
          },
        );
      }
    }

    onPressedTripId = tripId;

    accepting = true;
    update();
    Response response = await rideServiceInterface.tripAcceptOrReject(
      tripId,
      action,
    );
    if (response.statusCode == 200) {
      accepting = false;
      Get.find<RiderMapController>().getPickupToDestinationPolyline();
      if (action == 'rejected') {
        await rideServiceInterface.ignoreMessage(tripId);
        showCustomSnackBar(
          autoTimeout
              ? 'La course a expiré et a été réaffectée à un autre chauffeur.'
              : 'trip_is_rejected'.tr,
          isError: false,
        );
      } else {
        if (type == 'parcel') {
          totalParcelCount++;
          totalParcelWeight += double.parse(parcelWeight);
        }

        if (showSuccess) {
          showCustomSnackBar('trip_is_accepted'.tr, isError: false);
        }

        Future.delayed(const Duration(seconds: 15)).then((_) {
          if ((Get.find<SplashController>()
                      .config
                      ?.maximumParcelRequestAcceptLimitStatus ??
                  false) &&
              type == 'parcel') {
            if (totalParcelCount ==
                Get.find<SplashController>()
                    .config
                    ?.maximumParcelRequestAcceptLimit) {
              showCustomSnackBar(
                isError: true,
                'booking_acceptance_limit_reached'.tr,
                subMessage: 'kindly_complete_the_delivery_of_the_ongoing'.tr,
                seconds: 5,
              );
            }
          }

          if (type == 'parcel' &&
              (totalParcelWeight >
                  (Get.find<ProfileController>()
                          .profileInfo
                          ?.vehicle
                          ?.parcelWeightCapacity ??
                      0)) &&
              (Get.find<ProfileController>()
                      .profileInfo
                      ?.vehicle
                      ?.parcelWeightCapacity !=
                  null)) {
            showCustomSnackBar(
              isError: true,
              'parcel_weight_limit_exceeded'.tr,
              subMessage: 'parcel_weight_exceeds_the_set_limit'.tr,
              seconds: 5,
            );
          }
        });

        Get.find<OtpTimeCountController>().initialCounter();
      }
    } else {
      accepting = false;
    }
    accepting = false;
    onPressedTripId = null;
    update();
    return response;
  }

  String _verificationCode = '';
  String _otp = '';
  String get otp => _otp;
  String get verificationCode => _verificationCode;

  void updateVerificationCode(String query) {
    _verificationCode = query;
    if (_verificationCode.isNotEmpty) {
      _otp = _verificationCode;
    }
    update();
  }

  void clearVerificationCode() {
    _verificationCode = '';
    update();
  }

  Uint8List? imageFile;

  Future<Response> matchOtp(String tripId, String otp) async {
    isPinVerificationLoading = true;
    update();
    if (kDebugMode) {
      print('otp and id ===> $tripId/$otp');
    }
    Response response = await rideServiceInterface.matchOtp(tripId, otp);
    if (response.statusCode == 200) {
      if (tripDetail?.type != 'parcel') {
        Get.find<SafetyAlertController>().checkDriverNeedSafety();
      }

      resetPickupWaitingState();
      _pickupWaitingTripId = tripId;

      clearVerificationCode();
      if (tripDetail!.type! == 'parcel' &&
          tripDetail?.parcelInformation?.payer == 'sender') {
        Get.find<RiderMapController>().setRideCurrentState(RideState.ongoing);
        getFinalFare(tripId).then((value) {
          if (value.statusCode == 200) {
            Get.to(() => const PaymentReceivedScreen(fromParcel: true));
          }
        });
      } else {
        remainingDistance(tripDetail!.id!, mapBound: true);
        getRideDetails(tripDetail!.id!);
        Get.find<RiderMapController>().setRideCurrentState(RideState.ongoing);
      }

      if (otp.isEmpty) {
        showCustomSnackBar('trip_started'.tr, isError: false);
      } else {
        showCustomSnackBar('otp_verified_successfully'.tr, isError: false);
      }

      isPinVerificationLoading = false;
      Future.delayed(const Duration(seconds: 12)).then((value) async {
        imageFile = await Get.find<RiderMapController>().mapController!
            .takeSnapshot();
        if (imageFile != null) {
          uploadScreenShots(tripDetail!.id!, XFile.fromData(imageFile!));
        }
      });

      PusherHelper().tripCancelAfterOngoing(tripDetail!.id!);
      PusherHelper().tripPaymentSuccessful(tripDetail!.id!);
    } else {
      if (otp.isNotEmpty) {
        ApiChecker.checkApi(response);
      }
      isPinVerificationLoading = false;
    }
    update();
    return response;
  }

  String myDriveMode = '';
  RemainingDistanceModel? matchedMode;
  List<RemainingDistanceModel>? remainingDistanceItem = [];
  Future<Response> remainingDistance(
    String tripId, {
    bool mapBound = false,
  }) async {
    myDriveMode =
        Get.find<ProfileController>().profileInfo!.vehicle!.category!.type!;
    isLoading = true;
    Response response = await rideServiceInterface.remainDistance(tripId);
    List<String> status = ['pending', 'accepted', 'outForPickup', 'ongoing'];
    if (response.statusCode == 200) {
      isLoading = false;
      if (status.contains(
        Get.find<RiderMapController>().currentRideState.name,
      )) {
        Get.find<RiderMapController>().getDriverToPickupOrDestinationPolyline(
          response.body[0]['encoded_polyline'],
          mapBound: mapBound,
        );
      }

      remainingDistanceItem = [];
      response.body.forEach((distance) {
        remainingDistanceItem!.add(RemainingDistanceModel.fromJson(distance));
      });
      if (remainingDistanceItem != null && remainingDistanceItem!.isNotEmpty) {
        matchedMode = remainingDistanceItem![0];
      }

      if (tripDetail != null &&
          tripDetail!.currentStatus == 'ongoing' &&
          !tripDetail!.isPaused! &&
          matchedMode != null &&
          Get.find<RiderMapController>().isInside &&
          matchedMode!.isPicked!) {
        arrivalDestination(tripId, "destination");
        getRideDetails(tripId);
        AudioPlayer audio = AudioPlayer();
        audio.play(AssetSource('notification.wav'));
      }
    } else {
      _traceDispatch(
        'getRideDetailBeforeAccept failed tripId=$tripId status=${response.statusCode} body=${response.body}',
      );
      isLoading = false;
    }
    update();
    return response;
  }

  bool isStatusUpdating = false;

  Future<Response> tripStatusUpdate(
    String status,
    String id,
    String message,
    String cancellationCause, {
    String? dateTime,
  }) async {
    isLoading = true;
    isStatusUpdating = true;
    update();
    Response response = await rideServiceInterface.tripStatusUpdate(
      status,
      id,
      cancellationCause,
      dateTime ?? '',
    );

    if (response.statusCode == 200) {
      Get.find<TripController>().othersCancellationController.clear();
      Get.find<SafetyAlertController>().cancelDriverNeedSafetyStream();
      if (status == 'completed' || status == 'cancelled') {
        resetPickupWaitingState();
      }
      showCustomSnackBar(
        DynamicTranslationHelper.translate(message),
        isError: false,
      );
      isLoading = false;
    } else {
      isLoading = false;
      ApiChecker.checkApi(response);
    }
    isStatusUpdating = false;
    update();
    return response;
  }

  PendingRideRequestModel? pendingRideRequestModel;
  PendingRideRequestModel? get getPendingRideRequestModel =>
      pendingRideRequestModel;

  Future<Response> getPendingRideRequestList(
    int offset, {
    int limit = 10,
    bool isUpdate = false,
  }) async {
    isLoading = true;
    _traceDispatch(
      'getPendingRideRequestList start baseUrl=${Get.find<SplashController>().config?.baseUrl ?? 'unknown'} endpoint=pending-ride-list offset=$offset limit=$limit pusher=${Get.find<SplashController>().pusherConnectionStatus}',
    );
    if (isUpdate) {
      update();
    }
    Response response = await rideServiceInterface.getPendingRideRequestList(
      offset,
      limit: limit,
    );
    if (response.statusCode == 200) {
      pendingRideRequestModel?.data = [];
      pendingRideRequestModel?.totalSize = 0;
      pendingRideRequestModel?.offset = '1';
      if (response.body['data'] != null && response.body['data'] != '') {
        if (offset == 1) {
          pendingRideRequestModel = PendingRideRequestModel.fromJson(
            response.body,
          );
        } else {
          pendingRideRequestModel!.totalSize = PendingRideRequestModel.fromJson(
            response.body,
          ).totalSize;
          pendingRideRequestModel!.offset = PendingRideRequestModel.fromJson(
            response.body,
          ).offset;
          pendingRideRequestModel!.data!.addAll(
            PendingRideRequestModel.fromJson(response.body).data!,
          );
        }
      }

      isLoading = false;
      final int count = pendingRideRequestModel?.data?.length ?? 0;
      final List<String> ids = (pendingRideRequestModel?.data ?? [])
          .map((e) => e.id?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .take(5)
          .toList();

      if (_pendingRideDecisionTimer != null &&
          _pendingRideDecisionTripId != null &&
          !(pendingRideRequestModel?.data ?? <TripDetail>[]).any(
            (trip) => trip.id == _pendingRideDecisionTripId,
          )) {
        _traceDispatch(
          'pending timer cleared because trip is no longer in pending list activeTripId=$_pendingRideDecisionTripId',
        );
        cancelPendingRideDecisionTimer(resetToSeconds: 0);
      }

      _traceDispatch(
        'getPendingRideRequestList success status=${response.statusCode} count=$count first_ids=${ids.join(',')}',
      );
    } else {
      pendingRideRequestModel?.data = [];
      pendingRideRequestModel?.totalSize = 0;
      pendingRideRequestModel?.offset = '1';
      isLoading = false;
      _traceDispatch(
        'getPendingRideRequestList failed status=${response.statusCode} body=${response.body}',
      );
      if (!(Get.find<ProfileController>().profileInfo?.vehicle == null &&
          Get.find<ProfileController>().isFirstTimeShowBottomSheet)) {
        ApiChecker.checkApi(response);
      }
    }
    update();
    return response;
  }

  FinalFare? finalFare;
  Future<Response> getFinalFare(String tripId) async {
    isLoading = true;
    update();
    Response response = await rideServiceInterface.getFinalFare(tripId);
    if (response.statusCode == 200) {
      Get.find<RiderMapController>().initializeData();
      if (response.body['data'] != null) {
        finalFare = FinalFareModel.fromJson(response.body).data!;
      }
      isLoading = false;
    } else {
      isLoading = false;
      ApiChecker.checkApi(response);
    }
    update();
    return response;
  }

  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  final DateFormat _dateFormat = DateFormat('yyyy-MM-d');
  DateTime get startDate => _startDate;
  DateTime get endDate => _endDate;
  DateFormat get dateFormat => _dateFormat;

  void selectDate(String type, BuildContext context) {
    showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2022),
      lastDate: DateTime(2030),
    ).then((date) {
      if (type == 'start') {
        _startDate = date!;
      } else {
        _endDate = date!;
      }

      update();
    });
  }

  Future<Response> arrivalPickupPoint(String tripId) async {
    isLoading = true;
    if (kDebugMode) {
      print('details api call-====> $tripId');
    }
    Response response = await rideServiceInterface.arrivalPickupPoint(tripId);
    if (response.statusCode == 200) {
      isLoading = false;
    } else {
      isLoading = false;
      ApiChecker.checkApi(response);
    }
    update();
    return response;
  }

  Future<Response> markArrivedAtPickup(String tripId) async {
    isPinVerificationLoading = true;
    update();
    final response = await arrivalPickupPoint(tripId);
    if (response.statusCode == 200) {
      _hasArrivedAtPickup = true;
      arrivedAt = DateTime.now();
      _pickupWaitingTripId = tripId;
      showCustomSnackBar('trip_status_updated_successfully'.tr, isError: false);
      getRideDetails(tripId);
      getLiveFees(
        tripId,
      ); // fetch gracePeriodMinutes + waitingFeePerMin immediately
    }
    isPinVerificationLoading = false;
    update();
    return response;
  }

  Future<Response> arrivalDestination(String tripId, String type) async {
    Response response = await rideServiceInterface.arrivalDestination(
      tripId,
      type,
    );
    if (response.statusCode == 200) {
      if (kDebugMode) {
        print("===Arrived destination aria===");
      }
    } else {
      ApiChecker.checkApi(response);
    }
    update();
    return response;
  }

  Future<Response> waitingForCustomer(
    String tripId,
    String waitingStatus,
  ) async {
    isLoading = true;
    Response response = await rideServiceInterface.waitingForCustomer(
      tripId,
      waitingStatus,
    );
    if (response.statusCode == 200) {
      getRideDetails(tripId);
      isLoading = false;
      showCustomSnackBar('trip_status_updated_successfully'.tr, isError: false);
    } else {
      isLoading = false;
      ApiChecker.checkApi(response);
    }
    update();
    return response;
  }

  void startPauseTimer() {
    pauseStartedAt = DateTime.now();
    pauseTimer?.cancel();
    pauseTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      updatePauseElapsedTime();
    });
    updatePauseElapsedTime();
  }

  void stopPauseTimer() {
    pauseTimer?.cancel();
    pauseTimer = null;
    pauseStartedAt = null;
    displayPauseElapsedTime = '00:00:00';
    update();
  }

  void updatePauseElapsedTime() {
    if (pauseStartedAt == null) return;

    final elapsed = DateTime.now().difference(pauseStartedAt!);
    displayPauseElapsedTime = formatPauseTime(elapsed);
    update();
  }

  String formatPauseTime(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<Response?> getLiveFees(String tripId) async {
    Response response = await rideServiceInterface.getLiveFees(tripId);
    if (kDebugMode) {
      print(
        '[getLiveFees] status=${response.statusCode} body=${response.body}',
      );
    }
    if (response.statusCode == 200) {
      final data = response.body['data'];
      if (kDebugMode) {
        print(
          '[getLiveFees] waiting_fee_per_min=${data?["waiting_fee_per_min"]} grace=${data?["grace_period_minutes"]} waiting_fee=${data?["waiting_fee"]} waiting_time=${data?["waiting_time"]}',
        );
      }
      if (tripDetail != null && data != null) {
        tripDetail!.waitingFee =
            (data['waiting_fee'] as num?)?.toDouble() ?? tripDetail!.waitingFee;
        tripDetail!.waitingTime =
            data['waiting_time']?.toString() ?? tripDetail!.waitingTime;
        tripDetail!.idleFee =
            (data['idle_fee'] as num?)?.toDouble() ?? tripDetail!.idleFee;
        tripDetail!.idleTime =
            data['idle_time']?.toString() ?? tripDetail!.idleTime;
        tripDetail!.delayFee =
            (data['delay_fee'] as num?)?.toDouble() ?? tripDetail!.delayFee;
        gracePeriodMinutes =
            (data['grace_period_minutes'] as num?)?.toDouble() ??
            gracePeriodMinutes;
        waitingFeePerMin =
            (data['waiting_fee_per_min'] as num?)?.toDouble() ??
            waitingFeePerMin;
        // Back-calculate arrivedAt if not set (e.g. after app restart)
        if (arrivedAt == null) {
          final arrivedAtStr = data['driver_arrives_at'] as String?;
          if (arrivedAtStr != null) {
            arrivedAt = DateTime.tryParse(arrivedAtStr);
          }
        }
      }
      update();
    }
    return response;
  }

  Future<void> focusOnBottomSheet(
    GlobalKey<ExpandableBottomSheetState> key,
  ) async {
    if (key.currentState?.expansionStatus == ExpansionStatus.expanded) {
      // ignore: invalid_use_of_protected_member
      key.currentState?.reassemble();
      await Future.delayed(const Duration(milliseconds: 500));
    }
    key.currentState?.expand();
  }

  ParcelListModel? parcelListModel;
  Future<Response> getOngoingParcelList() async {
    isLoading = true;
    Response? response = await rideServiceInterface.getOnGoingParcelList(1);
    if (response!.statusCode == 200) {
      isLoading = false;
      if (response.body['data'] != null) {
        parcelListModel = ParcelListModel.fromJson(response.body);
      }
    } else {
      isLoading = false;
      ApiChecker.checkApi(response);
    }
    isLoading = false;
    update();
    _calculateTotalParcelWeight();
    return response;
  }

  void _calculateTotalParcelWeight() {
    totalParcelWeight = 0;
    totalParcelCount = 0;
    if (parcelListModel != null) {
      totalParcelCount = parcelListModel!.data!.length;
      for (int i = 0; i < parcelListModel!.data!.length; i++) {
        totalParcelWeight += double.parse(
          parcelListModel?.data?[i].parcelInformation?.weight ?? '0',
        );
      }
    }
  }

  ParcelListModel? unpaidParcelListModel;
  Future<Response> getUnpaidParcelList() async {
    isLoading = true;
    Response? response = await rideServiceInterface.getUnpaidParcelList(1);
    if (response!.statusCode == 200) {
      isLoading = false;
      if (response.body['data'] != null) {
        unpaidParcelListModel = ParcelListModel.fromJson(response.body);
      }
    } else {
      isLoading = false;
      ApiChecker.checkApi(response);
    }
    isLoading = false;
    update();
    return response;
  }

  Future<String?> generateThumbnail(String filePath) async {
    final directory = await getTemporaryDirectory();

    final thumbnailPath = await VideoThumbnail.thumbnailFile(
      video: filePath, // Replace with your video URL
      thumbnailPath: directory.path,
      imageFormat: ImageFormat.PNG, // You can use JPEG or WEBP too
      maxHeight: 100, // Specify the height of the thumbnail
      maxWidth: 200, // Specify the Width of the thumbnail
      quality: 1, // Quality of the thumbnail
    );

    return thumbnailPath;
  }

  String loadingId = '';
  Future<Response> checkDriverReachedDestination(String tripId) async {
    isLoading = true;
    loadingId = tripId;
    update();
    Response response = await rideServiceInterface.remainDistance(tripId);
    if (response.statusCode == 200) {
      getRideDetails(tripId);
      isLoading = false;
      Get.find<RiderMapController>().checkDriverReachedDestination(
        response.body[0]['encoded_polyline'],
      );

      remainingDistanceItem = [];
      response.body.forEach((distance) {
        remainingDistanceItem!.add(RemainingDistanceModel.fromJson(distance));
      });

      if (remainingDistanceItem != null && remainingDistanceItem!.isNotEmpty) {
        matchedMode = remainingDistanceItem![0];
      }
    } else {
      isLoading = false;
    }
    update();
    return response;
  }

  void showSafetyAlertTooltip() {
    justTheController.showTooltip();
  }

  Future<Response> startForPickup(String tripId) async {
    isPinVerificationLoading = true;
    update();

    Response response = await rideServiceInterface.startForPickup(tripId);
    if (response.statusCode == 200) {
      getRideDetails(tripDetail!.id!);
      Get.find<RiderMapController>().setRideCurrentState(
        RideState.outForPickup,
      );
      resetPickupWaitingState();
      _pickupWaitingTripId = tripId;

      // if(otp.isEmpty){
      //   showCustomSnackBar('trip_started'.tr, isError: false);
      // }else{
      //   showCustomSnackBar('otp_verified_successfully'.tr, isError: false);
      // }

      isPinVerificationLoading = false;
    } else {
      isPinVerificationLoading = false;
    }
    update();
    return response;
  }

  @override
  void onClose() {
    pauseTimer?.cancel();
    resetPickupWaitingState();
    super.onClose();
  }
}
