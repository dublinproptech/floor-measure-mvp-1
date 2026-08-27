import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../../data/models/flooring_type_model.dart';
import '../../admin/application/admin_providers.dart';
import '../data/room_model.dart';
import '../application/room_controllers.dart';
import '../domain/measurement_service.dart';
class RoomListScreen extends ConsumerWidget {
  final String projectId;
  const RoomListScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rooms = ref.watch(roomsProvider(projectId));
    final types = ref.watch(flooringTypesProvider);
    final totals = ref.watch(projectTotalsProvider(projectId));
    final svc = ref.watch(measurementServiceProvider);

    final typeMap = <String, FlooringTypeModel>{
      for (final t in (types.asData?.value ?? const <FlooringTypeModel>[])) t.id: t,
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Rooms & measurements')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.ink,
        foregroundColor: Colors.white,
        onPressed: () => context.push('/projects/$projectId/rooms/new'),
        icon: const Icon(Icons.add),
        label: const Text('Add room'),
      ),
      body: rooms.when(
        data: (list) => ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
          children: [
            _totalsCard(totals),
            const SizedBox(height: 12),
            if (list.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(
                  child: Text('No rooms yet',
                      style: TextStyle(color: AppColors.muted)),
                ),
              ),
            for (final r in list)
              _roomCard(context, ref, r, typeMap[r.flooringTypeId], svc),
          ],
        ),
        loading: () =>
        const Center(child: CircularProgressIndicator(color: AppColors.gold)),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _totalsCard(AsyncValue<ProjectTotals> totals) {
    final t = totals.asData?.value;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(kRadius),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _stat('Total floor area', '${(t?.totalArea ?? 0).toStringAsFixed(2)} m²'),
          Container(width: 1, height: 34, color: AppColors.line),
          _stat('Order area (with waste)',
              '${(t?.totalOrderArea ?? 0).toStringAsFixed(2)} m²'),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) => Column(
    children: [
      Text(value, style: const TextStyle(
          fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
    ],
  );

  Widget _roomCard(BuildContext context, WidgetRef ref, RoomModel r,
      FlooringTypeModel? type, MeasurementService svc) {
    final orderArea = svc.orderArea(r.area, r.wastagePct);
    final packs = type == null ? null : svc.packs(orderArea, type.packSize);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kRadius),
        side: const BorderSide(color: AppColors.line),
      ),
      child: ListTile(
        title: Text(r.name,
            style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink)),
        subtitle: Text(
          '${r.length} × ${r.width} ${r.unit}  ·  ${r.area.toStringAsFixed(2)} m²'
              '  ·  ${type?.name ?? 'No type'}'
              '${packs != null ? '  ·  $packs packs' : ''}',
          style: const TextStyle(color: AppColors.muted),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: AppColors.danger),
          onPressed: () =>
              ref.read(roomControllerProvider.notifier).deleteRoom(projectId, r.id),
        ),
        onTap: () =>
            context.push('/projects/$projectId/rooms/${r.id}/edit', extra: r),
      ),
    );
  }
}