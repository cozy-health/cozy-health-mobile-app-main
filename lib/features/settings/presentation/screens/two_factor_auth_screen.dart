import 'package:flutter/material.dart';

class TwoFactorAuthScreen extends StatelessWidget {
  const TwoFactorAuthScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Two-factor authentication')),
    body: const SafeArea(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Two-factor authentication setup is not available yet. This screen has not enabled additional account protection or generated recovery codes.',
        ),
      ),
    ),
  );
}
