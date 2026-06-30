import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/common_widgets/app_bar_widget.dart';
import 'package:ride_sharing_user_app/common_widgets/button_widget.dart';
import 'package:ride_sharing_user_app/features/notification/widgets/notification_shimmer_widget.dart';
import 'package:ride_sharing_user_app/features/safety_setup/controllers/safety_alert_controller.dart';
import 'package:ride_sharing_user_app/features/safety_setup/widgets/safety_alert_bottomsheet_widget.dart';
import 'package:ride_sharing_user_app/helper/display_helper.dart';
import 'package:ride_sharing_user_app/helper/dynamic_translation_helper.dart';
import 'package:ride_sharing_user_app/util/dimensions.dart';
import 'package:ride_sharing_user_app/util/images.dart';
import 'package:ride_sharing_user_app/util/styles.dart';

class SafetySetupScreen extends StatefulWidget {
  const SafetySetupScreen({super.key});

  @override
  State<SafetySetupScreen> createState() => _SafetySetupScreenState();
}

class _SafetySetupScreenState extends State<SafetySetupScreen> {
  @override
  void initState() {
    Get.find<SafetyAlertController>().getPrecautionList();
    super.initState();
  }

  // Liste des conseils de sécurité
  final List<String> _safetyTips = [
    'Prenez en charge le bon passager. N’hésitez pas à demander au passager de confirmer son nom et sa destination avant de le faire monter dans votre véhicule.',
    'Traitez vos passagers avec soin et respect et donnez la priorité à une excellente conduite à tout moment.',
    'Ne conduisez jamais en étant fatigué, ivre ou sous l’effet de stupéfiants. N’acceptez pas de commande si vous ne vous sentez pas bien.',
    'Avant chaque course, rassurez-vous que votre voiture est propre et bien ventilée.',
    'Respectez toujours les règles de conduite et le code de la route. La sécurité de tous est importante.',
    'Évitez de poser des questions personnelles aux passagers.',
    'Après chaque course, vérifiez votre véhicule pour tout objet oublié.',
    'Vous pouvez alerter discrètement et rapidement les services d’urgence en appuyant sur le bouton d’assistance d’urgence intégré dans l’application.',
    'Évaluez le passager : Vos commentaires aident les autres conducteurs à mieux connaître ceux qu\'ils prennent en charge.',
    'Puis-je planifier un trajet si j\'ai besoin d\'une voiture plus tard ? Oui, vous pouvez réserver un trajet jusqu\'à 90 jours à l\'avance dans l\'application pour une expérience de voyage encore plus pratique.',
    'Puis-je me faire livrer un objet perdu ? Si vous avez oublié quelque chose dans un véhicule, vous pouvez contacter le chauffeur partenaire via l\'application. Dans de nombreux cas, il pourra vous rendre l\'objet directement ou le déposer dans un centre le plus proche. Il vous suffit d\'ouvrir le trajet dans votre historique et de suivre les étapes pour signaler un objet perdu.',
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Scaffold(
        appBar: AppBarWidget(title: 'safety'.tr, showBackButton: true),
        body:
            GetBuilder<SafetyAlertController>(builder: (safetyAlertController) {
          final precautions =
              safetyAlertController.precautionListModel?.data ?? [];

          return Padding(
            padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
            child: ListView(
              children: [
                Container(
                  width: Get.width,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .error
                        .withValues(alpha: 0.10),
                    borderRadius:
                        BorderRadius.circular(Dimensions.paddingSizeSmall),
                  ),
                  child: Column(
                    spacing: Dimensions.paddingSizeSmall,
                    children: [
                      const SizedBox(height: Dimensions.paddingSizeSmall),
                      Image.asset(Images.safelyShieldIcon1,
                          height: 80, width: 80),
                      Text('trip_safety'.tr,
                          style: textSemiBold.copyWith(fontSize: 16)),
                      // Padding(
                      //   padding: const EdgeInsets.symmetric(
                      //     horizontal: Dimensions.paddingSizeExtraLarge,
                      //   ),
                      //   child: Text(
                      //     'when_you_make_a_call_or_send_ext'.tr,
                      //     style: textRegular.copyWith(fontSize: 12),
                      //     textAlign: TextAlign.center,
                      //   ),
                      // ),
                      ..._safetyTips.map((tip) => Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: Dimensions.paddingSizeDefault,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(
                                      top: 6.0,
                                      right: Dimensions.paddingSizeExtraSmall),
                                  child: Icon(
                                    Icons.circle,
                                    size: 7,
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    tip,
                                    style: textRegular.copyWith(fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                          )),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          Dimensions.paddingSizeDefault,
                          0,
                          Dimensions.paddingSizeDefault,
                          Dimensions.paddingSizeSmall,
                        ),
                        child: ButtonWidget(
                          buttonText: 'SOS',
                          radius: Dimensions.paddingSizeSmall,
                          backgroundColor: Theme.of(context).colorScheme.error,
                          onPressed: () {
                            if (safetyAlertController.isStoring) {
                              return;
                            }
                            final cardColor = Theme.of(context).cardColor;

                            safetyAlertController
                                .storeSafetyAlert('SOS')
                                .then((isSuccess) {
                              if (isSuccess) {
                                showCustomSnackBar('safety_alert_sent'.tr,
                                    isError: false);
                              } else {
                                Get.bottomSheet(
                                  isScrollControlled: true,
                                  const SafetyAlertBottomSheetWidget(
                                      fromTripDetailsScreen: true),
                                  backgroundColor: cardColor,
                                  isDismissible: false,
                                );
                              }
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Dimensions.paddingSizeDefault),
                if (precautions.isNotEmpty)
                  ...List.generate(precautions.length, (index) {
                    final item = precautions[index];
                    return Padding(
                      padding: EdgeInsets.only(
                          bottom: index == precautions.length - 1
                              ? 0
                              : Dimensions.paddingSizeSmall),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                              Dimensions.paddingSizeSmall),
                          border: Border.all(
                            color: Theme.of(context)
                                .hintColor
                                .withValues(alpha: 0.2),
                          ),
                        ),
                        child: ExpansionTile(
                          collapsedIconColor:
                              Theme.of(context).textTheme.bodyMedium!.color,
                          iconColor:
                              Theme.of(context).textTheme.bodyMedium!.color,
                          title: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${index + 1}.',
                                    style: textRegular.copyWith(
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.color,
                                    )),
                                Flexible(
                                  child: Text(
                                    DynamicTranslationHelper.translate(
                                        item.title),
                                    style: textRegular.copyWith(
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.color,
                                    ),
                                  ),
                                ),
                              ]),
                          shape: const Border(),
                          expandedAlignment: Alignment.centerLeft,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: Dimensions.paddingSizeSmall,
                                horizontal: Dimensions.paddingSizeExtraLarge,
                              ),
                              child: Text(DynamicTranslationHelper.translate(
                                  item.description)),
                            )
                          ],
                        ),
                      ),
                    );
                  })
                else
                  const NotificationShimmerWidget(),
              ],
            ),
          );
        }),
      ),
    );
  }
}
