import 'package:flutter/material.dart';

class ScreenUtil {
  static late double _screenWidth;
  static late double _screenHeight;
  static bool _initialized = false;

  static void init(BuildContext context) {
    final size = MediaQuery.of(context).size;
    _screenWidth = size.width;
    _screenHeight = size.height;
    _initialized = true;
  }

  static double get screenWidth {
    if (!_initialized) {
      throw Exception(
        'ScreenUtil not initialized. Call ScreenUtil.init(context) first.',
      );
    }
    return _screenWidth;
  }

  static double get screenHeight {
    if (!_initialized) {
      throw Exception(
        'ScreenUtil not initialized. Call ScreenUtil.init(context) first.',
      );
    }
    return _screenHeight;
  }

  static bool get isInitialized => _initialized;
}
