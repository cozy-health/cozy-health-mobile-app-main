import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/legal_documents.dart';
import '../../../../core/theme/app_surface.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_pressable.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../gen/assets.gen.dart';

typedef LegalDocumentLoader = Future<List<Map<String, dynamic>>> Function();
typedef LegalLinkOpener = Future<bool> Function(String? url);

class TermsPoliciesScreen extends StatefulWidget {
  const TermsPoliciesScreen({
    super.key,
    this.title = 'Terms & Policies',
    this.documentId,
    this.loadDocuments = LegalDocuments.load,
    this.openLink = LegalDocuments.open,
  });
  final String title;
  final String? documentId;
  final LegalDocumentLoader loadDocuments;
  final LegalLinkOpener openLink;
  @override
  State<TermsPoliciesScreen> createState() => _TermsPoliciesScreenState();
}

class _TermsPoliciesScreenState extends State<TermsPoliciesScreen> {
  late Future<List<Map<String, dynamic>>> _documents;
  @override
  void initState() {
    super.initState();
    _documents = Future.sync(widget.loadDocuments);
  }

  String? get _documentId =>
      widget.documentId ??
      switch (widget.title) {
        'Terms' => 'tos',
        'Privacy Policy' => 'privacy_policy',
        _ => null,
      };
  Future<void> _open(String? route) async {
    var opened = false;
    try {
      opened = await widget.openLink(LegalDocuments.documentUrl(route));
    } catch (_) {
      // The bundled copy remains readable when the browser is unavailable.
    }
    if (!opened && mounted) {
      AppSnackbar.show(
        context,
        AppSnackbar.error(
          'The online document could not be opened. You can still read the bundled copy here.',
        ),
      );
    }
  }

  Future<void> _licenses() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      showLicensePage(
        context: context,
        applicationName: 'Cozy Health',
        applicationVersion: info.version,
        applicationIcon: SvgPicture.asset(
          Assets.svg.logo,
          width: 60,
          height: 60,
          semanticsLabel: 'Cozy Health logo',
        ),
      );
    } catch (_) {
      if (!mounted) return;
      AppSnackbar.show(
        context,
        AppSnackbar.error('Licenses could not be opened. Please try again.'),
      );
    }
  }

  Widget _status(Map<String, dynamic> doc) {
    final effective = DateTime.tryParse(
      doc['effective_date']?.toString() ?? '',
    );
    final status = doc['published'] != true
        ? 'Prepared document — not yet effective or available for acceptance'
        : effective == null
        ? 'Published'
        : 'Effective ${DateFormat('d MMMM yyyy', 'en_US').format(effective)}';
    return Text(
      'Version ${doc['version']} · $status',
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }

  Widget _message(String message, {bool retry = false}) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(message),
        if (retry) ...[
          const SizedBox(height: 16),
          AppButton(
            key: const ValueKey('legal-retry'),
            text: 'Try again',
            onPressed: () => setState(() {
              _documents = Future.sync(widget.loadDocuments);
            }),
          ),
        ],
      ],
    ),
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.title)),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _documents,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return SingleChildScrollView(
                  child: _message(
                    'Documents could not be loaded. Try again or contact Team@cozyhealth.org.',
                    retry: true,
                  ),
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = (snapshot.data ?? <Map<String, dynamic>>[])
                  .where(
                    (doc) =>
                        doc['audience'] == 'consumer' &&
                        (_documentId == null || doc['id'] == _documentId),
                  )
                  .toList();
              if (docs.isEmpty) {
                return _message(
                  'This document is not included in this build. Contact Team@cozyhealth.org for help.',
                );
              }
              return ListView(
                padding: const EdgeInsets.all(24),
                children: _documentId == null
                    ? [
                        const Text(
                          'Read the documents included with this app, even when offline. Each document shows its version and status. Reading a document does not record acceptance.',
                        ),
                        const SizedBox(height: 24),
                        for (final doc in docs) ...[
                          Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              border: AppSurface.border(context),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: AppPressable(
                              key: ValueKey('legal-document-${doc['id']}'),
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => TermsPoliciesScreen(
                                    title: doc['title'] as String,
                                    documentId: doc['id'] as String,
                                    loadDocuments: widget.loadDocuments,
                                    openLink: widget.openLink,
                                  ),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            doc['title'] as String,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.titleMedium,
                                          ),
                                          const SizedBox(height: 8),
                                          _status(doc),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Icon(Icons.chevron_right),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        AppButton(
                          key: const ValueKey('legal-licenses'),
                          text: 'Open source licenses',
                          isOutlined: true,
                          onPressed: _licenses,
                        ),
                      ]
                    : [
                        for (final doc in docs) ...[
                          Text(
                            doc['title'] as String,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          _status(doc),
                          if (doc['updated'] is String)
                            Text('Document updated: ${doc['updated']}'),
                          const SizedBox(height: 24),
                          for (final section in doc['sections'] as List) ...[
                            Semantics(
                              header: true,
                              child: Text(
                                section['heading'] as String,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            for (final paragraph
                                in section['paragraphs'] as List)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: SelectableText(paragraph as String),
                              ),
                            const SizedBox(height: 16),
                          ],
                          AppButton(
                            key: ValueKey('legal-${doc['id']}'),
                            text: 'Read current document online',
                            isOutlined: true,
                            onPressed: () => _open(doc['route'] as String?),
                          ),
                        ],
                      ],
              );
            },
          ),
        ),
      ),
    ),
  );
}
