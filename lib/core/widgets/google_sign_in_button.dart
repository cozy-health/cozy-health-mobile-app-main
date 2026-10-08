import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../gen/assets.gen.dart';

class GoogleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  const GoogleSignInButton({super.key, this.onPressed, this.isLoading = false});
  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: isLoading ? null : onPressed,
    style: OutlinedButton.styleFrom(
      minimumSize: const Size(double.infinity, 56),
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
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(Assets.svg.google, width: 24, height: 24),
              const SizedBox(width: 12),
              const Text('Continue with Google'),
            ],
          ),
  );
}
