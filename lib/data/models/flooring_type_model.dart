import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Firestore collection: flooringTypes/{id}
class FlooringTypeModel extends Equatable {
  final String id;
  final String name;
  final double packSize; // m² per pack
  final double pricePerSqm;

  const FlooringTypeModel({
    required this.id,
    required this.name,
    required this.packSize,
    required this.pricePerSqm,
  });

  /// Empty instance used to prefill the "Add" form.
  factory FlooringTypeModel.empty() => const FlooringTypeModel(
        id: '',
        name: '',
        packSize: 0,
        pricePerSqm: 0,
      );

  factory FlooringTypeModel.fromMap(String id, Map<String, dynamic> map) {
    return FlooringTypeModel(
      id: id,
      name: map['name'] as String? ?? '',
      packSize: (map['packSize'] as num?)?.toDouble() ?? 0,
      pricePerSqm: (map['pricePerSqm'] as num?)?.toDouble() ?? 0,
    );
  }

  factory FlooringTypeModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw StateError('FlooringTypeModel.fromFirestore: doc ${doc.id} has no data');
    }
    return FlooringTypeModel.fromMap(doc.id, data);
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'packSize': packSize,
      'pricePerSqm': pricePerSqm,
    };
  }

  FlooringTypeModel copyWith({
    String? id,
    String? name,
    double? packSize,
    double? pricePerSqm,
  }) {
    return FlooringTypeModel(
      id: id ?? this.id,
      name: name ?? this.name,
      packSize: packSize ?? this.packSize,
      pricePerSqm: pricePerSqm ?? this.pricePerSqm,
    );
  }

  @override
  List<Object?> get props => [id, name, packSize, pricePerSqm];
}
