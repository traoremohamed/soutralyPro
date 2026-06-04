import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/helper/price_converter.dart';
import 'package:ride_sharing_user_app/localization/localization_controller.dart';
import 'package:ride_sharing_user_app/util/images.dart';
import 'package:ride_sharing_user_app/features/home/widgets/activity_card_widget.dart';
import 'package:ride_sharing_user_app/features/profile/controllers/profile_controller.dart';
import 'package:ride_sharing_user_app/common_widgets/title_widget.dart';
import 'package:ride_sharing_user_app/util/dimensions.dart';
import 'package:ride_sharing_user_app/util/styles.dart';

class MyActivityListViewWidget extends StatelessWidget {
  const MyActivityListViewWidget({super.key});

  void _logLiveCounters({
    required String isOnline,
    required String availability,
    required String? updatedAt,
    required int liveDeltaMinutes,
    required int active,
    required int driving,
    required int idle,
    required int offline,
  }) {
    if (!kDebugMode) {
      return;
    }

    debugPrint(
      '[MyActivity][live] isOnline=$isOnline availability=$availability '
      'updatedAt=${updatedAt ?? 'null'} deltaMin=$liveDeltaMinutes '
      'active=$active driving=$driving idle=$idle offline=$offline',
    );
  }

  int _elapsedMinutesSince(String? updatedAt) {
    if (updatedAt == null || updatedAt.isEmpty) {
      return 0;
    }

    final DateTime? parsed = DateTime.tryParse(updatedAt);
    if (parsed == null) {
      return 0;
    }

    final DateTime now = DateTime.now();
    final DateTime localParsed = parsed.toLocal();

    // Evite d'injecter un delta d'un autre jour dans les stats de la journee.
    if (localParsed.year != now.year ||
        localParsed.month != now.month ||
        localParsed.day != now.day) {
      return 0;
    }

    final int minutes = now.difference(localParsed).inMinutes;
    if (minutes <= 0) {
      return 0;
    }

    // Une journee ne peut pas depasser 24h de suivi.
    if (minutes > 1440) {
      return 1440;
    }

    return minutes;
  }

  bool _isDrivingStatus(String availability) {
    final String normalized = availability.trim().toLowerCase();
    return normalized == 'unavailable';
  }

  bool _isIdleStatus(String availability) {
    final String normalized = availability.trim().toLowerCase();
    return normalized.isEmpty || normalized == 'available';
  }

  int _toMinutesFromInt(int? raw) {
    if (raw == null || raw <= 0) {
      return 0;
    }
    // Certains payloads renvoient des secondes, d'autres des minutes.
    // Au-dela d'une journee en minutes, on considere que c'est en secondes.
    if (raw > 1440) {
      return (raw / 60).floor();
    }
    return raw;
  }

  int _toMinutesFromDouble(double? raw) {
    if (raw == null || raw <= 0) {
      return 0;
    }
    // Les champs details.*_time sont souvent en heures decimales.
    if (raw <= 24) {
      return (raw * 60).floor();
    }
    // Sinon, on le traite comme un nombre de minutes.
    return raw.floor();
  }

