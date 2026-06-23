import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:ride_sharing_user_app/features/splash/controllers/splash_controller.dart';

class PriceConverter {
  static String convertPrice(
    BuildContext context,
    double price, {
    double? discount,
    String? discountType,
  }) {
    final String symbol =
        Get.find<SplashController>().config!.currencySymbol ?? r'R$';

    if (discount != null && discountType != null) {
      if (discountType == 'amount') {
        price = price - discount;
      } else if (discountType == 'percent') {
        price = price - ((discount / 100) * price);
      }
    }

    return NumberFormat.currency(
      locale: 'pt_BR',
      symbol: symbol,
      decimalDigits: 2,
    ).format(price);
  }

  static double convertWithDiscount(
    BuildContext context,
    double price,
    double discount,
    String discountType,
  ) {
    if (discountType == 'amount') {
      price = price - discount;
    } else if (discountType == 'percent') {
      price = price - ((discount / 100) * price);
    }
    return price;
  }

  static double calculation(
    double amount,
    double discount,
    String type,
    int quantity,
  ) {
    double calculatedAmount = 0;
    if (type == 'amount') {
      calculatedAmount = discount * quantity;
    } else if (type == 'percent') {
      calculatedAmount = (discount / 100) * (amount * quantity);
    }
    return calculatedAmount;
  }

  static String percentageCalculation(
    BuildContext context,
    String price,
    String discount,
    String discountType,
  ) {
    return '$discount${discountType == 'percent' ? '%' : r'$'} OFF';
  }
}
