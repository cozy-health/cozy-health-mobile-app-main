import 'package:flutter/material.dart';

class ConnectedAppsScreen extends StatelessWidget {
  const ConnectedAppsScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Connected apps')),
    body: const SafeArea(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Health, fitness, and calendar integrations are not available yet. No external account is connected through this screen.',
        ),
      ),
    ),
  );
}
