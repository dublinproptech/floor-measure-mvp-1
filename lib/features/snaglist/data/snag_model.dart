import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum SnagPriority { low, medium, high, critical }

SnagPriority snagPriorityFromString(String value) => SnagPriority.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => SnagPriority.low,
    );

enum SnagStatus { open, inProgress, resolved, verified }

SnagStatus snagStatusFromString(String value) => SnagStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => SnagStatus.open,
    );

/// Firestore path: projects/{projectId}/snags/{id}  (subcollection under Project)
class SnagModel extends Equatable {
  final String id;
  final String projectId;
  final String? roomId; // FK -> RoomModel.id once Rooms feature exists
  final String ref; // e.g. "SNAG-001"
  final String location; // free-text room/location label, works without Rooms feature
  final String description;
  final String category;
  final SnagPriority priority;
  final SnagStatus status;
  final String? assignedTo; // FK -> UserModel.id
  final DateTime? completionDate;
  final DateTime createdAt;

  const SnagModel({
    required this.id,
    required this.projectId,
    this.roomId,
    required this.ref,
    required this.location,
    required this.description,
    required this.category,
    required this.priority,
    required this.status,
    this.assignedTo,
    this.completionDate,
    required this.createdAt,
  });

  factory SnagModel.fromMap(String id, Map<String, dynamic> map) {
    return SnagModel(
      id: id,
      projectId: map['projectId'] as String? ?? '',
      roomId: map['roomId'] as String?,
      ref: map['ref'] as String? ?? '',
      location: map['location'] as String? ?? '',
      description: map['description'] as String? ?? '',
      category: map['category'] as String? ?? '',
      priority: snagPriorityFromString(map['priority'] as String? ?? 'low'),
      status: snagStatusFromString(map['status'] as String? ?? 'open'),
      assignedTo: map['assignedTo'] as String?,
      completionDate: (map['completionDate'] as Timestamp?)?.toDate(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory SnagModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw StateError('SnagModel.fromFirestore: doc ${doc.id} has no data');
    }
    return SnagModel.fromMap(doc.id, data);
  }

  /// Omits null keys so partial writes never clobber unrelated fields.
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'projectId': projectId,
      'ref': ref,
      'location': location,
      'description': description,
      'category': category,
      'priority': priority.name,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
    };
    if (roomId != null) map['roomId'] = roomId;
    if (assignedTo != null) map['assignedTo'] = assignedTo;
    if (completionDate != null) map['completionDate'] = Timestamp.fromDate(completionDate!);
    return map;
  }

  SnagModel copyWith({
    String? roomId,
    String? ref,
    String? location,
    String? description,
    String? category,
    SnagPriority? priority,
    SnagStatus? status,
    String? assignedTo,
    DateTime? completionDate,
  }) {
    return SnagModel(
      id: id,
      projectId: projectId,
      roomId: roomId ?? this.roomId,
      ref: ref ?? this.ref,
      location: location ?? this.location,
      description: description ?? this.description,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      assignedTo: assignedTo ?? this.assignedTo,
      completionDate: completionDate ?? this.completionDate,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        projectId,
        roomId,
        ref,
        location,
        description,
        category,
        priority,
        status,
        assignedTo,
        completionDate,
        createdAt,
      ];
}
