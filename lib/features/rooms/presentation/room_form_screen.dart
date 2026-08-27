import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../../data/models/flooring_type_model.dart';
import '../../admin/application/admin_providers.dart';
import '../data/room_model.dart';
import '../application/room_controllers.dart';

class RoomFormScreen extends ConsumerStatefulWidget {
  final String projectId;
  final RoomModel? existing;
  const RoomFormScreen({super.key, required this.projectId, this.existing});
  @override
  ConsumerState<RoomFormScreen> createState() => _RoomFormScreenState();
}

class _RoomFormScreenState extends ConsumerState<RoomFormScreen> {
  late final TextEditingController _name, _length, _width, _wastage, _notes;
  String? _flooringTypeId;
  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _length = TextEditingController(text: e == null ? '' : e.length.toString());
    _width = TextEditingController(text: e == null ? '' : e.width.toString());
    _wastage = TextEditingController(text: (e?.wastagePct ?? 10).toString());
    _notes = TextEditingController(text: e?.notes ?? '');
    _flooringTypeId = e?.flooringTypeId;
  }

  @override
  void dispose() {
    for (final c in [_name, _length, _width, _wastage, _notes]) { c.dispose(); }
    super.dispose();
  }

  double get _len => double.tryParse(_length.text) ?? 0;
  double get _wid => double.tryParse(_width.text) ?? 0;
  double get _waste => double.tryParse(_wastage.text) ?? 0;

  Future<void> _save() async {
    if (_name.text.trim().isEmpty || _len <= 0 || _wid <= 0 ||
        _flooringTypeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Name, length, width and flooring type are required')));
      return;
    }
    final ctrl = ref.read(roomControllerProvider.notifier);
    final ok = _isEdit
        ? await ctrl.updateRoom(widget.existing!.copyWith(
        name: _name.text.trim(), flooringTypeId: _flooringTypeId,
        length: _len, width: _wid, wastagePct: _waste,
        notes: _notes.text.trim()))
        : await ctrl.addRoom(RoomModel(
        id: '', projectId: widget.projectId, name: _name.text.trim(),
        flooringTypeId: _flooringTypeId!, length: _len, width: _wid,
        wastagePct: _waste, notes: _notes.text.trim()));
    if (!mounted) return;
    if (ok) {
      context.pop();
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Save failed. Try again.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final types = ref.watch(flooringTypesProvider);
    final svc = ref.watch(measurementServiceProvider);
    final busy = ref.watch(roomControllerProvider).isLoading;

    final list = types.asData?.value ?? const <FlooringTypeModel>[];
    FlooringTypeModel? selected;
    for (final t in list) {
      if (t.id == _flooringTypeId) { selected = t; break; }
    }

    final area = svc.area(_len, _wid);
    final orderArea = svc.orderArea(area, _waste);
    final packs = selected == null ? null : svc.packs(orderArea, selected.packSize);

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit room' : 'Add room')),
      body: AbsorbPointer(
        absorbing: busy,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _label('Room name'),
            TextField(
              controller: _name,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(hintText: 'e.g. Living Room'),
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _numField('Length (m)', _length)),
                const SizedBox(width: 12),
                Expanded(child: _numField('Width (m)', _width)),
              ],
            ),
            const SizedBox(height: 14),
            _label('Flooring type'),
            types.when(
              data: (items) => DropdownButtonFormField<String>(
                initialValue: _flooringTypeId,
                isExpanded: true,
                hint: const Text('Select a flooring type'),
                items: items
                    .map((t) => DropdownMenuItem(
                    value: t.id,
                    child: Text('${t.name}  (${t.packSize} m²/pack)')))
                    .toList(),
                onChanged: (v) => setState(() => _flooringTypeId = v),
              ),
              loading: () => const LinearProgressIndicator(color: AppColors.gold),
              error: (e, _) => Text('Could not load flooring types: $e',
                  style: const TextStyle(color: AppColors.danger)),
            ),
            const SizedBox(height: 14),
            _label('Wastage %'),
            TextField(
              controller: _wastage,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(hintText: '10'),
            ),
            const SizedBox(height: 14),
            _label('Notes'),
            TextField(controller: _notes, maxLines: 2),
            const SizedBox(height: 20),
            _calcPreview(area, orderArea, packs),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: busy ? null : _save,
              child: busy
                  ? const SizedBox(height: 20, width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(_isEdit ? 'Save changes' : 'Add room'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _calcPreview(double area, double orderArea, int? packs) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(kRadius),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Live calculation', style: TextStyle(
              fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.label)),
          const SizedBox(height: 10),
          _calcRow('Area', '${area.toStringAsFixed(2)} m²'),
          _calcRow('Order area (with waste)', '${orderArea.toStringAsFixed(2)} m²'),
          _calcRow('Packs required',
              packs == null ? 'Select a flooring type' : '$packs packs'),
        ],
      ),
    );
  }

  Widget _calcRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
        Text(value, style: const TextStyle(
            color: AppColors.ink, fontWeight: FontWeight.w700, fontSize: 13)),
      ],
    ),
  );

  Widget _numField(String label, TextEditingController c) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _label(label),
      TextField(
        controller: c,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: (_) => setState(() {}),
        decoration: const InputDecoration(hintText: '0.00'),
      ),
    ],
  );

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text, style: const TextStyle(
        fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.label)),
  );
}