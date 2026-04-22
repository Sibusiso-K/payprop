import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/models/message_model.dart';
import '../../../data/repositories/message_repository.dart';
import '../../../providers/auth_provider.dart';

final _messageRepoProvider =
    Provider<MessageRepository>((_) => MessageRepository());

final _threadsProvider = StreamProvider<List<MessageThread>>((ref) {
  final uid = ref.watch(currentUserProvider).uid;
  return ref.watch(_messageRepoProvider).watchThreads(uid);
});

class MessagesScreen extends ConsumerWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final threads = ref.watch(_threadsProvider);
    final uid = ref.watch(currentUserProvider).uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: threads.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (list) => list.isEmpty
            ? const Center(child: Text('No messages yet.'))
            : ListView.separated(
                itemCount: list.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final t = list[i];
                  final unread = t.unreadFor(uid);
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(t.participants.length.toString()),
                    ),
                    title: Text(
                      t.participants
                          .where((p) => p != uid)
                          .join(', '),
                    ),
                    subtitle: Text(
                      t.lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          DateFormat('d MMM').format(t.lastMessageAt),
                          style: const TextStyle(fontSize: 12),
                        ),
                        if (unread > 0) ...[
                          const SizedBox(height: 4),
                          CircleAvatar(
                            radius: 10,
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            child: Text(
                              '$unread',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 10),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
