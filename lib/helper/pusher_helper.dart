import 'dart:convert';
import 'package:dart_pusher_channels/dart_pusher_channels.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/features/auth/controllers/auth_controller.dart';
import 'package:ride_sharing_user_app/features/home/screens/ride_list_screen.dart';
import 'package:ride_sharing_user_app/features/map/controllers/map_controller.dart';
import 'package:ride_sharing_user_app/features/map/screens/map_screen.dart';
import 'package:ride_sharing_user_app/features/ride/controllers/ride_controller.dart';
import 'package:ride_sharing_user_app/features/ride/screens/ride_request_list_screen.dart';
import 'package:ride_sharing_user_app/features/safety_setup/controllers/safety_alert_controller.dart';
import 'package:ride_sharing_user_app/features/splash/controllers/splash_controller.dart';
import 'package:ride_sharing_user_app/features/trip/screens/payment_received_screen.dart';
import 'package:ride_sharing_user_app/features/trip/screens/review_this_customer_screen.dart';
import 'package:ride_sharing_user_app/helper/notification_helper.dart';
import 'package:ride_sharing_user_app/util/app_constants.dart';
import '../features/dashboard/screens/dashboard_screen.dart';

class PusherHelper {
  static PusherChannelsClient? pusherClient;

  static void _dispatchLog(String message) {
    debugPrint('[DISPATCH][PUSHER] $message');
  }

  static String _extractHost(String? value) {
    final raw = (value ?? '').trim();
    if (raw.isEmpty) return '';

    if (raw.contains('://')) {
      final uri = Uri.tryParse(raw);
      return uri?.host ?? '';
    }

    final uri = Uri.tryParse('https://$raw');
    return uri?.host ?? raw;
  }

  static String _resolveWsHost() {
    final config = Get.find<SplashController>().config;
    final fromWebsocketUrl = _extractHost(config?.webSocketUrl);
    if (fromWebsocketUrl.isNotEmpty) return fromWebsocketUrl;

    final fromBaseUrl = _extractHost(config?.baseUrl);
    if (fromBaseUrl.isNotEmpty) {
      _dispatchLog(
          'webSocketUrl vide, fallback host depuis config.baseUrl=$fromBaseUrl');
      return fromBaseUrl;
    }

    final fromConstant = Uri.parse(AppConstants.baseUrl).host;
    _dispatchLog(
        'webSocketUrl/baseUrl vides, fallback host depuis AppConstants=$fromConstant');
    return fromConstant;
  }

  static String _resolveWsScheme() {
    final rawScheme =
        (Get.find<SplashController>().config?.websocketScheme ?? '')
            .toLowerCase();
    return (rawScheme == 'https' || rawScheme == 'wss') ? 'wss' : 'ws';
  }

  static String _resolveAuthScheme() {
    final wsScheme = _resolveWsScheme();
    return wsScheme == 'wss' ? 'https' : 'http';
  }

  static int _resolveWsPort() {
    final rawPort = Get.find<SplashController>().config?.webSocketPort;
    return int.tryParse('${rawPort ?? ''}') ?? 6001;
  }

  static Uri _resolveAuthEndpoint() {
    final host = _resolveWsHost();
    final scheme = _resolveAuthScheme();
    return Uri.parse('$scheme://$host/broadcasting/auth');
  }

  bool _isPusherConnected() {
    return Get.find<SplashController>().pusherConnectionStatus == 'Connected';
  }

