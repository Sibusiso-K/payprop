import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/payment_model.dart';
import '../data/repositories/payment_repository.dart';
import '../data/services/paystack_service.dart';
import 'auth_provider.dart';

final paymentRepositoryProvider =
    Provider<PaymentRepository>((_) => PaymentRepository());

final paystackServiceProvider =
    Provider<PaystackService>((_) => PaystackService());

/// Tenant: their payment history
final tenantPaymentsProvider = StreamProvider<List<PaymentModel>>((ref) {
  final uid = ref.watch(currentUserProvider).uid;
  return ref.watch(paymentRepositoryProvider).watchTenantPayments(uid);
});

/// Agent: payments for a specific property
final propertyPaymentsProvider =
    StreamProvider.family<List<PaymentModel>, String>((ref, propertyId) {
  return ref
      .watch(paymentRepositoryProvider)
      .watchPropertyPayments(propertyId);
});

/// Owner: received payments
final ownerPaymentsProvider = StreamProvider<List<PaymentModel>>((ref) {
  final uid = ref.watch(currentUserProvider).uid;
  return ref.watch(paymentRepositoryProvider).watchOwnerPayments(uid);
});

class PaymentNotifier extends AsyncNotifier<void> {
  PaymentRepository get _repo => ref.read(paymentRepositoryProvider);
  PaystackService get _paystack => ref.read(paystackServiceProvider);

  @override
  Future<void> build() async {}

  Future<String> initiateRentPayment({
    required PaymentModel payment,
    required String email,
  }) async {
    state = const AsyncLoading();
    late String authUrl;
    state = await AsyncValue.guard(() async {
      final paymentId = await _repo.createPayment(payment);
      final result = await _paystack.initializePayment(
        paymentId: paymentId,
        tenantId: payment.tenantId,
        email: email,
        amount: payment.amount,
      );
      authUrl = result.authorizationUrl;
    });
    return authUrl;
  }
}

final paymentNotifierProvider =
    AsyncNotifierProvider<PaymentNotifier, void>(PaymentNotifier.new);
