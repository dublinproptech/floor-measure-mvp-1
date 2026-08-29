import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class ReportModel extends Equatable {
  final String id;
  final String projectId;
  final DateTime generatedAt;
  final String? driveUrl; // null for now; filled when auto-upload lands later

  const ReportModel({
    required this.id,
    required this.projectId,
    required this.generatedAt,
    this.driveUrl,
  });

  factory ReportModel.fromMap(String id, Map<String, dynamic> map) => ReportModel(
    id: id,
    projectId: map['projectId'] ?? '',
    generatedAt: (map['generatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    driveUrl: map['driveUrl'],
  );

  Map<String, dynamic> toMap() => {
    'projectId': projectId,
    'generatedAt': Timestamp.fromDate(generatedAt),
    if (driveUrl != null) 'driveUrl': driveUrl,
  };

  @override
  List<Object?> get props => [id, projectId, generatedAt, driveUrl];
}