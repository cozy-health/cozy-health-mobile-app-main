import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_surface.dart';
import '../theme/cozy_colors.dart';

/// Keeps original illustration details readable without recolouring the asset.
class IllustrationPlate extends StatelessWidget {
  const IllustrationPlate({
    super.key,
    required this.asset,
    required this.height,
    this.width,
  });

  final String asset;
  final double height;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final tokens = context.cozyColors.wellness;
    return Container(
      height: height,
      width: width,
      padding: EdgeInsets.all(tokens.small),
      decoration: BoxDecoration(
        color: tokens.artworkSurface,
        borderRadius: BorderRadius.circular(tokens.small),
        border: AppSurface.border(context),
      ),
      child: asset.endsWith('.svg')
          ? SvgPicture.asset(
              asset,
              fit: BoxFit.contain,
              excludeFromSemantics: true,
            )
          : Image.asset(asset, fit: BoxFit.contain, excludeFromSemantics: true),
    );
  }
}
