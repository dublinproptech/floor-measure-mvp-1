import 'package:equatable/equatable.dart';

class RoomModel  extends Equatable {
  final String id;
  final String projectId;
  final String name;
  final String flooringTypeId;
  final double length;
  final double width;
  final String unit; // 'm' only for the MVP
  final double wastagePct;
  final String notes;

  const RoomModel({
    required this.id,
    required this.projectId,
    required this.name,
    required this.flooringTypeId,
    required this.length,
    required this.width,
    this.unit = 'm',
    this.wastagePct = 0,
    this.notes = '',
  });

  double get area => length * width;

  factory RoomModel.fromMap(String id, Map<String, dynamic> map) => RoomModel(
    id: id,
    projectId: map['projectId'] ?? '',
    name: map['name'] ?? '',
    flooringTypeId: map['flooringTypeId'] ?? '',
    length: (map['length'] ?? 0).toDouble(),
    width: (map['width'] ?? 0).toDouble(),
    unit: map['unit'] ?? 'm',
    wastagePct: (map['wastagePct'] ?? 0).toDouble(),
    notes: map['notes'] ?? '',
  );

  Map<String, dynamic> toMap() => {
    'projectId': projectId,
    'name': name,
    'flooringTypeId': flooringTypeId,
    'length': length,
    'width': width,
    'unit': unit,
    'wastagePct': wastagePct,
    'area': area, // denormalized, pure, never stale
    'notes': notes,
  };

  RoomModel copyWith({
    String? name, String? flooringTypeId, double? length, double? width,
    String? unit, double? wastagePct, String? notes,
  }) =>
      RoomModel(
        id: id,
        projectId: projectId,
        name: name ?? this.name,
        flooringTypeId: flooringTypeId ?? this.flooringTypeId,
        length: length ?? this.length,
        width: width ?? this.width,
        unit: unit ?? this.unit,
        wastagePct: wastagePct ?? this.wastagePct,
        notes: notes ?? this.notes,
      );
  @override
  List<Object?> get props =>
      [id, projectId, name, flooringTypeId, length, width, unit, wastagePct, notes];

}