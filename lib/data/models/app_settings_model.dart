import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Firestore doc: settings/app  (single fixed document, id is always 'app')
class AppSettingsModel extends Equatable {
  static const docId = 'app';

  final String companyName;
  final String companyAddress;
  final String companyPhone;
  final String companyEmail;
  final String? companyLogoUrl;
  final double defaultWastagePct;

  const AppSettingsModel({
    required this.companyName,
    required this.companyAddress,
    required this.companyPhone,
    required this.companyEmail,
    this.companyLogoUrl,
    required this.defaultWastagePct,
  });

  factory AppSettingsModel.empty() => const AppSettingsModel(
        companyName: '',
        companyAddress: '',
        companyPhone: '',
        companyEmail: '',
        companyLogoUrl: null,
        defaultWastagePct: 10,
      );

  factory AppSettingsModel.fromMap(Map<String, dynamic> map) {
    return AppSettingsModel(
      companyName: map['companyName'] as String? ?? '',
      companyAddress: map['companyAddress'] as String? ?? '',
      companyPhone: map['companyPhone'] as String? ?? '',
      companyEmail: map['companyEmail'] as String? ?? '',
      companyLogoUrl: map['companyLogoUrl'] as String?,
      defaultWastagePct: (map['defaultWastagePct'] as num?)?.toDouble() ?? 10,
    );
  }

  factory AppSettingsModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) return AppSettingsModel.empty();
    return AppSettingsModel.fromMap(data);
  }

  /// Omits null keys (companyLogoUrl before a logo is uploaded).
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'companyName': companyName,
      'companyAddress': companyAddress,
      'companyPhone': companyPhone,
      'companyEmail': companyEmail,
      'defaultWastagePct': defaultWastagePct,
    };
    if (companyLogoUrl != null) map['companyLogoUrl'] = companyLogoUrl;
    return map;
  }

  AppSettingsModel copyWith({
    String? companyName,
    String? companyAddress,
    String? companyPhone,
    String? companyEmail,
    String? companyLogoUrl,
    double? defaultWastagePct,
  }) {
    return AppSettingsModel(
      companyName: companyName ?? this.companyName,
      companyAddress: companyAddress ?? this.companyAddress,
      companyPhone: companyPhone ?? this.companyPhone,
      companyEmail: companyEmail ?? this.companyEmail,
      companyLogoUrl: companyLogoUrl ?? this.companyLogoUrl,
      defaultWastagePct: defaultWastagePct ?? this.defaultWastagePct,
    );
  }

  @override
  List<Object?> get props => [
        companyName,
        companyAddress,
        companyPhone,
        companyEmail,
        companyLogoUrl,
        defaultWastagePct,
      ];
}
