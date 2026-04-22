import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_router.dart';
import '../../../data/models/payment_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/maintenance_provider.dart';
import '../../../providers/payment_provider.dart';
import '../../../providers/property_provider.dart';
import '../../shared/widgets/loading_widget.dart';

class TenantDashboard extends ConsumerWidget {
  const TenantDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final tenancy = ref.watch(activeTenancyProvider);
    final payments = ref.watch(tenantPaymentsProvider);
    final maintenance = ref.watch(tenantMaintenanceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Hi, ${user.displayName.split(' ').first}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: () => context.go(AppRoutes.tenantMessages),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(activeTenancyProvider),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Rent due card
            tenancy.when(
              data: (t) {
                if (t == null) {
                  return const _InfoCard(
                    title: 'No active tenancy',
                    subtitle: 'Contact your agent to get linked.',
                    icon: Icons.home_outlined,
                    color: AppColors.textSecondary,
                  );
                }
                final dueDate = DateTime(
                    DateTime.now().year, DateTime.now().month + 1, 1);
                return _RentDueCard(
                  amount: t.monthlyRent,
                  dueDate: dueDate,
                  onPay: () => context.go(AppRoutes.rentPayment),
                );
              },
              loading: () => const AppLoadingWidget(),
              error: (e, _) => Text('Error: $e'),
            ),
            const SizedBox(height: 16),

            // Quick actions
            Row(
              children: [
                Expanded(
                  child: _QuickAction(
                    icon: Icons.build_outlined,
                    label: 'Report Issue',
                    color: AppColors.warning,
                    onTap: () => context.go(AppRoutes.reportIssue),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickAction(
                    icon: Icons.description_outlined,
                    label: 'Documents',
                    color: AppColors.info,
                    onTap: () => context.go(AppRoutes.tenantDocuments),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Recent payments
            Text('Payment History',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            payments.when(
              data: (list) => list.isEmpty
                  ? const Text('No payments yet.')
                  : Column(
                      children: list
                          .take(5)
                          .map((p) => _PaymentTile(payment: p))
                          .toList(),
                    ),
              loading: () => const AppLoadingWidget(),
              error: (e, _) => Text('Error: $e'),
            ),

            const SizedBox(height: 24),

            // Maintenance requests
            Text('Maintenance', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            maintenance.when(
              data: (list) => list.isEmpty
                  ? const Text('No open requests.')
                  : Column(
                      children: list
                          .take(3)
                          .map((m) => ListTile(
                                leading: const Icon(Icons.build_outlined),
                                title: Text(m.description,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                                subtitle: Text(m.status.name.toUpperCase()),
                                trailing: _statusChip(m.status),
                              ))
                          .toList(),
                    ),
              loading: () => const AppLoadingWidget(),
              error: (e, _) => Text('Error: $e'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(dynamic status) {
    final color = switch (status.name) {
      'completed' => AppColors.success,
      'inProgress' => AppColors.warning,
      'submitted' => AppColors.info,
      _ => AppColors.textSecondary,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.name,
        style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _RentDueCard extends StatelessWidget {
  final double amount;
  final DateTime dueDate;
  final VoidCallback onPay;

  const _RentDueCard({
    required this.amount,
    required this.dueDate,
    required this.onPay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Rent Due',
              style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 4),
          Text(
            'R${NumberFormat('#,##0.00').format(amount)}',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Due ${DateFormat('d MMM yyyy').format(dueDate)}',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onPay,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              minimumSize: const Size(double.infinity, 44),
            ),
            child: const Text('Pay Now'),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _InfoCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: Theme.of(context).textTheme.titleMedium),
                  Text(subtitle,
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color)),
          ],
        ),
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  final PaymentModel payment;
  const _PaymentTile({required this.payment});

  @override
  Widget build(BuildContext context) {
    final color = switch (payment.status) {
      PaymentStatus.completed => AppColors.success,
      PaymentStatus.failed => AppColors.error,
      PaymentStatus.pending => AppColors.warning,
    };
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.1),
        child: Icon(Icons.receipt_outlined, color: color),
      ),
      title: Text(payment.formattedAmount),
      subtitle: Text(payment.month),
      trailing: Text(
        payment.status.name.toUpperCase(),
        style: TextStyle(
            fontSize: 11, color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}
