import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/payment_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/property_provider.dart';
import '../../../providers/payment_provider.dart';
import '../../shared/widgets/loading_widget.dart';

class FinancialReportsScreen extends ConsumerWidget {
  const FinancialReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final properties = ref.watch(agentPropertiesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Financial Reports')),
      body: properties.when(
        loading: () => const AppLoadingWidget(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (props) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Collection Overview',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            ...props.map((p) => _PropertyRevenueCard(propertyId: p.propertyId, propertyName: p.name)),
          ],
        ),
      ),
    );
  }
}

class _PropertyRevenueCard extends ConsumerWidget {
  final String propertyId;
  final String propertyName;
  const _PropertyRevenueCard({required this.propertyId, required this.propertyName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payments = ref.watch(propertyPaymentsProvider(propertyId));

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(propertyName, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            payments.when(
              data: (list) {
                final completed = list.where(
                    (p) => p.status == PaymentStatus.completed);
                final pending = list.where(
                    (p) => p.status == PaymentStatus.pending);
                final total = completed.fold(0.0, (s, p) => s + p.amount);
                return Row(
                  children: [
                    Expanded(
                        child: _Metric(
                            label: 'Collected',
                            value: 'R${NumberFormat('#,##0').format(total)}',
                            color: AppColors.success)),
                    Expanded(
                        child: _Metric(
                            label: 'Pending',
                            value: '${pending.length}',
                            color: AppColors.warning)),
                    Expanded(
                        child: _Metric(
                            label: 'Total Payments',
                            value: '${list.length}',
                            color: AppColors.agentAccent)),
                  ],
                );
              },
              loading: () => const AppLoadingWidget(),
              error: (e, _) => Text('Error: $e'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _Metric({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w700, color: color)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}
