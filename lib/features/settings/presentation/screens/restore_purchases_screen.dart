import 'package:flutter/material.dart';
import '../widgets/launch_billing_panel.dart';
class RestorePurchasesScreen extends StatelessWidget {
  const RestorePurchasesScreen({super.key});
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Restore purchases')), body: const SafeArea(child: SingleChildScrollView(padding: EdgeInsets.all(24), child: LaunchBillingPanel())));
}
