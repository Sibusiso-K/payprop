import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class PropertyAddress extends Equatable {
  final String street;
  final String suburb;
  final String city;
  final String province;
  final String? postalCode;

  const PropertyAddress({
    required this.street,
    required this.suburb,
    required this.city,
    required this.province,
    this.postalCode,
  });

  factory PropertyAddress.fromMap(Map<String, dynamic> map) => PropertyAddress(
        street: map['street'] as String,
        suburb: map['suburb'] as String,
        city: map['city'] as String,
        province: map['province'] as String,
        postalCode: map['postalCode'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'street': street,
        'suburb': suburb,
        'city': city,
        'province': province,
        'postalCode': postalCode,
      };

  String get formatted => '$street, $suburb, $city';

  @override
  List<Object?> get props => [street, suburb, city, province];
}

enum PropertyType { apartment, house, complex, commercial }

class PropertyModel extends Equatable {
  final String propertyId;
  final String agentId;
  final String ownerId;
  final String name;
  final PropertyAddress address;
  final PropertyType type;
  final int totalUnits;
  final int occupiedUnits;
  final double monthlyRent;
  final String? description;
  final List<String> photos;
  final bool isActive;
  final DateTime createdAt;

  const PropertyModel({
    required this.propertyId,
    required this.agentId,
    required this.ownerId,
    required this.name,
    required this.address,
    required this.type,
    required this.totalUnits,
    required this.occupiedUnits,
    required this.monthlyRent,
    this.description,
    this.photos = const [],
    required this.isActive,
    required this.createdAt,
  });

  double get occupancyRate => totalUnits == 0 ? 0 : occupiedUnits / totalUnits;
  int get vacantUnits => totalUnits - occupiedUnits;

  factory PropertyModel.fromMap(Map<String, dynamic> map, String id) {
    return PropertyModel(
      propertyId: id,
      agentId: map['agentId'] as String,
      ownerId: map['ownerId'] as String,
      name: map['name'] as String,
      address: PropertyAddress.fromMap(map['address'] as Map<String, dynamic>),
      type: PropertyType.values.firstWhere(
        (t) => t.name == map['type'],
        orElse: () => PropertyType.apartment,
      ),
      totalUnits: map['totalUnits'] as int? ?? 1,
      occupiedUnits: map['occupiedUnits'] as int? ?? 0,
      monthlyRent: (map['monthlyRent'] as num).toDouble(),
      description: map['description'] as String?,
      photos: List<String>.from(map['photos'] as List? ?? []),
      isActive: map['isActive'] as bool? ?? true,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'agentId': agentId,
        'ownerId': ownerId,
        'name': name,
        'address': address.toMap(),
        'type': type.name,
        'totalUnits': totalUnits,
        'occupiedUnits': occupiedUnits,
        'monthlyRent': monthlyRent,
        'description': description,
        'photos': photos,
        'isActive': isActive,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  @override
  List<Object?> get props => [propertyId, agentId, ownerId, name];
}
