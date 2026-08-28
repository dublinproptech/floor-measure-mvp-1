import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../admin/application/admin_providers.dart' show usersProvider;
import '../../data/snag_model.dart';
import '../../application/snaglist_providers.dart';

/// Shows the add/edit sheet. Pass an existing [existing] to edit, or null to add.
Future<void> showSnagFormSheet(
  BuildContext context, {
  required String projectId,
  SnagModel? existing,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => _SnagFormSheet(projectId: projectId, existing: existing),
  );
}

class _SnagFormSheet extends ConsumerStatefulWidget {
  const _SnagFormSheet({required this.projectId, this.existing});

  final String projectId;
  final SnagModel? existing;

  @override
  ConsumerState<_SnagFormSheet> createState() => _SnagFormSheetState();
}

class _SnagFormSheetState extends ConsumerState<_SnagFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _locationCtrl;
  late final TextEditingController _descriptionCtrl;
  late final TextEditingController _categoryCtrl;
  late SnagPriority _priority;
  late SnagStatus _status;
  String? _assignedTo;
  DateTime? _completionDate;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _locationCtrl = TextEditingController(text: e?.location ?? '');
    _descriptionCtrl = TextEditingController(text: e?.description ?? '');
    _categoryCtrl = TextEditingController(text: e?.category ?? '');
    _priority = e?.priority ?? SnagPriority.low;
    _status = e?.status ?? SnagStatus.open;
    _assignedTo = e?.assignedTo;
    _completionDate = e?.completionDate;
  }

  @override
  void dispose() {
    _locationCtrl.dispose();
    _descriptionCtrl.dispose();
    _categoryCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickCompletionDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _completionDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _completionDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final controller = ref.read(snagFormControllerProvider.notifier);
    final isEdit = widget.existing != null;

    final model = SnagModel(
      id: widget.existing?.id ?? '',
      projectId: widget.projectId,
      roomId: widget.existing?.roomId,
      ref: widget.existing?.ref ?? await controller.nextRef(widget.projectId),
      location: _locationCtrl.text.trim(),
      description: _descriptionCtrl.text.trim(),
      category: _categoryCtrl.text.trim(),
      priority: _priority,
      status: _status,
      assignedTo: _assignedTo,
      completionDate: _completionDate,
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
    );

    await controller.save(model);

    if (!mounted) return;
    final error = ref.read(snagFormControllerProvider).error;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save: $error')),
      );
      return;
    }
    Navigator.of(context).pop();
    if (!isEdit) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${model.ref} logged')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final saving = ref.watch(snagFormControllerProvider).isLoading;
    final usersAsync = ref.watch(usersProvider);
    final isEdit = widget.existing != null;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isEdit ? 'Edit Snag${widget.existing!.ref.isNotEmpty ? ' (${widget.existing!.ref})' : ''}' : 'Log Snag',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationCtrl,
                decoration: const InputDecoration(labelText: 'Room / location'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionCtrl,
                decoration: const InputDecoration(labelText: 'Issue description'),
                maxLines: 3,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _categoryCtrl,
                decoration: const InputDecoration(labelText: 'Category (e.g. Flooring, Wall, Fixture)'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<SnagPriority>(
                initialValue: _priority,
                decoration: const InputDecoration(labelText: 'Priority'),
                items: SnagPriority.values
                    .map((p) => DropdownMenuItem(value: p, child: Text(p.name)))
                    .toList(),
                onChanged: (p) => setState(() => _priority = p ?? _priority),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<SnagStatus>(
                initialValue: _status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: SnagStatus.values
                    .map((s) => DropdownMenuItem(value: s, child: Text(s.name)))
                    .toList(),
                onChanged: (s) => setState(() => _status = s ?? _status),
              ),
              const SizedBox(height: 12),
              usersAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Could not load users: $e'),
                data: (users) => DropdownButtonFormField<String>(
                  initialValue: _assignedTo,
                  decoration: const InputDecoration(labelText: 'Assign to'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Unassigned')),
                    ...users.map((u) => DropdownMenuItem(value: u.id, child: Text(u.name))),
                  ],
                  onChanged: (id) => setState(() => _assignedTo = id),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  _completionDate == null
                      ? 'Completion date (optional)'
                      : 'Completion date: ${_completionDate!.toLocal().toString().split(' ').first}',
                ),
                trailing: const Icon(Icons.calendar_today, size: 20),
                onTap: _pickCompletionDate,
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: saving ? null : _submit,
                child: saving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isEdit ? 'Save changes' : 'Log snag'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
