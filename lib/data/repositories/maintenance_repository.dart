import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../models/maintenance_model.dart';

class MaintenanceRepository {
  final FirebaseFirestore _db;

  MaintenanceRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  Stream<List<MaintenanceModel>> watchTenantRequests(String tenantId) {
    return _db
        .collection('maintenance')
        .where('tenantId', isEqualTo: tenantId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs
            .map((d) => MaintenanceModel.fromMap(d.data(), d.id))
            .toList());
  }

  Stream<List<MaintenanceModel>> watchAgentOpenRequests(String agentId) {
    return _db
        .collection('maintenance')
        .where('agentId', isEqualTo: agentId)
        .where('status', whereIn: [
          MaintenanceStatus.submitted.name,
          MaintenanceStatus.assigned.name,
          MaintenanceStatus.inProgress.name,
        ])
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs
            .map((d) => MaintenanceModel.fromMap(d.data(), d.id))
            .toList());
  }

  Stream<List<MaintenanceModel>> watchPropertyRequests(
    String propertyId, {
    MaintenanceStatus? status,
  }) {
    Query<Map<String, dynamic>> q = _db
        .collection('maintenance')
        .where('propertyId', isEqualTo: propertyId)
        .orderBy('createdAt', descending: true);

    if (status != null) q = q.where('status', isEqualTo: status.name);

    return q.snapshots().map(
        (s) => s.docs.map((d) => MaintenanceModel.fromMap(d.data(), d.id)).toList());
  }

  Future<String> createRequest(MaintenanceModel request) async {
    final id = const Uuid().v4();
    await _db.collection('maintenance').doc(id).set(request.toMap());
    return id;
  }

  Future<void> updateRequest(String requestId, Map<String, dynamic> updates) async {
    await _db.collection('maintenance').doc(requestId).update(updates);
  }

  Future<void> assignVendor(
    String requestId, {
    required String vendorId,
    required String vendorName,
  }) async {
    await _db.collection('maintenance').doc(requestId).update({
      'vendorId': vendorId,
      'vendorName': vendorName,
      'status': MaintenanceStatus.assigned.name,
    });
  }

  Future<void> approveQuote(
    String requestId, {
    required double quote,
    required String approvedBy,
  }) async {
    await _db.collection('maintenance').doc(requestId).update({
      'quote': quote,
      'quoteApprovedBy': approvedBy,
      'status': MaintenanceStatus.inProgress.name,
    });
  }

  Future<void> closeRequest(String requestId) async {
    await _db.collection('maintenance').doc(requestId).update({
      'status': MaintenanceStatus.completed.name,
      'resolvedAt': Timestamp.fromDate(DateTime.now()),
    });
  }
}
