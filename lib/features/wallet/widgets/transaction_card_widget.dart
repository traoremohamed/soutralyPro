import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/helper/date_converter.dart';
import 'package:ride_sharing_user_app/helper/dynamic_translation_helper.dart';
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

  String _formatFrenchDateTime(String? rawDate) {
    return DateConverter.toFrenchDateTime(rawDate);
  }

  bool _isFailed(Transaction t) {
    final String status = (t.status ?? '').toLowerCase();
    final String attr = (t.attribute ?? '').toLowerCase();
    return status == 'failed' || attr.contains('failed');
  }

  bool _isForfaitSubscription(Transaction t) {
    final String attr = (t.attribute ?? '').toLowerCase();
    return attr.contains('driver_daily_forfait') || attr.contains('forfait');
  }

  bool _isDigitalRecharge(Transaction t) {
    final String attr = (t.attribute ?? '').toLowerCase();
    final String account = (t.account ?? '').toLowerCase();
    final String method = (t.paymentMethod ?? '').toLowerCase();
    return attr.contains('fund_added_digitally') ||
        account.contains('fund_added_digitally') ||
        account.contains('wallet') ||
        method == 'wave' ||
        method == 'orange_money';
  }

  bool _isOrange(Transaction t) {
    final String method = (t.paymentMethod ?? '').toLowerCase();
    final String attr = (t.attribute ?? '').toLowerCase();
    final String account = (t.account ?? '').toLowerCase();
    final String reference = (t.reference ?? '').toLowerCase();
    final String phone = (t.paymentNumber ?? '').toLowerCase();
    return method.contains('orange') ||
        attr.contains('orange') ||
        account.contains('orange') ||
        reference.startsWith('om-') ||
        phone.startsWith('07');
  }

  bool _isWave(Transaction t) {
    final String method = (t.paymentMethod ?? '').toLowerCase();
    final String attr = (t.attribute ?? '').toLowerCase();
    final String account = (t.account ?? '').toLowerCase();
    final String reference = (t.reference ?? '').toLowerCase();
    final String phone = (t.paymentNumber ?? '').toLowerCase();
    return method.contains('wave') ||
        attr.contains('wave') ||
        account.contains('wave') ||
        reference.startsWith('wave-') ||
        phone.startsWith('01') ||
        phone.startsWith('05');
  }

  String _paymentMethodLabel(Transaction t) {
    if (_isOrange(t)) {
      return 'Orange Money';
    }
    if (_isWave(t)) {
      return 'WAVE';
    }
    // Recharge digitale sans methode retournee: fallback metier voulu.
    return 'WAVE / Orange Money';
  }

  String _statusLabel(Transaction t) {
    final String status = (t.status ?? '').toLowerCase();
    if (_isFailed(t)) {
      return 'Échoué';
    }

    final double credit = t.credit ?? 0;
    final double debit = t.debit ?? 0;

    // Recharge digitale validée: argent crédité.
    if (_isDigitalRecharge(t) && credit > 0) {
      return 'Succès';
    }

    if (status.isEmpty) {
      return _isDigitalRecharge(t)
          ? (credit > 0 ? 'Succès' : 'Échoué')
          : 'Inconnu';
    }
    if (status == 'completed' ||
        status == 'success' ||
        status == 'successful' ||
        status == 'credited' ||
        status == 'paid' ||
        status == 'succeeded') {
      return 'Succès';
    }
    if (status == 'pending' ||
        status == 'initiated' ||
        status == 'processing') {
      return 'En attente';
    }
    if (status == 'failed' || status == 'failure' || status == 'error') {
      return 'Échoué';
    }
    if (status == 'cancelled' || status == 'canceled' || status == 'rejected') {
      return 'Échoué';
    }

    if (_isDigitalRecharge(t) && debit > 0 && credit <= 0) {
      return 'Échoué';
    }

    return status;
  }

  String _labelFromTransaction(Transaction t) {
    final String attr = (t.attribute ?? '').toLowerCase();
    final String account = (t.account ?? '').toLowerCase();

    if (_isFailed(t)) {
      final String method = (t.paymentMethod ?? '').toLowerCase();
      if (method == 'orange_money') {
        return 'Rechargement Orange Money echec';
      }
      if (method == 'wave') {
        return 'Rechargement Wave echec';
      }
      return 'Rechargement echoue';
    }

    if (attr.contains('fund_added_digitally')) {
      return 'Fonds ajoutes numeriquement';
    }
    if (attr.contains('driver_daily_forfait')) {
      return 'Achat de forfait';
    }
    if (attr.contains('admin_commission')) {
      return 'Prélèvement de commission';
    }
    if (attr.contains('wallet') || account.contains('wallet')) {
      if ((t.credit ?? 0) > 0) {
        return 'Rechargement de compte';
      }
      if ((t.debit ?? 0) > 0) {
        return 'Debit portefeuille';
      }
    }
    return DynamicTranslationHelper.translate(
      t.attribute ?? t.account ?? 'Transaction',
    );
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
                                _formatFrenchDateTime(transaction.createdAt),
                                style: textRegular.copyWith(
                                    color: Theme.of(context).hintColor),
                              ),
                            ),
                            if (_isDigitalRecharge(transaction))
                              Text(
                                'Type: ${_paymentMethodLabel(transaction)}',
                                style: textRegular.copyWith(
                                    color: Theme.of(context).hintColor),
                              ),
                            if (_isDigitalRecharge(transaction))
                              Text(
                                'Statut: ${_statusLabel(transaction)}',
                                style: textRegular.copyWith(
                                    color: Theme.of(context).hintColor),
                              ),
                            if (_isFailed(transaction) &&
                                (transaction.errorMessage ?? '').isNotEmpty)
                              Text(
                                transaction.errorMessage!,
                                style: textRegular.copyWith(
                                    color: Theme.of(context).colorScheme.error),
                              ),
                            if (_isForfaitSubscription(transaction))
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Recharge: ${_formatFrenchDateTime(transaction.forfaitRechargeAt)}',
                                    style: textRegular.copyWith(
                                        color: Theme.of(context).hintColor),
                                  ),
                                  Text(
                                    'Expiration: ${_formatFrenchDateTime(transaction.forfaitExpiresAt)}',
                                    style: textRegular.copyWith(
                                        color: Theme.of(context).hintColor),
                                  ),
                                  Text(
                                    'Jours: ${transaction.forfaitDays ?? '-'}',
                                    style: textRegular.copyWith(
                                        color: Theme.of(context).hintColor),
                                  ),
                                  Text(
                                    'Montant: ${PriceConverter.convertPayablePrice(context, transaction.forfaitAmount ?? (transaction.debit ?? transaction.credit ?? 0))}',
                                    style: textRegular.copyWith(
                                        color: Theme.of(context).hintColor),
                                  ),
                                ],
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
                          color: _isFailed(transaction)
                              ? Theme.of(context)
                                  .colorScheme
                                  .error
                                  .withValues(alpha: .15)
                              : transaction.debit! > 0
                                  ? Theme.of(context)
                                      .colorScheme
                                      .error
                                      .withValues(alpha: .15)
                                  : Theme.of(context)
                                      .primaryColor
                                      .withValues(alpha: .08)),
                      child: Text(
                          _isFailed(transaction)
                              ? 'Echec'
                              : '${transaction.debit! > 0 ? '-' : '+'}${PriceConverter.convertPayablePrice(context, transaction.debit! > 0 ? transaction.debit! : transaction.credit!)}',
                          style: textRobotoBold.copyWith(
                              color: (_isFailed(transaction) ||
                                      transaction.debit! > 0)
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
