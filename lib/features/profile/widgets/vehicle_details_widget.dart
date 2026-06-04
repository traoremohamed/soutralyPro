import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/common_widgets/button_widget.dart';
import 'package:ride_sharing_user_app/features/home/screens/vehicle_add_screen.dart';
import 'package:ride_sharing_user_app/features/profile/controllers/profile_controller.dart';
import 'package:ride_sharing_user_app/features/profile/widgets/profile_item_widget.dart';
import 'package:ride_sharing_user_app/helper/date_converter.dart';
import 'package:ride_sharing_user_app/helper/dynamic_translation_helper.dart';
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
          .map((category) =>
              DynamicTranslationHelper.translate(category.name, fallback: ''))
          .where((name) => name.isNotEmpty)
          .cast<String>()
          .toList();

      if (names.isNotEmpty) {
        return names.join(', ');
      }
    }

    return DynamicTranslationHelper.translate(vehicle?.category?.name,
        fallback: '--');
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
                  value: DynamicTranslationHelper.translate(
                      profileController.profileInfo!.vehicle!.category!.type),
                ),
                ProfileItemWidget(
                  title: 'vehicle_category',
                  value: _categoryNames(profileController),
                ),
                ProfileItemWidget(
                  title: 'vehicle_brand',
                  value: DynamicTranslationHelper.translate(
                      profileController.profileInfo?.vehicle?.brand?.name),
                ),
                ProfileItemWidget(
                  title: 'vehicle_model',
                  value: DynamicTranslationHelper.translate(
                      profileController.profileInfo?.vehicle?.model?.name),
                ),
                // Masque temporairement la ligne capacite de poids du colis.
                // if (_isShowParcelWeight(
                //     profileController.profileInfo?.details?.services))
                //   ProfileItemWidget(
                //     title: 'parcel_weight_capacity',
                //     value:
                //         '${profileController.profileInfo?.vehicle?.parcelWeightCapacity ?? 'unlimited'.tr} ${Get.find<SplashController>().config?.parcelWeightUnit}',
                //   ),
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
    final bool brandingEnabled = profileController.brandingEnabled;
    final double monthlyAmount = profileController.brandingMonthlyAmount;
    final int selectedMonths = profileController.brandingMonths;
    final double totalAmount = monthlyAmount * selectedMonths;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        border: Border.all(
          color: brandingEnabled
              ? Theme.of(context).primaryColor.withValues(alpha: 0.25)
              : Theme.of(context).hintColor.withValues(alpha: 0.12),
        ),
      ),
      child: Opacity(
        opacity: brandingEnabled ? 1 : 0.55,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Checkbox(
                  value: brandingEnabled,
                  onChanged: (value) {
                    profileController.setBrandingEnabled(value ?? false);
                  },
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Zone branding',
                        style: textBold.copyWith(
                            fontSize: Dimensions.fontSizeDefault),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Activez la visibilité de votre véhicule sur la plateforme.',
                        style: textRegular.copyWith(
                            color: Theme.of(context).hintColor,
                            fontSize: Dimensions.fontSizeSmall),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Get.dialog(
                    AlertDialog(
                      title: const Text('Avantages du branding'),
                      content: const Text(
                        'Le branding améliore la visibilité de votre véhicule, renforce la confiance des clients et peut augmenter vos chances d\'obtenir plus de courses dans les zones actives.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Get.back(),
                          child: const Text('Compris'),
                        ),
                      ],
                    ),
                  ),
                  icon: Icon(
                    Icons.info_outline,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Durée de souscription',
                    style: textMedium.copyWith(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Dimensions.paddingSizeSmall,
                    vertical: Dimensions.paddingSizeExtraSmall,
                  ),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).primaryColor.withValues(alpha: 0.08),
                    borderRadius:
                        BorderRadius.circular(Dimensions.paddingSizeExtraSmall),
                  ),
                  child: Text(
                    '${monthlyAmount.toStringAsFixed(0)} FCFA / mois',
                    style: textBold.copyWith(
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            DropdownButtonFormField<int>(
              initialValue: profileController.brandingAllowedMonths
                      .contains(selectedMonths)
                  ? selectedMonths
                  : profileController.brandingAllowedMonths.isNotEmpty
                      ? profileController.brandingAllowedMonths.first
                      : 3,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.paddingSizeSmall,
                  vertical: Dimensions.paddingSizeSmall,
                ),
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(Dimensions.paddingSizeSmall),
                ),
              ),
              items: profileController.brandingAllowedMonths
                  .map(
                    (month) => DropdownMenuItem<int>(
                      value: month,
                      child: Text('$month mois'),
                    ),
                  )
                  .toList(),
              onChanged: brandingEnabled
                  ? (value) {
                      if (value != null) {
                        profileController.setBrandingMonths(value);
                      }
                    }
                  : null,
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Coût total',
                  style: textMedium.copyWith(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
                Text(
                  '${totalAmount.toStringAsFixed(0)} FCFA',
                  style: textBold.copyWith(
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            ButtonWidget(
              width: Get.width,
              buttonText: 'Enregistrer le branding',
              onPressed: profileController.brandingUpdating
                  ? null
                  : () async {
                      await profileController.submitDriverBranding();
                    },
            ),
          ],
        ),
      ),
    );
  }
}
