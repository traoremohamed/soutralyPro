import 'package:image_picker/image_picker.dart';
import 'package:ride_sharing_user_app/data/api_client.dart';
import 'package:ride_sharing_user_app/features/profile/domain/models/vehicle_body.dart';

abstract class ProfileServiceInterface {
  Future<dynamic> profileOnlineOffline();
  Future<dynamic> getProfileInfo();
  Future<dynamic> dailyLog();
  Future<dynamic> getVehicleModelList(int offset);
  Future<dynamic> getVehicleBrandList(int offset);
  Future<dynamic> getCategoryList(int offset);
  Future<dynamic> addNewVehicle(VehicleBody vehicleBody,
      List<MultipartBody> images, List<MultipartDocument> files);
  Future<dynamic> updateVehicle(VehicleBody vehicleBody, String driverId,
      List<MultipartBody> images, List<MultipartDocument> files);
  Future<dynamic> getDriverPricingOptions();
  Future<dynamic> selectDriverPricingMode(Map<String, dynamic> body);
  Future<dynamic> getDriverBrandingOptions();
  Future<dynamic> subscribeDriverBranding(Map<String, dynamic> body);
  Future<dynamic> updateProfileInfo(
      String firstName,
      String lastname,
      String email,
      String identityType,
      String identityNumber,
      XFile? profile,
      List<MultipartBody>? identityImage,
      List<String> services,
      List<String> oldDocuments,
      List<MultipartDocument> newDocuments);
  Future<dynamic> getProfileLevelInfo();
}
