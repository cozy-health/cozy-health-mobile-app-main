import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../gen/assets.gen.dart';

class GoogleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool iconOnly;
  const GoogleSignInButton({
    super.key,
    this.onPressed,
    this.isLoading = false,
    this.iconOnly = false,
  });
  @override
  Widget build(BuildContext context) => Semantics(
    label: iconOnly ? 'Continue with Google' : null,
    child: OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: iconOnly
            ? const Size(56, 56)
            : const Size(double.infinity, 56),
        fixedSize: iconOnly ? const Size(56, 56) : null,
        padding: iconOnly ? EdgeInsets.zero : null,
      ),
      child: isLoading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                semanticsLabel: 'Signing in with Google',
              ),
            )
          : iconOnly
          ? SvgPicture.asset(Assets.svg.google, width: 24, height: 24)
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(Assets.svg.google, width: 24, height: 24),
                const SizedBox(width: 12),
                const Text('Continue with Google'),
              ],
            ),
    ),
  );
}
