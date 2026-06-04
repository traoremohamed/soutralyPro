import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ride_sharing_user_app/data/api_checker.dart';
import 'package:ride_sharing_user_app/data/api_client.dart';
import 'package:ride_sharing_user_app/features/auth/domain/enums/verification_from_enum.dart';
import 'package:ride_sharing_user_app/features/auth/domain/services/auth_service_interface.dart';
import 'package:ride_sharing_user_app/features/map/controllers/otp_time_count_controller.dart';
import 'package:ride_sharing_user_app/features/out_of_zone/controllers/out_of_zone_controller.dart';
import 'package:ride_sharing_user_app/features/safety_setup/controllers/safety_alert_controller.dart';
import 'package:ride_sharing_user_app/features/splash/domain/models/config_model.dart';
import 'package:ride_sharing_user_app/helper/country_code_picke.dart';
import 'package:ride_sharing_user_app/helper/display_helper.dart';
import 'package:ride_sharing_user_app/helper/pusher_helper.dart';
import 'package:ride_sharing_user_app/util/images.dart';
import 'package:ride_sharing_user_app/features/auth/domain/models/signup_body.dart';
import 'package:ride_sharing_user_app/features/auth/domain/models/category_model.dart';
import 'package:ride_sharing_user_app/features/auth/screens/sign_in_screen.dart';
import 'package:ride_sharing_user_app/features/auth/screens/otp_log_in_screen.dart';
import 'package:ride_sharing_user_app/features/auth/widgets/approve_dialog_widget.dart';
import 'package:ride_sharing_user_app/features/dashboard/screens/dashboard_screen.dart';
import 'package:ride_sharing_user_app/features/auth/screens/reset_password_screen.dart';
import 'package:ride_sharing_user_app/features/auth/screens/verification_screen.dart';
import 'package:ride_sharing_user_app/features/location/screens/access_location_screen.dart';
import 'package:ride_sharing_user_app/features/profile/controllers/profile_controller.dart';
import 'package:ride_sharing_user_app/features/ride/controllers/ride_controller.dart';
import 'package:ride_sharing_user_app/features/splash/controllers/splash_controller.dart';
import 'package:ride_sharing_user_app/common_widgets/snackbar_widget.dart';
import 'package:flutter/foundation.dart';

class AuthController extends GetxController implements GetxService {
  final AuthServiceInterface authServiceInterface;
  AuthController({required this.authServiceInterface});

  bool _isLoading = false;
  bool _acceptTerms = false;
  bool _isOtpSending = false;
  bool get isLoading => _isLoading;
  bool get acceptTerms => _acceptTerms;
  bool get isOtpSending => _isOtpSending;
  final String _mobileNumber = '';
  String get mobileNumber => _mobileNumber;
  XFile? _pickedProfileFile;
  XFile? get pickedProfileFile => _pickedProfileFile;
  XFile identityImage = XFile('');
  List<XFile> identityImages = [];
  List<MultipartBody> multipartList = [];
  List<MultipartDocument> otherDocuments = [];
  FilePickerResult? _otherFile;
  PlatformFile? objFile;
  String countryDialCode = '+880';
  bool isParcelShare = true;
  bool isRideShare = true;
  List<CategoryModel> categorieDrivers = [];
  final Set<int> selectedCategorieIds = <int>{};
  String prefillPhone = '';

  void setCountryCode(String code) {
    countryDialCode = code;
    update();
  }

  TextEditingController fNameController = TextEditingController();
  TextEditingController lNameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  TextEditingController identityNumberController = TextEditingController();
  TextEditingController drivingLicenseNumberController =
      TextEditingController();
  TextEditingController drivingLicenseExpiryController =
      TextEditingController();
  TextEditingController referralCodeController = TextEditingController();
  TextEditingController partnerVehicleCountController = TextEditingController();
  String partnerType = '';
  String partnerPersonType = ''; // 'morale' or 'physique'

