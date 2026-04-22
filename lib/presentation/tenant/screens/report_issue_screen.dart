import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/maintenance_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/maintenance_provider.dart';
import '../../../providers/property_provider.dart';

class ReportIssueScreen extends ConsumerStatefulWidget {
  const ReportIssueScreen({super.key});

  @override
  ConsumerState<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends ConsumerState<ReportIssueScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descCtrl = TextEditingController();
  MaintenanceCategory _category = MaintenanceCategory.other;
  MaintenancePriority _priority = MaintenancePriority.medium;
  final List<String> _photoPaths = [];

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) setState(() => _photoPaths.add(file.path));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(currentUserProvider);
    final tenancy = ref.read(activeTenancyProvider).valueOrNull;
    if (tenancy == null) return;

    final request = MaintenanceModel(
      requestId: const Uuid().v4(),
      propertyId: tenancy.propertyId,
      tenantId: user.uid,
      agentId: tenancy.agentId,
      category: _category,
      description: _descCtrl.text.trim(),
      photos: const [], // TODO: upload to Firebase Storage first
      status: MaintenanceStatus.submitted,
      priority: _priority,
      createdAt: DateTime.now(),
    );

    await ref.read(maintenanceNotifierProvider.notifier).submitRequest(request);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(maintenanceNotifierProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Report Issue')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Category', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              DropdownButtonFormField<MaintenanceCategory>(
                value: _category,
                decoration: const InputDecoration(),
                items: MaintenanceCategory.values
                    .map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(c.name[0].toUpperCase() + c.name.substring(1))))
                    .toList(),
                onChanged: (v) => setState(() => _category = v!),
              ),
              const SizedBox(height: 16),
              Text('Priority', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              SegmentedButton<MaintenancePriority>(
                segments: MaintenancePriority.values
                    .map((p) => ButtonSegment(
                        value: p,
                        label: Text(p.name[0].toUpperCase() + p.name.substring(1))))
                    .toList(),
                selected: {_priority},
                onSelectionChanged: (s) => setState(() => _priority = s.first),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Describe the issue in detail...',
                  alignLabelWithHint: true,
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _pickPhoto,
                icon: const Icon(Icons.photo_library_outlined),
                label: Text('Add Photos (${_photoPaths.length})'),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: isLoading ? null : _submit,
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Submit Report'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
