import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../data/room_model.dart';
import '../data/room_repository.dart';
import '../domain/measurement_service.dart';

final roomRepositoryProvider = Provider<RoomRepository>(
      (ref) => FirestoreRoomRepository(ref.watch(firestoreProvider)),
);

final measurementServiceProvider =
Provider<MeasurementService>((ref) => const MeasurementService());

final roomsProvider = StreamProvider.autoDispose.family<List<RoomModel>, String>(
      (ref, projectId) => ref.watch(roomRepositoryProvider).watchRooms(projectId),
);

final projectTotalsProvider =
Provider.autoDispose.family<AsyncValue<ProjectTotals>, String>((ref, projectId) {
  final svc = ref.watch(measurementServiceProvider);
  return ref.watch(roomsProvider(projectId)).whenData((rooms) {
    var area = 0.0, order = 0.0;
    for (final r in rooms) {
      area += r.area;
      order += svc.orderArea(r.area, r.wastagePct);
    }
    return ProjectTotals(area, order);
  });
});

final roomControllerProvider =
AsyncNotifierProvider.autoDispose<RoomController, void>(RoomController.new);

class RoomController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  RoomRepository get _repo => ref.read(roomRepositoryProvider);

  Future<bool> addRoom(RoomModel r) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.addRoom(r));
    return !state.hasError;
  }

  Future<bool> updateRoom(RoomModel r) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.updateRoom(r));
    return !state.hasError;
  }

  Future<void> deleteRoom(String projectId, String roomId) async {
    state = await AsyncValue.guard(() => _repo.deleteRoom(projectId, roomId));
  }
}