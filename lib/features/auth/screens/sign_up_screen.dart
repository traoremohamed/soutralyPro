import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/common_widgets/button_widget.dart';
import 'package:ride_sharing_user_app/features/auth/controllers/auth_controller.dart';
import 'package:ride_sharing_user_app/features/auth/screens/additional_sign_up_screen_1.dart';
import 'package:ride_sharing_user_app/features/auth/widgets/signup_appbar_widget.dart';
import 'package:ride_sharing_user_app/helper/display_helper.dart';
import 'package:ride_sharing_user_app/helper/svg_image_helper.dart';
import 'package:ride_sharing_user_app/util/dimensions.dart';
import 'package:ride_sharing_user_app/util/images.dart';
import 'package:ride_sharing_user_app/util/styles.dart';

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
          backgroundColor: Theme.of(context).cardColor,
          body: GetBuilder<AuthController>(builder: (authController) {
            return Column(children: [
              const SignUpAppbarWidget(
                  enableBackButton: true,
                  title: 'signup_as_a_driver',
                  progressText: '1_of_3'),
              const SizedBox(height: Dimensions.paddingSizeSignUp),
              Expanded(
                child: SingleChildScrollView(
                    child: Column(children: [
                  SvgPicture.asset(Images.logoWithNameSvg, height: 40),
                  const SizedBox(height: Dimensions.paddingSizeSignUp),

                  FutureBuilder<String>(
                      future: loadSvgAndChangeColors(Images.signUpScreenLogoSvg,
                          Theme.of(context).primaryColor),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.done &&
                            snapshot.hasData) {
                          return SvgPicture.string(snapshot.data!);
                        }
                        return SvgPicture.asset(Images.signUpScreenLogoSvg);
                      }),
                  const SizedBox(height: Dimensions.paddingSizeSignUp),

                  Text('choose_service'.tr,
                      style: textBold.copyWith(fontSize: 22)),
                  const SizedBox(height: Dimensions.paddingSizeSmall),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 50),
                    child: Text(
                      'select_your_preferable_service'.tr,
                      style: textRegular.copyWith(
                          fontSize: Dimensions.fontSizeSmall),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: Dimensions.paddingSizeSignUp),

                  // Dynamic categorie_driver checkboxes
                  if (authController.categorieDrivers.isEmpty)
                    const SizedBox.shrink()
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: Dimensions.paddingSizeLarge),
                      child: Column(
                        children: authController.categorieDrivers.map((cat) {
                          final code =
                              (cat.codeCategDriver ?? '').toUpperCase();
                          String label = 'Vous êtes';
                          if (code == 'PART')
                            label = 'Vous êtes partenaire';
                          else if (code == 'DRIVER')
                            label = 'Vous êtes chauffeur';
                          else if (code == 'LIVREUR')
                            label = 'Vous êtes livreur';
                          final disabled = (authController.categorieDrivers.any((c) =>
                                      (c.codeCategDriver ?? '').toUpperCase() == 'PART' &&
                                      authController.selectedCategorieIds
                                          .contains(c.id)) &&
                                  code != 'PART') ||
                              (code == 'PART' &&
                                  authController.categorieDrivers.any((c) =>
                                      (((c.codeCategDriver ?? '').toUpperCase() ==
                                                  'DRIVER' ||
                                              (c.codeCategDriver ?? '').toUpperCase() ==
                                                  'LIVREUR') &&
                                          authController.selectedCategorieIds
                                              .contains(c.id))));
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(Dimensions.radiusSmall),
                              border: Border.all(
                                  color: disabled
                                      ? Theme.of(context)
                                          .hintColor
                                          .withValues(alpha: 0.3)
                                      : Theme.of(context)
                                          .hintColor
                                          .withValues(alpha: 0.5),
                                  width: 0.5),
                            ),
                            child: Center(
                              child: CheckboxListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: Dimensions.paddingSizeSmall),
                                title: Text(label,
                                    style: textBold.copyWith(
                                        fontSize: 14,
                                        color: authController
                                                .selectedCategorieIds
                                                .contains(cat.id)
                                            ? Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.color
                                            : Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.color
                                                ?.withValues(alpha: 0.7))),
                                value: authController.selectedCategorieIds
                                    .contains(cat.id),
                                onChanged: disabled
                                    ? null
                                    : (_) {
                                        authController.toggleCategorie(
                                            cat.id ?? -1,
                                            cat.codeCategDriver ?? '');
                                      },
                                activeColor: Theme.of(context).primaryColor,
                                checkColor: Colors.white,
                                side: BorderSide(
                                    color: Theme.of(context)
                                        .hintColor
                                        .withValues(alpha: 0.5)),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                ])),
              ),
              Container(
                decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                          color: Theme.of(context)
                              .hintColor
                              .withValues(alpha: 0.15),
                          blurRadius: 10,
                          offset: Offset(0, -4))
                    ],
                    borderRadius: BorderRadius.only(
                        topRight: Radius.circular(Dimensions.paddingSizeLarge),
                        topLeft: Radius.circular(Dimensions.paddingSizeLarge)),
                    color: Theme.of(context).cardColor),
                padding: EdgeInsets.symmetric(
                        vertical: Dimensions.paddingSizeSmall,
                        horizontal: Dimensions.paddingSizeExtraSmall)
                    .copyWith(bottom: Dimensions.paddingSizeExtraLarge),
                child: ButtonWidget(
                  margin: EdgeInsets.symmetric(
                      horizontal: Dimensions.paddingSizeDefault),
                  radius: Dimensions.radiusExtraLarge,
                  buttonText: 'next'.tr,
                  onPressed: () {
                    if (authController.categorieDrivers.isNotEmpty) {
                      if (authController.selectedCategorieIds.isEmpty) {
                        showCustomSnackBar('required_to_select_service'.tr);
                        return;
                      }
                      Get.to(() => const AdditionalSignUpScreen1());
                    } else {
                      if (!authController.isRideShare &&
                          !authController.isParcelShare) {
                        showCustomSnackBar('required_to_select_service'.tr);
                      } else {
                        Get.to(() => const AdditionalSignUpScreen1());
                      }
                    }
                  },
                ),
              ),
            ]);
          })),
    );
  }
}
