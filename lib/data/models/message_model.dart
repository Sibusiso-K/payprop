import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class MessageThread extends Equatable {
  final String threadId;
  final List<String> participants;
  final Map<String, String> participantRoles; // uid -> role name
  final String? propertyId;
  final String lastMessage;
  final DateTime lastMessageAt;
  final String lastMessageBy;
  final Map<String, int> unreadCount; // uid -> count
  final DateTime createdAt;

  const MessageThread({
    required this.threadId,
    required this.participants,
    required this.participantRoles,
    this.propertyId,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.lastMessageBy,
    required this.unreadCount,
    required this.createdAt,
  });

  int unreadFor(String uid) => unreadCount[uid] ?? 0;

  factory MessageThread.fromMap(Map<String, dynamic> map, String id) {
    return MessageThread(
      threadId: id,
      participants: List<String>.from(map['participants'] as List),
      participantRoles: Map<String, String>.from(map['participantRoles'] as Map? ?? {}),
      propertyId: map['propertyId'] as String?,
      lastMessage: map['lastMessage'] as String? ?? '',
      lastMessageAt: (map['lastMessageAt'] as Timestamp).toDate(),
      lastMessageBy: map['lastMessageBy'] as String? ?? '',
      unreadCount: Map<String, int>.from(map['unreadCount'] as Map? ?? {}),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'participants': participants,
        'participantRoles': participantRoles,
        'propertyId': propertyId,
        'lastMessage': lastMessage,
        'lastMessageAt': Timestamp.fromDate(lastMessageAt),
        'lastMessageBy': lastMessageBy,
        'unreadCount': unreadCount,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  @override
  List<Object?> get props => [threadId, participants, lastMessageAt];
}

class ChatMessage extends Equatable {
  final String messageId;
  final String senderId;
  final String? text;
  final String? fileUrl;
  final String? fileType; // 'image' | 'pdf' | 'doc'
  final List<String> readBy;
  final DateTime createdAt;

  const ChatMessage({
    required this.messageId,
    required this.senderId,
    this.text,
    this.fileUrl,
    this.fileType,
    required this.readBy,
    required this.createdAt,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map, String id) {
    return ChatMessage(
      messageId: id,
      senderId: map['senderId'] as String,
      text: map['text'] as String?,
      fileUrl: map['fileUrl'] as String?,
      fileType: map['fileType'] as String?,
      readBy: List<String>.from(map['readBy'] as List? ?? []),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'senderId': senderId,
        'text': text,
        'fileUrl': fileUrl,
        'fileType': fileType,
        'readBy': readBy,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  @override
  List<Object?> get props => [messageId, senderId, createdAt];
}
