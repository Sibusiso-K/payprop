import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/maintenance_model.dart';
import '../data/repositories/maintenance_repository.dart';
import 'auth_provider.dart';

final maintenanceRepositoryProvider =
    Provider<MaintenanceRepository>((_) => MaintenanceRepository());

/// Tenant: their maintenance requests
final tenantMaintenanceProvider = StreamProvider<List<MaintenanceModel>>((ref) {
  final uid = ref.watch(currentUserProvider).uid;
  return ref.watch(maintenanceRepositoryProvider).watchTenantRequests(uid);
});

/// Agent: open requests across all their properties
final agentOpenMaintenanceProvider =
    StreamProvider<List<MaintenanceModel>>((ref) {
  final uid = ref.watch(currentUserProvider).uid;
  return ref
      .watch(maintenanceRepositoryProvider)
      .watchAgentOpenRequests(uid);
});

/// Per-property requests
final propertyMaintenanceProvider =
    StreamProvider.family<List<MaintenanceModel>, String>((ref, propertyId) {
  return ref
      .watch(maintenanceRepositoryProvider)
      .watchPropertyRequests(propertyId);
});

class MaintenanceNotifier extends AsyncNotifier<void> {
  MaintenanceRepository get _repo =>
      ref.read(maintenanceRepositoryProvider);

  @override
  Future<void> build() async {}

  Future<void> submitRequest(MaintenanceModel request) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.createRequest(request));
  }

  Future<void> assignVendor(
    String requestId, {
    required String vendorId,
    required String vendorName,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repo.assignVendor(requestId,
          vendorId: vendorId, vendorName: vendorName),
    );
  }

  Future<void> approveQuote(
    String requestId, {
    required double quote,
    required String approvedBy,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repo.approveQuote(requestId, quote: quote, approvedBy: approvedBy),
    );
  }

  Future<void> closeRequest(String requestId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.closeRequest(requestId));
  }
}

final maintenanceNotifierProvider =
    AsyncNotifierProvider<MaintenanceNotifier, void>(MaintenanceNotifier.new);
