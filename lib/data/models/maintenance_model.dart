import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum MaintenanceStatus { submitted, assigned, inProgress, completed, rejected }
enum MaintenancePriority { low, medium, high, urgent }
enum MaintenanceCategory { plumbing, electrical, structural, appliance, other }

class MaintenanceModel extends Equatable {
  final String requestId;
  final String propertyId;
  final String tenantId;
  final String agentId;
  final MaintenanceCategory category;
  final String description;
  final List<String> photos;
  final MaintenanceStatus status;
  final MaintenancePriority priority;
  final String? vendorId;
  final String? vendorName;
  final double? quote;
  final String? quoteApprovedBy;
  final String? agentNotes;
  final DateTime? resolvedAt;
  final DateTime createdAt;

  const MaintenanceModel({
    required this.requestId,
    required this.propertyId,
    required this.tenantId,
    required this.agentId,
    required this.category,
    required this.description,
    this.photos = const [],
    required this.status,
    required this.priority,
    this.vendorId,
    this.vendorName,
    this.quote,
    this.quoteApprovedBy,
    this.agentNotes,
    this.resolvedAt,
    required this.createdAt,
  });

  factory MaintenanceModel.fromMap(Map<String, dynamic> map, String id) {
    return MaintenanceModel(
      requestId: id,
      propertyId: map['propertyId'] as String,
      tenantId: map['tenantId'] as String,
      agentId: map['agentId'] as String,
      category: MaintenanceCategory.values.firstWhere(
        (c) => c.name == map['category'],
        orElse: () => MaintenanceCategory.other,
      ),
      description: map['description'] as String,
      photos: List<String>.from(map['photos'] as List? ?? []),
      status: MaintenanceStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => MaintenanceStatus.submitted,
      ),
      priority: MaintenancePriority.values.firstWhere(
        (p) => p.name == map['priority'],
        orElse: () => MaintenancePriority.medium,
      ),
      vendorId: map['vendorId'] as String?,
      vendorName: map['vendorName'] as String?,
      quote: (map['quote'] as num?)?.toDouble(),
      quoteApprovedBy: map['quoteApprovedBy'] as String?,
      agentNotes: map['agentNotes'] as String?,
      resolvedAt: (map['resolvedAt'] as Timestamp?)?.toDate(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'propertyId': propertyId,
        'tenantId': tenantId,
        'agentId': agentId,
        'category': category.name,
        'description': description,
        'photos': photos,
        'status': status.name,
        'priority': priority.name,
        'vendorId': vendorId,
        'vendorName': vendorName,
        'quote': quote,
        'quoteApprovedBy': quoteApprovedBy,
        'agentNotes': agentNotes,
        'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  MaintenanceModel copyWith({
    MaintenanceStatus? status,
    String? vendorId,
    String? vendorName,
    double? quote,
    String? quoteApprovedBy,
    String? agentNotes,
    DateTime? resolvedAt,
  }) =>
      MaintenanceModel(
        requestId: requestId,
        propertyId: propertyId,
        tenantId: tenantId,
        agentId: agentId,
        category: category,
        description: description,
        photos: photos,
        status: status ?? this.status,
        priority: priority,
        vendorId: vendorId ?? this.vendorId,
        vendorName: vendorName ?? this.vendorName,
        quote: quote ?? this.quote,
        quoteApprovedBy: quoteApprovedBy ?? this.quoteApprovedBy,
        agentNotes: agentNotes ?? this.agentNotes,
        resolvedAt: resolvedAt ?? this.resolvedAt,
        createdAt: createdAt,
      );

  @override
  List<Object?> get props => [requestId, propertyId, status];
}
