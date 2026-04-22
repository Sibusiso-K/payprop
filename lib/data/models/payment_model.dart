import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

enum PaymentStatus { pending, completed, failed }
enum PaymentType { rent, deposit, penalty, refund }

class PaymentModel extends Equatable {
  final String paymentId;
  final String tenancyId;
  final String tenantId;
  final String propertyId;
  final String agentId;
  final String ownerId;
  final double amount;
  final PaymentType type;
  final PaymentStatus status;
  final String? paystackReference;
  final String? paystackAuthUrl;
  final String month; // "2025-04" format for querying
  final DateTime dueDate;
  final DateTime? paidAt;
  final String? receiptUrl;
  final DateTime createdAt;

  const PaymentModel({
    required this.paymentId,
    required this.tenancyId,
    required this.tenantId,
    required this.propertyId,
    required this.agentId,
    required this.ownerId,
    required this.amount,
    required this.type,
    required this.status,
    this.paystackReference,
    this.paystackAuthUrl,
    required this.month,
    required this.dueDate,
    this.paidAt,
    this.receiptUrl,
    required this.createdAt,
  });

  bool get isOverdue =>
      status == PaymentStatus.pending && dueDate.isBefore(DateTime.now());

  String get formattedAmount =>
      'R${NumberFormat('#,##0.00').format(amount)}';

  factory PaymentModel.fromMap(Map<String, dynamic> map, String id) {
    return PaymentModel(
      paymentId: id,
      tenancyId: map['tenancyId'] as String,
      tenantId: map['tenantId'] as String,
      propertyId: map['propertyId'] as String,
      agentId: map['agentId'] as String,
      ownerId: map['ownerId'] as String,
      amount: (map['amount'] as num).toDouble(),
      type: PaymentType.values.firstWhere(
        (t) => t.name == map['type'],
        orElse: () => PaymentType.rent,
      ),
      status: PaymentStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => PaymentStatus.pending,
      ),
      paystackReference: map['paystackReference'] as String?,
      paystackAuthUrl: map['paystackAuthUrl'] as String?,
      month: map['month'] as String,
      dueDate: (map['dueDate'] as Timestamp).toDate(),
      paidAt: (map['paidAt'] as Timestamp?)?.toDate(),
      receiptUrl: map['receiptUrl'] as String?,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'tenancyId': tenancyId,
        'tenantId': tenantId,
        'propertyId': propertyId,
        'agentId': agentId,
        'ownerId': ownerId,
        'amount': amount,
        'type': type.name,
        'status': status.name,
        'paystackReference': paystackReference,
        'paystackAuthUrl': paystackAuthUrl,
        'month': month,
        'dueDate': Timestamp.fromDate(dueDate),
        'paidAt': paidAt != null ? Timestamp.fromDate(paidAt!) : null,
        'receiptUrl': receiptUrl,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  @override
  List<Object?> get props => [paymentId, tenancyId, status, month];
}
