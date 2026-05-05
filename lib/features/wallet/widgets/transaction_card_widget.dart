import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/helper/date_converter.dart';
import 'package:ride_sharing_user_app/helper/price_converter.dart';
import 'package:ride_sharing_user_app/util/dimensions.dart';
import 'package:ride_sharing_user_app/util/images.dart';
import 'package:ride_sharing_user_app/util/styles.dart';
import 'package:ride_sharing_user_app/features/wallet/controllers/wallet_controller.dart';
import 'package:ride_sharing_user_app/features/wallet/domain/models/transaction_model.dart';
import 'package:ride_sharing_user_app/common_widgets/divider_widget.dart';

class TransactionCardWidget extends StatelessWidget {
  final Transaction transaction;
  const TransactionCardWidget({super.key, required this.transaction});

  String _labelFromTransaction(Transaction t) {
    final String attr = (t.attribute ?? '').toLowerCase();
    final String account = (t.account ?? '').toLowerCase();

    if (attr.contains('fund_added_digitally')) {
      return 'Rechargement de compte par WAVE';
    }
    if (attr.contains('driver_daily_forfait')) {
      return 'Achat de forfait';
    }
    if (attr.contains('admin_commission')) {
      return 'Debit du compte pour comission';
    }
    if (attr.contains('wallet') || account.contains('wallet')) {
      if ((t.credit ?? 0) > 0) {
        return 'Rechargement de compte';
      }
      if ((t.debit ?? 0) > 0) {
        return 'Debit wallet';
      }
    }
    return t.attribute ?? t.account ?? 'Transaction';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault, 0,
          Dimensions.paddingSizeDefault, Dimensions.paddingSizeDefault),
      child: GetBuilder<WalletController>(builder: (walletController) {
        return Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
              child: Row(
                children: [
                  Expanded(
                      child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                          width: Dimensions.iconSizeLarge,
                          child: Image.asset(Images.myEarnIcon,
                              color: Theme.of(context).primaryColor)),
                      const SizedBox(width: Dimensions.paddingSizeSmall),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_labelFromTransaction(transaction),
                                style: textSemiBold.copyWith(
                                    color: Theme.of(context).primaryColor)),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: Dimensions.paddingSizeExtraSmall),
                              child: Text(
                                DateConverter.isoStringToDateTimeString(
                                    transaction.createdAt!),
                                style: textRegular.copyWith(
                                    color: Theme.of(context).hintColor),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )),
                  Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: Dimensions.paddingSizeDefault,
                          vertical: Dimensions.paddingSizeSeven),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(100),
                          color: transaction.debit! > 0
                              ? Theme.of(context)
                                  .colorScheme
                                  .error
                                  .withValues(alpha: .15)
                              : Theme.of(context)
                                  .primaryColor
                                  .withValues(alpha: .08)),
                      child: Text(
                          '${transaction.debit! > 0 ? '-' : '+'}${PriceConverter.convertPrice(context, transaction.debit! > 0 ? transaction.debit! : transaction.credit!)}',
                          style: textRobotoBold.copyWith(
                              color: transaction.debit! > 0
                                  ? Theme.of(context).colorScheme.error
                                  : Theme.of(context).primaryColor)))
                ],
              ),
            ),
            DividerWidget(
              height: .5,
              color: Theme.of(context).hintColor.withValues(alpha: .75),
            )
          ],
        );
      }),
    );
  }
}
