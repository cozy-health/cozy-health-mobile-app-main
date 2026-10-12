import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AppleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool iconOnly;

  const AppleSignInButton({
    super.key,
    this.onPressed,
    this.isLoading = false,
    this.iconOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) {
      return const SizedBox.shrink();
    }
    if (iconOnly) {
      return Semantics(
        label: isLoading ? 'Signing in with Apple' : 'Continue with Apple',
        child: OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(56, 56),
            fixedSize: const Size(56, 56),
            padding: EdgeInsets.zero,
          ),
          child: isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
                  Icons.apple,
                  size: 28,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
        ),
      );
    }
    if (isLoading) {
      return Semantics(
        label: 'Signing in with Apple',
        child: const SizedBox(
          height: 56,
          width: double.infinity,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            ),
          ),
        ),
      );
    }
    return SignInWithAppleButton(
      onPressed: onPressed,
      height: 56,
      style: SignInWithAppleButtonStyle.black,
    );
  }
}
