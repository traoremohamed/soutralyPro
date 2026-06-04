import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/features/notification/widgets/notification_shimmer_widget.dart';
import 'package:ride_sharing_user_app/features/wallet/controllers/wallet_controller.dart';
import 'package:ride_sharing_user_app/features/wallet/widgets/transaction_card_widget.dart';
import 'package:ride_sharing_user_app/common_widgets/no_data_widget.dart';
import 'package:ride_sharing_user_app/common_widgets/paginated_list_view_widget.dart';

class PayableTransactionListWidget extends StatefulWidget {
  final WalletController walletController;
  final ScrollController scrollController;
  final int tabIndex;

  const PayableTransactionListWidget(
      {super.key,
      required this.walletController,
      required this.scrollController,
      required this.tabIndex});

  @override
  State<PayableTransactionListWidget> createState() =>
      _PayableTransactionListWidgetState();
}

class _PayableTransactionListWidgetState
    extends State<PayableTransactionListWidget> {
  @override
  Widget build(BuildContext context) {
    final allTransactions =
        widget.walletController.transactionModel?.data ?? [];
    final filteredTransactions = widget.tabIndex == 2
        ? allTransactions
            .where((t) =>
                (t.attribute ?? '').toLowerCase().contains('admin_commission'))
            .toList()
        : allTransactions;

    return widget.walletController.transactionModel != null
        ? filteredTransactions.isNotEmpty
            ? Padding(
                padding: const EdgeInsets.only(bottom: 85.0),
                child: PaginatedListViewWidget(
                  scrollController: widget.scrollController,
                  totalSize:
                      widget.walletController.transactionModel!.totalSize,
                  offset: (widget.walletController.transactionModel != null &&
                          widget.walletController.transactionModel!.offset !=
                              null)
                      ? int.parse(widget
                          .walletController.transactionModel!.offset
                          .toString())
                      : null,
                  onPaginate: (int? offset) async {
                    if (kDebugMode) {
                      print('==========offset========>$offset');
                    }
                    if (widget.tabIndex == 1) {
                      await widget.walletController
                          .getCashCollectHistoryList(offset!);
                    } else if (widget.tabIndex == 2) {
                      await widget.walletController
                          .getWalletHistoryList(offset!);
                    } else {
                      widget.walletController.selectedHistoryIndex == 1
                          ? widget.walletController.payableTypeIndex == 1
                              ? await widget.walletController
                                  .getCashCollectHistoryList(offset!)
                              : await widget.walletController
                                  .getPayableHistoryList(offset!)
                          : await widget.walletController
                              .getWalletHistoryList(offset!);
                    }
                  },
                  itemView: ListView.builder(
                    itemCount: filteredTransactions.length,
                    padding: const EdgeInsets.all(0),
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemBuilder: (BuildContext context, int index) {
                      return TransactionCardWidget(
                          transaction: filteredTransactions[index]);
                    },
                  ),
                ),
              )
            : const NoDataWidget(title: 'no_transaction_found')
        : SizedBox(
            height: Get.height, child: const NotificationShimmerWidget());
  }
}
