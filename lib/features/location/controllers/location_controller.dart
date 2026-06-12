import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ride_sharing_user_app/features/location/domain/services/location_service_interface.dart';
import 'package:ride_sharing_user_app/helper/display_helper.dart';
import 'package:ride_sharing_user_app/util/images.dart';
import 'package:ride_sharing_user_app/features/auth/controllers/auth_controller.dart';
import 'package:ride_sharing_user_app/features/location/domain/models/zone_response.dart';
import 'package:ride_sharing_user_app/features/map/controllers/map_controller.dart';

class LocationController extends GetxController implements GetxService {
  final LocationServiceInterface locationServiceInterface;
  LocationController({required this.locationServiceInterface});

  Position _position = Position(
      longitude: 0,
      latitude: 0,
      timestamp: DateTime.now(),
      accuracy: 1,
      altitude: 1,
      heading: 1,
      speed: 1,
      speedAccuracy: 1,
      altitudeAccuracy: 1,
      headingAccuracy: 1);
  String _address = '';
  bool _isLoading = false;
  GoogleMapController? _mapController;
  bool get isLoading => _isLoading;
  Position get position => _position;
  String get address => _address;
  GoogleMapController get mapController => _mapController!;
  LatLng _initialPosition = const LatLng(23.83721, 90.363715);
  LatLng get initialPosition => _initialPosition;

  StreamSubscription? _locationSubscription;
  Future<Position> getCurrentLocation(
      {bool isAnimate = true,
      GoogleMapController? mapController,
      bool callZone = true}) async {
    debugPrint('[MAP_DEBUG] LocationController.getCurrentLocation() appelé');
    bool isSuccess = await checkPermission();
    debugPrint('[MAP_DEBUG] checkPermission() retourne: $isSuccess');
    if (isSuccess) {
      try {
        var location = await Geolocator.getCurrentPosition(
            locationSettings: LocationSettings(
                accuracy: LocationAccuracy.high,
                timeLimit: const Duration(seconds: 5)));

        Get.find<RiderMapController>().updateMarkerAndCircle(
            LatLng(location.latitude, location.longitude));

        if (_locationSubscription != null) {
          _locationSubscription!.cancel();
        }
        Position newLocalData = await Geolocator.getCurrentPosition(
            locationSettings: LocationSettings(
                accuracy: LocationAccuracy.high,
                timeLimit: const Duration(seconds: 5)));
        _position = newLocalData;
        _initialPosition = LatLng(_position.latitude, _position.longitude);
        debugPrint(
            '[MAP_DEBUG] ✅ Position mise à jour: lat=${_position.latitude}, lng=${_position.longitude}');
        if (callZone) {
          getZone(_position.latitude.toString(), _position.longitude.toString(),
              false);
          getAddressFromGeocode(_initialPosition);
        }
        if (Get.find<AuthController>().isLoggedIn()) {
          updateLastLocation(
              location.latitude.toString(), location.longitude.toString());
        }
        _locationSubscription =
            Geolocator.getPositionStream().listen((newLocalData) {
          if (mapController != null) {
            mapController.moveCamera(CameraUpdate.newCameraPosition(
                CameraPosition(
                    bearing: 192.8334901395799,
                    target:
                        LatLng(newLocalData.latitude, newLocalData.longitude),
                    tilt: 0,
                    zoom: 16)));
            Get.find<RiderMapController>().updateMarkerAndCircle(
                LatLng(newLocalData.latitude, newLocalData.longitude));
          }
        });
        if (isAnimate) {
          _mapController?.moveCamera(CameraUpdate.newCameraPosition(
              CameraPosition(target: _initialPosition, zoom: 16)));
        }
      } catch (e) {
        debugPrint(
            '[MAP_DEBUG] ❌ Exception dans LocationController.getCurrentLocation: $e');
        if (kDebugMode) {
          print('');
        }
        _position = (await Geolocator.getLastKnownPosition()) ?? _position;
      }
    }
    return _position;
  }

  String zoneID = '';
  Future<ZoneResponseModel> getZone(
      String lat, String long, bool markerLoad) async {
    _isLoading = true;
    update();
    ZoneResponseModel responseModel;
    Response response = await locationServiceInterface.getZone(lat, long);
    if (response.statusCode == 200) {
      zoneID = response.body['data']['id'];
      if (Get.find<AuthController>().isLoggedIn()) {
        storeLastLocationApi(lat, long, zoneID);
      }
      responseModel = ZoneResponseModel(true, '', zoneID);
      if (kDebugMode) {
        print('Here is your zoneId==> $zoneID');
      }
      if (zoneID != '') {
        setUserZoneId(zoneID);
        Get.find<AuthController>().updateZoneId(zoneID);
      }
    } else {
      responseModel = ZoneResponseModel(false, response.statusText, '');
    }
    _isLoading = false;
    update();
    return responseModel;
  }

  Future<void> setUserZoneId(String zoneId) async {
    locationServiceInterface.saveUserZoneId(zoneId);
  }

  Future<void> updateLastLocation(String lat, String lng) async {
    storeLastLocationApi(lat, lng, zoneID);

    update();
  }

  bool lastLocationLoading = false;
  Future<void> storeLastLocationApi(
      String lat, String lng, String zoneID) async {
    lastLocationLoading = true;
    update();
    Response response =
        await locationServiceInterface.storeLastLocationApi(lat, lng, zoneID);
    if (response.statusCode == 200) {
      lastLocationLoading = false;
    }
    update();
  }

  Future<String> getAddressFromGeocode(LatLng latLng) async {
    Response response =
        await locationServiceInterface.getAddressFromGeocode(latLng);
    if (response.statusCode == 200) {
      _address =
          response.body['data']['results'][0]['formatted_address'].toString();
    }
    return _address;
  }

  Future<bool> checkPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    debugPrint('[MAP_DEBUG] Permission GPS actuelle: $permission');

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.whileInUse) {
      final PermissionStatus alwaysStatus =
          await Permission.locationAlways.request();
      if (alwaysStatus.isGranted) {
        permission = LocationPermission.always;
      }
    }

    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      return true;
    } else {
      showCustomSnackBar('you_have_to_allow'.tr);
      return false;
    }
  }

  Future<LatLng?> getCurrentPosition() async {
    bool isSuccess = await checkPermission();
    LatLng? latLng;
    if (isSuccess) {
      try {
        Position newLocalData = await Geolocator.getCurrentPosition(
            locationSettings:
                LocationSettings(accuracy: LocationAccuracy.high));
        latLng = LatLng(newLocalData.latitude, newLocalData.longitude);
      } catch (e) {
        if (kDebugMode) {
          print(e);
        }
      }
    }
    return latLng;
  }
}
