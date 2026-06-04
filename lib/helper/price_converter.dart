import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/features/splash/controllers/splash_controller.dart';

class PriceConverter {
  static String _normalizedCurrencySymbol(String? symbol) {
    final raw = (symbol ?? 'FCFA').trim();
    if (raw.isEmpty) return 'FCFA';

    final upper = raw.toUpperCase();
    if (upper == 'CFA' || upper == 'F CFA' || upper == 'F.CFA') {
      return 'FCFA';
    }
    return raw;
  }

  static String convertPrice(BuildContext context, double price,
      {double? discount, String? discountType}) {
    bool inRight =
        Get.find<SplashController>().config!.currencySymbolPosition == 'right';
    String decimal =
        Get.find<SplashController>().config!.currencyDecimalPoint ?? '1';
    String symbol = _normalizedCurrencySymbol(
        Get.find<SplashController>().config!.currencySymbol);
    String finalResult;
    if (discount != null && discountType != null) {
      if (discountType == 'amount') {
        price = price - discount;
      } else if (discountType == 'percent') {
        price = price - ((discount / 100) * price);
      }
    }
    if (inRight) {
      finalResult =
          '${(price).toStringAsFixed(int.parse(decimal)).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} $symbol';
    } else {
      finalResult = '$symbol '
          '${(price).toStringAsFixed(int.parse(decimal)).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
    }
    return finalResult;
  }

  static double roundPayableAmount(double amount) {
    if (amount == 0) {
      return 0;
    }

    final bool isNegative = amount < 0;
    int absoluteInt = amount.abs().round();

    final int lastDigit = absoluteInt % 10;
    if (lastDigit == 0 || lastDigit == 5) {
      return isNegative ? -absoluteInt.toDouble() : absoluteInt.toDouble();
    }

    if (lastDigit < 5) {
      absoluteInt -= lastDigit;
    } else {
      absoluteInt += (10 - lastDigit);
    }

    return isNegative ? -absoluteInt.toDouble() : absoluteInt.toDouble();
  }

  static String convertPayablePrice(BuildContext context, double price,
      {double? discount, String? discountType}) {
    final double rounded = roundPayableAmount(price);
    return convertPrice(
      context,
      rounded,
      discount: discount,
      discountType: discountType,
    );
  }

  static double convertWithDiscount(BuildContext context, double price,
      double discount, String discountType) {
    if (discountType == 'amount') {
      price = price - discount;
    } else if (discountType == 'percent') {
      price = price - ((discount / 100) * price);
    }
    return price;
  }

  static double calculation(
      double amount, double discount, String type, int quantity) {
    double calculatedAmount = 0;
    if (type == 'amount') {
      calculatedAmount = discount * quantity;
    } else if (type == 'percent') {
      calculatedAmount = (discount / 100) * (amount * quantity);
    }
    return calculatedAmount;
  }

  static String percentageCalculation(BuildContext context, String price,
      String discount, String discountType) {
    String symbol = _normalizedCurrencySymbol(
        Get.find<SplashController>().config!.currencySymbol);
    return '$discount${discountType == 'percent' ? '%' : symbol} OFF';
  }
}
