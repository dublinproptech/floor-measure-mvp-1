import 'package:cloud_firestore/cloud_firestore.dart';

enum AttachmentType { roomPhoto, snagPhotoBefore, snagPhotoAfter, siteDoc }

AttachmentType attachmentTypeFromString(String v) =>
    AttachmentType.values.firstWhere(
        (e) => e.name.toLowerCase() == v.toLowerCase(),
        orElse: () => AttachmentType.siteDoc,
    );

class AttachmentModel {
  final String id;
  final String projectId;
  final String? roomId;
  final String? snagId;
  final AttachmentType type;
  final String imageBase64;
  final DateTime createdAt;

  const AttachmentModel({
    required this.id,
    required this.projectId,
    required this.roomId,
    required this.snagId,
    required this.type,
    required this.imageBase64,
    required this.createdAt
  });

  factory AttachmentModel.fromMap(String id, Map<String, dynamic> map) =>
      AttachmentModel(id: id, projectId: map['projectId'] ?? '', roomId: map['roomId'], snagId: map['snagId'], type: attachmentTypeFromString(map['type'] ?? 'siteDoc'), imageBase64: map['imageBase64'] ?? '', createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now());

  Map<String, dynamic> toMap() => {
    'projectId': projectId,
    if (roomId != null) 'roomId': roomId,
    if (snagId != null) 'snagId': snagId,
    'type': type.name,
    'imageBase64': imageBase64,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  @override
  List<Object?> get props =>
      [id, projectId, roomId, snagId, type, imageBase64, createdAt];

}

