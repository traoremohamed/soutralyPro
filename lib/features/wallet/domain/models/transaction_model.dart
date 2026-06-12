class TransactionModel {
  String? responseCode;
  String? message;
  int? totalSize;
  String? limit;
  String? offset;
  List<Transaction>? data;

  TransactionModel({
    this.responseCode,
    this.message,
    this.totalSize,
    this.limit,
    this.offset,
    this.data,
  });

  TransactionModel.fromJson(Map<String, dynamic> json) {
    responseCode = json['response_code'];
    message = json['message'];
    totalSize = json['total_size'];
    limit = json['limit'];
    offset = json['offset'];

    dynamic items = json['data'];
    if (items is Map<String, dynamic> && items['data'] != null) {
      items = items['data'];
      totalSize ??= items is List ? items.length : null;
    }

    if (items != null && items is Iterable) {
      data = <Transaction>[];
      items.forEach((v) {
        data!.add(Transaction.fromJson(v));
      });
    }
  }
}

class Transaction {
  String? id;
  String? attribute;
  String? account;
  String? attributeId;
  String? status;
  String? paymentMethod;
  String? reference;
  String? paymentNumber;
  String? errorMessage;
  double? debit;
  double? credit;
  String? createdAt;
  String? forfaitRechargeAt;
  String? forfaitExpiresAt;
  int? forfaitDays;
  double? forfaitAmount;

  Transaction(
      {this.id,
      this.attribute,
      this.account,
      this.attributeId,
      this.status,
      this.paymentMethod,
      this.reference,
      this.paymentNumber,
      this.errorMessage,
      this.debit,
      this.credit,
      this.createdAt,
      this.forfaitRechargeAt,
      this.forfaitExpiresAt,
      this.forfaitDays,
      this.forfaitAmount});

  Transaction.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    attribute = json['attribute'];
    account = json['account'];
    attributeId = json['attribute_id'];
    status = json['status']?.toString();
    paymentMethod = json['payment_method']?.toString();
    reference = json['reference']?.toString();
    paymentNumber = json['payment_number']?.toString();
    errorMessage = json['error_message']?.toString();
    debit = json['debit'] == null ? 0 : (json['debit'] as num).toDouble();
    credit = json['credit'] == null ? 0 : (json['credit'] as num).toDouble();
    createdAt = json['created_at'];
    forfaitRechargeAt = _extractNestedString(json, const [
          'recharge_date',
          'forfait_recharge_at',
          'start_date',
          'created_at',
        ]) ??
        json['created_at']?.toString();
    forfaitExpiresAt = _extractNestedString(json, const [
      'expiry_date',
      'forfait_expires_at',
      'expires_at',
      'end_date',
      'end_at',
      'subscription_end_date',
    ]);
    forfaitDays =
        int.tryParse((json['days'] ?? json['forfait_days'] ?? '0').toString());
    forfaitAmount = double.tryParse(
        (json['amount'] ?? json['forfait_amount'] ?? '0').toString());
  }

  String? _extractNestedString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final dynamic value = json[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }

    const nestedContainers = [
      'data',
      'subscription',
      'forfait_subscription',
      'forfait',
      'details',
      'meta',
      'history',
    ];

    for (final containerKey in nestedContainers) {
      final dynamic nested = json[containerKey];
      if (nested is Map<String, dynamic>) {
        for (final key in keys) {
          final dynamic value = nested[key];
          if (value != null && value.toString().trim().isNotEmpty) {
            return value.toString();
          }
        }
      }
    }

    return null;
  }
}
