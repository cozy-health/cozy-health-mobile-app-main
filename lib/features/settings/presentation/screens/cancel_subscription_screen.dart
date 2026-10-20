import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/widgets/app_button.dart';
class CancelSubscriptionScreen extends StatelessWidget {
  const CancelSubscriptionScreen({super.key});
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Manage subscription')), body: SafeArea(child: Padding(padding: const EdgeInsets.all(24), child: Column(children: [const Text('Manage renewal and cancellation in the store account used to purchase. Deleting your Cozy Health account does not cancel store billing.'), const SizedBox(height: 24), AppButton(text: 'Open store subscriptions', onPressed: () => launchUrl(Uri.parse(defaultTargetPlatform == TargetPlatform.iOS ? 'https://apps.apple.com/account/subscriptions' : 'https://play.google.com/store/account/subscriptions'), mode: LaunchMode.externalApplication))]))));
}
