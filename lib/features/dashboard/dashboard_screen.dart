import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_controller.dart';
import '../../core/auth.dart';
import '../projects/data/project_model.dart';
import '../projects/application/project_controllers.dart';
import '../admin/application/admin_providers.dart' show usersProvider;
import 'application/dashboard_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).asData?.value;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _confirmSignOut(context, ref),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(projectListProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            _MetricsGrid(),
            SizedBox(height: 24),
            _SearchAndFilterBar(),
            SizedBox(height: 12),
            _ProjectResultsList(),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You will need to sign in again to continue.'),
        actions: [
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Sign out')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(authControllerProvider.notifier).signOut();
    }
  }
}

// ---------------------------------------------------------------------------
// Metric cards
// ---------------------------------------------------------------------------

class _MetricsGrid extends ConsumerWidget {
  const _MetricsGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countsAsync = ref.watch(dashboardCountsProvider);

    return countsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Could not load dashboard: $e'),
      data: (c) => GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.3,
        children: [
          _MetricCard(label: 'Total projects', value: c.total),
          _MetricCard(label: 'Active', value: c.active),
          _MetricCard(label: 'Completed', value: c.completed),
          _MetricCard(label: 'Pending reports', value: c.pendingReports),
          _MetricCard(label: 'Open snags', value: c.openSnags),
          _MetricCard(label: 'Completed snags', value: c.completedSnags),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$value', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Search & filter
// ---------------------------------------------------------------------------

class _SearchAndFilterBar extends ConsumerWidget {
  const _SearchAndFilterBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(projectFiltersProvider);
    final notifier = ref.read(projectFiltersProvider.notifier);
    final usersAsync = ref.watch(usersProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          decoration: const InputDecoration(
            hintText: 'Search by name, client, or address',
            prefixIcon: Icon(Icons.search),
            isDense: true,
          ),
          onChanged: notifier.setQuery,
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              DropdownButton<ProjectStatus?>(
                value: filters.status,
                hint: const Text('Status'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All statuses')),
                  ...ProjectStatus.values.map(
                    (s) => DropdownMenuItem(value: s, child: Text(s.label)),
                  ),
                ],
                onChanged: notifier.setStatus,
              ),
              const SizedBox(width: 12),
              usersAsync.maybeWhen(
                data: (users) => DropdownButton<String?>(
                  value: filters.surveyorId,
                  hint: const Text('Surveyor'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All surveyors')),
                    ...users.map((u) => DropdownMenuItem(value: u.id, child: Text(u.name))),
                  ],
                  onChanged: notifier.setSurveyor,
                ),
                orElse: () => const SizedBox.shrink(),
              ),
              const SizedBox(width: 12),
              TextButton.icon(
                onPressed: () async {
                  final range = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime.now().subtract(const Duration(days: 365 * 3)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (range != null) {
                    notifier.setDateFrom(range.start);
                    notifier.setDateTo(range.end);
                  }
                },
                icon: const Icon(Icons.date_range, size: 18),
                label: Text(
                  filters.dateFrom == null
                      ? 'Date'
                      : '${filters.dateFrom!.day}/${filters.dateFrom!.month} - ${filters.dateTo!.day}/${filters.dateTo!.month}',
                ),
              ),
              if (filters.isActive)
                TextButton(
                  onPressed: notifier.clear,
                  child: const Text('Clear'),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Results
// ---------------------------------------------------------------------------

class _ProjectResultsList extends ConsumerWidget {
  const _ProjectResultsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(filteredProjectsProvider);
    final filters = ref.watch(projectFiltersProvider);

    return projectsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Could not load projects: $e'),
      data: (projects) {
        final display = filters.isActive ? projects : projects.take(5).toList();

        if (display.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: Text('No projects match.')),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              filters.isActive ? 'Results (${projects.length})' : 'Recent projects',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ...display.map((p) => Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Theme.of(context).dividerColor),
                  ),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(p.name),
                    subtitle: Text('${p.client} • ${p.status.label}'),
                    trailing: Text(
                      '${p.surveyDate.day}/${p.surveyDate.month}/${p.surveyDate.year}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    onTap: () => context.push('/projects/${p.id}'),
                  ),
                )),
            if (!filters.isActive)
              TextButton(
                onPressed: () => context.push('/projects'),
                child: const Text('View all projects'),
              ),
          ],
        );
      },
    );
  }
}
