import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/features/wallet/widgets/payment_method_bottomsheet_widget.dart';
import 'package:ride_sharing_user_app/features/wallet/widgets/point_to_wallet_money_widget.dart';
import 'package:ride_sharing_user_app/helper/date_converter.dart';
import 'package:ride_sharing_user_app/helper/display_helper.dart';
import 'package:ride_sharing_user_app/helper/price_converter.dart';
import 'package:ride_sharing_user_app/util/dimensions.dart';
import 'package:ride_sharing_user_app/util/images.dart';
import 'package:ride_sharing_user_app/util/styles.dart';
import 'package:ride_sharing_user_app/features/profile/controllers/profile_controller.dart';
import 'package:ride_sharing_user_app/features/splash/controllers/splash_controller.dart';
import 'package:ride_sharing_user_app/features/wallet/controllers/wallet_controller.dart';
import 'package:ride_sharing_user_app/features/wallet/widgets/withdraw_bottom_sheet_widget.dart';
import 'package:ride_sharing_user_app/features/wallet/widgets/recharge_bottom_sheet_widget.dart';
import 'package:ride_sharing_user_app/features/wallet/screens/wave_recharge_page.dart';
import 'package:ride_sharing_user_app/features/wallet/screens/digital_payment_screen.dart';

class WalletMoneyAmountWidget extends StatelessWidget {
  final VoidCallback? onWithdrawableBalanceTap;
  const WalletMoneyAmountWidget({
    super.key,
    this.onWithdrawableBalanceTap,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<WalletController>(builder: (walletController) {
      return GetBuilder<ProfileController>(builder: (profileController) {
        final double walletBalance =
            profileController.profileInfo?.wallet?.walletBalance ?? 0;
        final double minimumWithdrawAmount =
            (Get.find<SplashController>().config?.cashInHandMinAmountToPay ?? 0)
                .toDouble();
        final bool canRequestWithdraw = walletBalance >= minimumWithdrawAmount;
        final bool canSubscribe = walletBalance > 0;
        final bool canSubmitSubscription =
            canSubscribe && !profileController.pricingModeUpdating;
        final double shownAmount = walletController.walletTypeIndex == 0
            ? walletBalance
            : (profileController.profileInfo?.loyaltyPoint?.toDouble() ?? 0);
        final DateTime? forfaitExpiryDate =
            DateTime.tryParse(profileController.forfaitExpiresAt ?? '')
                ?.toLocal();
        final bool isForfaitActive = walletController.walletTypeIndex == 0 &&
            profileController.driverPricingMode == 'forfait' &&
            forfaitExpiryDate != null &&
            forfaitExpiryDate.isAfter(DateTime.now());
        final bool isForfaitExpiringSoon = forfaitExpiryDate != null &&
            forfaitExpiryDate.difference(DateTime.now()).inMinutes <= 180;
        final Color panelBackgroundColor =
            isForfaitActive ? const Color(0xFFEAF6FF) : const Color(0xFFFFF4E8);
        final Color panelBorderColor = isForfaitActive
            ? const Color(0xFF90CAF9)
            : const Color(0xFFFFA75C).withValues(alpha: 0.45);
        final Color titleColor = isForfaitActive
            ? const Color(0xFF0B3C6F)
            : canRequestWithdraw
                ? const Color(0xFFB24D00)
                : Theme.of(context).textTheme.bodyMedium!.color ??
                    const Color(0xFF212121);
        final Color subtitleColor = isForfaitActive
            ? const Color(0xFF124A88)
            : canRequestWithdraw
                ? const Color(0xFF7A3A08)
                : Theme.of(context)
                        .textTheme
                        .bodyMedium!
                        .color
                        ?.withValues(alpha: 0.9) ??
                    const Color(0xFF424242);
        final String formattedForfaitExpiry = forfaitExpiryDate != null
            ? DateConverter.toFrenchDateTime(
                forfaitExpiryDate.toIso8601String())
            : (profileController.forfaitExpiresAt ?? '');
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            Dimensions.paddingSizeDefault,
            0,
            Dimensions.paddingSizeDefault,
            Dimensions.paddingSizeDefault,
          ),
          child: InkWell(
              onTap: () {
                if (walletController.walletTypeIndex == 1) {
                  if (Get.find<SplashController>().config!.conversionStatus!) {
                    showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => Padding(
                            padding: EdgeInsets.only(
                                bottom:
                                    MediaQuery.of(context).viewInsets.bottom),
                            child: PointToWalletMoneyWidget()));
                  } else {
                    showCustomSnackBar(
                        'point_conversion_is_currently_unavailable'.tr);
                  }
                } else if (walletController.walletTypeIndex == 0) {
                  if (canRequestWithdraw) {
                    if (onWithdrawableBalanceTap != null) {
                      onWithdrawableBalanceTap!();
                    }
                    showModalBottomSheet(
                      backgroundColor: Colors.transparent,
                      isScrollControlled: true,
                      context: context,
                      builder: (_) => const WithdrawRequestWidget(),
                    );
                  } else {
                    showCustomSnackBar(
                        '${'minimum_payment_amount'.tr} ${PriceConverter.convertPayablePrice(context, minimumWithdrawAmount)}');
                  }
                }
              },
              child: Container(
                width: Get.width,
                decoration: BoxDecoration(
                    color: panelBackgroundColor,
                    border: Border.all(color: panelBorderColor),
                    borderRadius:
                        BorderRadius.circular(Dimensions.paddingSizeSmall)),
                padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        walletController.walletTypeIndex == 0
                            ? canRequestWithdraw
                                ? 'withdraw_able_balance'.tr
                                : 'wallet_money'.tr
                            : 'convert_able_point'.tr,
                        style: textBold.copyWith(
                            fontSize: Dimensions.fontSizeLarge,
                            color: titleColor),
                      ),
                      Text(
                        walletController.walletTypeIndex == 0
                            ? canRequestWithdraw
                                ? 'you_can_send_withdraw_request'.tr
                                : ''
                            : 'convert_loyalty_point_to_wallet'.tr,
                        style: textRegular.copyWith(color: subtitleColor),
                      ),
                      if (walletController.walletTypeIndex == 0 &&
                          profileController.driverPricingMode == 'forfait' &&
                          profileController.forfaitExpiresAt != null)
                        Padding(
                          padding: const EdgeInsets.only(
                              top: Dimensions.paddingSizeExtraSmall),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: Dimensions.paddingSizeSmall,
                              vertical: Dimensions.paddingSizeExtraSmall,
                            ),
                            decoration: BoxDecoration(
                              color: isForfaitExpiringSoon
                                  ? const Color(0xFFFFF1E0)
                                  : const Color(0xFFEAF6FF),
                              borderRadius: BorderRadius.circular(
                                  Dimensions.paddingSizeExtraSmall),
                              border: Border.all(
                                color: isForfaitExpiringSoon
                                    ? const Color(0xFFFF9800)
                                    : const Color(0xFF1E88E5),
                              ),
                            ),
                            child: Text(
                              'Forfait actif jusqu\'au $formattedForfaitExpiry',
                              style: textRegular.copyWith(
                                fontSize: Dimensions.fontSizeSmall,
                                color: isForfaitExpiringSoon
                                    ? const Color(0xFFB85E00)
                                    : const Color(0xFF0D5EA8),
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: Dimensions.paddingSizeSmall),
                      Container(
                        decoration: BoxDecoration(
                            color: isForfaitActive
                                ? const Color(0xFFF4FAFF)
                                : Colors.white,
                            border: Border.all(
                                color: isForfaitActive
                                    ? const Color(0xFFB3D9FF)
                                    : canRequestWithdraw
                                        ? const Color(0xFFFFD7B0)
                                        : Theme.of(context)
                                            .hintColor
                                            .withValues(alpha: 0.2)),
                            borderRadius: BorderRadius.circular(
                                Dimensions.paddingSizeSmall)),
                        padding:
                            const EdgeInsets.all(Dimensions.paddingSizeSmall),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Image.asset(Images.withdrawMoneyIcon,
                                    height: 30, width: 30),
                                const SizedBox(
                                    width: Dimensions.paddingSizeSmall),
                                Expanded(
                                  child: walletController.walletTypeIndex == 0
                                      ? Text(
                                          PriceConverter.convertPayablePrice(
                                              context, shownAmount),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: textRobotoBold.copyWith(
                                              fontSize:
                                                  Dimensions.fontSizeDefault,
                                              color: Theme.of(context)
                                                  .primaryColor),
                                        )
                                      : Text(
                                          profileController
                                                  .profileInfo?.loyaltyPoint
                                                  .toString() ??
                                              '0',
                                          style: textBold.copyWith(
                                            fontSize:
                                                Dimensions.fontSizeDefault,
                                            color:
                                                Theme.of(context).primaryColor,
                                          ),
                                        ),
                                ),
                              ],
                            ),
                            if (walletController.walletTypeIndex == 0) ...[
                              const SizedBox(
                                  height: Dimensions.paddingSizeSmall),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFFFF7A00),
                                        foregroundColor: Colors.white,
                                        disabledBackgroundColor:
                                            const Color(0xFFFFB067),
                                        disabledForegroundColor: Colors.white70,
                                      ),
                                      onPressed: () async {
                                        final result = await Get.bottomSheet(
                                          PaymentMethodBottomsheetWidget(
                                              payableBalance: PriceConverter
                                                  .roundPayableAmount(
                                                      shownAmount)),
                                          isScrollControlled: true,
                                        );
                                        if (result != null) {
                                          if (!context.mounted) {
                                            return;
                                          }
                                          final gateway =
                                              (result['gateway'] ?? '')
                                                  .toString();
                                          final amount =
                                              result['amount'] ?? shownAmount;
                                          final lowerGateway =
                                              gateway.toLowerCase();
                                          if (lowerGateway.contains('wave') ||
                                              lowerGateway == 'orange_money') {
                                            await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (_) =>
                                                      WaveRechargePage(
                                                          initialAmount:
                                                              amount.toString(),
                                                          paymentMethod:
                                                              lowerGateway)),
                                            );
                                          } else {
                                            Get.to(() => DigitalPaymentScreen(
                                                paymentMethod: gateway,
                                                totalAmount:
                                                    amount.toString()));
                                          }
                                        }
                                      },
                                      child: Text('recharge'.tr),
                                    ),
                                  ),
                                  const SizedBox(
                                      width: Dimensions.paddingSizeSmall),
                                  Expanded(
                                    child: OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        backgroundColor: Colors.black,
                                        foregroundColor: Colors.white,
                                        disabledBackgroundColor: Colors.black38,
                                        disabledForegroundColor: Colors.white70,
                                        side: BorderSide.none,
                                      ),
                                      onPressed: canSubmitSubscription
                                          ? () {
                                              Get.bottomSheet(
                                                const RechargeBottomSheetWidget(),
                                                isScrollControlled: true,
                                                backgroundColor:
                                                    Colors.transparent,
                                              );
                                            }
                                          : null,
                                      child: profileController
                                              .pricingModeUpdating
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : Text('subscribe'.tr),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      )
                    ]),
              )),
        );
      });
    });
  }
}
