import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/message_model.dart';
import '../../../data/repositories/message_repository.dart';
import '../../../providers/auth_provider.dart';
import '../../shared/widgets/loading_widget.dart';

final _agentMessageRepoProvider =
    Provider<MessageRepository>((_) => MessageRepository());

final _agentThreadsProvider = StreamProvider<List<MessageThread>>((ref) {
  final uid = ref.watch(currentUserProvider).uid;
  return ref.watch(_agentMessageRepoProvider).watchThreads(uid);
});

class CommunicationHubScreen extends ConsumerWidget {
  const CommunicationHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final threads = ref.watch(_agentThreadsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Communication Hub'),
        actions: [
          IconButton(
            icon: const Icon(Icons.campaign_outlined),
            tooltip: 'Broadcast',
            onPressed: () => _showBroadcastDialog(context),
          ),
        ],
      ),
      body: threads.when(
        loading: () => const AppLoadingWidget(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (list) => list.isEmpty
            ? const Center(child: Text('No conversations yet.'))
            : ListView.builder(
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final t = list[i];
                  return ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(t.lastMessageBy),
                    subtitle: Text(t.lastMessage,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: t.propertyId != null
                        ? const Icon(Icons.home_outlined, size: 16)
                        : null,
                  );
                },
              ),
      ),
    );
  }

  void _showBroadcastDialog(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Broadcast Announcement'),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Message',
            hintText: 'Send to all tenants...',
            alignLabelWithHint: true,
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              // TODO: Cloud Function broadcast
              Navigator.pop(context);
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }
}
