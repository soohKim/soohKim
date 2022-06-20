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
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(
          this,
          style: TextStyle(
            fontSize: 15,
          ),
        ),
      );
}
