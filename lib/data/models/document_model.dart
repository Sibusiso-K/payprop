import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum DocumentType { lease, receipt, notice, invoice, other }

class DocumentModel extends Equatable {
  final String docId;
  final DocumentType type;
  final String title;
  final String url;
  final String uploadedBy;
  final String? relatedId; // tenancyId, paymentId, etc.
  final List<String> visibleTo; // list of uids
  final DateTime createdAt;
  final DateTime? expiresAt;

  const DocumentModel({
    required this.docId,
    required this.type,
    required this.title,
    required this.url,
    required this.uploadedBy,
    this.relatedId,
    this.visibleTo = const [],
    required this.createdAt,
    this.expiresAt,
  });

  bool get isExpired =>
      expiresAt != null && expiresAt!.isBefore(DateTime.now());

  factory DocumentModel.fromMap(Map<String, dynamic> map, String id) {
    return DocumentModel(
      docId: id,
      type: DocumentType.values.firstWhere(
        (t) => t.name == map['type'],
        orElse: () => DocumentType.other,
      ),
      title: map['title'] as String,
      url: map['url'] as String,
      uploadedBy: map['uploadedBy'] as String,
      relatedId: map['relatedId'] as String?,
      visibleTo: List<String>.from(map['visibleTo'] as List? ?? []),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      expiresAt: (map['expiresAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'type': type.name,
        'title': title,
        'url': url,
        'uploadedBy': uploadedBy,
        'relatedId': relatedId,
        'visibleTo': visibleTo,
        'createdAt': Timestamp.fromDate(createdAt),
        'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      };

  @override
  List<Object?> get props => [docId, type, title];
}
