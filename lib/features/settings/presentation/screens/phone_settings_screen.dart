import 'package:flutter/material.dart';

class PhoneSettingsScreen extends StatelessWidget {
  const PhoneSettingsScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Phone settings')),
    body: const SafeArea(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Phone number updates and SMS verification are not available yet. No number has been verified or changed.',
        ),
      ),
    ),
  );
}
