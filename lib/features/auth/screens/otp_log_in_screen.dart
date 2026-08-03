import 'package:country_code_picker/country_code_picker.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ride_sharing_user_app/common_widgets/text_field_widget.dart';
import 'package:ride_sharing_user_app/features/auth/controllers/auth_controller.dart';
import 'package:ride_sharing_user_app/features/auth/domain/enums/verification_from_enum.dart';
import 'package:ride_sharing_user_app/features/auth/screens/verification_screen.dart';
import 'package:ride_sharing_user_app/features/splash/controllers/splash_controller.dart';
import 'package:ride_sharing_user_app/helper/display_helper.dart';
import 'package:ride_sharing_user_app/util/dimensions.dart';
import 'package:ride_sharing_user_app/util/images.dart';
import 'package:ride_sharing_user_app/util/styles.dart';
import 'package:ride_sharing_user_app/common_widgets/button_widget.dart';

class OtpLoginScreen extends StatefulWidget {
  final bool fromSignIn;
  const OtpLoginScreen({super.key, this.fromSignIn = false});

  @override
  State<OtpLoginScreen> createState() => _OtpLoginScreenState();
}

class _OtpLoginScreenState extends State<OtpLoginScreen> {
  TextEditingController phoneController = TextEditingController();
  FocusNode phoneNode = FocusNode();
  bool _notificationPermissionGranted = false;
  bool _permissionChecked = false;
  bool _requestingPermission = false;

