import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../models/property_model.dart';
import '../models/tenancy_model.dart';

class PropertyRepository {
  final FirebaseFirestore _db;

  PropertyRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  // --- Properties ---

  Stream<List<PropertyModel>> watchAgentProperties(String agentId) {
    return _db
        .collection('properties')
        .where('agentId', isEqualTo: agentId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((s) => s.docs
            .map((d) => PropertyModel.fromMap(d.data(), d.id))
            .toList());
  }

  Stream<List<PropertyModel>> watchOwnerProperties(String ownerId) {
    return _db
        .collection('properties')
        .where('ownerId', isEqualTo: ownerId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((s) => s.docs
            .map((d) => PropertyModel.fromMap(d.data(), d.id))
            .toList());
  }

  Future<PropertyModel> getProperty(String propertyId) async {
    final doc = await _db.collection('properties').doc(propertyId).get();
    return PropertyModel.fromMap(doc.data()!, doc.id);
  }

  Future<String> createProperty(PropertyModel property) async {
    final id = const Uuid().v4();
    await _db.collection('properties').doc(id).set(property.toMap());
    return id;
  }

  Future<void> updateProperty(String id, Map<String, dynamic> updates) async {
    await _db.collection('properties').doc(id).update(updates);
  }

  // --- Tenancies ---

  Stream<TenancyModel?> watchTenantActiveTenancy(String tenantId) {
    return _db
        .collection('tenancies')
        .where('tenantId', isEqualTo: tenantId)
        .where('status', isEqualTo: 'active')
        .limit(1)
        .snapshots()
        .map((s) => s.docs.isEmpty
            ? null
            : TenancyModel.fromMap(s.docs.first.data(), s.docs.first.id));
  }

  Stream<List<TenancyModel>> watchPropertyTenancies(String propertyId) {
    return _db
        .collection('tenancies')
        .where('propertyId', isEqualTo: propertyId)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((s) => s.docs
            .map((d) => TenancyModel.fromMap(d.data(), d.id))
            .toList());
  }

  Future<String> createTenancy(TenancyModel tenancy) async {
    final id = const Uuid().v4();
    await _db.collection('tenancies').doc(id).set(tenancy.toMap());
    // increment occupiedUnits on property
    await _db
        .collection('properties')
        .doc(tenancy.propertyId)
        .update({'occupiedUnits': FieldValue.increment(1)});
    return id;
  }
}
