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
  double? debit;
  double? credit;
  String? createdAt;

  Transaction(
      {this.id,
      this.attribute,
      this.account,
      this.attributeId,
      this.debit,
      this.credit,
      this.createdAt});

  Transaction.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    attribute = json['attribute'];
    account = json['account'];
    attributeId = json['attribute_id'];
    debit = json['debit'] == null ? 0 : (json['debit'] as num).toDouble();
    credit = json['credit'] == null ? 0 : (json['credit'] as num).toDouble();
    createdAt = json['created_at'];
  }
}
