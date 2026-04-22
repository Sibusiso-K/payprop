import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/maintenance_model.dart';
import '../../../data/repositories/maintenance_repository.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/maintenance_provider.dart';
import '../../shared/widgets/loading_widget.dart';

final _ownerMaintenanceRepoProvider =
    Provider<MaintenanceRepository>((_) => MaintenanceRepository());

final _ownerMaintenanceProvider = StreamProvider<List<MaintenanceModel>>((ref) {
  final uid = ref.watch(currentUserProvider).uid;
  return ref
      .watch(_ownerMaintenanceRepoProvider)
      .watchAgentOpenRequests(uid); // re-uses the open-requests stream; Firestore rules restrict to owner
});

class ApprovalsScreen extends ConsumerWidget {
  const ApprovalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(_ownerMaintenanceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Pending Approvals')),
      body: requests.when(
        loading: () => const AppLoadingWidget(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (list) => list.isEmpty
            ? const Center(
                child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 64, color: AppColors.success),
                  SizedBox(height: 16),
                  Text('Nothing pending approval'),
                ],
              ))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) => _ApprovalCard(request: list[i]),
              ),
      ),
    );
  }
}

class _ApprovalCard extends ConsumerWidget {
  final MaintenanceModel request;
  const _ApprovalCard({required this.request});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(request.description,
                style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 4),
            Text('Vendor: ${request.vendorName ?? "TBD"}',
                style: Theme.of(context).textTheme.bodyMedium),
            if (request.quote != null) ...[
              const SizedBox(height: 8),
              Text(
                'Quote: R${NumberFormat('#,##0.00').format(request.quote)}',
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: AppColors.primary),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => ref
                      .read(maintenanceNotifierProvider.notifier)
                      .updateRequest(request.requestId,
                          {'status': MaintenanceStatus.rejected.name}),
                  style: TextButton.styleFrom(
                      foregroundColor: AppColors.error),
                  child: const Text('Reject'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => ref
                      .read(maintenanceNotifierProvider.notifier)
                      .approveQuote(
                        request.requestId,
                        quote: request.quote ?? 0,
                        approvedBy: ref.read(currentUserProvider).uid,
                      ),
                  child: const Text('Approve'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
