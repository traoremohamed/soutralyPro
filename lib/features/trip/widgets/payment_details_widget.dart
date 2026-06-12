import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/common_widgets/payment_item_info_widget.dart';
import 'package:ride_sharing_user_app/features/ride/domain/models/trip_details_model.dart';
import 'package:ride_sharing_user_app/helper/dynamic_translation_helper.dart';
import 'package:ride_sharing_user_app/helper/price_converter.dart';
import 'package:ride_sharing_user_app/util/dimensions.dart';
import 'package:ride_sharing_user_app/util/images.dart';
import 'package:ride_sharing_user_app/util/styles.dart';

class PaymentDetailsWidget extends StatelessWidget {
  final TripDetail? tripDetail;
  const PaymentDetailsWidget({super.key, required this.tripDetail});

  @override
  Widget build(BuildContext context) {
    final subtotalAmount = (tripDetail?.distanceWiseFare ?? 0) +
        (tripDetail?.type != 'parcel' ? (tripDetail?.waitingFee ?? 0) : 0);

    return Container(
      padding: const EdgeInsets.fromLTRB(
        Dimensions.paddingSizeDefault,
        Dimensions.paddingSizeDefault,
        Dimensions.paddingSizeDefault,
        0,
      ),
      decoration: BoxDecoration(
        border: Border.all(
            color: Theme.of(context)
                .textTheme
                .bodyMedium!
                .color!
                .withValues(alpha: 0.2),
            width: .5),
        borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(
              'payment_details'.tr,
              style: textSemiBold.copyWith(
                  color: Theme.of(context).textTheme.bodyMedium!.color),
            ),
            Text(
              DynamicTranslationHelper.translate(
                  tripDetail!.paymentMethod?.toLowerCase()),
              style: textSemiBold.copyWith(
                  color: Theme.of(context).textTheme.bodyMedium!.color),
            ),
          ]),
        ),
        PaymentItemInfoWidget(
          icon: Images.farePrice,
          title: 'fare_price'.tr,
          amount: tripDetail!.distanceWiseFare ?? 0,
          payableRounded: true,
        ),
        if (tripDetail?.type != 'parcel')
          PaymentItemInfoWidget(
            icon: Images.waitingPrice,
            title:
                '${'waiting_fee'.tr} (${((double.tryParse((tripDetail?.waitingTime ?? '0').toString()) ?? 0)).toStringAsFixed(2)} min)',
            amount: tripDetail?.waitingFee ?? 0,
            payableRounded: true,
          ),
        /*
        if (tripDetail?.type != 'parcel')
          PaymentItemInfoWidget(
            icon: Images.farePrice,
            title: 'commission_deducted_amount'.tr,
            amount: tripDetail?.adminCommission ?? 0,
            payableRounded: true,
          ),
        */
        Divider(color: Theme.of(context).hintColor.withValues(alpha: 0.2)),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Flexible(
            child: Text('sub_total'.tr,
                style: textSemiBold.copyWith(
                  color: Theme.of(context).primaryColor,
                )),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Dimensions.paddingSizeSmall,
              vertical: Dimensions.paddingSizeExtraSmall,
            ),
            decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: .1),
                borderRadius:
                    BorderRadius.circular(Dimensions.paddingSizeExtraSmall)),
            child: Text(
              PriceConverter.convertPayablePrice(context, subtotalAmount),
              style: textRobotoBold.copyWith(
                color: Get.isDarkMode
                    ? Colors.white
                    : Theme.of(context).primaryColor,
              ),
            ),
          )
        ]),
        if (tripDetail?.type == 'parcel' &&
            (tripDetail?.currentStatus == 'returning' ||
                tripDetail?.currentStatus == 'returned')) ...[
          const SizedBox(height: Dimensions.paddingSizeSmall),
          PaymentItemInfoWidget(
            icon: Images.returnDetailsIcon,
            title:
                '${'return_fee'.tr} (${tripDetail?.currentStatus == 'returning' ? 'due'.tr : 'paid'.tr})',
            amount: tripDetail!.returnFee ?? 0,
            payableRounded: true,
          )
        ],
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(
              'payment_status'.tr,
              style: textSemiBold.copyWith(
                  color: Theme.of(context).textTheme.bodyMedium!.color),
            ),
            Text(
              DynamicTranslationHelper.translate(tripDetail!.paymentStatus),
              style: textSemiBold.copyWith(
                  color: Theme.of(context).textTheme.bodyMedium!.color),
            ),
          ]),
        ),
      ]),
    );
  }
}
