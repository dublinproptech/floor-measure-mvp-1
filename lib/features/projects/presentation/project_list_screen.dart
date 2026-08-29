import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../data/project_model.dart';
import '../application/project_controllers.dart';

class ProjectListScreen extends ConsumerStatefulWidget {
  const ProjectListScreen({super.key});
  @override
  ConsumerState<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends ConsumerState<ProjectListScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final projects = ref.watch(projectListProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Projects')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.ink,
        foregroundColor: Colors.white,
        onPressed: () => context.push('/projects/new'),
        icon: const Icon(Icons.add),
        label: const Text('New project'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search by name or client',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
            ),
          ),
          Expanded(
            child: projects.when(
              data: (list) {
                final filtered = _query.isEmpty
                    ? list
                    : list.where((p) =>
                p.name.toLowerCase().contains(_query) ||
                    p.client.toLowerCase().contains(_query)).toList();
                if (filtered.isEmpty) {
                  return const Center(
                      child: Text('No projects yet',
                          style: TextStyle(color: AppColors.muted)));
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 96),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => _ProjectCard(filtered[i]),
                );
              },
              loading: () =>
              const Center(child: CircularProgressIndicator(color: AppColors.gold)),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final ProjectModel p;
  const _ProjectCard(this.p);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kRadius),
        side: const BorderSide(color: AppColors.line),
      ),
      child: ListTile(
        title: Text(p.name,
            style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink)),
        subtitle: Text(p.client, style: const TextStyle(color: AppColors.muted)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.paper,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.line),
          ),
          child: Text(p.status.label,
              style: const TextStyle(fontSize: 11, color: AppColors.goldDeep,
                  fontWeight: FontWeight.w700)),
        ),
        onTap: () => context.push('/projects/${p.id}'),
      ),
    );
  }
}