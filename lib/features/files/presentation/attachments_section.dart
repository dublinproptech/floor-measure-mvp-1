import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme.dart';
import '../data/attachment_model.dart';
import '../application/attachment_controllers.dart';

import 'dart:convert';

class AttachmentsSection extends ConsumerWidget {
  final String projectId;
  final String? roomId;
  final String? snagId;
  final AttachmentType type;
  final String title;

  const AttachmentsSection({
    super.key,
    required this.projectId,
    this.roomId,
    this.snagId,
    this.type = AttachmentType.siteDoc,
    this.title = 'Photos',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(attachmentsProvider(projectId));
    final busy = ref.watch(attachmentControllerProvider).isLoading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.label,
              ),
            ),
            TextButton.icon(
              onPressed: busy ? null : () => _pickSource(context, ref),
              icon: const Icon(Icons.add_a_photo_outlined, size: 18),
              label: const Text('Add'),
            ),
          ],
        ),
        if (busy)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: LinearProgressIndicator(color: AppColors.gold),
          ),
        async.when(
          data: (all) {
            final items = all.where((a) {
              if (snagId != null) return a.snagId == snagId;
              if (roomId != null) return a.roomId == roomId;
              return a.roomId == null && a.snagId == null; // project-level only
            }).toList();
            if (items.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'No photos yet',
                  style: TextStyle(color: AppColors.muted, fontSize: 13),
                ),
              );
            }
            return GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: [for (final a in items) _thumb(context, ref, a)],
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(8),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.gold),
            ),
          ),
          error: (e, _) => Text(
            'Error: $e',
            style: const TextStyle(color: AppColors.danger),
          ),
        ),
      ],
    );
  }

  Widget _thumb(BuildContext context, WidgetRef ref, AttachmentModel a) =>
      GestureDetector(
        onTap: () => _preview(context, ref, a),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(
            base64Decode(a.imageBase64),
            fit: BoxFit.cover,
            gaplessPlayback: true,
            errorBuilder: (c, e, s) => Container(
              color: AppColors.paper,
              child: const Icon(Icons.broken_image, color: AppColors.muted),
            ),
          ),
        ),
      );

  Future<void> _pickSource(BuildContext context, WidgetRef ref) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final ok = await ref
        .read(attachmentControllerProvider.notifier)
        .addPhoto(
          projectId: projectId,
          roomId: roomId,
          snagId: snagId,
          type: type,
          source: source,
        );
    if (!ok &&
        context.mounted &&
        ref.read(attachmentControllerProvider).hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Upload failed. Try again.')),
      );
    }
  }

  Future<void> _preview(
    BuildContext context,
    WidgetRef ref,
    AttachmentModel a,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: InteractiveViewer(
                child: Image.memory(base64Decode(a.imageBase64)),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    ref.read(attachmentControllerProvider.notifier).remove(a);
                  },
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppColors.danger,
                  ),
                  label: const Text(
                    'Delete',
                    style: TextStyle(color: AppColors.danger),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
