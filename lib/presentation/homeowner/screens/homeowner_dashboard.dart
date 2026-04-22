import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_router.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/payment_provider.dart';
import '../../../providers/property_provider.dart';
import '../../shared/widgets/loading_widget.dart';

class HomeownerDashboard extends ConsumerWidget {
  const HomeownerDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final properties = ref.watch(ownerPropertiesProvider);
    final payments = ref.watch(ownerPaymentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Hi, ${user.displayName.split(' ').first}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.approval_outlined),
            onPressed: () => context.go(AppRoutes.approvals),
          ),
          IconButton(
            icon: const Icon(Icons.folder_outlined),
            onPressed: () => context.go(AppRoutes.documentVault),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(ownerPropertiesProvider),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Portfolio summary
            properties.when(
              data: (props) {
                final totalIncome = payments.valueOrNull?.fold(
                        0.0, (s, p) => s + p.amount) ??
                    0.0;
                final occupancyAvg = props.isEmpty
                    ? 0.0
                    : props.fold(0.0, (s, p) => s + p.occupancyRate) /
                        props.length;

                return Column(
                  children: [
                    _SummaryCard(
                      title: 'Portfolio Value',
                      value:
                          'R${NumberFormat('#,##0').format(props.fold(0.0, (s, p) => s + p.monthlyRent * 12))}',
                      subtitle: '${props.length} properties',
                      icon: Icons.account_balance_outlined,
                      color: AppColors.ownerAccent,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _StatTile(
                            label: 'Monthly Income',
                            value:
                                'R${NumberFormat('#,##0').format(totalIncome)}',
                            color: AppColors.success,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatTile(
                            label: 'Avg Occupancy',
                            value:
                                '${(occupancyAvg * 100).round()}%',
                            color: occupancyAvg > 0.8
                                ? AppColors.success
                                : AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
              loading: () => const AppLoadingWidget(),
              error: (e, _) => Text('Error: $e'),
            ),
            const SizedBox(height: 24),

            // Navigation cards
            Row(
              children: [
                Expanded(
                  child: _NavCard(
                    icon: Icons.trending_up,
                    label: 'Investments',
                    onTap: () => context.go(AppRoutes.investmentOverview),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _NavCard(
                    icon: Icons.bar_chart,
                    label: 'Financials',
                    onTap: () => context.go(AppRoutes.financialDashboard),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Properties
            Text('My Properties',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            properties.when(
              data: (list) => Column(
                children: list
                    .map((p) => Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.ownerAccent.withOpacity(0.1),
                              child: const Icon(Icons.home,
                                  color: AppColors.ownerAccent),
                            ),
                            title: Text(p.name),
                            subtitle: Text(p.address.formatted),
                            trailing: Text(
                              '${(p.occupancyRate * 100).round()}%',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: p.occupancyRate > 0.8
                                    ? AppColors.success
                                    : AppColors.warning,
                              ),
                            ),
                          ),
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
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 40),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.bodyMedium),
              Text(value,
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: color)),
              Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatTile({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: color)),
        ],
      ),
    );
  }
}

class _NavCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _NavCard(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: AppColors.primary),
            const SizedBox(height: 8),
            Text(label, style: Theme.of(context).textTheme.labelLarge),
          ],
        ),
      ),
    );
  }
}
