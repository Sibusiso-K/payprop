import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../data/models/document_model.dart';
import '../../../data/repositories/document_repository.dart';
import '../../../providers/auth_provider.dart';

final _docRepoProvider =
    Provider<DocumentRepository>((_) => DocumentRepository());

final _tenantDocsProvider = StreamProvider<List<DocumentModel>>((ref) {
  final uid = ref.watch(currentUserProvider).uid;
  return ref.watch(_docRepoProvider).watchUserDocuments(uid);
});

class TenantDocumentsScreen extends ConsumerWidget {
  const TenantDocumentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docs = ref.watch(_tenantDocsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Documents')),
      body: docs.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (list) => list.isEmpty
            ? const Center(child: Text('No documents yet.'))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) => _DocumentCard(doc: list[i]),
              ),
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  final DocumentModel doc;
  const _DocumentCard({required this.doc});

  IconData get _icon => switch (doc.type) {
        DocumentType.lease => Icons.article_outlined,
        DocumentType.receipt => Icons.receipt_outlined,
        DocumentType.notice => Icons.notifications_outlined,
        DocumentType.invoice => Icons.request_page_outlined,
        DocumentType.other => Icons.description_outlined,
      };

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(_icon, color: Theme.of(context).colorScheme.primary),
        title: Text(doc.title),
        subtitle: Text(
          DateFormat('d MMM yyyy').format(doc.createdAt),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        trailing: IconButton(
          icon: const Icon(Icons.open_in_new),
          onPressed: () => launchUrl(Uri.parse(doc.url),
              mode: LaunchMode.externalApplication),
        ),
      ),
    );
  }
}
