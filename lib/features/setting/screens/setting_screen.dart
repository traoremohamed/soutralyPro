import 'package:flutter/material.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/features/html/domain/html_enum_types.dart';
import 'package:ride_sharing_user_app/features/html/screens/policy_viewer_screen.dart';
import 'package:ride_sharing_user_app/common_widgets/custom_asset_image_widget.dart';
import 'package:ride_sharing_user_app/features/setting/widgets/language_select_bottomsheet.dart';
import 'package:ride_sharing_user_app/localization/localization_controller.dart';
import 'package:ride_sharing_user_app/theme/theme_controller.dart';
import 'package:ride_sharing_user_app/util/app_constants.dart';
import 'package:ride_sharing_user_app/util/dimensions.dart';
import 'package:ride_sharing_user_app/util/images.dart';
import 'package:ride_sharing_user_app/util/styles.dart';
import 'package:ride_sharing_user_app/features/setting/controllers/setting_controller.dart';
import 'package:ride_sharing_user_app/common_widgets/app_bar_widget.dart';
import 'package:ride_sharing_user_app/common_widgets/confirmation_bottomsheet_widget.dart';
import 'package:ride_sharing_user_app/features/auth/controllers/auth_controller.dart';
import 'package:ride_sharing_user_app/features/splash/controllers/splash_controller.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  Widget _settingLinkTile({
    required BuildContext context,
    required String icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Dimensions.paddingSize),
        border: Border.all(color: Theme.of(context).hintColor, width: .5),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Dimensions.paddingSizeDefault,
            vertical: Dimensions.paddingSizeDefault,
          ),
          child: Row(children: [
            SizedBox(
              width: Dimensions.iconSizeLarge,
              child: Image.asset(
                icon,
                color: iconColor ?? Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(width: Dimensions.paddingSizeDefault),
            Expanded(
              child: Text(
                title.tr,
                style: textSemiBold.copyWith(
                  color: textColor ??
                      Theme.of(context).textTheme.bodyMedium!.color,
                  fontSize: Dimensions.fontSizeLarge,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios_outlined,
                size: Dimensions.fontSizeDefault),
          ]),
        ),
      ),
    );
  }

  @override
  void initState() {
    Get.find<LocalizationController>().setInitialIndex();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    String languageName = '';
    AppConstants.languages.any((element) {
      if (element.languageCode ==
          Get.find<LocalizationController>().locale.languageCode) {
        languageName = element.languageName;
        return true;
      }
      return false;
    });
    return SafeArea(
      top: false,
      child: Scaffold(
        appBar: AppBarWidget(title: 'setting'.tr, regularAppbar: true),
        body: GetBuilder<SettingController>(builder: (settingController) {
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Dimensions.paddingSizeSmall,
                vertical: Dimensions.paddingSizeLarge,
              ),
              child: Column(children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Dimensions.paddingSizeDefault,
                    vertical: Dimensions.paddingSize,
                  ),
                  decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(Dimensions.paddingSize),
                      border: Border.all(
                          color: Theme.of(context).hintColor, width: .5)),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(children: [
                          CustomAssetImageWidget(Images.languageSetting,
                              color: Theme.of(context).primaryColor),
                          const SizedBox(width: Dimensions.paddingSizeLarge),
                          Text('language'.tr,
                              style: textRegular.copyWith(
                                fontSize: Dimensions.fontSizeLarge,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyMedium!
                                    .color,
                              )),
                        ]),
                        InkWell(
                          onTap: () {
                            showModalBottomSheet(
                              isDismissible: false,
                              enableDrag: false,
                              backgroundColor: Theme.of(context).cardColor,
                              context: context,
                              builder: (context) {
                                return const LanguageSelectBottomSheet();
                              },
                            );
                          },
                          child: Row(children: [
                            Text(languageName,
                                style: textRegular.copyWith(
                                    fontSize: Dimensions.fontSizeLarge)),
                            const SizedBox(
                              width: Dimensions.paddingSizeExtraSmall,
                            ),
                            Icon(
                              Icons.arrow_forward_ios_outlined,
                              size: Dimensions.fontSizeLarge,
                            )
                          ]),
                        ),
                      ]),
                ),
                const SizedBox(height: Dimensions.paddingSize),
                _settingLinkTile(
                  context: context,
                  icon: Images.privacyPolicy,
                  title: 'privacy_policy',
                  onTap: () => Get.to(() => PolicyViewerScreen(
                        htmlType: HtmlType.privacyPolicy,
                        image: Get.find<SplashController>()
                                .config
                                ?.privacyPolicy
                                ?.image ??
                            '',
                      )),
                ),
                const SizedBox(height: Dimensions.paddingSize),
                _settingLinkTile(
                  context: context,
                  icon: Images.termsAndCondition,
                  title: 'terms_and_condition',
                  onTap: () => Get.to(() => PolicyViewerScreen(
                        htmlType: HtmlType.termsAndConditions,
                        image: Get.find<SplashController>()
                                .config
                                ?.termsAndConditions
                                ?.image ??
                            '',
                      )),
                ),
                // const SizedBox(height: Dimensions.paddingSize),
                // _settingLinkTile(
                //   context: context,
                //   icon: Images.termsAndCondition,
                //   title: 'refund_policy',
                //   onTap: () => Get.to(() => PolicyViewerScreen(
                //         htmlType: HtmlType.refundPolicy,
                //         image: Get.find<SplashController>()
                //                 .config
                //                 ?.refundPolicy
                //                 ?.image ??
                //             '',
                //       )),
                // ),
                const SizedBox(height: Dimensions.paddingSize),
                _settingLinkTile(
                  context: context,
                  icon: Images.privacyPolicy,
                  title: 'legal',
                  onTap: () => Get.to(() => PolicyViewerScreen(
                        htmlType: HtmlType.legal,
                        image:
                            Get.find<SplashController>().config?.legal?.image ??
                                '',
                      )),
                ),
                const SizedBox(height: Dimensions.paddingSize),
                _settingLinkTile(
                  context: context,
                  icon: Images.logOutIcon,
                  title: 'logout',
                  onTap: () {
                    Get.bottomSheet(
                      GetBuilder<AuthController>(builder: (authController) {
                        return ConfirmationBottomsheetWidget(
                          icon: Images.exitIcon,
                          iconColor: Theme.of(context).cardColor,
                          isLoading: authController.logging,
                          title: 'logout'.tr,
                          description: 'do_you_want_to_log_out_this_account'.tr,
                          onYesPressed: () => authController.logOut(),
                          onNoPressed: () => Get.back(),
                        );
                      }),
                    );
                  },
                  iconColor: Colors.black.withValues(alpha: 0.7),
                  textColor: Colors.black.withValues(alpha: 0.7),
                ),
                const SizedBox(height: Dimensions.paddingSize),
                Container(
                  decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(Dimensions.paddingSize),
                      border: Border.all(
                          color: Theme.of(context).hintColor, width: .5)),
                  child: Row(children: [
                    Expanded(
                        child: ListTile(
                      title: Text('theme'.tr,
                          style: textRegular.copyWith(
                            color:
                                Theme.of(context).textTheme.bodyMedium!.color,
                          )),
                      leading: CustomAssetImageWidget(Images.themeLogo,
                          width: 20, color: Theme.of(context).primaryColor),
                    )),
                    GetBuilder<ThemeController>(builder: (themeController) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FlutterSwitch(
                          value: themeController.darkTheme,
                          onToggle: (value) {
                            themeController.changeThemeSetting(value);
                          },
                          width: 60,
                          height: 30,
                          activeIcon: Image.asset(Images.darkThemeIcon,
                              color: Theme.of(context).primaryColor),
                          activeToggleColor: Theme.of(context).cardColor,
                          inactiveToggleColor: Theme.of(context).cardColor,
                          inactiveIcon: Image.asset(Images.lightThemeIcon,
                              color: Theme.of(context).primaryColor,
                              height: 60,
                              width: 60,
                              scale: 0.5),
                          inactiveColor: Colors.grey.withValues(alpha: 0.25),
                          activeColor: Theme.of(context)
                              .primaryColor
                              .withValues(alpha: 0.25),
                        ),
                      );
                    })
                  ]),
                ),
                const SizedBox(height: Dimensions.paddingSize),
                // Masque temporairement le bouton de suppression definitive du compte.
                // Container(
                //   decoration: BoxDecoration(
                //       borderRadius:
                //           BorderRadius.circular(Dimensions.paddingSize),
                //       border: Border.all(
                //           color: Theme.of(context).hintColor, width: .5)),
                //   child: InkWell(
                //     onTap: () {
                //       Get.bottomSheet(
                //           GetBuilder<AuthController>(builder: (authController) {
                //         return ConfirmationBottomsheetWidget(
                //           icon: Images.logOutIcon,
                //           isLoading: authController.logging,
                //           title: 'permanently_delete_account'.tr,
                //           description:
                //               'do_you_want_to_delete_this_account_permanently'
                //                   .tr,
                //           onYesPressed: () => authController.permanentDelete(),
                //           onNoPressed: () => Get.back(),
                //           fontSize: Dimensions.fontSizeLarge,
                //           color: Colors.black.withValues(alpha: 0.7),
                //         );
                //       }));
                //     },
                //     child: Padding(
                //       padding: const EdgeInsets.symmetric(
                //           horizontal: Dimensions.paddingSizeDefault,
                //           vertical: Dimensions.paddingSizeDefault),
                //       child: Row(children: [
                //         SizedBox(
                //           width: Dimensions.iconSizeLarge,
                //           child: Image.asset(Images.logOutIcon,
                //               color: Colors.black.withValues(alpha: 0.7)),
                //         ),
                //         const SizedBox(width: Dimensions.paddingSizeDefault),
                //         Expanded(
                //           child: Text(
                //             'permanently_delete_account'.tr,
                //             maxLines: 1,
                //             overflow: TextOverflow.ellipsis,
                //             style: textSemiBold.copyWith(
                //               color: Colors.black.withValues(alpha: 0.7),
                //               fontSize: Dimensions.fontSizeLarge,
                //             ),
                //           ),
                //         ),
                //       ]),
                //     ),
                //   ),
                // ),
              ]),
            ),
          );
        }),
      ),
    );
  }
}
