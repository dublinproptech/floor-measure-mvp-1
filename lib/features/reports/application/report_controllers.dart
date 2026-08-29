import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../../core/providers.dart';
import '../../projects/data/project_model.dart';
import '../../projects/application/project_controllers.dart';
import '../../rooms/application/room_controllers.dart';
import '../../snaglist/application/snaglist_providers.dart';
import '../../files/application/attachment_controllers.dart';
import '../../admin/application/admin_providers.dart' show flooringTypesProvider;
import '../data/report_model.dart';
import '../data/report_repository.dart';
import 'report_service.dart';

final reportServiceProvider = Provider<ReportService>((ref) => const ReportService());

final reportRepositoryProvider = Provider<ReportRepository>(
      (ref) => FirestoreReportRepository(ref.watch(firestoreProvider)),
);

final reportControllerProvider =
AsyncNotifierProvider.autoDispose<ReportController, void>(ReportController.new);

class ReportController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  /// Builds the PDF for a project, opens the share sheet, records it,
  /// and moves the project to reportGenerated. Returns false on error.
  Future<bool> generateAndShare(ProjectModel project) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      // Snapshot each stream once (.future gives the next emission).
      final rooms = ref.read(roomsProvider(project.id)).value ?? const [];
      final snags = ref.read(snagsProvider(project.id)).value ?? const [];
      final types = ref.read(flooringTypesProvider).value ?? const [];
      final attachments = ref.read(attachmentsProvider(project.id)).value ?? const [];

      final bytes = await ref.read(reportServiceProvider).build(ReportData(
        project: project,
        rooms: rooms,
        snags: snags,
        flooringTypes: types,
        attachments: attachments,
      ));

      // Native share sheet: email, WhatsApp, Files, Drive (manual), etc.
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'Floor Survey - ${project.name}.pdf',
      );

      await ref.read(reportRepositoryProvider).recordReport(ReportModel(
        id: '', projectId: project.id, generatedAt: DateTime.now(),
      ));

      // Only advance status if the survey isn't already further along.
      if (project.status == ProjectStatus.draft ||
          project.status == ProjectStatus.surveyCompleted) {
        await ref
            .read(projectControllerProvider.notifier)
            .updateStatus(project.id, ProjectStatus.reportGenerated);
      }
    });
    return !state.hasError;
  }
}