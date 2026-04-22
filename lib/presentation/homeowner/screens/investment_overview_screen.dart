import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../providers/property_provider.dart';
import '../../shared/widgets/loading_widget.dart';

class InvestmentOverviewScreen extends ConsumerWidget {
  const InvestmentOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final properties = ref.watch(ownerPropertiesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Investment Overview')),
      body: properties.when(
        loading: () => const AppLoadingWidget(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (list) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ...list.map((p) => Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.name,
                            style: Theme.of(context).textTheme.titleMedium),
                        Text(p.address.formatted,
                            style: Theme.of(context).textTheme.bodyMedium),
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _Row('Occupancy',
                                '${(p.occupancyRate * 100).round()}%'),
                            _Row('Monthly Income',
                                'R${NumberFormat('#,##0').format(p.monthlyRent * p.occupiedUnits)}'),
                            _Row('Annual',
                                'R${NumberFormat('#,##0').format(p.monthlyRent * p.occupiedUnits * 12)}'),
                          ],
                        ),
                      ],
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 16)),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      );
}
