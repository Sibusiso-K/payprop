import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/maintenance_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/maintenance_provider.dart';
import '../../shared/widgets/loading_widget.dart';

class MaintenanceManagerScreen extends ConsumerWidget {
  const MaintenanceManagerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(agentOpenMaintenanceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Maintenance')),
      body: requests.when(
        loading: () => const AppLoadingWidget(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (list) => list.isEmpty
            ? const Center(child: Text('No open maintenance requests.'))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) => _MaintenanceCard(request: list[i]),
              ),
      ),
    );
  }
}

class _MaintenanceCard extends ConsumerWidget {
  final MaintenanceModel request;
  const _MaintenanceCard({required this.request});

  Color get _priorityColor => switch (request.priority) {
        MaintenancePriority.urgent => AppColors.error,
        MaintenancePriority.high => AppColors.warning,
        MaintenancePriority.medium => AppColors.info,
        MaintenancePriority.low => AppColors.textSecondary,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _priorityColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    request.priority.name.toUpperCase(),
                    style: TextStyle(
                        fontSize: 11,
                        color: _priorityColor,
                        fontWeight: FontWeight.w700),
                  ),
                ),
                const Spacer(),
                Text(
                  DateFormat('d MMM').format(request.createdAt),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(request.description,
                style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 4),
            Text(
              request.category.name[0].toUpperCase() +
                  request.category.name.substring(1),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (request.status == MaintenanceStatus.submitted)
                  TextButton(
                    onPressed: () => _showAssignDialog(context, ref),
                    child: const Text('Assign Vendor'),
                  ),
                if (request.status == MaintenanceStatus.assigned)
                  TextButton(
                    onPressed: () => _showQuoteDialog(context, ref),
                    child: const Text('Approve Quote'),
                  ),
                if (request.status == MaintenanceStatus.inProgress)
                  TextButton(
                    onPressed: () => ref
                        .read(maintenanceNotifierProvider.notifier)
                        .closeRequest(request.requestId),
                    child: const Text('Mark Complete'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAssignDialog(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Assign Vendor'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Vendor Name'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              ref.read(maintenanceNotifierProvider.notifier).assignVendor(
                    request.requestId,
                    vendorId: 'manual',
                    vendorName: ctrl.text.trim(),
                  );
              Navigator.pop(context);
            },
            child: const Text('Assign'),
          ),
        ],
      ),
    );
  }

  void _showQuoteDialog(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController();
    final uid = ref.read(currentUserProvider).uid;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Approve Quote'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Amount (R)'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(ctrl.text);
              if (amount != null) {
                ref.read(maintenanceNotifierProvider.notifier).approveQuote(
                      request.requestId,
                      quote: amount,
                      approvedBy: uid,
                    );
              }
              Navigator.pop(context);
            },
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }
}
