import 'package:flutter/material.dart';
import 'terms_policies_screen.dart';

/// Settings and authentication share the same offline document catalog.
class LegalHubScreen extends StatelessWidget {
  const LegalHubScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const TermsPoliciesScreen(title: 'Legal');
}
