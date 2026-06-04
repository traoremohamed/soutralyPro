import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/common_widgets/button_widget.dart';
import 'package:ride_sharing_user_app/features/safety_setup/controllers/safety_alert_controller.dart';
import 'package:ride_sharing_user_app/features/safety_setup/widgets/safety_alert_bottomsheet_widget.dart';
import 'package:ride_sharing_user_app/features/ride/controllers/ride_controller.dart';
import 'package:ride_sharing_user_app/features/splash/controllers/splash_controller.dart';
import 'package:ride_sharing_user_app/util/dimensions.dart';
import 'package:ride_sharing_user_app/util/images.dart';
import 'package:ride_sharing_user_app/util/styles.dart';
import 'package:url_launcher/url_launcher.dart';

class SafetyAlertContentWidget extends StatelessWidget {
  const SafetyAlertContentWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SafetyAlertController>(builder: (safetyAlertController) {
      return Column(spacing: Dimensions.paddingSizeSmall, children: [
        Image.asset(Images.safelyShieldIcon3, height: 70, width: 70),
        Text('trip_safety'.tr, style: textBold),
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: Dimensions.paddingSizeExtraLarge),
          child: Text('hey_there_do_you_feel_unsafe'.tr,
              style: textRegular.copyWith(fontSize: Dimensions.fontSizeSmall),
              textAlign: TextAlign.center),
        ),
        safetyAlertController.isStoring
            ? SpinKitCircle(color: Theme.of(context).primaryColor, size: 40.0)
            : ButtonWidget(
                margin: EdgeInsets.symmetric(
                    horizontal: Dimensions.paddingSizeExtraLarge),
                buttonText: 'send_safety_alert'.tr,
                onPressed: () {
                  safetyAlertController.storeSafetyAlert('').then((value) {
                    if (value) {
                      Get.back();
                      Get.find<RideController>().showSafetyAlertTooltip();
                      Get.find<SafetyAlertController>().updateSafetyAlertState(
                          SafetyAlertState.afterSendAlert,
                          isUpdate: false);
                      Get.showSnackbar(GetSnackBar(
                        dismissDirection: DismissDirection.horizontal,
                        isDismissible: false,
                        duration: Duration(seconds: 15),
                        backgroundColor: Get.isDarkMode
                            ? Colors.white
                            : Theme.of(Get.context!)
                                .textTheme
                                .titleMedium!
                                .color!,
                        messageText: GetBuilder<SafetyAlertController>(
                            builder: (safetyAlertController) {
                          return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${'safety_alert_send_to'.tr} ${Get.find<SplashController>().config?.businessName}',
                                  style: textMedium.copyWith(
                                      color: Get.isDarkMode
                                          ? Theme.of(Get.context!)
                                              .textTheme
                                              .titleMedium!
                                              .color
                                          : Colors.white,
                                      fontSize: Dimensions.fontSizeSmall),
                                ),
                                Row(
                                    spacing: Dimensions.paddingSizeSmall,
                                    children: [
                                      InkWell(
                                        onTap: () {
                                          Get.back();
                                          Get.bottomSheet(
                                            isScrollControlled: true,
                                            const SafetyAlertBottomSheetWidget(),
                                            backgroundColor:
                                                Theme.of(Get.context!)
                                                    .cardColor,
                                            isDismissible: false,
                                          );
                                        },
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                              vertical: Dimensions
                                                  .paddingSizeExtraSmall,
                                              horizontal:
                                                  Dimensions.paddingSizeSmall),
                                          decoration: BoxDecoration(
                                            color: Theme.of(Get.context!)
                                                .cardColor,
                                            borderRadius: BorderRadius.circular(
                                                Dimensions.paddingSizeSmall),
                                          ),
                                          child: Text('view'.tr,
                                              style: textRegular.copyWith(
                                                  fontSize: Dimensions
                                                      .fontSizeSmall)),
                                        ),
                                      ),
                                      safetyAlertController.isLoading
                                          ? CircularProgressIndicator(
                                              color: Theme.of(Get.context!)
                                                  .primaryColor)
                                          : InkWell(
                                              onTap: () => safetyAlertController
                                                  .undoSafetyAlert(),
                                              child: Container(
                                                padding: EdgeInsets.symmetric(
                                                    vertical: Dimensions
                                                        .paddingSizeExtraSmall,
                                                    horizontal: Dimensions
                                                        .paddingSizeSmall),
                                                decoration: BoxDecoration(
                                                  border: Border.all(
                                                      color:
                                                          Theme.of(Get.context!)
                                                              .cardColor),
                                                  borderRadius: BorderRadius
                                                      .circular(Dimensions
                                                          .paddingSizeSmall),
                                                ),
                                                child: Text('undo'.tr,
                                                    style: textRegular.copyWith(
                                                        fontSize: Dimensions
                                                            .fontSizeSmall,
                                                        color: Theme.of(
                                                                Get.context!)
                                                            .cardColor)),
                                              ),
                                            ),
                                    ]),
                              ]);
                        }),
                      ));
                    }
                  });
                },
              ),
        if (Get.find<SplashController>()
                .config
                ?.safetyFeatureEmergencyGovtNumber !=
            null)
          ButtonWidget(
            margin: EdgeInsets.symmetric(
                horizontal: Dimensions.paddingSizeExtraLarge),
            backgroundColor: Theme.of(context).cardColor,
            borderColor: Theme.of(context).primaryColor,
            showBorder: true,
            textColor: Theme.of(context).textTheme.bodyMedium!.color,
            buttonText:
                '${'call_emergency'.tr} (${Get.find<SplashController>().config?.safetyFeatureEmergencyGovtNumber})',
            onPressed: () {
              launchUrl(Uri.parse(
                  "tel: ${Get.find<SplashController>().config?.safetyFeatureEmergencyGovtNumber}"));
            },
          ),
        safetyAlertController.otherEmergencyNumberModel?.data != null &&
                (safetyAlertController
                        .otherEmergencyNumberModel?.data?.isNotEmpty ??
                    false)
            ? InkWell(
                onTap: () => Get.find<SafetyAlertController>()
                    .updateSafetyAlertState(SafetyAlertState.otherNumberState),
                child: Text(
                  'other_emergency_numbers'.tr,
                  style: textRegular.copyWith(
                    decoration: TextDecoration.underline,
                    decorationColor:
                        Theme.of(context).colorScheme.surfaceContainer,
                    color: Theme.of(context).colorScheme.surfaceContainer,
                  ),
                ),
              )
            : const SizedBox(),
        const SizedBox(height: Dimensions.paddingSizeSmall),
      ]);
    });
  }
}
