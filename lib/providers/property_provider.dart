import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/property_model.dart';
import '../data/models/tenancy_model.dart';
import '../data/repositories/property_repository.dart';
import 'auth_provider.dart';

final propertyRepositoryProvider =
    Provider<PropertyRepository>((_) => PropertyRepository());

/// Agent: live list of their properties
final agentPropertiesProvider = StreamProvider<List<PropertyModel>>((ref) {
  final uid = ref.watch(currentUserProvider).uid;
  return ref.watch(propertyRepositoryProvider).watchAgentProperties(uid);
});

/// Owner: live list of their properties
final ownerPropertiesProvider = StreamProvider<List<PropertyModel>>((ref) {
  final uid = ref.watch(currentUserProvider).uid;
  return ref.watch(propertyRepositoryProvider).watchOwnerProperties(uid);
});

/// Single property by id
final propertyProvider =
    FutureProvider.family<PropertyModel, String>((ref, id) {
  return ref.watch(propertyRepositoryProvider).getProperty(id);
});

/// Property tenancies
final propertyTenanciesProvider =
    StreamProvider.family<List<TenancyModel>, String>((ref, propertyId) {
  return ref
      .watch(propertyRepositoryProvider)
      .watchPropertyTenancies(propertyId);
});

/// Tenant: their active tenancy
final activeTenancyProvider = StreamProvider<TenancyModel?>((ref) {
  final uid = ref.watch(currentUserProvider).uid;
  return ref
      .watch(propertyRepositoryProvider)
      .watchTenantActiveTenancy(uid);
});
