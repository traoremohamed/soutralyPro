import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/features/profile/controllers/profile_controller.dart';
import 'package:ride_sharing_user_app/helper/display_helper.dart';
import 'package:ride_sharing_user_app/helper/price_converter.dart';
import 'package:ride_sharing_user_app/util/dimensions.dart';
import 'package:ride_sharing_user_app/util/styles.dart';

class RechargeBottomSheetWidget extends StatefulWidget {
  const RechargeBottomSheetWidget({super.key});

  @override
  State<RechargeBottomSheetWidget> createState() =>
      _RechargeBottomSheetWidgetState();
}

class _RechargeBottomSheetWidgetState extends State<RechargeBottomSheetWidget> {
  bool isForfait = true;
  // when forfait: select specific categories and number of days
  Set<String> selectedCategoryIds = {};
  String? selectedPlanKey;
  int days = 1;
  final TextEditingController daysController = TextEditingController(text: '1');

  @override
  Widget build(BuildContext context) {
    final profile = Get.find<ProfileController>();
    if (profile.categoryList.isEmpty) {
      profile.getCategoryList(1);
    }

    // allowed category ids come from pricingVehicleCategoryIds if provided,
    // otherwise from the vehicle categories that driver selected when adding the vehicle
    final List<String> allowedCategoryIds =
        profile.pricingVehicleCategoryIds.isNotEmpty
            ? profile.pricingVehicleCategoryIds
            : (profile.profileInfo?.vehicle?.categoryIds ?? <String>[]);

    double sumSelectedCategoriesMontant() {
      double sum = 0;
      for (final cat in profile.categoryList) {
        if (cat.id != null &&
            selectedCategoryIds.contains(cat.id) &&
            allowedCategoryIds.contains(cat.id)) {
          sum += cat.montant ?? 0;
        }
      }
      return sum;
    }

    double computedAmount =
        isForfait ? (sumSelectedCategoriesMontant() * days) : 0;

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Souscription wallet', style: textBold.copyWith(fontSize: 16)),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          Row(children: [
            Expanded(
                child: ListTile(
              title: Text('forfait'.tr),
              leading: Radio<bool>(
                  value: true,
                  groupValue: isForfait,
                  onChanged: (v) {
                    setState(() => isForfait = true);
                  }),
            )),
            Expanded(
                child: ListTile(
              title: Text('commission'.tr),
              leading: Radio<bool>(
                  value: false,
                  groupValue: isForfait,
                  onChanged: (v) {
                    setState(() => isForfait = false);
                  }),
            )),
          ]),
          if (isForfait) ...[
            // Plan presets dropdown (préselection de catégories recommandées)
            const SizedBox(height: Dimensions.paddingSizeSmall),
            Row(children: [
              Expanded(
                child: InputDecorator(
                  decoration: InputDecoration(labelText: 'plan'.tr),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      isExpanded: true,
                      value: selectedPlanKey,
                      hint: Text('choose_plan'.tr),
                      items: <DropdownMenuItem<String?>>[
                        const DropdownMenuItem(
                            value: null,
                            child: Text(
                                'Veuillez selectionnez le type de forfait')),
                        const DropdownMenuItem(
                            value: 'eco', child: Text('Gbonhi')),
                        DropdownMenuItem(
                            value: 'eco_confort', child: Text('Choco')),
                        const DropdownMenuItem(
                            value: 'eco_confort_premium',
                            child: Text('Fariman')),
                      ],
                      onChanged: (val) {
                        setState(() {
                          selectedPlanKey = val;
                          if (val != null) {
                            final recommended = Get.find<ProfileController>()
                                .resolvePlanCategoriesPublic(val);
                            selectedCategoryIds = Set<String>.from(recommended
                                .where((id) => allowedCategoryIds.contains(id))
                                .toList());
                          } else {
                            selectedCategoryIds.clear();
                          }
                        });
                      },
                    ),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: profile.categoryList
                  .where(
                      (c) => c.id != null && allowedCategoryIds.contains(c.id))
                  .map((cat) {
                final bool isSelected = selectedCategoryIds.contains(cat.id);
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: Dimensions.paddingSizeSmall,
                      vertical: Dimensions.paddingSizeExtraSmall),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).primaryColor.withValues(alpha: 0.16)
                        : Theme.of(context).hintColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : Theme.of(context).hintColor.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Text(
                    '${cat.name ?? ''} (${(cat.montant ?? 0).toStringAsFixed(0)})',
                    style: textRegular.copyWith(
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            Row(children: [
              Expanded(
                child: TextField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'days'.tr),
                  controller: daysController,
                  onChanged: (v) {
                    setState(() => days = int.tryParse(v) ?? 1);
                  },
                ),
              ),
            ]),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
              decoration: BoxDecoration(
                color: Theme.of(context).hintColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'En mode commission, la commission sera deduite du wallet a chaque course (si aucun forfait actif).',
                style: textRegular,
              ),
            ),
          ],
          const SizedBox(height: Dimensions.paddingSizeSmall),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('${'total'.tr}:', style: textBold),
            Text(PriceConverter.convertPrice(context, computedAmount),
                style: textBold),
          ]),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                  onPressed: () async {
                    if (isForfait) {
                      if (selectedCategoryIds.isEmpty) {
                        Get.snackbar(
                            '', 'Veuillez selectionnez le type de forfait',
                            backgroundColor: Colors.red,
                            colorText: Colors.white);
                        return;
                      }
                      final int useDays = days < 1 ? 1 : days;
                      final double requiredAmount =
                          sumSelectedCategoriesMontant() * useDays;
                      final double walletBalance =
                          profile.profileInfo?.wallet?.walletBalance ?? 0;
                      if (walletBalance < requiredAmount) {
                        showCustomSnackBar('Solde wallet insuffisant');
                        return;
                      }
                      final bool subscriptionSucceeded =
                          await profile.purchaseForfaitWithCategories(
                              selectedCategoryIds.toList(),
                              days: useDays);
                      if (!subscriptionSucceeded) {
                        return;
                      }
                      Navigator.of(context).pop();
                      // show receipt / confirmation using updated profile values
                      final double amountPaid =
                          sumSelectedCategoriesMontant() * useDays;
                      final List<String> categoryNames = profile.categoryList
                          .where((c) =>
                              c.id != null &&
                              selectedCategoryIds.contains(c.id))
                          .map((c) => c.name ?? '')
                          .toList();

                      Get.dialog(AlertDialog(
                        title: Text('receipt'.tr),
                        content:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                          Row(children: [
                            Text('${'total'.tr}: '),
                            Text(PriceConverter.convertPrice(
                                context, amountPaid))
                          ]),
                          Row(children: [
                            Text('${'days'.tr}: '),
                            Text('$useDays')
                          ]),
                          const SizedBox(height: 8),
                          Align(
                              alignment: Alignment.centerLeft,
                              child: Text('${'categories'.tr}:')),
                          ...categoryNames.map((n) => Align(
                              alignment: Alignment.centerLeft,
                              child: Text(' - $n'))),
                          const SizedBox(height: 8),
                          if (profile.forfaitExpiresAt != null)
                            Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                    '${'expires_at'.tr}: ${profile.forfaitExpiresAt}')),
                        ]),
                        actions: [
                          TextButton(
                              onPressed: () => Get.back(), child: Text('ok'.tr))
                        ],
                      ));
                    } else {
                      await profile.selectCommissionMode();
                      if (profile.driverPricingMode == 'commission') {
                        Get.back();
                        Get.snackbar('success'.tr, 'Mode commission active');
                      }
                    }
                  },
                  child: Text(
                      isForfait ? 'Souscrire forfait' : 'Activer commission'))),
          const SizedBox(height: Dimensions.paddingSizeSmall),
        ]),
      ),
    );
  }
}