  static void initializePusher() async {
    PusherChannelsOptions testOptions = PusherChannelsOptions.fromHost(
      host: _resolveWsHost(),
      scheme: _resolveWsScheme(),
      key: Get.find<SplashController>().config!.webSocketKey ?? '',
      port: _resolveWsPort(),
    );
    _dispatchLog(
        'initialize wsHost=${_resolveWsHost()} wsScheme=${_resolveWsScheme()} wsPort=${_resolveWsPort()} auth=${_resolveAuthEndpoint()} key=${Get.find<SplashController>().config!.webSocketKey}');

    pusherClient = PusherChannelsClient.websocket(
      options: testOptions,
      connectionErrorHandler: (exception, trace, refresh) async {
        _dispatchLog('connectionError: $exception');
        Get.find<SplashController>().setPusherStatus('Disconnected');
        refresh();
      },
    );

    await pusherClient?.connect();

    String? pusherChannelId =
        pusherClient?.channelsManager.channelsConnectionDelegate.socketId;
    _dispatchLog('connect socketId=$pusherChannelId');
    if (pusherChannelId != null) {
      Get.find<SplashController>().setPusherStatus('Connected');
    }

    pusherClient?.lifecycleStream.listen((event) {
      final lifecycle = event.toString().toLowerCase();
      _dispatchLog('lifecycle: $event');
      if (lifecycle.contains('connected')) {
        Get.find<SplashController>().setPusherStatus('Connected');
      } else if (lifecycle.contains('disconnect') ||
          lifecycle.contains('error') ||
          lifecycle.contains('failed')) {
        Get.find<SplashController>().setPusherStatus('Disconnected');
      }
    });
  }

  late PrivateChannel driverTripSubscribe;
  void driverTripRequestSubscribe(String id) {
    if (_isPusherConnected()) {
      if (pusherClient == null) {
        _dispatchLog('subscribe skipped: pusherClient is null for user=$id');
        return;
      }

      final channelName = "private-customer-trip-request.$id";
      final eventName = "customer-trip-request.$id";
      _dispatchLog('subscribe channel=$channelName event=$eventName');

      driverTripSubscribe = pusherClient!.privateChannel(channelName,
          authorizationDelegate:
              EndpointAuthorizableChannelTokenAuthorizationDelegate
                  .forPrivateChannel(
            authorizationEndpoint: _resolveAuthEndpoint(),
            headers: {
              "Accept": "application/json",
              "Authorization":
                  "Bearer ${Get.find<AuthController>().getUserToken()}",
              "Access-Control-Allow-Origin": "*",
              'Access-Control-Allow-Methods': "PUT, GET, POST, DELETE, OPTIONS"
            },
          ));

      if (driverTripSubscribe.currentStatus == null) {
        driverTripSubscribe.subscribeIfNotUnsubscribed();
        _dispatchLog('subscribed channel=$channelName');

        driverTripSubscribe.bind(eventName).listen((event) {
          _dispatchLog('event received name=$eventName payload=${event.data}');

          Map<String, dynamic> eventData;
          try {
            eventData = jsonDecode(event.data ?? '{}');
          } catch (e) {
            _dispatchLog('payload decode failed: $e raw=${event.data}');
            return;
          }

          final tripId = eventData['trip_id']?.toString();
          if (tripId == null || tripId.isEmpty) {
            _dispatchLog('payload missing trip_id: $eventData');
            return;
          }

          NotificationHelper.notifyIncomingRideSignal(
            tripId: tripId,
            source: 'pusher.event',
          );

          Get.find<RideController>().ongoingTripList().then((value) {
            if ((Get.find<RideController>().ongoingTrip ?? []).isEmpty) {
              Get.find<RideController>().getPendingRideRequestList(1);
              Get.find<RideController>().setRideId(tripId);
              Get.find<RiderMapController>()
                  .setRideCurrentState(RideState.pending, notify: false);
              Get.find<RideController>()
                  .getRideDetailBeforeAccept(tripId)
                  .then((value) {
                if (value.statusCode == 200) {
                  Get.find<RideController>().playIncomingRideAlert(
                      incomingTrip: Get.find<RideController>().tripDetail);
                  _dispatchLog('ride details loaded for trip_id=$tripId');
                  Get.find<RiderMapController>()
                      .setRideCurrentState(RideState.pending);
                  Get.find<RideController>().updateRoute(false, notify: true);
                  Get.to(() => const MapScreen());
                } else {
                  _dispatchLog(
                      'ride details load failed status=${value.statusCode} trip_id=$tripId');
                }
              });
            } else {
              if (Get.currentRoute == '/MapScreen') {
                Get.find<RideController>()
                    .getPendingRideRequestList(1, limit: 100);
              } else {
                Get.to(() => RideRequestScreen());
              }
            }
          });

          customerInitialTripCancel(tripId, id);
          anotherDriverAcceptedTrip(tripId, id);
        });
      } else {
        _dispatchLog('already subscribed channel=$channelName');
      }
    } else {
      _dispatchLog(
          'subscribe skipped: pusher status=${Get.find<SplashController>().pusherConnectionStatus} user=$id');
    }
  }

