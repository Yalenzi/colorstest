class ReagentModel {
  final String id;
  final String name;
  final String nameAr;
  final String description;
  final String descriptionAr;
  final String safetyLevel;
  final Map<String, dynamic> safety;
  final List<dynamic> references;
  final dynamic testInstructions;
  final List<dynamic> chemicals;
  final List<dynamic> drugResults;
  final List<dynamic> equipment;
  final List<dynamic> handlingProcedures;
  final List<dynamic> specificHazards;
  final List<dynamic> storage;
  final int testDuration;

  ReagentModel({
    required this.id,
    required this.name,
    required this.nameAr,
    required this.description,
    required this.descriptionAr,
    required this.safetyLevel,
    required this.safety,
    required this.references,
    required this.testInstructions,
    required this.chemicals,
    required this.drugResults,
    required this.equipment,
    required this.handlingProcedures,
    required this.specificHazards,
    required this.storage,
    required this.testDuration,
  });

  factory ReagentModel.fromJson(
      String id,
      Map<String, dynamic> json,
      Map<String, dynamic> safetyJson,
      Map<String, dynamic> referenceJson) {
    
    // Safety level resolution
    String resolvedSafetyLevel = 'UNKNOWN';
    if (safetyJson['level'] != null && safetyJson['level'].toString().isNotEmpty) {
      resolvedSafetyLevel = safetyJson['level'].toString().toUpperCase();
    } else if (json['safetyLevel'] != null && json['safetyLevel'].toString().isNotEmpty) {
      resolvedSafetyLevel = json['safetyLevel'].toString().toUpperCase();
    }

    return ReagentModel(
      id: id,
      name: json['reagentName'] ?? json['name'] ?? id,
      nameAr: json['reagentName_ar'] ?? json['name_ar'] ?? '',
      description: json['description'] ?? '',
      descriptionAr: json['description_ar'] ?? '',
      safetyLevel: resolvedSafetyLevel,
      safety: safetyJson,
      references: referenceJson[id] is List ? referenceJson[id] : [],
      testInstructions: json['instructions'] ?? json['testInstructions'] ?? [],
      chemicals: json['chemicals'] ?? [],
      drugResults: json['drugResults'] ?? [],
      equipment: json['equipment'] ?? [],
      handlingProcedures: json['handlingProcedures'] ?? [],
      specificHazards: json['specificHazards'] ?? [],
      storage: json['storage'] ?? [],
      testDuration: (json['testDuration'] as num?)?.toInt() ?? 1,
    );
  }
}

