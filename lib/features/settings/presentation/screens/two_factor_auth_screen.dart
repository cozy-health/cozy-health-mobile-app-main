import 'package:flutter/material.dart';
import '../../../auth/presentation/screens/signin_protection_screen.dart';

/// Compatibility screen for existing navigation links; no authenticator app.
class TwoFactorAuthScreen extends StatelessWidget {
  const TwoFactorAuthScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const SignInProtectionScreen(settings: true);
}
