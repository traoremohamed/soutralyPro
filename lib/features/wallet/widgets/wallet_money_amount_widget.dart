import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/features/wallet/widgets/payment_method_bottomsheet_widget.dart';
import 'package:ride_sharing_user_app/features/wallet/widgets/point_to_wallet_money_widget.dart';
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
  const WalletMoneyAmountWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<WalletController>(builder: (walletController) {
      return GetBuilder<ProfileController>(builder: (profileController) {
        double receivableBalance = _calculateReceivableBalanceBalance(
          profileController.profileInfo?.wallet?.receivableBalance ?? 0,
          profileController.profileInfo?.wallet?.payableBalance ?? 0,
        );
        double payableBalance =
            (profileController.profileInfo?.wallet?.payableBalance ?? 0) -
                (profileController.profileInfo?.wallet?.receivableBalance ?? 0);
        final double walletBalance =
            profileController.profileInfo?.wallet?.walletBalance ?? 0;
        final bool canSubscribe = walletBalance > 0;
        final double shownAmount = walletController.walletTypeIndex == 0
            ? (receivableBalance > 0
                ? receivableBalance
                : (payableBalance > 0 ? payableBalance : walletBalance))
            : (profileController.profileInfo?.loyaltyPoint?.toDouble() ?? 0);
        final DateTime? forfaitExpiryDate =
            DateTime.tryParse(profileController.forfaitExpiresAt ?? '')
                ?.toLocal();
        final bool isForfaitExpiringSoon = forfaitExpiryDate != null &&
            forfaitExpiryDate.difference(DateTime.now()).inMinutes <= 180;
        final String formattedForfaitExpiry = forfaitExpiryDate != null
            ? _formatFrenchDateTime(forfaitExpiryDate)
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
                  if (receivableBalance > 0) {
                    showModalBottomSheet(
                      backgroundColor: Colors.transparent,
                      isScrollControlled: true,
                      context: context,
                      builder: (_) => const WithdrawRequestWidget(),
                    );
                  } else {
                    if (payableBalance >=
                        (Get.find<SplashController>()
                                .config
                                ?.cashInHandMinAmountToPay ??
                            0)) {
                      Get.bottomSheet(
                          PaymentMethodBottomsheetWidget(
                              payableBalance: payableBalance),
                          isScrollControlled: true);
                    } else {
                      showCustomSnackBar(
                          '${'minimum_payment_amount'.tr} ${PriceConverter.convertPrice(context, (Get.find<SplashController>().config?.cashInHandMinAmountToPay ?? 0))}');
                    }
                  }
                }
              },
              child: Container(
                width: Get.width,
                decoration: BoxDecoration(
                    color: Theme.of(context).hintColor.withValues(alpha: 0.15),
                    borderRadius:
                        BorderRadius.circular(Dimensions.paddingSizeSmall)),
                padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        walletController.walletTypeIndex == 0
                            ? receivableBalance > 0
                                ? 'withdraw_able_balance'.tr
                                : 'wallet_money'.tr
                            : 'convert_able_point'.tr,
                        style: textBold.copyWith(
                            fontSize: Dimensions.fontSizeLarge,
                            color: Get.isDarkMode
                                ? Theme.of(context)
                                    .textTheme
                                    .bodyMedium!
                                    .color!
                                    .withValues(alpha: 0.9)
                                : null),
                      ),
                      Text(
                        walletController.walletTypeIndex == 0
                            ? receivableBalance > 0
                                ? 'you_can_send_withdraw_request'.tr
                                : ''
                            : 'convert_loyalty_point_to_wallet'.tr,
                        style: textRegular.copyWith(
                            color: Get.isDarkMode
                                ? Theme.of(context)
                                    .textTheme
                                    .bodyMedium!
                                    .color!
                                    .withValues(alpha: 0.8)
                                : null),
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
                              color: (isForfaitExpiringSoon
                                      ? Colors.orange
                                      : Colors.blue)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(
                                  Dimensions.paddingSizeExtraSmall),
                              border: Border.all(
                                color: (isForfaitExpiringSoon
                                        ? Colors.orange
                                        : Colors.blue)
                                    .withValues(alpha: 0.45),
                              ),
                            ),
                            child: Text(
                              'Forfait actif jusqu\'au $formattedForfaitExpiry',
                              style: textRegular.copyWith(
                                fontSize: Dimensions.fontSizeSmall,
                                color: isForfaitExpiringSoon
                                    ? Colors.orange
                                    : Colors.blue,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: Dimensions.paddingSizeSmall),
                      Container(
                        decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
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
                                          PriceConverter.convertPrice(
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
                                      onPressed: () async {
                                        final result = await Get.bottomSheet(
                                          PaymentMethodBottomsheetWidget(
                                              payableBalance: payableBalance > 0
                                                  ? payableBalance
                                                  : shownAmount),
                                          isScrollControlled: true,
                                        );
                                        if (result != null) {
                                          final gateway =
                                              (result['gateway'] ?? '')
                                                  .toString();
                                          final amount = result['amount'] ??
                                              (payableBalance > 0
                                                  ? payableBalance
                                                  : shownAmount);
                                          if (gateway
                                              .toLowerCase()
                                              .contains('wave')) {
                                            await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (_) =>
                                                      WaveRechargePage(
                                                          initialAmount: amount
                                                              .toString())),
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
                                      onPressed: canSubscribe
                                          ? () {
                                              Get.bottomSheet(
                                                const RechargeBottomSheetWidget(),
                                                isScrollControlled: true,
                                                backgroundColor:
                                                    Colors.transparent,
                                              );
                                            }
                                          : null,
                                      child: const Text('Souscrire'),
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

  double _calculateReceivableBalanceBalance(
      double receivableBalance, double payableBalance) {
    return receivableBalance - payableBalance;
  }

  String _formatFrenchDateTime(DateTime dateTime) {
    final String day = dateTime.day.toString().padLeft(2, '0');
    final String month = dateTime.month.toString().padLeft(2, '0');
    final String year = dateTime.year.toString();
    final String hour = dateTime.hour.toString().padLeft(2, '0');
    final String minute = dateTime.minute.toString().padLeft(2, '0');
    return '$day/$month/$year à $hour:$minute';
  }
}
