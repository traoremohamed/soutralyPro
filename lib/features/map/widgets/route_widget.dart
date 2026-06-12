import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/util/dimensions.dart';
import 'package:ride_sharing_user_app/util/images.dart';
import 'package:ride_sharing_user_app/util/styles.dart';
import 'package:ride_sharing_user_app/features/ride/controllers/ride_controller.dart';
import 'package:ride_sharing_user_app/common_widgets/divider_widget.dart';

class RouteWidget extends StatelessWidget {
  final String pickupAddress;
  final String destinationAddress;
  final String? extraOne;
  final String? extraTwo;
  final String? extraThree;
  final String? entrance;
  final bool fromCard;
  const RouteWidget(
      {super.key,
      required this.pickupAddress,
      required this.destinationAddress,
      this.extraOne,
      this.extraTwo,
      this.extraThree,
      this.entrance,
      this.fromCard = false});

  @override
  Widget build(BuildContext context) {
    final List<String> stops = <String>[
      if (extraOne != null && extraOne!.isNotEmpty) extraOne!,
      if (extraTwo != null && extraTwo!.isNotEmpty) extraTwo!,
      if (extraThree != null && extraThree!.isNotEmpty) extraThree!,
    ];

    final List<String> labels = <String>[
      pickupAddress,
      ...stops,
      destinationAddress
    ];
    final int destinationIndex = labels.length - 1;
    final double connectorHeight = fromCard ? 18 : 22;

    return GetBuilder<RideController>(builder: (riderController) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < labels.length; i++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Dimensions.paddingSizeExtraSmall,
                  ),
                  child: SizedBox(
                    width: Dimensions.iconSizeMedium,
                    child: Image.asset(
                      i == 0
                          ? Images.currentLocation
                          : (i == destinationIndex
                              ? Images.customerDestinationIcon
                              : Images.customerRouteIcon),
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: i == 0 ? 0 : Dimensions.paddingSizeSmall,
                      top: i == destinationIndex && i > 0
                          ? (fromCard
                              ? Dimensions.paddingSizeSmall
                              : Dimensions.paddingSizeLarge)
                          : 0,
                    ),
                    child: Text(
                      labels[i],
                      style: textRegular.copyWith(
                        color: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.color
                            ?.withValues(alpha: 0.7),
                        fontSize: i == 0 || i == destinationIndex
                            ? Dimensions.fontSizeDefault
                            : Dimensions.fontSizeSmall,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            if (i != destinationIndex)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.paddingSizeExtraSmall,
                ),
                child: SizedBox(
                  width: Dimensions.iconSizeMedium,
                  child: Center(
                    child: SizedBox(
                      height: connectorHeight,
                      width: 10,
                      child: DividerWidget(
                        height: 2,
                        dashWidth: 1,
                        axis: Axis.vertical,
                        color: Theme.of(context).textTheme.bodyMedium!.color!,
                      ),
                    ),
                  ),
                ),
              ),
          ],
          if (entrance != null && entrance!.isNotEmpty)
            Divider(color: Theme.of(context).hintColor),
          if (entrance != null && entrance!.isNotEmpty)
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              SizedBox(height: 25, child: Image.asset(Images.curvedArrow)),
              const SizedBox(width: Dimensions.paddingSizeSmall),
              Container(
                transform: Matrix4.translationValues(0, 10, 0),
                child: Text(entrance!,
                    style: textRegular.copyWith(
                      color: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.color
                          ?.withValues(alpha: 0.7),
                      fontSize: Dimensions.fontSizeDefault,
                    )),
              ),
            ]),
        ],
      );
    });
  }
}