  @override
  void initState() {
    super.initState();

    Get.find<AuthController>().countryDialCode = CountryCode.fromCountryCode(
            Get.find<SplashController>().config!.countryCode!)
        .dialCode!;

    final AuthController authController = Get.find<AuthController>();
    if (authController.prefillPhone.isNotEmpty) {
      phoneController.text = authController.prefillPhone
          .replaceAll(authController.countryDialCode, '');
      authController.clearPrefillPhone(notify: false);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureNotificationPermissionBeforeOtp();
    });
  }

  Future<void> _ensureNotificationPermissionBeforeOtp() async {
    if (_requestingPermission) return;

    _requestingPermission = true;
    if (mounted) {
      setState(() {});
    }

    PermissionStatus status = await Permission.notification.status;

    if (!status.isGranted && GetPlatform.isIOS) {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      status = await Permission.notification.status;
    }

    if (!status.isGranted &&
        !status.isPermanentlyDenied &&
        !status.isRestricted) {
      status = await Permission.notification.request();
    }

    if (!mounted) {
      _requestingPermission = false;
      return;
    }

    _notificationPermissionGranted = status.isGranted;
    _permissionChecked = true;
    _requestingPermission = false;
    setState(() {});

    if (!_notificationPermissionGranted) {
      showCustomSnackBar(
          'Autorisez les notifications pour recevoir automatiquement votre code OTP.');
    }

    if (status.isPermanentlyDenied || status.isRestricted) {
      _showPermissionSettingsDialog();
    }
  }

  Future<void> _showPermissionSettingsDialog() async {
    await Get.dialog(
      AlertDialog(
        title: const Text('Notifications requises'),
        content: const Text(
            'Veuillez activer les notifications dans les paramètres pour recevoir le code OTP automatiquement.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              await openAppSettings();
            },
            child: const Text('Ouvrir les paramètres'),
          ),
        ],
      ),
      barrierDismissible: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final String phoneDigits =
        phoneController.text.replaceAll(RegExp(r'\D'), '');
    final bool isPhoneLengthValid = phoneDigits.length == 10;
    final bool canContinue = _notificationPermissionGranted && isPhoneLengthValid;

    return SafeArea(
      top: false,
      child: Scaffold(
        backgroundColor: Theme.of(context).canvasColor,
        body: GetBuilder<AuthController>(builder: (authController) {
          return Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                        child: Image.asset(Images.logoWithName,
                            height: 75, width: 200)),
                    const SizedBox(height: Dimensions.paddingSizeExtraLarge),

                    // FutureBuilder<String>(
                    //     future: loadSvgAndChangeColors(Images.otpLoginGraphics,
                    //         Theme.of(context).primaryColor),
                    //     builder: (context, snapshot) {
                    //       if (snapshot.connectionState ==
                    //               ConnectionState.done &&
                    //           snapshot.hasData) {
                    //         return SvgPicture.string(snapshot.data!);
                    //       }
                    //       return SvgPicture.asset(Images.otpLoginGraphics);
                    //     }),
                    const SizedBox(height: Dimensions.paddingSizeSmall),

                    Center(
                      child: Text(
                        'login_with_otp'.tr,
                        textAlign: TextAlign.center,
                        style: textBold.copyWith(
                            fontSize: Dimensions.fontSizeTwenty),
                      ),
                    ),
                    const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                    Center(
                      child: Text(
                        'please_enter_your_mobile_number_to_continue'.tr,
                        style: textMedium.copyWith(
                            color: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.color
                                ?.withValues(alpha: 0.7),
                            fontSize: Dimensions.fontSizeSmall),
                        maxLines: 2,
                      ),
                    ),
                    const SizedBox(height: Dimensions.paddingSizeSignUp),

                    if (_requestingPermission || !_permissionChecked)
                      const Center(child: CircularProgressIndicator())
                    else if (!_notificationPermissionGranted)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(
                            bottom: Dimensions.paddingSizeDefault),
                        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .error
                              .withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(
                              Dimensions.radiusDefault),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Autorisation notifications requise',
                              style: textSemiBold.copyWith(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                            const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                            Text(
                              'Activez les notifications pour recevoir le code OTP automatiquement.',
                              style: textRegular.copyWith(
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.color,
                              ),
                            ),
                            const SizedBox(height: Dimensions.paddingSizeSmall),
                            SizedBox(
                              height: 40,
                              child: ButtonWidget(
                                buttonText: 'Activer les notifications',
                                onPressed: _ensureNotificationPermissionBeforeOtp,
                                radius: 10,
                              ),
                            ),
                          ],
                        ),
                      ),

                    TextFieldWidget(
                      hintText: 'SAISIR VOTRE N° DE TELEPHONE',
                      inputType: TextInputType.number,
                      countryDialCode: authController.countryDialCode,
                      controller: phoneController,
                      focusNode: phoneNode,
                      inputAction: TextInputAction.done,
                      onCountryChanged: (CountryCode countryCode) {
                        authController.countryDialCode = countryCode.dialCode!;
                        authController.setCountryCode(countryCode.dialCode!);
                      },
                      onChanged: (_) => setState(() {}),
                      autoFocus: phoneController.text.isEmpty,
                      showCountryCode: true,
                      isEnabled: _notificationPermissionGranted,
                    ),
                    const SizedBox(height: Dimensions.paddingSizeExtraLarge),

                    // Bouton Continuer (désactivé si numéro != 10 chiffres)
                    authController.isOtpSending
                        ? Center(
                            child: SpinKitCircle(
                                color: Theme.of(context).primaryColor,
                                size: 40.0))
                        : ButtonWidget(
                            buttonText: 'CONTINUER',
                          onPressed: canContinue
                                ? () {
                                    String phone = phoneController.text.trim();

                                    if (phone.isEmpty) {
                                      showCustomSnackBar(
                                          'enter_your_phone_number'.tr);
                                      FocusScope.of(context)
                                          .requestFocus(phoneNode);
                                    } else if (!GetUtils.isPhoneNumber(
                                        authController.countryDialCode +
                                            phone)) {
                                      showCustomSnackBar(
                                          'phone_number_is_not_valid'.tr);
                                    } else {
                                      // Appel au backend pour génération/enregistrement de l'OTP
                                      authController
                                          .sendOtp(
                                              countryCode: authController
                                                  .countryDialCode,
                                              number: phone)
                                          .then((value) {
                                        if (value.statusCode == 200) {
                                          final bool isNewUser =
                                              value.body['data']
                                                      ?['is_new_user'] ??
                                                  false;
                                          Get.to(() => VerificationScreen(
                                                countryCode: authController
                                                    .countryDialCode,
                                                number: phone,
                                                form: VerificationForm.login,
                                                isNewUser: isNewUser,
                                              ));
                                        }
                                      });
                                    }
                                  }
                                : null,
                            radius: 50,
                          ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
