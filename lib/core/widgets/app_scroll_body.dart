import 'package:flutter/material.dart';

/// Keeps short fixed-column screens full height while allowing large text to scroll.
/// Supply a minimum content height for columns containing their own viewport.
class AppScrollBody extends StatelessWidget {
  const AppScrollBody({
    super.key,
    required this.child,
    this.minimumContentHeight,
  });

  final Widget child;
  final double? minimumContentHeight;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (_, constraints) => SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: constraints.hasBoundedHeight ? constraints.maxHeight : 0,
        ),
        child: minimumContentHeight == null
            ? IntrinsicHeight(child: child)
            : SizedBox(
                height:
                    constraints.hasBoundedHeight &&
                        constraints.maxHeight > minimumContentHeight!
                    ? constraints.maxHeight
                    : minimumContentHeight!,
                child: child,
              ),
      ),
    ),
  );
}