  late PrivateChannel customerInitialTripCancelChannel;

  void customerInitialTripCancel(String tripId, String userId) {
    if (_isPusherConnected()) {
      customerInitialTripCancelChannel = pusherClient!.privateChannel(
          "private-customer-trip-cancelled.$tripId.$userId",
          authorizationDelegate:
              EndpointAuthorizableChannelTokenAuthorizationDelegate
                  .forPrivateChannel(
            authorizationEndpoint: _resolveAuthEndpoint(),
            headers: {
              "Accept": "application/json",
              "Authorization":
                  "Bearer ${Get.find<AuthController>().getUserToken()}",
              "Access-Control-Allow-Origin": "*",
              'Access-Control-Allow-Methods': "PUT, GET, POST, DELETE, OPTIONS"
            },
          ));

      if (customerInitialTripCancelChannel.currentStatus == null) {
        customerInitialTripCancelChannel.subscribe();
        customerInitialTripCancelChannel
            .bind("customer-trip-cancelled.$tripId.$userId")
            .listen((event) {
          Get.find<RideController>().playTripCanceledAlert();
          if (Get.find<RideController>().tripDetail?.id ==
              jsonDecode(event.data!)['trip_id']) {
            Get.find<SafetyAlertController>().cancelDriverNeedSafetyStream();
            Get.find<RideController>()
                .getPendingRideRequestList(1)
                .then((value) {
              if (value.statusCode == 200) {
                Get.find<RiderMapController>()
                    .setRideCurrentState(RideState.initial);
                Get.offAll(() => const DashboardScreen());
              }
            });
          } else {
            Get.find<RideController>().ongoingTripList();
            Get.find<RideController>().getPendingRideRequestList(1, limit: 100);
          }
        });
      }
    }
  }

  late PrivateChannel anotherDriverAcceptedTripChannel;

  void anotherDriverAcceptedTrip(String tripId, String userId) {
    if (_isPusherConnected()) {
      anotherDriverAcceptedTripChannel = pusherClient!.privateChannel(
          "private-another-driver-trip-accepted.$tripId.$userId",
          authorizationDelegate:
              EndpointAuthorizableChannelTokenAuthorizationDelegate
                  .forPrivateChannel(
            authorizationEndpoint: _resolveAuthEndpoint(),
            headers: {
              "Accept": "application/json",
              "Authorization":
                  "Bearer ${Get.find<AuthController>().getUserToken()}",
              "Access-Control-Allow-Origin": "*",
              'Access-Control-Allow-Methods': "PUT, GET, POST, DELETE, OPTIONS"
            },
          ));

      if (anotherDriverAcceptedTripChannel.currentStatus == null) {
        anotherDriverAcceptedTripChannel.subscribe();
        anotherDriverAcceptedTripChannel
            .bind("another-driver-trip-accepted.$tripId.$userId")
            .listen((event) {
          if (Get.find<RideController>().tripDetail?.id ==
              jsonDecode(event.data!)['trip_id']) {
            Get.find<SafetyAlertController>().cancelDriverNeedSafetyStream();
            Get.find<RideController>()
                .getPendingRideRequestList(1)
                .then((value) {
              if (value.statusCode == 200) {
                Get.find<RiderMapController>()
                    .setRideCurrentState(RideState.initial);
                Get.offAll(() => const DashboardScreen());
              }
            });
          } else {
            Get.find<RideController>().ongoingTripList();
            Get.find<RideController>().getPendingRideRequestList(1, limit: 100);
          }
        });
      }
    }
  }

  late PrivateChannel tripCancelAfterOngoingChannel;

