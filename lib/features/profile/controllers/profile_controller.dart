import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ride_sharing_user_app/data/api_checker.dart';
import 'package:ride_sharing_user_app/data/api_client.dart';
import 'package:ride_sharing_user_app/features/dashboard/screens/dashboard_screen.dart';
import 'package:ride_sharing_user_app/features/map/controllers/map_controller.dart';
import 'package:ride_sharing_user_app/features/profile/domain/models/level_model.dart';
import 'package:ride_sharing_user_app/features/profile/domain/services/profile_service_interface.dart';
import 'package:ride_sharing_user_app/features/wallet/widgets/payment_method_bottomsheet_widget.dart';
import 'package:ride_sharing_user_app/features/wallet/screens/digital_payment_screen.dart';
import 'package:ride_sharing_user_app/features/wallet/screens/wave_recharge_page.dart';
import 'package:ride_sharing_user_app/features/splash/controllers/splash_controller.dart';
import 'package:ride_sharing_user_app/helper/display_helper.dart';
import 'package:ride_sharing_user_app/util/images.dart';
import 'package:ride_sharing_user_app/features/auth/controllers/auth_controller.dart';
import 'package:ride_sharing_user_app/features/location/controllers/location_controller.dart';
import 'package:ride_sharing_user_app/features/wallet/controllers/wallet_controller.dart';
import 'package:ride_sharing_user_app/features/profile/domain/models/categoty_model.dart';
import 'package:ride_sharing_user_app/features/profile/domain/models/profile_model.dart';
import 'package:ride_sharing_user_app/features/profile/domain/models/reward_model.dart';
import 'package:ride_sharing_user_app/features/profile/domain/models/vehicle_brand_model.dart';
import 'package:ride_sharing_user_app/features/profile/domain/models/vehicle_body.dart';
import 'package:ride_sharing_user_app/features/ride/controllers/ride_controller.dart';
import 'package:ride_sharing_user_app/common_widgets/config.dart';
import 'package:ride_sharing_user_app/common_widgets/confirmation_dialog_widget.dart';

class ProfileController extends GetxController implements GetxService {
  final ProfileServiceInterface profileServiceInterface;

  ProfileController({required this.profileServiceInterface});

  bool isLoading = false;
  List<RewardModel> rewardList = [];
  List<String> termList = [];

  List<String> profileType = [
    'my_profile',
    'my_level',
    'my_vehicle',
  ];

  int _profileTypeIndex = 0;
  int get profileTypeIndex => _profileTypeIndex;
  List<int> profileTypeIndexList = [];
  List<MultipartDocument> documents = [];
  FilePickerResult? _otherFile;
  FilePickerResult? get otherFile => _otherFile;
  List<FilePickerResult> listOfDocuments = [];
  PlatformFile? objFile;
  List<String>? oldDocuments;
  bool isFirstTimeShowBottomSheet = true;
  bool isCashInHandWarningShow = false;
  bool isCashInHandHoldAccount = false;

  void updateFirstTimeShowBottomSheet(bool status) {
    isFirstTimeShowBottomSheet = status;
  }

  void setProfileTypeIndex(int index, {bool isUpdate = false}) {
    _profileTypeIndex = index;
    if (index == 0) {
      profileTypeIndexList = [];
      profileTypeIndexList.add(0);
    } else {
      profileTypeIndexList.remove(index);
      profileTypeIndexList.add(index);
    }
    if (isUpdate) {
      update();
    }
  }

  void moveToPreviousProfileType() {
    _profileTypeIndex = profileTypeIndexList[profileTypeIndexList.length - 2];
    profileTypeIndexList.removeLast();
    update();
  }

  final zoomDrawerController = ZoomDrawerController();
  bool toggle = false;

  void toggleDrawer() {
    zoomDrawerController.toggle?.call();
    toggle = !toggle;
    debugPrint("Toggle drawer===>$toggle");
    update();
  }

