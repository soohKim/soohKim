import 'package:withsum/constants/enums.dart';

class CalculatorModel {
  WhereBuy type;
  int? deliveryFee;
  int? amount;
  int? price;

  CalculatorModel({
    required this.type,
    this.deliveryFee,
    this.amount,
    this.price,
  });
}
