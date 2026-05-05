class VehicleBody {
  String? brandId;
  String? modelId;
  String? categoryId;
  List<String>? categoryIds;
  String? licencePlateNumber;
  String? licenceExpireDate;
  String? vinNumber;
  String? transmission;
  String? fuelType;
  String? vehicleYear;
  String? vehicleColor;
  String? technicalInspectionExpiryDate;
  String? insuranceExpiryDate;
  String? patenteExpiryDate;
  String? driverId;
  String? ownership;
  String? parcelCapacityWeight;

  VehicleBody(
      {this.brandId,
      this.modelId,
      this.categoryId,
      this.categoryIds,
      this.licencePlateNumber,
      this.licenceExpireDate,
      this.vinNumber,
      this.transmission,
      this.fuelType,
      this.vehicleYear,
      this.vehicleColor,
      this.technicalInspectionExpiryDate,
      this.insuranceExpiryDate,
      this.patenteExpiryDate,
      this.driverId,
      this.ownership,
      this.parcelCapacityWeight});

  VehicleBody.fromJson(Map<String, dynamic> json) {
    brandId = json['brand_id'];
    modelId = json['model_id'];
    categoryId = json['category_id'];
    categoryIds = json['category_ids']?.cast<String>();
    licencePlateNumber = json['licence_plate_number'];
    licenceExpireDate = json['licence_expire_date'];
    vinNumber = json['vin_number'];
    transmission = json['transmission'];
    fuelType = json['fuel_type'];
    vehicleYear = json['vehicle_year'];
    vehicleColor = json['vehicle_color'];
    technicalInspectionExpiryDate = json['technical_inspection_expiry_date'];
    insuranceExpiryDate = json['insurance_expiry_date'];
    patenteExpiryDate = json['patente_expiry_date'];
    driverId = json['driver_id'];
    ownership = json['ownership'];
    parcelCapacityWeight = json['parcel_weight_capacity'];
  }

  Map<String, String> toJson() {
    final Map<String, String> data = <String, String>{};
    if (brandId != null) data['brand_id'] = brandId!;
    if (modelId != null) data['model_id'] = modelId!;
    if (categoryId != null) data['category_id'] = categoryId!;
    if (categoryIds != null && categoryIds!.isNotEmpty) {
      data['category_ids'] = categoryIds!.join(',');
    }
    if (licencePlateNumber != null)
      data['licence_plate_number'] = licencePlateNumber!;
    if (licenceExpireDate != null)
      data['licence_expire_date'] = licenceExpireDate!;
    if (vinNumber != null && vinNumber!.isNotEmpty)
      data['vin_number'] = vinNumber!;
    if (transmission != null && transmission!.isNotEmpty)
      data['transmission'] = transmission!;
    if (fuelType != null && fuelType!.isNotEmpty) data['fuel_type'] = fuelType!;
    if (vehicleYear != null && vehicleYear!.isNotEmpty)
      data['vehicle_year'] = vehicleYear!;
    if (vehicleColor != null && vehicleColor!.isNotEmpty)
      data['vehicle_color'] = vehicleColor!;
    if (technicalInspectionExpiryDate != null &&
        technicalInspectionExpiryDate!.isNotEmpty) {
      data['technical_inspection_expiry_date'] = technicalInspectionExpiryDate!;
    }
    if (insuranceExpiryDate != null && insuranceExpiryDate!.isNotEmpty) {
      data['insurance_expiry_date'] = insuranceExpiryDate!;
    }
    if (patenteExpiryDate != null && patenteExpiryDate!.isNotEmpty) {
      data['patente_expiry_date'] = patenteExpiryDate!;
    }
    if (driverId != null) data['driver_id'] = driverId!;
    if (ownership != null) data['ownership'] = ownership!;
    if (parcelCapacityWeight != null && parcelCapacityWeight!.isNotEmpty) {
      data['parcel_weight_capacity'] = parcelCapacityWeight!;
    }
    return data;
  }
}
