import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/snag_model.dart';
import '../application/snaglist_providers.dart';
import 'widgets/snag_form_sheet.dart';

/// Route: /projects/:id/snags
class SnagListScreen extends StatelessWidget {
  const SnagListScreen({super.key, required this.projectId});

  final String projectId;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Snaglist'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Open'),
              Tab(text: 'All'),
              Tab(text: 'Resolved'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => showSnagFormSheet(context, projectId: projectId),
          child: const Icon(Icons.add),
        ),
        body: TabBarView(
          children: [
            _SnagListView(projectId: projectId, filter: _SnagFilter.open),
            _SnagListView(projectId: projectId, filter: _SnagFilter.all),
            _SnagListView(projectId: projectId, filter: _SnagFilter.resolved),
          ],
        ),
      ),
    );
  }
}

enum _SnagFilter { open, all, resolved }

class _SnagListView extends ConsumerWidget {
  const _SnagListView({required this.projectId, required this.filter});

  final String projectId;
  final _SnagFilter filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snagsAsync = switch (filter) {
      _SnagFilter.open => ref.watch(openSnagsProvider(projectId)),
      _SnagFilter.resolved => ref.watch(resolvedSnagsProvider(projectId)),
      _SnagFilter.all => ref.watch(snagsProvider(projectId)),
    };

    return snagsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Could not load snags: $e')),
      data: (snags) {
        if (snags.isEmpty) {
          return const Center(child: Text('No snags here yet.'));
        }
        return ListView.separated(
          padding: const EdgeInsets.only(bottom: 88),
          itemCount: snags.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, i) => _SnagTile(snag: snags[i], projectId: projectId),
        );
      },
    );
  }
}

class _SnagTile extends ConsumerWidget {
  const _SnagTile({required this.snag, required this.projectId});

  final SnagModel snag;
  final String projectId;

  Color _priorityColor(SnagPriority p) => switch (p) {
        SnagPriority.low => Colors.blueGrey,
        SnagPriority.medium => Colors.orange,
        SnagPriority.high => Colors.deepOrange,
        SnagPriority.critical => Colors.red,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      onTap: () => showSnagFormSheet(context, projectId: projectId, existing: snag),
      leading: CircleAvatar(
        backgroundColor: _priorityColor(snag.priority),
        child: Text(
          snag.priority.name[0].toUpperCase(),
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ),
      title: Text('${snag.ref} — ${snag.location}'),
      subtitle: Text(
        snag.description,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: DropdownButton<SnagStatus>(
        value: snag.status,
        underline: const SizedBox.shrink(),
        items: SnagStatus.values
            .map((s) => DropdownMenuItem(value: s, child: Text(s.name)))
            .toList(),
        onChanged: (status) {
          if (status == null) return;
          ref
              .read(snagStatusControllerProvider.notifier)
              .updateStatus(projectId, snag.id, status);
        },
      ),
    );
  }
}
