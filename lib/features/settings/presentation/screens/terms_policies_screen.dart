import 'package:flutter/material.dart';
import '../../../../core/services/legal_documents.dart';
import '../../../../core/widgets/app_button.dart';

class TermsPoliciesScreen extends StatelessWidget {
  const TermsPoliciesScreen({super.key, this.title = 'Terms & Policies'});
  final String title;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: SafeArea(
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: LegalDocuments.load(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Documents could not be loaded. Visit cozyhealth.org/legal or contact Team@cozyhealth.org.',
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data ?? [];
          final visible = docs.where(
            (doc) =>
                doc['audience'] == 'consumer' &&
                (title == 'Terms'
                    ? doc['id'] == 'tos'
                    : title == 'Privacy Policy'
                    ? doc['id'] == 'privacy_policy'
                    : true),
          );
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              for (final doc in visible) ...[
                Text(
                  doc['title'] as String,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Text(
                  'Version ${doc['version']} · ${doc['published'] == true ? 'Published' : 'Review draft, not yet available for acceptance'}',
                ),
                const SizedBox(height: 16),
                for (final section in doc['sections'] as List) ...[
                  Text(
                    section['heading'] as String,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  for (final paragraph in section['paragraphs'] as List)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(paragraph as String),
                    ),
                ],
                AppButton(
                  key: ValueKey('legal-${doc['id']}'),
                  text: 'Read current document online',
                  isOutlined: true,
                  onPressed: () => LegalDocuments.open(
                    'https://cozyhealth.org${doc['route']}',
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ],
          );
        },
      ),
    ),
  );
}
