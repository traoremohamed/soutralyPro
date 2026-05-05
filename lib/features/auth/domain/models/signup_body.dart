import 'dart:convert';

class SignUpBody {
  String? fName;
  String? lName;
  String? phone;
  String? email;
  String? password;
  String? confirmPassword;
  String? address;
  String? identificationType;
  String? identityNumber;
  String? deviceToken;
  String? referralCode;
  List<String>? services;
  List<int>? categorieDriverIds;
  String? fcmToken;
  // Partner-specific
  String? partnerType;
  String? partnerPersonType;
  String? partnerVehicleCount;
  String? companyName;
  String? drivingLicenseNumber;
  String? drivingLicenseExpireDate;

  SignUpBody(
      {this.fName,
      this.lName,
      this.phone,
      this.email,
      this.password,
      this.confirmPassword,
      this.address,
      this.identificationType,
      this.identityNumber,
      this.deviceToken,
      this.services,
      this.categorieDriverIds,
      this.referralCode,
      this.fcmToken});
  // partner fields intentionally kept out of constructor signature to maintain compatibility

  SignUpBody.fromJson(Map<String, dynamic> json) {
    fName = json['first_name'];
    lName = json['last_name'];
    phone = json['phone'];
    password = json['password'];
    confirmPassword = json['confirm_password'];
    email = json['email'];
    address = json['address'];
    identificationType = json['identification_type'];
    identityNumber = json['identification_number'];
    deviceToken = json['fcm_token'];
    referralCode = json['referral_code'];
    fcmToken = json['fcm_token'];
    drivingLicenseNumber = json['driving_license_number'];
    drivingLicenseExpireDate = json['driving_license_expire_date'];
  }

  Map<String, String> toJson() {
    final Map<String, String> data = <String, String>{};
    data['first_name'] = fName ?? '';
    data['last_name'] = lName ?? '';
    data['phone'] = phone ?? '';
    if (password != null && password!.isNotEmpty) {
      data['password'] = password!;
    }
    if (confirmPassword != null && confirmPassword!.isNotEmpty) {
      data['confirm_password'] = confirmPassword!;
    }
    data['email'] = email ?? '';
    data['address'] = address ?? '';
    data['identification_type'] = identificationType ?? '';
    data['identification_number'] = identityNumber ?? '';
    data['fcm_token'] = deviceToken ?? '';
    if (companyName != null && companyName!.isNotEmpty) {
      data['company_name'] = companyName!;
    }
    data['service'] = jsonEncode(services ?? []);
    data['referral_code'] = referralCode ?? '';
    data['fcm_token'] = fcmToken ?? '';
    if (partnerType != null && partnerType!.isNotEmpty) {
      data['partner_type'] = partnerType!;
    }
    if (partnerPersonType != null && partnerPersonType!.isNotEmpty) {
      data['partner_person_type'] = partnerPersonType!;
    }
    if (partnerVehicleCount != null && partnerVehicleCount!.isNotEmpty) {
      data['partner_vehicle_count'] = partnerVehicleCount!;
    }
    if (drivingLicenseNumber != null && drivingLicenseNumber!.isNotEmpty) {
      data['driving_license_number'] = drivingLicenseNumber!;
    }
    if (drivingLicenseExpireDate != null &&
        drivingLicenseExpireDate!.isNotEmpty) {
      data['driving_license_expire_date'] = drivingLicenseExpireDate!;
    }
    if (categorieDriverIds != null) {
      data['categorie_driver_ids'] = jsonEncode(categorieDriverIds);
    }
    return data;
  }
}
