import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum ProjectStatus { draft, surveyCompleted, reportGenerated, workInProgress, completed }

ProjectStatus projectStatusFromString(String v) => ProjectStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == v.toLowerCase(),
  orElse: () => ProjectStatus.draft,
);

extension ProjectStatusX on ProjectStatus {
  String get label => switch (this) {
    ProjectStatus.draft => 'Draft',
    ProjectStatus.surveyCompleted => 'Survey completed',
    ProjectStatus.reportGenerated => 'Report generated',
    ProjectStatus.workInProgress => 'Work in progress',
    ProjectStatus.completed => 'Completed',
  };
}

class ProjectModel extends Equatable {
  final String id;
  final String name;
  final String client;
  final String address;
  final String contactDetails;
  final String surveyorId;
  final ProjectStatus status;
  final DateTime surveyDate;
  final DateTime createdAt;
  final String notes;
  final String? driveFolderId;

  const ProjectModel({
    required this.id,
    required this.name,
    required this.client,
    required this.address,
    this.contactDetails = '',
    required this.surveyorId,
    this.status = ProjectStatus.draft,
    required this.surveyDate,
    required this.createdAt,
    this.notes = '',
    this.driveFolderId,
  });

  factory ProjectModel.fromMap(String id, Map<String, dynamic> map) => ProjectModel(
    id: id,
    name: map['name'] ?? '',
    client: map['client'] ?? '',
    address: map['address'] ?? '',
    contactDetails: map['contactDetails'] ?? '',
    surveyorId: map['surveyorId'] ?? '',
    status: projectStatusFromString(map['status'] ?? 'draft'),
    surveyDate: (map['surveyDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
    createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    notes: map['notes'] ?? '',
    driveFolderId: map['driveFolderId'],
  );

  Map<String, dynamic> toMap() => {
    'name': name,
    'client': client,
    'address': address,
    'contactDetails': contactDetails,
    'surveyorId': surveyorId,
    'status': status.name,
    'surveyDate': Timestamp.fromDate(surveyDate),
    'createdAt': Timestamp.fromDate(createdAt),
    'notes': notes,
    if (driveFolderId != null) 'driveFolderId': driveFolderId,
  };

  ProjectModel copyWith({
    String? name, String? client, String? address, String? contactDetails,
    ProjectStatus? status, DateTime? surveyDate, String? notes, String? driveFolderId,
  }) =>
      ProjectModel(
        id: id,
        name: name ?? this.name,
        client: client ?? this.client,
        address: address ?? this.address,
        contactDetails: contactDetails ?? this.contactDetails,
        surveyorId: surveyorId,
        status: status ?? this.status,
        surveyDate: surveyDate ?? this.surveyDate,
        createdAt: createdAt,
        notes: notes ?? this.notes,
        driveFolderId: driveFolderId ?? this.driveFolderId,
      );

  @override
  List<Object?> get props => [id, name, client, address, contactDetails,
    surveyorId, status, surveyDate, createdAt, notes, driveFolderId];
}