  FocusNode fNameNode = FocusNode();
  FocusNode lNameNode = FocusNode();
  FocusNode phoneNode = FocusNode();
  FocusNode passwordNode = FocusNode();
  FocusNode confirmPasswordNode = FocusNode();
  FocusNode emailNode = FocusNode();
  FocusNode addressNode = FocusNode();
  FocusNode identityNumberNode = FocusNode();
  FocusNode drivingLicenseNumberNode = FocusNode();
  FocusNode drivingLicenseExpiryNode = FocusNode();
  FocusNode referralNode = FocusNode();

  List<XFile> drivingLicenseImages = [];

  void addImageAndRemoveMultiParseData() {
    multipartList.clear();
    identityImages.clear();
    update();
  }

  void updateServiceType(bool ride) {
    if (ride) {
      isRideShare = !isRideShare;
    } else {
      isParcelShare = !isParcelShare;
    }
    update();
  }

  @override
  void onInit() {
    super.onInit();
    loadCategorieDrivers();
  }

  Future<void> loadCategorieDrivers() async {
    Response? response = await authServiceInterface.getCategorieDrivers();
    if (response != null && response.statusCode == 200) {
      final dynamic body = response.body;
      if (body != null && body is List) {
        categorieDrivers = body.map((e) => CategoryModel.fromJson(e)).toList();
      } else if (body != null && body['data'] != null && body['data'] is List) {
        categorieDrivers = (body['data'] as List)
            .map((e) => CategoryModel.fromJson(e))
            .toList();
      }
    }
    update();
  }

  void setPrefillPhone(String phoneWithCountryCode) {
    prefillPhone = phoneWithCountryCode;
    update();
  }

  void clearPrefillPhone({bool notify = true}) {
    prefillPhone = '';
    if (notify) {
      update();
    }
  }

  void toggleCategorie(int id, String code) {
    // Rules:
    // If selecting PART (code 'PART') then disable DRIVER and LIVREUR
    // If selecting DRIVER or LIVREUR then disable PART
    final bool isPart = code.toUpperCase() == 'PART';
    final bool alreadySelected = selectedCategorieIds.contains(id);
    if (alreadySelected) {
      selectedCategorieIds.remove(id);
    } else {
      // add with rules
      if (isPart) {
        // remove any DRIVER/LIVREUR selections
        final toRemove = <int>[];
        for (final cat in categorieDrivers) {
          if (cat.codeCategDriver != null) {
            final c = cat.codeCategDriver!.toUpperCase();
            if (c == 'DRIVER' || c == 'LIVREUR') {
              toRemove.add(cat.id ?? -1);
            }
          }
        }
        for (final r in toRemove) {
          if (r != -1) selectedCategorieIds.remove(r);
        }
        selectedCategorieIds.add(id);
      } else {
        // selecting DRIVER or LIVREUR => remove PART
        final partIds = categorieDrivers
            .where((cat) => (cat.codeCategDriver ?? '').toUpperCase() == 'PART')
            .map((e) => e.id)
            .where((v) => v != null)
            .cast<int>();
        for (final p in partIds) {
          selectedCategorieIds.remove(p);
        }
        selectedCategorieIds.add(id);
      }
    }
    update();
  }

  void pickImage(bool isBack, bool isProfile) async {
    if (isProfile) {
      _pickedProfileFile =
          (await ImagePicker().pickImage(source: ImageSource.gallery))!;
    } else {
      identityImage =
          (await ImagePicker().pickImage(source: ImageSource.gallery))!;
      identityImages.add(identityImage);
      multipartList.add(MultipartBody('identity_images[]', identityImage));
    }
    update();
  }

  void removeImage(int index) {
    identityImages.removeAt(index);
    multipartList.removeAt(index);
    update();
  }

