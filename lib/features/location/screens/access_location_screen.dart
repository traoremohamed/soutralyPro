import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/common_widgets/app_bar_widget.dart';
import 'package:ride_sharing_user_app/features/out_of_zone/controllers/out_of_zone_controller.dart';
import 'package:ride_sharing_user_app/util/dimensions.dart';
import 'package:ride_sharing_user_app/util/images.dart';
import 'package:ride_sharing_user_app/util/styles.dart';
import 'package:ride_sharing_user_app/features/auth/controllers/auth_controller.dart';
import 'package:ride_sharing_user_app/features/auth/screens/sign_in_screen.dart';
import 'package:ride_sharing_user_app/features/dashboard/controllers/bottom_menu_controller.dart';
import 'package:ride_sharing_user_app/features/dashboard/screens/dashboard_screen.dart';
import 'package:ride_sharing_user_app/features/location/controllers/location_controller.dart';
import 'package:ride_sharing_user_app/common_widgets/button_widget.dart';
import 'package:ride_sharing_user_app/common_widgets/loader_widget.dart';

class AccessLocationScreen extends StatefulWidget {
  const AccessLocationScreen({super.key});

  @override
  State<AccessLocationScreen> createState() => _AccessLocationScreenState();
}

class _AccessLocationScreenState extends State<AccessLocationScreen> {
  @override
  void initState() {
    super.initState();
    _requestNotificationPermission();
  }

  Future<void> _requestNotificationPermission() async {
    await FirebaseMessaging.instance.requestPermission();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Scaffold(
          body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (res, val) async {
          Get.find<BottomMenuController>().exitApp();
          return;
        },
        child: Column(
          children: [
            AppBarWidget(title: 'set_location'.tr, showBackButton: false),
            Expanded(
              child: Center(
                child: GetBuilder<LocationController>(
                    builder: (locationController) {
                  return SizedBox(
                    width: 700,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(Images.mapLocationIcon, height: 240),
                          const SizedBox(height: Dimensions.paddingSizeSmall),
                          Text(
                            'find_customer_near_you'.tr,
                            textAlign: TextAlign.center,
                            style: textMedium.copyWith(
                              fontSize: Dimensions.fontSizeExtraLarge,
                              color: Get.isDarkMode
                                  ? Theme.of(context).primaryColorLight
                                  : Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(
                                Dimensions.paddingSizeLarge),
                            child: Text(
                              'please_select_you_location_to_start_finding_available_customer_near_you'
                                  .tr,
                              textAlign: TextAlign.center,
                              style: textRegular.copyWith(
                                fontSize: Dimensions.fontSizeSmall,
                                color: Get.isDarkMode
                                    ? Theme.of(context).primaryColorLight
                                    : Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: Dimensions.paddingSizeLarge),
                          const BottomButton(),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      )),
    );
  }
}

class BottomButton extends StatelessWidget {
  const BottomButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: MediaQuery.of(context).size.width - 40,
        child: Column(
          children: [
            ButtonWidget(
              buttonText: 'use_current_location'.tr,
              fontSize: Dimensions.fontSizeSmall,
              onPressed: () async {
                final permissionGranted =
                    await Get.find<LocationController>().checkPermission();
                if (permissionGranted) {
                  Get.dialog(const LoaderWidget(), barrierDismissible: false);
                  Get.find<LocationController>()
                      .getCurrentLocation()
                      .then((value) {
                    Get.back();
                    if (value.latitude != 0 && value.longitude != 0) {
                      if (Get.find<AuthController>().isLoggedIn()) {
                        Get.find<OutOfZoneController>().getZoneList();
                        Get.offAll(() => const DashboardScreen());
                      } else {
                        Get.offAll(() => const SignInScreen());
                      }
                    }
                  });
                }
              },
              icon: Icons.my_location,
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),
          ],
        ),
      ),
    );
  }
}
