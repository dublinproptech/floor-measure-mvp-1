import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../data/project_model.dart';
import '../application/project_controllers.dart';
import '../../files/presentation/attachments_section.dart';
import '../../files/data/attachment_model.dart';

class ProjectDetailScreen extends ConsumerWidget {
  final String projectId;
  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(projectProvider(projectId));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Project'),
        actions: [
          async.maybeWhen(
            data: (p) => p == null
                ? const SizedBox.shrink()
                : IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () =>
                  context.push('/projects/$projectId/edit', extra: p),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: async.when(
        data: (p) {
          if (p == null) return const Center(child: Text('Project not found'));
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(p.name, style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.ink)),
              const SizedBox(height: 4),
              Text(p.client, style: const TextStyle(color: AppColors.muted, fontSize: 15)),
              const SizedBox(height: 16),
              Row(children: [
                const Text('Status', style: TextStyle(
                    fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.label)),
                const SizedBox(width: 12),
                DropdownButton<ProjectStatus>(
                  value: p.status,
                  underline: const SizedBox.shrink(),
                  items: ProjectStatus.values
                      .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
                      .toList(),
                  onChanged: (s) {
                    if (s != null) {
                      ref.read(projectControllerProvider.notifier)
                          .updateStatus(p.id, s);
                    }
                  },
                ),
              ]),
              const Divider(height: 32),
              _row('Address', p.address),
              _row('Contact', p.contactDetails),
              _row('Survey date',
                  '${p.surveyDate.day}/${p.surveyDate.month}/${p.surveyDate.year}'),
              if (p.notes.isNotEmpty) _row('Notes', p.notes),
              const Divider(height: 32),
              _navCard(context, Icons.straighten, 'Rooms & measurements', onTap: () => context.push('/projects/$projectId/rooms')),
              _navCard(context, Icons.report_problem_outlined, 'Snaglist', onTap: () => context.push('/projects/$projectId/snags')),
              const Divider(height: 32),
              AttachmentsSection(
                projectId: projectId,
                type: AttachmentType.siteDoc,
                title: 'Site photos',
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () => _confirmDelete(context, ref),
                icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                label: const Text('Delete project',
                    style: TextStyle(color: AppColors.danger)),
              ),
            ],
          );
        },
        loading: () =>
        const Center(child: CircularProgressIndicator(color: AppColors.gold)),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(
            fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.label)),
        const SizedBox(height: 2),
        Text(value.isEmpty ? '-' : value,
            style: const TextStyle(fontSize: 15, color: AppColors.ink)),
      ],
    ),
  );

  Widget _navCard(BuildContext context, IconData icon, String label, {VoidCallback? onTap}) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(kRadius),
      side: const BorderSide(color: AppColors.line),
    ),
    child: ListTile(
      leading: Icon(icon, color: AppColors.gold),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap ??
              () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Coming in the next feature'))),
    ),
  );

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete project?'),
        content: const Text('This permanently removes the project and cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(projectControllerProvider.notifier).delete(projectId);
      if (context.mounted) context.pop();
    }
  }
}