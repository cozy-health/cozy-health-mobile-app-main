import 'package:flutter/widgets.dart';

class AppScaffoldPadding {
  static EdgeInsets tabScrollBottom(BuildContext context) {
    // MainScreen reserves space for actions and navigation outside the body.
    return const EdgeInsets.only(bottom: 24);
  }
}
