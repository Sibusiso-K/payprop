import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/property_provider.dart';
import '../../shared/widgets/loading_widget.dart';

class PropertyDetailsScreen extends ConsumerWidget {
  final String propertyId;
  const PropertyDetailsScreen({super.key, required this.propertyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final property = ref.watch(propertyProvider(propertyId));
    final tenancies = ref.watch(propertyTenanciesProvider(propertyId));

    return Scaffold(
      appBar: AppBar(title: const Text('Property Details')),
      body: property.when(
        loading: () => const AppLoadingWidget(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (p) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(p.name, style: Theme.of(context).textTheme.headlineMedium),
            Text(p.address.formatted,
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            Row(
              children: [
                _Detail(label: 'Total Units', value: '${p.totalUnits}'),
                const SizedBox(width: 16),
                _Detail(label: 'Occupied', value: '${p.occupiedUnits}'),
                const SizedBox(width: 16),
                _Detail(
                    label: 'Monthly Rent', value: p.monthlyRent.toStringAsFixed(0)),
              ],
            ),
            const Divider(height: 32),
            Text('Tenants', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            tenancies.when(
              data: (list) => list.isEmpty
                  ? const Text('No active tenants.')
                  : Column(
                      children: list
                          .map((t) => ListTile(
                                leading: const CircleAvatar(
                                    child: Icon(Icons.person)),
                                title: Text(t.tenantId),
                                subtitle: Text(
                                    'Unit ${t.unitNumber ?? "N/A"} · R${t.monthlyRent.toStringAsFixed(0)}/mo'),
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

class _Detail extends StatelessWidget {
  final String label;
  final String value;
  const _Detail({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}
