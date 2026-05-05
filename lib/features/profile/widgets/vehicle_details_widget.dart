import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/common_widgets/button_widget.dart';
import 'package:ride_sharing_user_app/features/home/screens/vehicle_add_screen.dart';
import 'package:ride_sharing_user_app/features/profile/controllers/profile_controller.dart';
import 'package:ride_sharing_user_app/features/profile/widgets/profile_item_widget.dart';
import 'package:ride_sharing_user_app/features/splash/controllers/splash_controller.dart';
import 'package:ride_sharing_user_app/helper/date_converter.dart';
import 'package:ride_sharing_user_app/util/dimensions.dart';
import 'package:ride_sharing_user_app/util/images.dart';
import 'package:ride_sharing_user_app/util/styles.dart';

class VehicleDetailsWidget extends StatelessWidget {
  const VehicleDetailsWidget({super.key});

  String _safeDateLabel(String? rawDate) {
    if (rawDate == null || rawDate.trim().isEmpty) {
      return '--';
    }
    try {
      return DateConverter.isoStringToLocalDateOnly(rawDate);
    } catch (_) {
      return '--';
    }
  }

  String _categoryNames(ProfileController profileController) {
    final vehicle = profileController.profileInfo?.vehicle;
    final List<String> categoryIds = vehicle?.categoryIds ?? <String>[];

    if (categoryIds.isNotEmpty && profileController.categoryList.isNotEmpty) {
      final List<String> names = profileController.categoryList
          .where((category) =>
              category.id != null && categoryIds.contains(category.id))
          .map((category) => category.name?.tr ?? '')
          .where((name) => name.isNotEmpty)
          .toList();

      if (names.isNotEmpty) {
        return names.join(', ');
      }
    }

    return vehicle?.category?.name?.tr ?? '--';
  }

  String _documentStatus(String? recto, String? verso) {
    final bool hasRecto = recto != null && recto.trim().isNotEmpty;
    final bool hasVerso = verso != null && verso.trim().isNotEmpty;

    if (hasRecto && hasVerso) {
      return 'Recto / verso fournis';
    }
    if (hasRecto || hasVerso) {
      return 'Document fourni';
    }
    return '--';
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProfileController>(builder: (profileController) {
      return profileController.profileInfo!.vehicle != null
          ? Container(
              padding: EdgeInsets.all(Dimensions.paddingSizeDefault),
              decoration: BoxDecoration(
                  color:
                      Theme.of(context).highlightColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.all(
                      Radius.circular(Dimensions.radiusDefault))),
              child: Column(children: [
                ProfileItemWidget(
                  title: 'vehicle_category_type',
                  value: profileController
                      .profileInfo!.vehicle!.category!.type!.tr,
                ),
                ProfileItemWidget(
                  title: 'vehicle_category',
                  value: _categoryNames(profileController),
                ),
                ProfileItemWidget(
                  title: 'vehicle_brand',
                  value:
                      profileController.profileInfo?.vehicle?.brand?.name ?? '',
                ),
                ProfileItemWidget(
                  title: 'vehicle_model',
                  value:
                      profileController.profileInfo?.vehicle?.model?.name ?? '',
                ),
                if (_isShowParcelWeight(
                    profileController.profileInfo?.details?.services))
                  ProfileItemWidget(
                    title: 'parcel_weight_capacity',
                    value:
                        '${profileController.profileInfo?.vehicle?.parcelWeightCapacity ?? 'unlimited'.tr} ${Get.find<SplashController>().config?.parcelWeightUnit}',
                  ),
                ProfileItemWidget(
                  title: 'IMMATRICULATION',
                  value: profileController
                          .profileInfo?.vehicle?.licencePlateNumber ??
                      '',
                ),
                ProfileItemWidget(
                  title: 'DATE D’EXPIRATION DU PERMIS DE CONDUIRE',
                  value: _safeDateLabel(
                    profileController.profileInfo?.vehicle?.licenceExpireDate,
                  ),
                ),
                ProfileItemWidget(
                  title: 'COULEUR DE LA VOITURE',
                  value: profileController.profileInfo?.vehicle?.vehicleColor ??
                      '--',
                ),
                ProfileItemWidget(
                  title: 'CARTE GRISE',
                  value: _documentStatus(
                    profileController.profileInfo?.vehicle?.registrationCard,
                    profileController
                        .profileInfo?.vehicle?.registrationCardBack,
                  ),
                ),
                ProfileItemWidget(
                  title: 'VISITE TECHNIQUE',
                  value: _documentStatus(
                    profileController
                        .profileInfo?.vehicle?.technicalInspectionDocument,
                    profileController
                        .profileInfo?.vehicle?.technicalInspectionDocumentBack,
                  ),
                ),
                ProfileItemWidget(
                  title: 'DATE D’EXPIRATION VISITE TECHNIQUE',
                  value: _safeDateLabel(profileController
                      .profileInfo?.vehicle?.technicalInspectionExpiryDate),
                ),
                ProfileItemWidget(
                  title: 'ASSURANCE',
                  value: _documentStatus(
                    profileController.profileInfo?.vehicle?.insuranceDocument,
                    profileController
                        .profileInfo?.vehicle?.insuranceDocumentBack,
                  ),
                ),
                ProfileItemWidget(
                  title: 'DATE D’EXPIRATION ASSURANCE',
                  value: _safeDateLabel(
                    profileController.profileInfo?.vehicle?.insuranceExpiryDate,
                  ),
                ),
                ProfileItemWidget(
                  title: 'PATENTE',
                  value: _documentStatus(
                    profileController.profileInfo?.vehicle?.patenteDocument,
                    profileController.profileInfo?.vehicle?.patenteDocumentBack,
                  ),
                ),
                ProfileItemWidget(
                  title: 'DATE D’EXPIRATION PATENTE',
                  value: _safeDateLabel(
                    profileController.profileInfo?.vehicle?.patenteExpiryDate,
                  ),
                ),
                const SizedBox(height: Dimensions.paddingSizeDefault),
                _pricingSection(profileController, context),
              ]),
            )
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50),
              child: Column(children: [
                Image.asset(
                  Images.noVehicleFound,
                  height: Get.height * 0.3,
                  width: Get.width * 0.7,
                ),
                Text('ready_to_drive'.tr,
                    style: textBold, textAlign: TextAlign.center),
                const SizedBox(height: Dimensions.paddingSizeDefault),
                Text(
                  'you_have_allmost_ready'.tr,
                  textAlign: TextAlign.center,
                  style:
                      textRegular.copyWith(color: Theme.of(context).hintColor),
                ),
                const SizedBox(height: Dimensions.paddingSizeDefault),
                ButtonWidget(
                    width: 150,
                    buttonText: 'add_vehicle'.tr,
                    onPressed: () => Get.to(() => const VehicleAddScreen()))
              ]),
            );
    });
  }

  Widget _pricingSection(
      ProfileController profileController, BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'BRANDING',
            style: textBold.copyWith(fontSize: Dimensions.fontSizeDefault),
          ),
          const SizedBox(height: Dimensions.paddingSizeExtraSmall),
          Text(
            'Option de branding',
            style: textRegular.copyWith(color: Theme.of(context).primaryColor),
          ),
          const SizedBox(height: Dimensions.paddingSizeExtraSmall),
          Text(
            'Cout du branding: 5000 FCFA',
            style: textMedium.copyWith(
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
        ],
      ),
    );
  }

  bool _isShowParcelWeight(List<String>? services) {
    if (services == null) {
      return false;
    } else {
      if (services.contains('parcel')) {
        return true;
      } else {
        return false;
      }
    }
  }
}
