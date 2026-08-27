import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/auth.dart';
import '../../../core/theme.dart';
import '../data/project_model.dart';
import '../application/project_controllers.dart';

class ProjectFormScreen extends ConsumerStatefulWidget {
  final ProjectModel? existing;
  const ProjectFormScreen({super.key, this.existing});
  @override
  ConsumerState<ProjectFormScreen> createState() => _ProjectFormScreenState();
}

class _ProjectFormScreenState extends ConsumerState<ProjectFormScreen> {
  late final TextEditingController _name, _client, _address, _contact, _notes;
  late DateTime _surveyDate;
  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _client = TextEditingController(text: e?.client ?? '');
    _address = TextEditingController(text: e?.address ?? '');
    _contact = TextEditingController(text: e?.contactDetails ?? '');
    _notes = TextEditingController(text: e?.notes ?? '');
    _surveyDate = e?.surveyDate ?? DateTime.now();
  }

  @override
  void dispose() {
    for (final c in [_name, _client, _address, _contact, _notes]) { c.dispose(); }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context, initialDate: _surveyDate,
      firstDate: DateTime(2020), lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _surveyDate = picked);
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty || _client.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Project name and client are required')));
      return;
    }
    final ctrl = ref.read(projectControllerProvider.notifier);
    bool done;
    if (_isEdit) {
      done = await ctrl.updateProject(widget.existing!.copyWith(
        name: _name.text.trim(), client: _client.text.trim(),
        address: _address.text.trim(), contactDetails: _contact.text.trim(),
        notes: _notes.text.trim(), surveyDate: _surveyDate,
      ));
    } else {
      final uid = ref.read(firebaseAuthProvider).currentUser?.uid ?? '';
      final id = await ctrl.create(ProjectModel(
        id: '', name: _name.text.trim(), client: _client.text.trim(),
        address: _address.text.trim(), contactDetails: _contact.text.trim(),
        surveyorId: uid, surveyDate: _surveyDate, createdAt: DateTime.now(),
        notes: _notes.text.trim(),
      ));
      done = id != null;
    }
    if (!mounted) return;
    if (done) {
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Save failed. Please try again.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = ref.watch(projectControllerProvider).isLoading;
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit project' : 'New project')),
      body: AbsorbPointer(
        absorbing: busy,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _field('Project name', _name),
            _field('Client', _client),
            _field('Property address', _address, maxLines: 2),
            _field('Contact details', _contact),
            _dateField(),
            _field('Notes', _notes, maxLines: 3),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: busy ? null : _save,
              child: busy
                  ? const SizedBox(height: 20, width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(_isEdit ? 'Save changes' : 'Create project'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController c, {int maxLines = 1}) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(label, style: const TextStyle(
              fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.label)),
        ),
        TextField(controller: c, maxLines: maxLines),
      ],
    ),
  );

  Widget _dateField() => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 6),
          child: Text('Survey date', style: TextStyle(
              fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.label)),
        ),
        InkWell(
          onTap: _pickDate,
          child: InputDecorator(
            decoration: const InputDecoration(),
            child: Text('${_surveyDate.day}/${_surveyDate.month}/${_surveyDate.year}'),
          ),
        ),
      ],
    ),
  );
}