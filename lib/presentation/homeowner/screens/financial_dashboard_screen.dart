import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/payment_model.dart';
import '../../../providers/payment_provider.dart';
import '../../shared/widgets/loading_widget.dart';

class FinancialDashboardScreen extends ConsumerWidget {
  const FinancialDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payments = ref.watch(ownerPaymentsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Financial Dashboard')),
      body: payments.when(
        loading: () => const AppLoadingWidget(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (list) {
          final total = list.fold(0.0, (s, p) => s + p.amount);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.ownerAccent, Color(0xFF047857)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Received',
                        style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 4),
                    Text(
                      'R${NumberFormat('#,##0.00').format(total)}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w700),
                    ),
                    Text('${list.length} payments',
                        style: const TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text('Recent Payments',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              ...list.map((p) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: AppColors.successLight,
                      child: const Icon(Icons.check, color: AppColors.success),
                    ),
                    title: Text(p.formattedAmount),
                    subtitle: Text(p.month),
                    trailing: p.paidAt != null
                        ? Text(DateFormat('d MMM').format(p.paidAt!))
                        : null,
                  )),
            ],
          );
        },
      ),
    );
  }
}
