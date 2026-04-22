import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../models/document_model.dart';

class DocumentRepository {
  final FirebaseFirestore _db;

  DocumentRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  Stream<List<DocumentModel>> watchUserDocuments(String uid) {
    return _db
        .collection('documents')
        .where('visibleTo', arrayContains: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs
            .map((d) => DocumentModel.fromMap(d.data(), d.id))
            .toList());
  }

  Stream<List<DocumentModel>> watchPropertyDocuments(String relatedId) {
    return _db
        .collection('documents')
        .where('relatedId', isEqualTo: relatedId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs
            .map((d) => DocumentModel.fromMap(d.data(), d.id))
            .toList());
  }

  Future<String> uploadDocument(DocumentModel doc) async {
    final id = const Uuid().v4();
    await _db.collection('documents').doc(id).set(doc.toMap());
    return id;
  }

  Future<void> deleteDocument(String docId) async {
    await _db.collection('documents').doc(docId).delete();
  }
}
