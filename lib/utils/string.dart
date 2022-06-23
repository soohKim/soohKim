import 'package:flutter/material.dart';

extension StringExtension on String? {
  bool get isNotNullEmpty {
    if (this != null) {
      if (this != '') {
        return true;
      } else {
        return false;
      }
    } else {
      return false;
    }
  }
}

extension NotNullStringExtension on String {
  Widget get titleWidget => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          this,
          style: TextStyle(
            fontSize: 15,
          ),
        ),
      );

  Widget get sellerItemTitle => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          this,
          style: TextStyle(
            fontSize: 13,
          ),
        ),
      );

  Widget get listItemTitle => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          this,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
      );
}

extension NullableStringExtension on String? {
  Widget get listsubItemTitle => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          this ?? "",
          style: TextStyle(
            fontSize: 11,
          ),
        ),
      );
}
