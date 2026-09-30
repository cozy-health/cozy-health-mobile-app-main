import 'package:flutter/widgets.dart';

class AppScaffoldPadding {
  static EdgeInsets tabScrollBottom(BuildContext context) {
    final safe = MediaQuery.of(context).padding.bottom;
    return EdgeInsets.only(bottom: 88 + safe);
  }
}
