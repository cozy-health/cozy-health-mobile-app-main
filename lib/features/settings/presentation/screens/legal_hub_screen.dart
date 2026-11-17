import 'package:flutter/material.dart';
import '../../../../core/services/legal_documents.dart';
import 'terms_policies_screen.dart';

/// Settings and authentication share the same offline document catalog.
class LegalHubScreen extends StatelessWidget {
  const LegalHubScreen({super.key, this.loadDocuments = LegalDocuments.load});

  final LegalDocumentLoader loadDocuments;

  @override
  Widget build(BuildContext context) =>
      TermsPoliciesScreen(title: 'Legal', loadDocuments: loadDocuments);
}
