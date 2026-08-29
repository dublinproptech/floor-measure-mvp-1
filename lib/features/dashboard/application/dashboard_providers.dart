import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../projects/data/project_model.dart';
import '../../projects/application/project_controllers.dart';
import '../../snaglist/data/snag_model.dart';
import '../../snaglist/application/snaglist_providers.dart';

// ---------------------------------------------------------------------------
// Dashboard counts — all derived from the existing projectListProvider and
// allSnagsProvider streams. No new project/snag queries are made here.
// ---------------------------------------------------------------------------

class DashboardCounts {
  final int total;
  final int active;
  final int completed;
  final int pendingReports;
  final int openSnags;
  final int completedSnags;

  const DashboardCounts({
    required this.total,
    required this.active,
    required this.completed,
    required this.pendingReports,
    required this.openSnags,
    required this.completedSnags,
  });
}

final dashboardCountsProvider = Provider<AsyncValue<DashboardCounts>>((ref) {
  final projectsAsync = ref.watch(projectListProvider);
  final snagsAsync = ref.watch(allSnagsProvider);

  if (projectsAsync.isLoading || snagsAsync.isLoading) {
    return const AsyncLoading();
  }
  if (projectsAsync.hasError) {
    return AsyncError(projectsAsync.error!, projectsAsync.stackTrace!);
  }
  if (snagsAsync.hasError) {
    return AsyncError(snagsAsync.error!, snagsAsync.stackTrace!);
  }

  final projects = projectsAsync.value ?? [];
  final snags = snagsAsync.value ?? [];

  final completed = projects.where((p) => p.status == ProjectStatus.completed).length;
  final pendingReports =
      projects.where((p) => p.status == ProjectStatus.surveyCompleted).length;
  final openSnags = snags
      .where((s) => s.status == SnagStatus.open || s.status == SnagStatus.inProgress)
      .length;
  final completedSnags = snags
      .where((s) => s.status == SnagStatus.resolved || s.status == SnagStatus.verified)
      .length;

  return AsyncData(DashboardCounts(
    total: projects.length,
    active: projects.length - completed, // anything not yet completed
    completed: completed,
    pendingReports: pendingReports,
    openSnags: openSnags,
    completedSnags: completedSnags,
  ));
});

// ---------------------------------------------------------------------------
// Search & filter — applied client-side over the same projectListProvider
// stream (project counts are small; no need for server-side query params).
// ---------------------------------------------------------------------------

class ProjectFilters {
  final String query; // matches name, client, or address
  final ProjectStatus? status;
  final String? surveyorId;
  final DateTime? dateFrom;
  final DateTime? dateTo;

  const ProjectFilters({
    this.query = '',
    this.status,
    this.surveyorId,
    this.dateFrom,
    this.dateTo,
  });

  bool get isActive =>
      query.isNotEmpty || status != null || surveyorId != null || dateFrom != null || dateTo != null;

  ProjectFilters copyWith({
    String? query,
    ProjectStatus? status,
    bool clearStatus = false,
    String? surveyorId,
    bool clearSurveyor = false,
    DateTime? dateFrom,
    bool clearDateFrom = false,
    DateTime? dateTo,
    bool clearDateTo = false,
  }) {
    return ProjectFilters(
      query: query ?? this.query,
      status: clearStatus ? null : (status ?? this.status),
      surveyorId: clearSurveyor ? null : (surveyorId ?? this.surveyorId),
      dateFrom: clearDateFrom ? null : (dateFrom ?? this.dateFrom),
      dateTo: clearDateTo ? null : (dateTo ?? this.dateTo),
    );
  }
}

class ProjectFiltersNotifier extends Notifier<ProjectFilters> {
  @override
  ProjectFilters build() => const ProjectFilters();

  void setQuery(String query) => state = state.copyWith(query: query);
  void setStatus(ProjectStatus? status) =>
      state = status == null ? state.copyWith(clearStatus: true) : state.copyWith(status: status);
  void setSurveyor(String? id) =>
      state = id == null ? state.copyWith(clearSurveyor: true) : state.copyWith(surveyorId: id);
  void setDateFrom(DateTime? d) =>
      state = d == null ? state.copyWith(clearDateFrom: true) : state.copyWith(dateFrom: d);
  void setDateTo(DateTime? d) =>
      state = d == null ? state.copyWith(clearDateTo: true) : state.copyWith(dateTo: d);
  void clear() => state = const ProjectFilters();
}

final projectFiltersProvider = NotifierProvider<ProjectFiltersNotifier, ProjectFilters>(
  ProjectFiltersNotifier.new,
);

/// The filtered + searched project list the dashboard actually displays.
final filteredProjectsProvider = Provider<AsyncValue<List<ProjectModel>>>((ref) {
  final projectsAsync = ref.watch(projectListProvider);
  final filters = ref.watch(projectFiltersProvider);

  return projectsAsync.whenData((projects) {
    var result = projects;

    if (filters.query.trim().isNotEmpty) {
      final q = filters.query.trim().toLowerCase();
      result = result.where((p) {
        return p.name.toLowerCase().contains(q) ||
            p.client.toLowerCase().contains(q) ||
            p.address.toLowerCase().contains(q);
      }).toList();
    }

    if (filters.status != null) {
      result = result.where((p) => p.status == filters.status).toList();
    }

    if (filters.surveyorId != null) {
      result = result.where((p) => p.surveyorId == filters.surveyorId).toList();
    }

    if (filters.dateFrom != null) {
      result = result.where((p) => !p.surveyDate.isBefore(filters.dateFrom!)).toList();
    }

    if (filters.dateTo != null) {
      result = result.where((p) => !p.surveyDate.isAfter(filters.dateTo!)).toList();
    }

    // Most recent survey date first — used for the "recent projects" list too.
    result.sort((a, b) => b.surveyDate.compareTo(a.surveyDate));
    return result;
  });
});
