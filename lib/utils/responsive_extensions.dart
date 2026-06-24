import 'package:flutter/material.dart';
import 'screen_util.dart';

extension ResponsiveIntExtension on num {
  /// Returns percentage of screen height as double
  double get h {
    return (this / 100) * ScreenUtil.screenHeight;
  }

  /// Returns percentage of screen width as double
  double get w {
    return (this / 100) * ScreenUtil.screenWidth;
  }

  /// Returns SizedBox with height as percentage of screen height
  SizedBox get sh {
    return SizedBox(height: h);
  }

  /// Returns SizedBox with width as percentage of screen width
  SizedBox get sw {
    return SizedBox(width: w);
  }
}