import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../models/message_model.dart';

class MessageRepository {
  final FirebaseFirestore _db;

  MessageRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  Stream<List<MessageThread>> watchThreads(String uid) {
    return _db
        .collection('messages')
        .where('participants', arrayContains: uid)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((s) => s.docs
            .map((d) => MessageThread.fromMap(d.data(), d.id))
            .toList());
  }

  Stream<List<ChatMessage>> watchMessages(String threadId) {
    return _db
        .collection('messages')
        .doc(threadId)
        .collection('chats')
        .orderBy('createdAt')
        .snapshots()
        .map((s) => s.docs
            .map((d) => ChatMessage.fromMap(d.data(), d.id))
            .toList());
  }

  Future<String> getOrCreateThread({
    required List<String> participants,
    required Map<String, String> participantRoles,
    String? propertyId,
  }) async {
    final sorted = [...participants]..sort();
    final existing = await _db
        .collection('messages')
        .where('participants', isEqualTo: sorted)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) return existing.docs.first.id;

    final id = const Uuid().v4();
    final thread = MessageThread(
      threadId: id,
      participants: sorted,
      participantRoles: participantRoles,
      propertyId: propertyId,
      lastMessage: '',
      lastMessageAt: DateTime.now(),
      lastMessageBy: '',
      unreadCount: {for (final p in sorted) p: 0},
      createdAt: DateTime.now(),
    );
    await _db.collection('messages').doc(id).set(thread.toMap());
    return id;
  }

  Future<void> sendMessage(
    String threadId, {
    required String senderId,
    String? text,
    String? fileUrl,
    String? fileType,
    required List<String> participants,
  }) async {
    final msgId = const Uuid().v4();
    final now = DateTime.now();
    final message = ChatMessage(
      messageId: msgId,
      senderId: senderId,
      text: text,
      fileUrl: fileUrl,
      fileType: fileType,
      readBy: [senderId],
      createdAt: now,
    );

    final batch = _db.batch();
    batch.set(
      _db.collection('messages').doc(threadId).collection('chats').doc(msgId),
      message.toMap(),
    );
    final unreadUpdates = <String, dynamic>{
      'lastMessage': text ?? '📎 Attachment',
      'lastMessageAt': Timestamp.fromDate(now),
      'lastMessageBy': senderId,
    };
    for (final p in participants) {
      if (p != senderId) {
        unreadUpdates['unreadCount.$p'] = FieldValue.increment(1);
      }
    }
    batch.update(_db.collection('messages').doc(threadId), unreadUpdates);
    await batch.commit();
  }

  Future<void> markThreadRead(String threadId, String uid) async {
    await _db
        .collection('messages')
        .doc(threadId)
        .update({'unreadCount.$uid': 0});
  }
}