  int _offerSelectedIndex = 0;
  int get offerSelectedIndex => _offerSelectedIndex;

  bool pricingOptionsLoading = false;
  bool pricingModeUpdating = false;
  bool pricingModeEnabled = true;
  String driverPricingMode = 'commission';
  String? activeForfaitPlan;
  String? forfaitExpiresAt;
  List<String> forfaitCategories = [];
  List<String> pricingVehicleCategoryIds = [];
  Map<String, double> commissionRatesByCategory = {};
  double forfaitEcoAmount = 5000;
  double forfaitEcoConfortAmount = 7500;
  double forfaitEcoConfortPremiumAmount = 10000;

  void setOfferTypeIndex(int index) {
    _offerSelectedIndex = index;
    update();
  }

  ProfileInfo? profileInfo;

  String driverName = '';
  String driverImage = '';
  String driverId = '';

  String isOnline = '0';
  Future<Response> getProfileInfo() async {
    isLoading = true;
    Response? response = await profileServiceInterface.getProfileInfo();
    if (response!.statusCode == 200) {
      profileInfo = ProfileModel.fromJson(response.body).data!;
      await getDriverPricingOptions(isUpdate: false);
      Get.find<AuthController>().addImageAndRemoveMultiParseData();
      checkCashInHandWarningShow();
      driverId = profileInfo!.id!;
      driverImage = profileInfo!.profileImage ?? '';
      isOnline = profileInfo?.details?.isOnline ?? '0';
      oldDocuments = profileInfo?.documents;
      if (isOnline == "1") {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever ||
            (GetPlatform.isIOS
                ? false
                : permission == LocationPermission.whileInUse)) {
          Get.dialog(
              ConfirmationDialogWidget(
                icon: Images.location,
                description: 'this_app_collects_location_data'.tr,
                onYesPressed: () {
                  Get.back();
                  _checkPermission(() => startLocationRecord());
                },
              ),
              barrierDismissible: false);
        } else {
          startLocationRecord();
        }
      } else {
        stopLocationRecord();
      }
    } else {
      ApiChecker.checkApi(response);
    }
    isLoading = false;
    update();
    return response;
  }

  Future<void> getDriverPricingOptions({bool isUpdate = true}) async {
    pricingOptionsLoading = true;
    if (isUpdate) {
      update();
    }

    Response? response =
        await profileServiceInterface.getDriverPricingOptions();
    if (response?.statusCode == 200 && response?.body != null) {
      final dynamic body = response!.body;
      final dynamic rawData =
          body is Map<String, dynamic> ? body['data'] : null;

      Map<String, dynamic> data = <String, dynamic>{};
      if (rawData is Map) {
        data = Map<String, dynamic>.from(rawData);
      } else if (rawData is List &&
          rawData.isNotEmpty &&
          rawData.first is Map) {
        data = Map<String, dynamic>.from(rawData.first as Map);
      } else if (body is Map<String, dynamic>) {
        // Fallback si l'API renvoie les champs directement à la racine
        data = Map<String, dynamic>.from(body);
      }

      pricingModeEnabled = (data['is_enabled'] ?? 1) == 1;
      driverPricingMode = (data['current_mode'] ??
              profileInfo?.details?.pricingMode ??
              'commission')
          .toString();
      activeForfaitPlan = data['active_forfait_plan']?.toString();
      forfaitExpiresAt = data['forfait_expires_at']?.toString();

      forfaitCategories = data['forfait_categories'] is List
          ? List<String>.from(
              (data['forfait_categories'] as List).map((e) => '$e'))
          : <String>[];
      pricingVehicleCategoryIds = data['vehicle_category_ids'] is List
          ? List<String>.from(
              (data['vehicle_category_ids'] as List).map((e) => '$e'))
          : <String>[];

      final Map<String, dynamic> forfaitAmounts = data['forfait_amounts'] is Map
          ? Map<String, dynamic>.from(data['forfait_amounts'] as Map)
          : <String, dynamic>{};
      forfaitEcoAmount =
          double.tryParse('${forfaitAmounts['eco'] ?? 5000}') ?? 5000;
      forfaitEcoConfortAmount =
          double.tryParse('${forfaitAmounts['eco_confort'] ?? 7500}') ?? 7500;
      forfaitEcoConfortPremiumAmount = double.tryParse(
              '${forfaitAmounts['eco_confort_premium'] ?? 10000}') ??
          10000;

      commissionRatesByCategory = {};
      final Map<String, dynamic> rateMap =
          data['commission_rates_by_category'] is Map
              ? Map<String, dynamic>.from(
                  data['commission_rates_by_category'] as Map)
              : <String, dynamic>{};
      rateMap.forEach((key, value) {
        commissionRatesByCategory[key] = double.tryParse('$value') ?? 0;
      });
    }

    pricingOptionsLoading = false;
    update();
  }

  Future<void> selectCommissionMode() async {
    pricingModeUpdating = true;
    update();

    Response? response = await profileServiceInterface
        .selectDriverPricingMode({'mode': 'commission'});
    if (response?.statusCode == 200) {
      driverPricingMode = 'commission';
      activeForfaitPlan = null;
      forfaitExpiresAt = null;
      forfaitCategories = [];
      showCustomSnackBar('Mode commission activé', isError: false);
      await getDriverPricingOptions(isUpdate: false);
      await getProfileInfo();
    } else {
      ApiChecker.checkApi(response!);
    }

    pricingModeUpdating = false;
    update();
  }

  Future<void> activateForfait(String planKey, {int days = 1}) async {
    final List<String> selectedPlanCategories = _resolvePlanCategories(planKey);
    if (selectedPlanCategories.isEmpty) {
      showCustomSnackBar('Aucune catégorie disponible pour ce forfait');
      return;
    }

    pricingModeUpdating = true;
    update();

    Response? response = await profileServiceInterface.selectDriverPricingMode({
      'mode': 'forfait',
      'category_ids': selectedPlanCategories,
      'days': days,
    });

    if (response?.statusCode == 200) {
      showCustomSnackBar('Forfait activé avec succès', isError: false);
      await getDriverPricingOptions(isUpdate: false);
      await getProfileInfo();
    } else {
      ApiChecker.checkApi(response!);
    }

    pricingModeUpdating = false;
    update();
  }

  /// Achete un forfait en fournissant explicitement les catégories et le nombre de jours.
  Future<bool> purchaseForfaitWithCategories(List<String> categoryIds,
      {int days = 1}) async {
    if (categoryIds.isEmpty) {
      showCustomSnackBar('Veuillez sélectionner au moins une catégorie');
      return false;
    }

    pricingModeUpdating = true;
    update();
    // compute required amount first
    double amount = 0;
    for (final cid in categoryIds) {
      final idx = categoryList.indexWhere((c) => c.id == cid);
      if (idx != -1) amount += categoryList[idx].montant ?? 0;
    }
    amount = amount * (days < 1 ? 1 : days);

    Response? response;
    try {
      response = await profileServiceInterface.selectDriverPricingMode({
        'mode': 'forfait',
        'category_ids': categoryIds,
        'days': days,
      });
    } catch (e) {
      response = null;
    }

    if (response?.statusCode == 200) {
      showCustomSnackBar('Forfait acheté avec succès', isError: false);
      await getDriverPricingOptions(isUpdate: false);
      await getProfileInfo();
      pricingModeUpdating = false;
      update();
      return true;
    } else if (response?.statusCode == 403) {
      final code = response?.body != null &&
              response!.body is Map &&
              response.body['response_code'] != null
          ? response.body['response_code']
          : null;
      if (code == 'insufficient_wallet_balance_403') {
        // prompt user to recharge via payment methods and retry
        final result = await Get.bottomSheet(
          PaymentMethodBottomsheetWidget(payableBalance: amount),
          isScrollControlled: true,
        );
        if (result != null) {
          final gateway = (result['gateway'] ?? '').toString();
          final amt = result['amount'] ?? amount;
          if (gateway.toLowerCase().contains('wave')) {
            await Get.to(() => WaveRechargePage(initialAmount: amt.toString()));
          } else {
            await Get.to(() => DigitalPaymentScreen(
                paymentMethod: gateway, totalAmount: amt.toString()));
          }

          // after returning from payment, retry purchase once
          try {
            final retryResp =
                await profileServiceInterface.selectDriverPricingMode({
              'mode': 'forfait',
              'category_ids': categoryIds,
              'days': days,
            });
            if (retryResp?.statusCode == 200) {
              showCustomSnackBar('Forfait acheté avec succès', isError: false);
              await getDriverPricingOptions(isUpdate: false);
              await getProfileInfo();
              pricingModeUpdating = false;
              update();
              return true;
            } else {
              ApiChecker.checkApi(retryResp!);
            }
          } catch (e) {
            // ignore
          }
        }
      } else {
        ApiChecker.checkApi(response!);
      }
    } else {
      ApiChecker.checkApi(response!);
    }

    pricingModeUpdating = false;
    update();
    return false;
  }

  List<String> _resolvePlanCategories(String planKey) {
    final List<String> source = pricingVehicleCategoryIds.isNotEmpty
        ? pricingVehicleCategoryIds
        : (profileInfo?.vehicle?.categoryIds ?? <String>[]);
    if (source.isEmpty) {
      return <String>[];
    }

    int takeCount = 1;
    if (planKey == 'eco_confort') {
      takeCount = 2;
    } else if (planKey == 'eco_confort_premium') {
      takeCount = 3;
    }

    if (source.length <= takeCount) {
      return List<String>.from(source);
    }
    return List<String>.from(source.take(takeCount));
  }

  /// Resolve plan categories public wrapper for UI usage.
  List<String> resolvePlanCategoriesPublic(String planKey) {
    return _resolvePlanCategories(planKey);
  }

  Future<void> getDailyLog() async {
    Response? response = await profileServiceInterface.dailyLog();
    if (response!.statusCode == 200) {}
    update();
  }

  Future<Response> updateProfile(String firstName, String lastName,
      String email, String identityNumber, List<String> services) async {
    isLoading = true;
    update();
    Response? response = await profileServiceInterface.updateProfileInfo(
        firstName,
        lastName,
        email,
        Get.find<AuthController>().identityType,
        identityNumber,
        Get.find<AuthController>().pickedProfileFile,
        Get.find<AuthController>().multipartList,
        services,
        oldDocuments ?? [],
        Get.find<AuthController>().otherDocuments);
    if (response!.statusCode == 200) {
      Get.back();
      showCustomSnackBar('profile_info_updated_successfully'.tr,
          isError: false);
      isLoading = false;
      getProfileInfo();
      Get.find<AuthController>().clearOtherDocuments();
    } else {
      isLoading = false;
      ApiChecker.checkApi(response);
    }

    isLoading = false;
    update();
    return response;
  }

  Future<Response> profileOnlineOffline(bool value) async {
    isLoading = true;
    update();
    Response? response = await profileServiceInterface.profileOnlineOffline();
    if (response!.statusCode == 200) {
      if (isOnline == "0") {
        isOnline = "1";
      } else if (isOnline == "1") {
        isOnline = "0";
      }
    } else {
      Get.back();
      isLoading = false;
      ApiChecker.checkApi(response);
    }
    isLoading = false;
    update();
    return response;
  }

  List<Brand> brandList = [];
  List<VehicleModels> modelList = [];
  int selectedBrandIndex = 0;
  int selectedBrandId = 0;
  int selectedModelId = 0;
  int selectedModelIndex = 0;
  List<int> brandIds = [];
  List<int> modelIds = [];

  Brand? selectedBrand;

  Future<Response> getVehicleBrandList(int offset) async {
    brandIds = [];
    brandIds.add(0);
    isLoading = true;
    Response? response =
        await profileServiceInterface.getVehicleBrandList(offset);
    if (response!.statusCode == 200) {
      brandList = [];
      brandList.add(
          Brand(id: 'abc', name: 'select_brand_model'.tr, vehicleModels: []));
      brandList.addAll(VehicleBrandModel.fromJson(response.body).data!);

      int index = brandList.indexWhere(
          (value) => value.name == profileInfo?.vehicle?.brand?.name);
      if (index == -1) {
        setBrandIndex(brandList[0], true);
      } else {
        setBrandIndex(brandList[index], true);
      }
    } else {
      ApiChecker.checkApi(response);
    }
    isLoading = false;
    update();
    return response;
  }

  void setBrandIndex(Brand brand, bool notify) {
    selectedBrand = brand;
    modelList = [];
    if (selectedBrand != null) {
      modelList.add(VehicleModels(id: 'abc', name: 'select_vehicle_model'));
      modelList.addAll(selectedBrand!.vehicleModels!);

      int index = modelList.indexWhere(
          (value) => value.name == profileInfo?.vehicle?.model?.name);
      if (index == -1) {
        selectedModel = modelList[0];
      } else {
        selectedModel = modelList[index];
      }
    }
    if (notify) {
      update();
    }
  }

  VehicleModels selectedModel = VehicleModels();
  void setModelIndex(VehicleModels model, bool notify) {
    selectedModel = model;
    if (notify) {
      update();
    }
  }

  String selectedFuelType = 'select_fuel_type';
  void setFuelType(String type, bool notify) {
    selectedFuelType = type;
    if (notify) {
      update();
    }
  }

  List<Category> categoryList = [];
  List<Category> selectedCategories = [];
  List<String> selectedCategoryIds = [];

  Future<void> getCategoryList(int offset) async {
    Response? response = await profileServiceInterface.getCategoryList(offset);
    if (response!.statusCode == 200 && response.body['data'] != null) {
      categoryList = [];
      categoryList.add(Category(id: 'abc', name: 'select_vehicle_category'));
      final List<Category> fetchedCategories =
          CategoryModel.fromJson(response.body).data!;
      fetchedCategories.sort(
          (a, b) => (a.ordrePriorite ?? 0).compareTo(b.ordrePriorite ?? 0));
      final List<String> allowedCategories = ['fariman', 'choco', 'gbonhi'];
      categoryList.addAll(
        fetchedCategories.where((category) =>
            allowedCategories.contains((category.name ?? '').toLowerCase())),
      );

      if (categoryList.length == 1) {
        categoryList.addAll(fetchedCategories);
      }

      selectedCategories = [];
      selectedCategoryIds = [];

      final List<String> existingCategoryIds =
          profileInfo?.vehicle?.categoryIds ?? <String>[];

      if (existingCategoryIds.isNotEmpty) {
        for (final String categoryId in existingCategoryIds) {
          final int existingIndex =
              categoryList.indexWhere((value) => value.id == categoryId);
          if (existingIndex > 0) {
            selectedCategories.add(categoryList[existingIndex]);
            selectedCategoryIds.add(categoryList[existingIndex].id ?? '');
          }
        }
      }

      int index = categoryList.indexWhere(
          (value) => value.name == profileInfo?.vehicle?.category?.name);
      if (index == -1) {
        selectedCategory = categoryList[0];
      } else {
        selectedCategory = categoryList[index];
        if (selectedCategories.isEmpty &&
            selectedCategory.id != null &&
            selectedCategory.id != 'abc') {
          selectedCategories.add(selectedCategory);
          selectedCategoryIds.add(selectedCategory.id!);
        }
      }
    } else {
      isLoading = false;
      ApiChecker.checkApi(response);
    }
    update();
  }

  Category selectedCategory = Category();
  void setCategoryIndex(Category category, bool notify) {
    if (category.id == null || category.id == 'abc') return;
    selectedCategory = category;
    final int catPriority = category.ordrePriorite ?? 0;

    // Build the target selection: all categories with priority <= catPriority
    final List<Category> newSelection = catPriority > 0
        ? categoryList
            .where((c) =>
                c.id != null &&
                c.id != 'abc' &&
                (c.ordrePriorite ?? 0) > 0 &&
                (c.ordrePriorite ?? 0) <= catPriority)
            .toList()
        : [category];
    newSelection
        .sort((a, b) => (a.ordrePriorite ?? 0).compareTo(b.ordrePriorite ?? 0));

    // Toggle: if the target matches current selection exactly, clear everything
    final List<String> newIds = newSelection.map((c) => c.id!).toList()..sort();
    final List<String> currentIds = List<String>.from(selectedCategoryIds)
      ..sort();
    if (newIds.join(',') == currentIds.join(',')) {
      selectedCategories = [];
      selectedCategoryIds = [];
    } else {
      selectedCategories = newSelection;
      selectedCategoryIds = newSelection
          .where((c) => c.id != null && c.id != 'abc')
          .map((c) => c.id!)
          .toList();
    }

    if (notify) {
      update();
    }
  }

  bool _isValidPrioritySelection(List<Category> categories) {
    if (categories.length <= 1) {
      return true;
    }

    final List<int> priorities = categories
        .map((category) => category.ordrePriorite ?? 0)
        .where((priority) => priority > 0)
        .toList()
      ..sort();

    if (priorities.length != categories.length) {
      return false;
    }

    return priorities.last - priorities.first + 1 == priorities.length;
  }

  DateTime? _startDate;
  DateTime? _endDate;
  final DateFormat _dateFormat = DateFormat('yyyy-MM-d');
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  DateFormat get dateFormat => _dateFormat;

  void setStartDate(DateTime startDate) {
    _startDate = startDate;
  }

  void selectDate(String type, BuildContext context) {
    showDatePicker(
      cancelText: 'cancel'.tr,
      confirmText: 'ok'.tr,
      helpText: 'select_date'.tr,
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

  bool creating = false;
  Future<void> addNewVehicle(VehicleBody vehicleBody,
      List<MultipartBody> images, List<MultipartDocument> files) async {
    creating = true;
    update();
    Response? response =
        await profileServiceInterface.addNewVehicle(vehicleBody, images, files);
    if (response!.statusCode == 200) {
      creating = false;
      getProfileInfo().then((value) {
        if (value.statusCode == 200) {
          Get.offAll(() => const DashboardScreen());
          showCustomSnackBar('vehicle_added_successfully'.tr, isError: false);
        }
      });
    } else {
      creating = false;
      ApiChecker.checkApi(response);
    }
    creating = false;
    update();
  }

  Future<Response> updateVehicle(VehicleBody vehicleBody, String driverId,
      List<MultipartBody> images, List<MultipartDocument> files) async {
    creating = true;
    update();
    Response? response = await profileServiceInterface.updateVehicle(
        vehicleBody, driverId, images, files);
    if (response!.statusCode == 200) {
      creating = false;
      getProfileInfo().then((value) {
        if (value.statusCode == 200) {
          showCustomSnackBar(response.body['message'], isError: false);
        }
      });
    } else {
      creating = false;
      ApiChecker.checkApi(response);
    }
    creating = false;
    update();
    return response;
  }

  void clearVehicleData() {
    listOfDocuments = [];
  }

  File? selectedFileForImport = File('');
  void setSelectedFileName(File fileName) {
    selectedFileForImport = fileName;
    update();
  }

  Future<bool> pickOtherFile(bool isRemove) async {
    if (isRemove) {
      _otherFile = null;
    } else {
      _otherFile = (await FilePicker.platform.pickFiles(withReadStream: true))!;
      if (_otherFile != null) {
        listOfDocuments.add(_otherFile!);
        objFile = _otherFile!.files.single;
        documents.add(MultipartDocument('upload_documents[]', objFile));
      }
    }
    update();
    return true;
  }

  void removeFile(int index) async {
    listOfDocuments.removeAt(index);
    documents.removeAt(index);
    update();
  }

  Timer? _timer;
  final Location _location = Location();
  void startLocationRecord() {
    _location.enableBackgroundMode(enable: true);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      List<String> status = ['accepted', 'ongoing'];
      if (Get.find<RideController>().tripDetail != null &&
          status
              .contains(Get.find<RiderMapController>().currentRideState.name) &&
          Get.find<AuthController>().getUserToken() != '') {
        Get.find<RideController>()
            .remainingDistance(Get.find<RideController>().tripDetail!.id!);
      }
      Get.find<LocationController>().getCurrentLocation(callZone: false);
    });
  }

  void stopLocationRecord() {
    _location.enableBackgroundMode(enable: false);
    _timer?.cancel();
  }

  void _checkPermission(Function callback) async {
    LocationPermission permission = await Geolocator.requestPermission();
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        (GetPlatform.isIOS
            ? false
            : permission == LocationPermission.whileInUse)) {
      Get.dialog(
          ConfirmationDialogWidget(
            description: 'you_denied'.tr,
            onYesPressed: () async {
              Get.back();
              await Geolocator.requestPermission();
              _checkPermission(callback);
            },
            icon: Images.logo,
          ),
          barrierDismissible: false);
    } else if (permission == LocationPermission.deniedForever) {
      Get.dialog(
          ConfirmationDialogWidget(
            description: 'you_denied_forever'.tr,
            onYesPressed: () async {
              Get.back();
              await Geolocator.openAppSettings();
              _checkPermission(callback);
            },
            icon: Images.logo,
          ),
          barrierDismissible: false);
    } else {
      callback();
    }
    await Permission.notification.isDenied.then((value) {
      if (value) {
        Permission.notification.request();
      }
    });
  }

  LevelModel? _levelModel;
  LevelModel? get levelModel => _levelModel;

  Future<void> getProfileLevelInfo() async {
    Response response = await profileServiceInterface.getProfileLevelInfo();
    if (response.statusCode == 200) {
      _levelModel = LevelModel.fromJson(response.body);
    } else {
      ApiChecker.checkApi(response);
    }
    update();
  }

  void removeOldDocument(int index) async {
    oldDocuments?.removeAt(index);
    update();
  }

  void checkCashInHandWarningShow() {
    double payableBalance = (profileInfo?.wallet?.payableBalance ?? 0) -
        (profileInfo?.wallet?.receivableBalance ?? 0);
    double maxCashInHand =
        Get.find<SplashController>().config?.cashInHandMaxAmountHold ?? 0;
    double percentageCashInHand = maxCashInHand * 0.8;
    if ((payableBalance >= percentageCashInHand) &&
        (payableBalance < maxCashInHand) &&
        (Get.find<SplashController>().config?.cashInHandSetupStatus ?? false)) {
      isCashInHandHoldAccount = false;
      isCashInHandWarningShow = true;
    } else if ((payableBalance >= maxCashInHand) &&
        (Get.find<SplashController>().config?.cashInHandSetupStatus ?? false)) {
      isCashInHandHoldAccount = true;
      isCashInHandWarningShow = false;
    } else {
      isCashInHandHoldAccount = false;
      isCashInHandWarningShow = false;
    }
  }

  void removeCashInHandWarnings() {
    isCashInHandHoldAccount = false;
    isCashInHandWarningShow = false;
    update();
  }
}
