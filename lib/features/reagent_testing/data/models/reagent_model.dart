import '../../domain/entities/reagent_entity.dart';
import 'drug_result_model.dart';

class ReagentModel {
  final String reagentName;
  final String reagentNameAr;
  final String description;
  final String descriptionAr;
  final String safetyLevel;
  final String safetyLevelAr;
  final int testDuration;
  final List<String> chemicals;
  final List<DrugResultModel> drugResults;
  final String category;
  final List<String> references;

  const ReagentModel({
    required this.reagentName,
    required this.reagentNameAr,
    required this.description,
    required this.descriptionAr,
    required this.safetyLevel,
    required this.safetyLevelAr,
    required this.testDuration,
    required this.chemicals,
    required this.drugResults,
    required this.category,
    this.references = const [],
  });

  // Convert from JSON to Model
  factory ReagentModel.fromJson(Map<String, dynamic> json) {
    return ReagentModel(
      reagentName: json['reagentName'] as String,
      reagentNameAr:
          json['reagentName_ar'] as String? ??
          json['reagentNameAr'] as String? ??
          '',
      description: json['description'] as String,
      descriptionAr:
          json['description_ar'] as String? ??
          json['descriptionAr'] as String? ??
          '',
      safetyLevel: json['safetyLevel'] as String,
      safetyLevelAr:
          json['safetyLevel_ar'] as String? ??
          json['safetyLevelAr'] as String? ??
          '',
      testDuration: json['testDuration'] as int,
      chemicals: List<String>.from(json['chemicals'] as List),
      drugResults: (json['drugResults'] as List)
          .map(
            (drugResult) =>
                DrugResultModel.fromJson(drugResult as Map<String, dynamic>),
          )
          .toList(),
      category: json['category'] as String? ?? 'Primary Tests',
      references: List<String>.from(json['reference'] as List? ?? []),
    );
  }

  // Convert Model to JSON
  Map<String, dynamic> toJson() {
    return {
      'reagentName': reagentName,
      'reagentName_ar': reagentNameAr,
      'description': description,
      'description_ar': descriptionAr,
      'safetyLevel': safetyLevel,
      'safetyLevel_ar': safetyLevelAr,
      'testDuration': testDuration,
      'chemicals': chemicals,
      'drugResults': drugResults
          .map((drugResult) => drugResult.toJson())
          .toList(),
      'category': category,
      'reference': references,
    };
  }

  // Non-destructive copy with optional field overrides
  ReagentModel copyWith({
    String? reagentName,
    String? reagentNameAr,
    String? description,
    String? descriptionAr,
    String? safetyLevel,
    String? safetyLevelAr,
    int? testDuration,
    List<String>? chemicals,
    List<DrugResultModel>? drugResults,
    String? category,
    List<String>? references,
  }) {
    return ReagentModel(
      reagentName:   reagentName   ?? this.reagentName,
      reagentNameAr: reagentNameAr ?? this.reagentNameAr,
      description:   description   ?? this.description,
      descriptionAr: descriptionAr ?? this.descriptionAr,
      safetyLevel:   safetyLevel   ?? this.safetyLevel,
      safetyLevelAr: safetyLevelAr ?? this.safetyLevelAr,
      testDuration:  testDuration  ?? this.testDuration,
      chemicals:     chemicals     ?? this.chemicals,
      drugResults:   drugResults   ?? this.drugResults,
      category:      category      ?? this.category,
      references:    references    ?? this.references,
    );
  }

  // Convert Model to Entity
  ReagentEntity toEntity() {
    return ReagentEntity(
      reagentName: reagentName,
      reagentNameAr: reagentNameAr,
      description: description,
      descriptionAr: descriptionAr,
      safetyLevel: safetyLevel,
      safetyLevelAr: safetyLevelAr,
      testDuration: testDuration,
      chemicals: chemicals,
      drugResults: drugResults
          .map((drugResult) => drugResult.toEntity())
          .toList(),
      category: category,
      references: references,
    );
  }

  // Convert from Entity to Model
  factory ReagentModel.fromEntity(ReagentEntity entity) {
    return ReagentModel(
      reagentName: entity.reagentName,
      reagentNameAr: entity.reagentNameAr,
      description: entity.description,
      descriptionAr: entity.descriptionAr,
      safetyLevel: entity.safetyLevel,
      safetyLevelAr: entity.safetyLevelAr,
      testDuration: entity.testDuration,
      chemicals: entity.chemicals,
      drugResults: entity.drugResults
          .map((drugResult) => DrugResultModel.fromEntity(drugResult))
          .toList(),
      category: entity.category,
      references: entity.references,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReagentModel &&
        other.reagentName == reagentName &&
        other.reagentNameAr == reagentNameAr &&
        other.description == description &&
        other.descriptionAr == descriptionAr &&
        other.safetyLevel == safetyLevel &&
        other.safetyLevelAr == safetyLevelAr &&
        other.testDuration == testDuration &&
        _listEquals(other.chemicals, chemicals) &&
        _listEquals(other.drugResults, drugResults) &&
        other.category == category &&
        _listEquals(other.references, references);
  }

  @override
  int get hashCode {
    return reagentName.hashCode ^
        reagentNameAr.hashCode ^
        description.hashCode ^
        descriptionAr.hashCode ^
        safetyLevel.hashCode ^
        safetyLevelAr.hashCode ^
        testDuration.hashCode ^
        chemicals.hashCode ^
        drugResults.hashCode ^
        category.hashCode ^
        references.hashCode;
  }

  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  String toString() {
    return 'ReagentModel(reagentName: $reagentName, description: $description, '
        'safetyLevel: $safetyLevel, testDuration: $testDuration, '
        'chemicals: $chemicals, drugResults: ${drugResults.length} results, '
        'category: $category, references: ${references.length})';
  }
}