  void tripCancelAfterOngoing(String tripId) {
    if (_isPusherConnected()) {
      tripCancelAfterOngoingChannel = pusherClient!.privateChannel(
          "private-customer-trip-cancelled-after-ongoing.$tripId",
          authorizationDelegate:
              EndpointAuthorizableChannelTokenAuthorizationDelegate
                  .forPrivateChannel(
            authorizationEndpoint: _resolveAuthEndpoint(),
            headers: {
              "Accept": "application/json",
              "Authorization":
                  "Bearer ${Get.find<AuthController>().getUserToken()}",
              "Access-Control-Allow-Origin": "*",
              'Access-Control-Allow-Methods': "PUT, GET, POST, DELETE, OPTIONS"
            },
          ));

      if (tripCancelAfterOngoingChannel.currentStatus == null) {
        tripCancelAfterOngoingChannel.subscribe();
        tripCancelAfterOngoingChannel
            .bind("customer-trip-cancelled-after-ongoing.$tripId")
            .listen((event) {
          Get.find<RideController>().playTripCanceledAlert();
          Get.find<SafetyAlertController>().cancelDriverNeedSafetyStream();
          Get.find<RideController>()
              .getRideDetails(jsonDecode(event.data!)['id'])
              .then((value) {
            if (value.statusCode == 200) {
              if (Get.find<RideController>().tripDetail?.type ==
                  AppConstants.parcel) {
                Get.offAll(() => const DashboardScreen());
              } else {
                Get.find<RideController>()
                    .getFinalFare(jsonDecode(event.data!)['id'])
                    .then((value) {
                  if (value.statusCode == 200) {
                    Get.find<RiderMapController>()
                        .setRideCurrentState(RideState.initial);
                    Get.to(() => const PaymentReceivedScreen());
                  }
                });
              }
            }
          });
          // pusherClient!.unsubscribe('private-customer-trip-cancelled-after-ongoing.$tripId');
        });
      }
    }
  }

  late PrivateChannel tripPaymentSuccessfulChannel;

  void tripPaymentSuccessful(String tripId) {
    if (_isPusherConnected()) {
      tripPaymentSuccessfulChannel = pusherClient!.privateChannel(
          "private-customer-trip-payment-successful.$tripId",
          authorizationDelegate:
              EndpointAuthorizableChannelTokenAuthorizationDelegate
                  .forPrivateChannel(
            authorizationEndpoint: _resolveAuthEndpoint(),
            headers: {
              "Accept": "application/json",
              "Authorization":
                  "Bearer ${Get.find<AuthController>().getUserToken()}",
              "Access-Control-Allow-Origin": "*",
              'Access-Control-Allow-Methods': "PUT, GET, POST, DELETE, OPTIONS"
            },
          ));

      if (tripPaymentSuccessfulChannel.currentStatus == null) {
        tripPaymentSuccessfulChannel.subscribe();
        tripPaymentSuccessfulChannel
            .bind("customer-trip-payment-successful.$tripId")
            .listen((event) {
          if (jsonDecode(event.data!)['type'] == 'parcel') {
            Get.find<RideController>()
                .getRideDetails(jsonDecode(event.data!)['id'])
                .then((value) {
              if (value.statusCode == 200) {
                Get.find<RideController>().getOngoingParcelList();
                Get.back();
              }
            });
          } else {
            Get.find<RideController>().ongoingTripList().then((value) {
              if ((Get.find<RideController>().ongoingTrip ?? []).isEmpty) {
                Get.find<RideController>()
                    .getRideDetails(jsonDecode(event.data!)['id'])
                    .then((value) {
                  if (value.statusCode == 200) {
                    if (Get.find<SplashController>().config!.reviewStatus!) {
                      Get.offAll(() => ReviewThisCustomerScreen(
                          tripId: jsonDecode(event.data!)['id']));
                    } else {
                      Get.offAll(() => const DashboardScreen());
                    }
                  }
                });
              } else {
                Get.offAll(() => const RideListScreen());
              }
            });
          }
        });
      }
    }
  }

  void pusherDisconnectPusher() {
    pusherClient!.disconnect();
  }
}
