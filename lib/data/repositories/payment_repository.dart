import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../models/payment_model.dart';

class PaymentRepository {
  final FirebaseFirestore _db;

  PaymentRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  Stream<List<PaymentModel>> watchTenantPayments(String tenantId) {
    return _db
        .collection('payments')
        .where('tenantId', isEqualTo: tenantId)
        .orderBy('dueDate', descending: true)
        .limit(24)
        .snapshots()
        .map((s) => s.docs
            .map((d) => PaymentModel.fromMap(d.data(), d.id))
            .toList());
  }

  Stream<List<PaymentModel>> watchPropertyPayments(
    String propertyId, {
    PaymentStatus? status,
  }) {
    Query<Map<String, dynamic>> q = _db
        .collection('payments')
        .where('propertyId', isEqualTo: propertyId)
        .orderBy('dueDate', descending: true);

    if (status != null) {
      q = q.where('status', isEqualTo: status.name);
    }

    return q.snapshots().map(
        (s) => s.docs.map((d) => PaymentModel.fromMap(d.data(), d.id)).toList());
  }

  Stream<List<PaymentModel>> watchOwnerPayments(String ownerId) {
    return _db
        .collection('payments')
        .where('ownerId', isEqualTo: ownerId)
        .where('status', isEqualTo: PaymentStatus.completed.name)
        .orderBy('paidAt', descending: true)
        .limit(50)
        .snapshots()
        .map((s) => s.docs
            .map((d) => PaymentModel.fromMap(d.data(), d.id))
            .toList());
  }

  Future<PaymentModel?> getPendingPaymentForMonth(
    String tenantId,
    String month,
  ) async {
    final snap = await _db
        .collection('payments')
        .where('tenantId', isEqualTo: tenantId)
        .where('month', isEqualTo: month)
        .where('status', isEqualTo: PaymentStatus.pending.name)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;
    return PaymentModel.fromMap(snap.docs.first.data(), snap.docs.first.id);
  }

  Future<String> createPayment(PaymentModel payment) async {
    final id = const Uuid().v4();
    await _db.collection('payments').doc(id).set(payment.toMap());
    return id;
  }

  Future<void> updatePaymentStatus(
    String paymentId,
    PaymentStatus status, {
    String? paystackReference,
    DateTime? paidAt,
    String? receiptUrl,
  }) async {
    await _db.collection('payments').doc(paymentId).update({
      'status': status.name,
      if (paystackReference != null) 'paystackReference': paystackReference,
      if (paidAt != null) 'paidAt': Timestamp.fromDate(paidAt),
      if (receiptUrl != null) 'receiptUrl': receiptUrl,
    });
  }
}
