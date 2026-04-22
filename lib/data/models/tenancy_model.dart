import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum TenancyStatus { active, expired, terminated }

class TenancyModel extends Equatable {
  final String tenancyId;
  final String propertyId;
  final String tenantId;
  final String agentId;
  final String ownerId;
  final String? unitNumber;
  final double monthlyRent;
  final double depositAmount;
  final bool depositPaid;
  final DateTime leaseStart;
  final DateTime leaseEnd;
  final TenancyStatus status;
  final DateTime createdAt;

  const TenancyModel({
    required this.tenancyId,
    required this.propertyId,
    required this.tenantId,
    required this.agentId,
    required this.ownerId,
    this.unitNumber,
    required this.monthlyRent,
    required this.depositAmount,
    required this.depositPaid,
    required this.leaseStart,
    required this.leaseEnd,
    required this.status,
    required this.createdAt,
  });

  bool get isExpiringSoon {
    final daysUntilExpiry = leaseEnd.difference(DateTime.now()).inDays;
    return daysUntilExpiry <= 30 && daysUntilExpiry > 0;
  }

  factory TenancyModel.fromMap(Map<String, dynamic> map, String id) {
    return TenancyModel(
      tenancyId: id,
      propertyId: map['propertyId'] as String,
      tenantId: map['tenantId'] as String,
      agentId: map['agentId'] as String,
      ownerId: map['ownerId'] as String,
      unitNumber: map['unitNumber'] as String?,
      monthlyRent: (map['monthlyRent'] as num).toDouble(),
      depositAmount: (map['depositAmount'] as num).toDouble(),
      depositPaid: map['depositPaid'] as bool? ?? false,
      leaseStart: (map['leaseStart'] as Timestamp).toDate(),
      leaseEnd: (map['leaseEnd'] as Timestamp).toDate(),
      status: TenancyStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => TenancyStatus.active,
      ),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'propertyId': propertyId,
        'tenantId': tenantId,
        'agentId': agentId,
        'ownerId': ownerId,
        'unitNumber': unitNumber,
        'monthlyRent': monthlyRent,
        'depositAmount': depositAmount,
        'depositPaid': depositPaid,
        'leaseStart': Timestamp.fromDate(leaseStart),
        'leaseEnd': Timestamp.fromDate(leaseEnd),
        'status': status.name,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  @override
  List<Object?> get props => [tenancyId, propertyId, tenantId, status];
}
