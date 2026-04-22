import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/payment_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/payment_provider.dart';
import '../../../providers/property_provider.dart';

class RentPaymentScreen extends ConsumerWidget {
  const RentPaymentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tenancy = ref.watch(activeTenancyProvider);
    final user = ref.watch(currentUserProvider);
    final isLoading = ref.watch(paymentNotifierProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Pay Rent')),
      body: tenancy.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (t) {
          if (t == null) {
            return const Center(child: Text('No active tenancy found.'));
          }
          final now = DateTime.now();
          final month = DateFormat('yyyy-MM').format(now);
          final dueDate = DateTime(now.year, now.month + 1, 1);

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Monthly Rent',
                          style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 4),
                      Text(
                        'R${NumberFormat('#,##0.00').format(t.monthlyRent)}',
                        style: Theme.of(context)
                            .textTheme
                            .displayMedium
                            ?.copyWith(color: AppColors.primary),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Due: ${DateFormat('d MMMM yyyy').format(dueDate)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Payment is processed securely via Paystack.'),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: isLoading
                      ? null
                      : () async {
                          final payment = PaymentModel(
                            paymentId: '',
                            tenancyId: t.tenancyId,
                            tenantId: user.uid,
                            propertyId: t.propertyId,
                            agentId: t.agentId,
                            ownerId: t.ownerId,
                            amount: t.monthlyRent,
                            type: PaymentType.rent,
                            status: PaymentStatus.pending,
                            month: month,
                            dueDate: dueDate,
                            createdAt: DateTime.now(),
                          );

                          final url = await ref
                              .read(paymentNotifierProvider.notifier)
                              .initiateRentPayment(
                                payment: payment,
                                email: user.email,
                              );

                          if (url.isNotEmpty && context.mounted) {
                            await launchUrl(Uri.parse(url),
                                mode: LaunchMode.externalApplication);
                          }
                        },
                  icon: isLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.payment),
                  label: const Text('Pay with Paystack'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
