import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_router.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/maintenance_provider.dart';
import '../../../providers/property_provider.dart';
import '../../shared/widgets/loading_widget.dart';

class AgentDashboard extends ConsumerWidget {
  const AgentDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final properties = ref.watch(agentPropertiesProvider);
    final openMaintenance = ref.watch(agentOpenMaintenanceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Hi, ${user.displayName.split(' ').first}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_outlined),
            onPressed: () => context.go(AppRoutes.financialReports),
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: () => context.go(AppRoutes.communicationHub),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(agentPropertiesProvider),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Stats row
            properties.when(
              data: (list) {
                final totalUnits =
                    list.fold(0, (s, p) => s + p.totalUnits);
                final occupiedUnits =
                    list.fold(0, (s, p) => s + p.occupiedUnits);
                return Row(children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Properties',
                      value: '${list.length}',
                      color: AppColors.agentAccent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: 'Units',
                      value: '$occupiedUnits/$totalUnits',
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: 12),
                  openMaintenance.when(
                    data: (m) => Expanded(
                      child: _StatCard(
                        label: 'Open Issues',
                        value: '${m.length}',
                        color: m.isEmpty ? AppColors.success : AppColors.warning,
                      ),
                    ),
                    loading: () => const Expanded(child: AppLoadingWidget()),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ]);
              },
              loading: () => const AppLoadingWidget(),
              error: (e, _) => Text('Error: $e'),
            ),
            const SizedBox(height: 24),

            // Quick actions
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.build_outlined,
                    label: 'Maintenance',
                    onTap: () => context.go(AppRoutes.maintenanceManager),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.add_home_outlined,
                    label: 'Add Property',
                    onTap: () {}, // TODO: add property flow
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Properties list
            Text('My Properties',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            properties.when(
              data: (list) => list.isEmpty
                  ? const Text('No properties yet. Add your first one.')
                  : Column(
                      children: list
                          .map((p) => Card(
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: AppColors.primaryLight,
                                    child: Text(
                                      '${(p.occupancyRate * 100).round()}%',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  title: Text(p.name),
                                  subtitle: Text(p.address.formatted),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () => context.go(
                                    '/agent/property/${p.propertyId}',
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

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 48),
      ),
    );
  }
}
