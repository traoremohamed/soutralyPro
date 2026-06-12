import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/helper/price_converter.dart';
import 'package:ride_sharing_user_app/util/dimensions.dart';
import 'package:ride_sharing_user_app/util/styles.dart';

class WalletAmountTypeCardWidget extends StatelessWidget {
  final String icon;
  final double amount;
  final String title;
  final String? badgeText;
  final bool haveBorderColor;
  const WalletAmountTypeCardWidget(
      {super.key,
      required this.icon,
      required this.amount,
      required this.title,
      this.badgeText,
      this.haveBorderColor = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Dimensions.paddingSizeDefault,
        Dimensions.paddingSizeSmall,
        0,
        Dimensions.paddingSizeSmall,
      ),
      child: Container(
        width: 180,
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        decoration: BoxDecoration(
          border: Border.all(
            color: haveBorderColor
                ? Theme.of(context).primaryColor
                : Theme.of(context).primaryColor.withValues(alpha: 0.25),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 40, child: Image.asset(icon)),
          if (badgeText != null && badgeText!.isNotEmpty)
            Container(
              margin:
                  const EdgeInsets.only(top: Dimensions.paddingSizeExtraSmall),
              padding: const EdgeInsets.symmetric(
                horizontal: Dimensions.paddingSizeExtraSmall,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
              ),
              child: Text(
                badgeText!,
                style: textRegular.copyWith(
                  fontSize: Dimensions.fontSizeExtraSmall,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(top: Dimensions.paddingSizeSmall),
            child: Text(
              PriceConverter.convertPayablePrice(context, amount),
              style: textRobotoMedium.copyWith(
                  fontSize: Dimensions.fontSizeExtraLarge,
                  color: Get.isDarkMode
                      ? Theme.of(context)
                          .textTheme
                          .bodyMedium!
                          .color!
                          .withValues(alpha: 0.8)
                      : null),
            ),
          ),
          Text(title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textRegular.copyWith(
                  fontSize: Dimensions.fontSizeSmall,
                  color: haveBorderColor
                      ? Theme.of(context).textTheme.bodyMedium!.color
                      : Theme.of(context)
                          .textTheme
                          .bodyMedium!
                          .color!
                          .withValues(alpha: 0.8))),
        ]),
      ),
    );
  }
}
