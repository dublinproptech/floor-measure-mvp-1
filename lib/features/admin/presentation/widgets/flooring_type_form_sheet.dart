import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/flooring_type_model.dart';
import '../../application/admin_providers.dart';

/// Shows the add/edit sheet. Pass an existing [existing] to edit, or null to add.
Future<void> showFlooringTypeFormSheet(
  BuildContext context, {
  FlooringTypeModel? existing,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => _FlooringTypeFormSheet(existing: existing),
  );
}

class _FlooringTypeFormSheet extends ConsumerStatefulWidget {
  const _FlooringTypeFormSheet({this.existing});

  final FlooringTypeModel? existing;

  @override
  ConsumerState<_FlooringTypeFormSheet> createState() => _FlooringTypeFormSheetState();
}

class _FlooringTypeFormSheetState extends ConsumerState<_FlooringTypeFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _packSizeCtrl;
  late final TextEditingController _priceCtrl;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _packSizeCtrl = TextEditingController(text: e != null ? e.packSize.toString() : '');
    _priceCtrl = TextEditingController(text: e != null ? e.pricePerSqm.toString() : '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _packSizeCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final model = FlooringTypeModel(
      id: widget.existing?.id ?? '',
      name: _nameCtrl.text.trim(),
      packSize: double.parse(_packSizeCtrl.text.trim()),
      pricePerSqm: double.parse(_priceCtrl.text.trim()),
    );

    await ref.read(flooringTypeFormControllerProvider.notifier).save(model);

    if (!mounted) return;
    final error = ref.read(flooringTypeFormControllerProvider).error;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save: $error')),
      );
      return;
    }
    Navigator.of(context).pop();
  }

  String? _requiredPositiveNumber(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    final n = double.tryParse(value.trim());
    if (n == null) return 'Enter a number';
    if (n <= 0) return 'Must be greater than 0';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final saving = ref.watch(flooringTypeFormControllerProvider).isLoading;
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isEdit ? 'Edit Flooring Type' : 'Add Flooring Type',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Name (e.g. Laminate Oak)'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _packSizeCtrl,
              decoration: const InputDecoration(labelText: 'Pack size (m² per pack)'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: _requiredPositiveNumber,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _priceCtrl,
              decoration: const InputDecoration(labelText: 'Price per m²'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: _requiredPositiveNumber,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: saving ? null : _submit,
              child: saving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(isEdit ? 'Save changes' : 'Add flooring type'),
            ),
          ],
        ),
      ),
    );
  }
}