  int _resolveMinutes({
    required int? primary,
    required double? fallback,
    bool forceAtLeastOneMinute = false,
  }) {
    final int primaryMinutes = _toMinutesFromInt(primary);
    final int fallbackMinutes = _toMinutesFromDouble(fallback);
    final int value = primaryMinutes > 0 ? primaryMinutes : fallbackMinutes;

    if (forceAtLeastOneMinute && value == 0) {
      return 1;
    }
    return value;
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const TitleWidget(title: 'my_activity'),
      GetBuilder<ProfileController>(builder: (profileController) {
        return StreamBuilder<int>(
            stream: Stream<int>.periodic(
                const Duration(seconds: 30), (count) => count),
            initialData: 0,
            builder: (context, snapshot) {
              int activeSec = 0, offlineSec = 0, drivingSec = 0, idleSec = 0;
              final profile = profileController.profileInfo;
              final timeTrack = profile?.timeTrack;
              final details = profile?.details;

              if (profile != null) {
                activeSec = _resolveMinutes(
                  primary: timeTrack?.totalOnline,
                  fallback: details?.onlineTime,
                  forceAtLeastOneMinute: profileController.isOnline == '1',
                );
                drivingSec = _resolveMinutes(
                  primary: timeTrack?.totalDriving,
                  fallback: details?.onDrivingTime,
                );
                idleSec = _resolveMinutes(
                  primary: timeTrack?.totalIdle,
                  fallback: details?.idleTime,
                );
                offlineSec = _resolveMinutes(
                  primary: timeTrack?.totalOffline,
                  fallback: null,
                );

                if (profileController.isOnline == '1') {
                  final int liveDeltaMinutes =
                      _elapsedMinutesSince(details?.updatedAt);
                  if (liveDeltaMinutes > 0) {
                    activeSec += liveDeltaMinutes;

                    final String availability =
                        (details?.availabilityStatus ?? '').toLowerCase();
                    if (_isDrivingStatus(availability)) {
                      drivingSec += liveDeltaMinutes;
                    } else if (_isIdleStatus(availability)) {
                      idleSec += liveDeltaMinutes;
                    }

                    _logLiveCounters(
                      isOnline: profileController.isOnline,
                      availability: availability,
                      updatedAt: details?.updatedAt,
                      liveDeltaMinutes: liveDeltaMinutes,
                      active: activeSec,
                      driving: drivingSec,
                      idle: idleSec,
                      offline: offlineSec,
                    );
                  }
                } else {
                  final int liveDeltaMinutes =
                      _elapsedMinutesSince(details?.updatedAt);
                  if (liveDeltaMinutes > 0) {
                    offlineSec += liveDeltaMinutes;

                    _logLiveCounters(
                      isOnline: profileController.isOnline,
                      availability: (details?.availabilityStatus ?? ''),
                      updatedAt: details?.updatedAt,
                      liveDeltaMinutes: liveDeltaMinutes,
                      active: activeSec,
                      driving: drivingSec,
                      idle: idleSec,
                      offline: offlineSec,
                    );
                  }
                }
              }
              return profileController.profileInfo != null
                  ? SizedBox(
                      height:
                          Get.find<LocalizationController>().isLtr ? 106 : 110,
                      child: ListView(
                          shrinkWrap: true,
                          scrollDirection: Axis.horizontal,
                          children: [
                            MyActivityCardWidget(
                                title: 'active',
                                icon: Images.activeHourIcon,
                                index: 0,
                                value: activeSec,
                                color: Theme.of(Get.context!)
                                    .colorScheme
                                    .tertiary),
                            MyActivityCardWidget(
                                title: 'on_driving',
                                icon: Images.onDrivingHourIcon,
                                index: 0,
                                value: drivingSec,
                                color: Theme.of(Get.context!)
                                    .colorScheme
                                    .secondary),
                            MyActivityCardWidget(
                                title: 'idle_time',
                                icon: Images.idleHourIcon,
                                index: 0,
                                value: idleSec,
                                color: Theme.of(Get.context!)
                                    .colorScheme
                                    .tertiaryContainer),
                            MyActivityCardWidget(
                                title: 'offline',
                                icon: Images.offlineHourIcon,
                                index: 0,
                                value: offlineSec,
                                color: Theme.of(Get.context!)
                                    .colorScheme
                                    .secondaryContainer),
                            _CommissionHistoryCard(
                                amount: profileController
                                        .profileInfo?.totalCommission ??
                                    0),
                          ]))
                  : const SizedBox();
            });
      }),
    ]);
  }
}

class _CommissionHistoryCard extends StatelessWidget {
  final double amount;
  const _CommissionHistoryCard({required this.amount});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: Dimensions.paddingSizeDefault),
      child: Container(
        width: 215,
        padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
        decoration: BoxDecoration(
          color: Theme.of(context).highlightColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'commission_deduction_history'.tr,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textSemiBold.copyWith(
                        color: Theme.of(context).primaryColor,
                        fontSize: Dimensions.fontSizeDefault),
                  ),
                ),
                SizedBox(
                    width: Dimensions.iconSizeMedium,
                    child: Image.asset(Images.totalCommissionIcon,
                        color: Theme.of(context).primaryColor)),
              ],
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            Text(
              PriceConverter.convertPrice(context, amount),
              style: textSemiBold.copyWith(
                color: Theme.of(context).primaryColor,
                fontSize: Dimensions.fontSizeLarge,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
