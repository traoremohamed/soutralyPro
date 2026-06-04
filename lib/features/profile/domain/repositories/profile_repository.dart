import 'dart:convert';

import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ride_sharing_user_app/data/api_client.dart';
import 'package:ride_sharing_user_app/features/profile/domain/repositories/profile_repository_interface.dart';
import 'package:ride_sharing_user_app/util/app_constants.dart';
import 'package:ride_sharing_user_app/features/profile/domain/models/vehicle_body.dart';

class ProfileRepository implements ProfileRepositoryInterface {
  ApiClient apiClient;
  ProfileRepository({required this.apiClient});

  @override
  Future<Response?> profileOnlineOffline() async {
    return await apiClient.postData(AppConstants.onlineOfflineStatus, {});
  }

  @override
  Future<Response?> getProfileInfo() async {
    return await apiClient.getData(AppConstants.profileInfo);
  }

  @override
  Future<Response?> dailyLog() async {
    return await apiClient.getData(AppConstants.trackDriverLog);
  }

  @override
  Future<Response?> getVehicleModelList(int offset) async {
    return await apiClient.getData('${AppConstants.vehicleModelList}$offset');
  }

  @override
  Future<Response?> getVehicleBrandList(int offset) async {
    return await apiClient.getData('${AppConstants.vehicleBrandList}$offset');
  }

  @override
  Future<Response?> getCategoryList(int offset) async {
    return await apiClient
        .getData('${AppConstants.vehicleMainCategory}$offset');
  }

  @override
  Future<Response?> addNewVehicle(VehicleBody vehicleBody,
      List<MultipartBody> images, List<MultipartDocument> files) async {
    return await apiClient.postMultipartData(
        AppConstants.addNewVehicle, vehicleBody.toJson(), images, null, files);
  }

  @override
  Future<Response?> updateVehicle(VehicleBody vehicleBody, String driverId,
      List<MultipartBody> images, List<MultipartDocument> files) async {
    return await apiClient.postMultipartData(
      AppConstants.updateVehicle + driverId,
      vehicleBody.toJson(),
      images,
      null,
      files,
    );
  }

  @override
  Future<Response?> getDriverPricingOptions() async {
    return await apiClient.getData(AppConstants.driverPricingOptions);
  }

  @override
  Future<Response?> selectDriverPricingMode(Map<String, dynamic> body) async {
    return await apiClient.postData(AppConstants.driverPricingSelectMode, body);
  }

  @override
  Future<Response?> getDriverBrandingOptions() async {
    return await apiClient.getData(AppConstants.driverBrandingOptions);
  }

  @override
  Future<Response?> subscribeDriverBranding(Map<String, dynamic> body) async {
    return await apiClient.postData(AppConstants.driverBrandingSubscribe, body);
  }

  @override
  Future<Response?> updateProfileInfo(
      String firstName,
      String lastname,
      String email,
      String identityType,
      String identityNumber,
      XFile? profile,
      List<MultipartBody>? identityImage,
      List<String> services,
      List<String> oldDocuments,
      List<MultipartDocument> newDocuments) async {
    Map<String, String> fields = {};

    fields.addAll(<String, String>{
      '_method': 'put',
      'first_name': firstName,
      'last_name': lastname,
      'identification_type': identityType,
      'identification_number': identityNumber,
      'email': email,
      'service': jsonEncode(services),
      'existing_documents': jsonEncode(oldDocuments)
    });
    return await apiClient.postMultipartData(
        AppConstants.updateProfileInfo,
        fields,
        identityImage!,
        MultipartBody('profile_image', profile),
        newDocuments);
  }

  @override
  Future<Response> getProfileLevelInfo() async {
    return apiClient.getData(AppConstants.getProfileLevel);
  }

  @override
  Future add(value) {
    // TODO: implement add
    throw UnimplementedError();
  }

  @override
  Future delete(int id) {
    // TODO: implement delete
    throw UnimplementedError();
  }

  @override
  Future get(String id) {
    // TODO: implement get
    throw UnimplementedError();
  }

  @override
  Future getList({int? offset = 1}) {
    // TODO: implement getList
    throw UnimplementedError();
  }

  @override
  Future update(Map<String, dynamic> body, int id) {
    // TODO: implement update
    throw UnimplementedError();
  }
}
