import 'package:flutter/material.dart';

extension NumExtenstion on num {
  SizedBox get hBox => SizedBox(
        height: this.toDouble(),
      );
}
