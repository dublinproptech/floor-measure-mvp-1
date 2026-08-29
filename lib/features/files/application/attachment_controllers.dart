import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/providers.dart';
import '../data/attachment_model.dart';
import '../data/attachment_repository.dart';

final _imagePickerProvider = Provider<ImagePicker>((ref) => ImagePicker());

final attachmentRepositoryProvider = Provider<AttachmentRepository>(
      (ref) => FirestoreAttachmentRepository(ref.watch(firestoreProvider)),
);

final attachmentsProvider =
StreamProvider.autoDispose.family<List<AttachmentModel>, String>(
      (ref, projectId) =>
      ref.watch(attachmentRepositoryProvider).watchAttachments(projectId),
);

final attachmentControllerProvider =
AsyncNotifierProvider.autoDispose<AttachmentController, void>(
    AttachmentController.new);

class AttachmentController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<bool> addPhoto({
    required String projectId,
    String? roomId,
    String? snagId,
    required AttachmentType type,
    required ImageSource source,
  }) async {
    // Compress aggressively: photos must fit inside a Firestore doc.
    final picked = await ref.read(_imagePickerProvider).pickImage(
      source: source,
      imageQuality: 50,
      maxWidth: 1024,
    );
    if (picked == null) return false; // cancelled

    state = const AsyncLoading();
    final bytes = await picked.readAsBytes();
    state = await AsyncValue.guard(() =>
        ref.read(attachmentRepositoryProvider).upload(
          projectId: projectId,
          roomId: roomId,
          snagId: snagId,
          type: type,
          bytes: Uint8List.fromList(bytes),
        ));
    return !state.hasError;
  }

  Future<void> remove(AttachmentModel a) async {
    state = await AsyncValue.guard(
            () => ref.read(attachmentRepositoryProvider).delete(a));
  }
}