  void pickDrivingLicenseImage() async {
    final XFile? picked =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null && drivingLicenseImages.length < 2) {
      drivingLicenseImages.add(picked);
      update();
    }
  }

  void removeDrivingLicenseImage(int index) {
    drivingLicenseImages.removeAt(index);
    update();
  }

  Future<bool> pickOtherFile() async {
    _otherFile = (await FilePicker.platform.pickFiles(
      type: FileType.custom,
      withReadStream: true,
      allowedExtensions: [
        'cvc',
        'cvs',
        'doc',
        'jpeg',
        'jpg',
        'pdf',
        'png',
        'webp',
        'xls',
        'xlsx'
      ],
    ))!;
    if (_otherFile != null) {
      objFile = _otherFile!.files.single;
      otherDocuments.add(MultipartDocument('upload_documents[]', objFile));
    }
    update();
    return true;
  }

  void removeFile(int index) async {
    otherDocuments.removeAt(index);
    update();
  }

  PlatformFile? partnerRccmFile;
  PlatformFile? partnerTransportFile;
  PlatformFile? partnerIdFile;

  Future<void> pickPartnerDocument(String kind) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      withReadStream: true,
      allowedExtensions: [
        'cvc',
        'cvs',
        'doc',
        'jpeg',
        'jpg',
        'pdf',
        'png',
        'webp',
        'xls',
        'xlsx'
      ],
    );
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.single;
      if (kind == 'rccm') {
        partnerRccmFile = file;
      } else if (kind == 'transport') {
        partnerTransportFile = file;
      } else if (kind == 'id') {
        partnerIdFile = file;
      }
      update();
    }
  }

  void removePartnerDocument(String kind) {
    if (kind == 'rccm') partnerRccmFile = null;
    if (kind == 'transport') partnerTransportFile = null;
    if (kind == 'id') partnerIdFile = null;
    update();
  }

  void clearOtherDocuments() {
    otherDocuments.clear();
  }

  final List<String> _identityTypeList = [
    'nid',
    'passport',
    'residence_card',
  ];
  List<String> get identityTypeList => _identityTypeList;
  String _identityType = '';
  String get identityType => _identityType;

  void setIdentityType(String setValue) {
    _identityType = setValue;
    update();
  }

  void setPartnerType(String type) {
    partnerType = type;
    update();
  }

  Future<void> login(String countryCode, String phone, String password) async {
    _isLoading = true;
    update();
    final String fullPhoneNumber = countryCode + phone;

    Response? response = await authServiceInterface.login(
        phone: fullPhoneNumber, password: password);

    if (response!.statusCode == 200) {
      Map map = response.body;
      String token = '';
      token = map['data']['token'];
      setUserToken(token);
      PusherHelper.initializePusher();
      updateToken().then((value) {
        Get.find<OutOfZoneController>().getZoneList();
        _navigateLogin(countryCode, phone, password);
      });
      _isLoading = false;
    } else if (response.statusCode == 202) {
      if (response.body['data']['is_phone_verified'] == 0) {
        final bool isPhoneNotVerified =
            response.body['data']['is_phone_verified'] == 0;
        final AuthController authController = Get.find<AuthController>();

        if (isPhoneNotVerified) {
          authController
              .sendOtp(countryCode: countryCode, number: phone)
              .then((otpResponse) {
            if (otpResponse.statusCode == 200) {
              Get.to(() => VerificationScreen(
                  countryCode: countryCode,
                  number: phone,
                  form: VerificationForm.login));
            }
          });
        }
      }
    } else {
      _isLoading = false;
      if (kDebugMode) {
        // Log full response for debugging
        print(
            'REGISTER ERROR: status=${response.statusCode} body=${response.body}');
        showCustomSnackBar('DEBUG RESPONSE: ${response.body}');
      }
      ApiChecker.checkApi(response);
    }
    _isLoading = false;
    update();
  }

  bool logging = false;
  Future<void> logOut() async {
    logging = true;
    update();
    Response? response = await authServiceInterface.logOut();
    if (response!.statusCode == 200) {
      Get.find<RideController>().updateRoute(false, notify: true);
      Get.find<ProfileController>().stopLocationRecord();
      logging = false;
      Get.back();
      Get.offAll(() => const SignInScreen());

      PusherHelper().pusherDisconnectPusher();
      Get.find<SafetyAlertController>().cancelDriverNeedSafetyStream();
    } else {
      logging = false;
      ApiChecker.checkApi(response);
    }
    update();
  }

  Future<void> permanentDelete() async {
    logging = true;
    update();
    Response? response = await authServiceInterface.permanentDelete();
    if (response!.statusCode == 200) {
      Get.find<RideController>().updateRoute(false, notify: true);
      Get.find<ProfileController>().stopLocationRecord();
      logging = false;
      Get.back();
      Get.offAll(() => const SignInScreen());
      Get.find<SafetyAlertController>().cancelDriverNeedSafetyStream();
      showCustomSnackBar('successfully_delete_account'.tr, isError: false);
    } else {
      logging = false;
      ApiChecker.checkApi(response);
    }
    update();
  }

  Future<void> register(String code, SignUpBody signUpBody) async {
    final ConfigModel? configModel = Get.find<SplashController>().config;

    _isLoading = true;
    update();
    // Prepare documents list including partner-specific docs if present
    final List<MultipartDocument> docs = List.from(otherDocuments);
    final List<MultipartBody> registrationImages = List.from(multipartList);

    for (final image in drivingLicenseImages) {
      registrationImages.add(MultipartBody('driving_license_images[]', image));
    }

    if (partnerRccmFile != null) {
      docs.add(MultipartDocument('rccm', partnerRccmFile));
    }
    if (partnerTransportFile != null) {
      docs.add(MultipartDocument('transport_card', partnerTransportFile));
    }
    if (partnerIdFile != null) {
      docs.add(MultipartDocument('partner_id', partnerIdFile));
    }

    Response? response = await authServiceInterface.registration(
        signUpBody: signUpBody,
        profileImage: pickedProfileFile,
        identityImage: registrationImages,
        documents: docs);
    if (response!.statusCode == 200) {
      fNameController.clear();
      lNameController.clear();
      passwordController.clear();
      phoneController.clear();
      confirmPasswordController.clear();
      emailController.clear();
      addressController.clear();
      identityNumberController.clear();
      drivingLicenseNumberController.clear();
      drivingLicenseExpiryController.clear();
      _pickedProfileFile = null;
      identityImages.clear();
      drivingLicenseImages.clear();
      multipartList.clear();
      referralCodeController.clear();
      otherDocuments.clear();
      _isLoading = false;

      showCustomSnackBar(
        'Votre demande d\'inscription a été envoyée. Elle sera validée sous 24h.',
        isError: false,
      );

      if (configModel?.verification ?? false) {
        final String signUpPhone = signUpBody.phone ?? '';
        setPrefillPhone(signUpPhone);
        Get.offAll(() => const OtpLoginScreen());
      } else {
        showCustomSnackBar('registration_completed_successfully'.tr,
            isError: false);
        Get.offAll(() => const SignInScreen());
      }
      Get.find<ProfileController>().updateFirstTimeShowBottomSheet(true);
    } else {
      _isLoading = false;
      ApiChecker.checkApi(response);
    }
    update();
  }

  void _navigateLogin(String code, String phone, String password) {
    if (_isActiveRememberMe) {
      saveUserCredential(code, phone, password);
    } else {
      clearUserCredential();
    }
    Get.find<ProfileController>().getProfileInfo().then((value) {
      // Navigation garantie quel que soit le résultat de getProfileInfo
      if (getZoneId() == '') {
        Get.offAll(() => const AccessLocationScreen());
      } else {
        Get.offAll(() => const DashboardScreen());
      }

      if (value.statusCode == 200) {
        PusherHelper().driverTripRequestSubscribe(value.body['data']['id']);
      }
    }).catchError((_) {
      // En cas d'exception inattendue, on évite de bloquer l'utilisateur sur l'OTP
      if (getZoneId() == '') {
        Get.offAll(() => const AccessLocationScreen());
      } else {
        Get.offAll(() => const DashboardScreen());
      }
    });
  }

  Future<Response> sendOtp(
      {required String countryCode, required String number}) async {
    _isOtpSending = true;
    update();

    String? fcmToken;
    try {
      fcmToken = await FirebaseMessaging.instance.getToken();
    } catch (_) {}

    Response? response = await authServiceInterface.sendOtp(
        phone: countryCode + number, fcmToken: fcmToken);
    if (response!.statusCode == 200) {
      _isOtpSending = false;
      showCustomSnackBar('otp_sent_successfully'.tr, isError: false);
    } else {
      _isOtpSending = false;
      ApiChecker.checkApi(response);
    }
    update();
    return response;
  }

  Future<void> firebaseOtpSend(
      {required String countryCode,
      required String number,
      bool canRoute = true,
      required VerificationForm from}) async {
    _isOtpSending = true;
    update();

    Response? response = await authServiceInterface.isUserRegistered(
        phone: countryCode + number);
    if (response!.statusCode == 200) {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: countryCode + number,
        verificationCompleted: (PhoneAuthCredential credential) {},
        verificationFailed: (FirebaseAuthException e) {
          _isOtpSending = false;
          update();

          if (e.code == 'invalid-phone-number') {
            showCustomSnackBar('please_submit_a_valid_phone_number'.tr);
          } else {
            showCustomSnackBar(e.message?.replaceAll('_', ' ') ?? '');
          }
        },
        codeSent: (String vId, int? resendToken) {
          _isOtpSending = false;
          update();
          if (canRoute) {
            Get.to(() => VerificationScreen(
                countryCode: countryCode,
                number: number,
                session: vId,
                form: from));
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } else {
      _isOtpSending = false;
      ApiChecker.checkApi(response);
      update();
    }
  }

  Future<Response?> otpVerification(String phoneNumber, String otp,
      {String password = '',
      required VerificationForm from,
      String? session,
      bool suppressAutoLogin = false}) async {
    _isLoading = true;
    update();

    Response? response;
    bool useFirebase =
        Get.find<SplashController>().config?.isFirebaseOtpVerification ?? false;
    if (useFirebase && session != null) {
      response = await authServiceInterface.verifyFirebaseOtp(
          phone: phoneNumber, otp: otp, session: session);
    } else {
      response =
          await authServiceInterface.verifyOtp(phone: phoneNumber, otp: otp);
    }

    if (response?.statusCode == 200) {
      clearVerificationCode();
      _isLoading = false;
      if (from == VerificationForm.signUp) {
        showDialog(
            context: Get.context!,
            builder: (_) => ApproveDialogWidget(
                icon: Images.waitForVerification,
                description: 'create_account_approve_description'.tr,
                title: 'registration_not_approve_yet'.tr,
                onYesPressed: () {
                  Get.offAll(() => const SignInScreen());
                }),
            barrierDismissible: false);
      } else if (from == VerificationForm.login) {
        Map? map = response?.body;
        _isLoading = false;
        if (!suppressAutoLogin) {
          final firebaseCustomToken = (map != null && map['data'] != null)
              ? map['data']['firebase_custom_token']
              : null;

          if (firebaseCustomToken is String && firebaseCustomToken.isNotEmpty) {
            try {
              await FirebaseAuth.instance
                  .signInWithCustomToken(firebaseCustomToken);
            } catch (e) {
              if (kDebugMode) {
                print('Firebase custom token sign-in failed: $e');
              }
            }
          }

          // Token peut être sous map['data']['token'] ou directement map['token']
          final token = (map != null &&
                  map['data'] != null &&
                  map['data']['token'] != null)
              ? map['data']['token']
              : (map != null ? map['token'] : null);
          if (token != null && token is String && token.isNotEmpty) {
            await setUserToken(token);
            updateToken().then((value) {
              Get.find<OutOfZoneController>().getZoneList();
              String countryCode =
                  CountryCodeHelper.getCountryCode(phoneNumber) ?? '';
              _navigateLogin(countryCode,
                  phoneNumber.replaceAll(countryCode, ''), password);
            });
          } else {
            ApiChecker.checkApi(response!);
          }
        } else {
          // suppressAutoLogin true: caller will handle redirection (e.g. to sign-up)
        }
      } else {
        Get.to(() => ResetPasswordScreen(phoneNumber: phoneNumber));
      }
    } else {
      _isLoading = false;
      ApiChecker.checkApi(response!);
    }
    update();
    return response;
  }

  Future<void> forgetPassword(String phone) async {
    _isLoading = true;
    update();
    Response? response = await authServiceInterface.forgetPassword(phone);
    if (response!.statusCode == 200) {
      _isLoading = false;
      snackBarWidget('successfully_sent_otp'.tr, isError: false);
    } else {
      _isLoading = false;
      snackBarWidget('invalid_number'.tr);
    }
    update();
  }

  Future<void> resetPassword(String phone, String password) async {
    _isLoading = true;
    update();
    Response? response =
        await authServiceInterface.resetPassword(phone, password);
    if (response!.statusCode == 200) {
      snackBarWidget('password_change_successfully'.tr, isError: false);
      Get.offAll(() => const SignInScreen());
    } else {
      ApiChecker.checkApi(response);
    }
    _isLoading = false;
    update();
  }

  Future<void> changePassword(String password, String newPassword) async {
    _isLoading = true;
    update();
    Response? response =
        await authServiceInterface.changePassword(password, newPassword);
    if (response!.statusCode == 200) {
      snackBarWidget('password_change_successfully'.tr, isError: false);
      Get.offAll(() => const DashboardScreen());
    } else {
      ApiChecker.checkApi(response);
    }
    _isLoading = false;
    update();
  }

  bool updateFcm = false;
  Future<void> updateToken() async {
    updateFcm = true;
    update();
    Response? response = await authServiceInterface.updateToken();
    if (response?.statusCode == 200) {
      updateFcm = false;
    } else {
      updateFcm = false;
      ApiChecker.checkApi(response!);
    }
    update();
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

  void clearVerificationCode({bool isUpdate = true}) {
    _otp = '';
    _verificationCode = '';
    if (isUpdate) {
      update();
    }
  }

  bool _isActiveRememberMe = false;
  bool get isActiveRememberMe => _isActiveRememberMe;

  void toggleTerms() {
    _acceptTerms = !_acceptTerms;
    update();
  }

  void toggleRememberMe() {
    _isActiveRememberMe = !_isActiveRememberMe;
    update();
  }

  void setRememberMe() {
    _isActiveRememberMe = true;
  }

  bool isLoggedIn() {
    return authServiceInterface.isLoggedIn();
  }

  Future<bool> clearSharedData() async {
    return authServiceInterface.clearSharedData();
  }

  void saveUserCredential(String code, String number, String password) {
    authServiceInterface.saveUserCredential(code, number, password);
  }

  String getUserNumber() {
    return authServiceInterface.getUserNumber();
  }

  String getUserCountryCode() {
    return authServiceInterface.getUserCountryCode();
  }

  String getLoginCountryCode() {
    return authServiceInterface.getLoginCountryCode();
  }

  String getUserPassword() {
    return authServiceInterface.getUserPassword();
  }

  bool isNotificationActive() {
    return authServiceInterface.isNotificationActive();
  }

  void toggleNotificationSound() {
    authServiceInterface.toggleNotificationSound(!isNotificationActive());
    update();
  }

  Future<bool> clearUserCredential() async {
    return authServiceInterface.clearUserCredentials();
  }

  String getUserToken() {
    return authServiceInterface.getUserToken();
  }

  String getDeviceToken() {
    return authServiceInterface.getDeviceToken();
  }

  Future<void> setUserToken(String token) async {
    authServiceInterface.saveUserToken(token, getZoneId());
  }

  Future<void> updateZoneId(String zoneId) async {
    authServiceInterface.updateZone(zoneId);
  }

  String getZoneId() {
    return authServiceInterface.getZonId();
  }

  void saveRideCreatedTime() {
    authServiceInterface.saveRideCreatedTime(DateTime.now());
  }

  void remainingTime() async {
    String time = await authServiceInterface.remainingTime();
    if (time.isNotEmpty) {
      DateTime oldTime = DateTime.parse(time);
      DateTime newTime = DateTime.now();
      int diff = newTime.difference(oldTime).inSeconds;
      Get.find<OtpTimeCountController>().resumeCountingTime(diff);
    }
  }
}
