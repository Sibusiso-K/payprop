import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/document_model.dart';
import '../../../data/repositories/document_repository.dart';
import '../../../providers/auth_provider.dart';

final _vaultDocsProvider = StreamProvider<List<DocumentModel>>((ref) {
  final uid = ref.watch(currentUserProvider).uid;
  return DocumentRepository().watchUserDocuments(uid);
});

class DocumentVaultScreen extends ConsumerWidget {
  const DocumentVaultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docs = ref.watch(_vaultDocsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Document Vault')),
      body: docs.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (list) {
          if (list.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.folder_open, size: 64, color: AppColors.textSecondary),
                  SizedBox(height: 16),
                  Text('No documents yet.'),
                ],
              ),
            );
          }

          final grouped = <DocumentType, List<DocumentModel>>{};
          for (final d in list) {
            grouped.putIfAbsent(d.type, () => []).add(d);
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: grouped.entries
                .map((e) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            e.key.name[0].toUpperCase() +
                                e.key.name.substring(1) +
                                's',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        ...e.value.map((d) => Card(
                              child: ListTile(
                                leading: const Icon(Icons.description_outlined,
                                    color: AppColors.primary),
                                title: Text(d.title),
                                subtitle: Text(
                                    DateFormat('d MMM yyyy').format(d.createdAt)),
                                trailing: IconButton(
                                  icon: const Icon(Icons.download_outlined),
                                  onPressed: () => launchUrl(
                                    Uri.parse(d.url),
                                    mode: LaunchMode.externalApplication,
                                  ),
                                ),
                              ),
                            )),
                        const SizedBox(height: 8),
                      ],
                    ))
                .toList(),
          );
        },
      ),
    );
  }
}
