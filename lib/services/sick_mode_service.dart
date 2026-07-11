import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Model untuk kondisi kesehatan pengguna
class HealthCondition {
  final String id;
  final String nameId;
  final String nameEn;
  final String severity; // 'mild', 'moderate', 'severe'
  final String category; // 'joint', 'back', 'heart', 'respiratory', 'general', 'other'

  const HealthCondition({
    required this.id,
    required this.nameId,
    required this.nameEn,
    required this.severity,
    required this.category,
  });

  String getName(String langCode) => langCode == 'id' ? nameId : nameEn;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nameId': nameId,
      'nameEn': nameEn,
      'severity': severity,
      'category': category,
    };
  }

  factory HealthCondition.fromMap(Map<String, dynamic> map) {
    return HealthCondition(
      id: map['id'] ?? '',
      nameId: map['nameId'] ?? '',
      nameEn: map['nameEn'] ?? '',
      severity: map['severity'] ?? 'moderate',
      category: map['category'] ?? 'general',
    );
  }
}

/// Predefined list of common health conditions
class HealthConditionDatabase {
  static const List<HealthCondition> conditions = [
    // Joint issues
    HealthCondition(
      id: 'knee_pain',
      nameId: 'Nyeri Lutut',
      nameEn: 'Knee Pain',
      severity: 'moderate',
      category: 'joint',
    ),
    HealthCondition(
      id: 'hip_pain',
      nameId: 'Nyeri Pinggul',
      nameEn: 'Hip Pain',
      severity: 'moderate',
      category: 'joint',
    ),
    HealthCondition(
      id: 'shoulder_pain',
      nameId: 'Nyeri Bahu',
      nameEn: 'Shoulder Pain',
      severity: 'moderate',
      category: 'joint',
    ),
    HealthCondition(
      id: 'wrist_pain',
      nameId: 'Nyeri Pergelangan Tangan',
      nameEn: 'Wrist Pain',
      severity: 'mild',
      category: 'joint',
    ),
    HealthCondition(
      id: 'ankle_pain',
      nameId: 'Nyeri Pergelangan Kaki',
      nameEn: 'Ankle Pain',
      severity: 'mild',
      category: 'joint',
    ),
    HealthCondition(
      id: 'arthritis',
      nameId: 'Arthritis/Radang Sendi',
      nameEn: 'Arthritis',
      severity: 'severe',
      category: 'joint',
    ),

    // Back issues
    HealthCondition(
      id: 'lower_back_pain',
      nameId: 'Nyeri Punggung Bawah',
      nameEn: 'Lower Back Pain',
      severity: 'moderate',
      category: 'back',
    ),
    HealthCondition(
      id: 'upper_back_pain',
      nameId: 'Nyeri Punggung Atas',
      nameEn: 'Upper Back Pain',
      severity: 'mild',
      category: 'back',
    ),
    HealthCondition(
      id: 'herniated_disc',
      nameId: 'Hernia Disc/Tulang Belakang',
      nameEn: 'Herniated Disc',
      severity: 'severe',
      category: 'back',
    ),

    // Heart/Circulation
    HealthCondition(
      id: 'heart_condition',
      nameId: 'Kondisi Jantung',
      nameEn: 'Heart Condition',
      severity: 'severe',
      category: 'heart',
    ),
    HealthCondition(
      id: 'high_blood_pressure',
      nameId: 'Tekanan Darah Tinggi',
      nameEn: 'High Blood Pressure',
      severity: 'moderate',
      category: 'heart',
    ),
    HealthCondition(
      id: 'low_blood_pressure',
      nameId: 'Tekanan Darah Rendah',
      nameEn: 'Low Blood Pressure',
      severity: 'mild',
      category: 'heart',
    ),

    // Respiratory
    HealthCondition(
      id: 'asthma',
      nameId: 'Asma',
      nameEn: 'Asthma',
      severity: 'moderate',
      category: 'respiratory',
    ),
    HealthCondition(
      id: 'bronchitis',
      nameId: 'Bronkitis',
      nameEn: 'Bronchitis',
      severity: 'moderate',
      category: 'respiratory',
    ),
    HealthCondition(
      id: 'cold_flu',
      nameId: 'Pilek/Flu',
      nameEn: 'Cold/Flu',
      severity: 'mild',
      category: 'general',
    ),
    HealthCondition(
      id: 'covid',
      nameId: 'COVID-19/Positif Covid',
      nameEn: 'COVID-19',
      severity: 'moderate',
      category: 'respiratory',
    ),

    // General illness
    HealthCondition(
      id: 'fatigue',
      nameId: 'Kelelahan',
      nameEn: 'Fatigue',
      severity: 'mild',
      category: 'general',
    ),
    HealthCondition(
      id: 'muscle_strain',
      nameId: 'Terluka/Otot Tegang',
      nameEn: 'Muscle Strain',
      severity: 'moderate',
      category: 'general',
    ),
    HealthCondition(
      id: 'sprain',
      nameId: 'Keseleo',
      nameEn: 'Sprain',
      severity: 'moderate',
      category: 'general',
    ),
    HealthCondition(
      id: 'fever',
      nameId: 'Demam',
      nameEn: 'Fever',
      severity: 'mild',
      category: 'general',
    ),
    HealthCondition(
      id: 'headache',
      nameId: 'Sakit Kepala',
      nameEn: 'Headache',
      severity: 'mild',
      category: 'general',
    ),
    HealthCondition(
      id: 'pregnancy',
      nameId: 'Hamil/Kehamilan',
      nameEn: 'Pregnancy',
      severity: 'moderate',
      category: 'other',
    ),
    HealthCondition(
      id: 'post_surgery',
      nameId: 'Pasca Operasi',
      nameEn: 'Post Surgery',
      severity: 'severe',
      category: 'other',
    ),
    HealthCondition(
      id: 'other',
      nameId: 'Lainnya',
      nameEn: 'Other',
      severity: 'mild',
      category: 'other',
    ),
  ];

  static HealthCondition? getById(String id) {
    try {
      return conditions.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  static List<HealthCondition> getByCategory(String category) {
    return conditions.where((c) => c.category == category).toList();
  }

  static String getCategoryName(String category, String langCode) {
    final categoryMap = {
      'joint': {'id': 'Sendi', 'en': 'Joint'},
      'back': {'id': 'Punggung', 'en': 'Back'},
      'heart': {'id': 'Jantung', 'en': 'Heart'},
      'respiratory': {'id': 'Pernapasan', 'en': 'Respiratory'},
      'general': {'id': 'Umum', 'en': 'General'},
      'other': {'id': 'Lainnya', 'en': 'Other'},
    };
    return categoryMap[category]?[langCode] ?? category;
  }
}

/// Service untuk mengelola mode terbatas/penyakitan
class SickModeService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY'); // isi api key disini

  /// Cek apakah user sedang dalam mode terbatas
  static Future<bool> isSickModeActive(String uid) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('sick_mode')
          .doc('current')
          .get();

      if (!doc.exists || doc.data() == null) return false;

      final data = doc.data()!;
      final isActive = data['isActive'] as bool? ?? false;
      final endDate = data['endDate'] as Timestamp?;

      if (!isActive) return false;

      // Cek apakah sudah expired
      if (endDate != null && endDate.toDate().isBefore(DateTime.now())) {
        // Auto deactivate
        await deactivateSickMode(uid);
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Aktifkan mode terbatas
  static Future<void> activateSickMode({
    required String uid,
    required List<String> conditionIds,
    String? customNote,
    int durationDays = 7,
  }) async {
    try {
      final endDate = DateTime.now().add(Duration(days: durationDays));

      await _firestore
          .collection('users')
          .doc(uid)
          .collection('sick_mode')
          .doc('current')
          .set({
        'isActive': true,
        'conditionIds': conditionIds,
        'customNote': customNote,
        'startDate': FieldValue.serverTimestamp(),
        'endDate': Timestamp.fromDate(endDate),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error activating sick mode: $e');
      rethrow;
    }
  }

  /// Nonaktifkan mode terbatas
  static Future<void> deactivateSickMode(String uid) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('sick_mode')
          .doc('current')
          .set({
        'isActive': false,
        'deactivatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error deactivating sick mode: $e');
    }
  }

  /// Ambil data mode terbatas user
  static Future<SickModeData?> getSickModeData(String uid) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('sick_mode')
          .doc('current')
          .get();

      if (!doc.exists || doc.data() == null) return null;

      final data = doc.data()!;
      if (data['isActive'] != true) return null;

      final conditionIds = List<String>.from(data['conditionIds'] ?? []);
      final conditions = conditionIds
          .map((id) => HealthConditionDatabase.getById(id))
          .where((c) => c != null)
          .cast<HealthCondition>()
          .toList();

      return SickModeData(
        isActive: true,
        conditions: conditions,
        customNote: data['customNote'],
        startDate: data['startDate'] != null
            ? (data['startDate'] as Timestamp).toDate()
            : DateTime.now(),
        endDate: data['endDate'] != null
            ? (data['endDate'] as Timestamp).toDate()
            : null,
      );
    } catch (e) {
      debugPrint('Error getting sick mode data: $e');
      return null;
    }
  }

  /// Hitung multiplier berdasarkan kondisi
  /// Mengembalikan pengurangan difficulty (0.0 = normal, -0.5 = 50% lebih mudah)
  static double calculateDifficultyReduction(List<HealthCondition> conditions) {
    if (conditions.isEmpty) return 0.0;

    double reduction = 0.0;

    for (final condition in conditions) {
      switch (condition.severity) {
        case 'mild':
          reduction += 0.15; // 15% easier
          break;
        case 'moderate':
          reduction += 0.30; // 30% easier
          break;
        case 'severe':
          reduction += 0.50; // 50% easier
          break;
      }
    }

    // Cap at 70% easier
    return reduction.clamp(0.0, 0.70);
  }

  /// Get adjusted quest parameters based on sick mode
  static Map<String, dynamic> getAdjustedQuestParams({
    required int originalSets,
    required int originalReps,
    required int originalRest,
    required int originalTimeLimit,
    required String difficulty,
    required List<HealthCondition> conditions,
  }) {
    final reduction = calculateDifficultyReduction(conditions);

    if (reduction == 0.0) {
      return {
        'sets': originalSets,
        'reps': originalReps,
        'rest': originalRest,
        'timeLimit': originalTimeLimit,
        'difficulty': difficulty,
      };
    }

    // Apply reduction
    int newSets = (originalSets * (1 - reduction * 0.3)).round().clamp(1, originalSets);
    int newReps = (originalReps * (1 - reduction * 0.5)).round().clamp(5, originalReps);
    int newRest = (originalRest * (1 + reduction * 0.3)).round();
    int newTimeLimit = (originalTimeLimit * (1 + reduction * 0.5)).round();

    // Adjust difficulty label
    String newDifficulty = difficulty;
    if (difficulty == 'advanced') {
      newDifficulty = 'intermediate';
    } else if (difficulty == 'intermediate') {
      newDifficulty = 'beginner';
    }

    return {
      'sets': newSets,
      'reps': newReps,
      'rest': newRest,
      'timeLimit': newTimeLimit,
      'difficulty': newDifficulty,
      'reduction': reduction,
    };
  }
}

/// Data model untuk mode terbatas
class SickModeData {
  final bool isActive;
  final List<HealthCondition> conditions;
  final String? customNote;
  final DateTime startDate;
  final DateTime? endDate;

  SickModeData({
    required this.isActive,
    required this.conditions,
    this.customNote,
    required this.startDate,
    this.endDate,
  });

  int? get remainingDays {
    if (endDate == null) return null;
    final diff = endDate!.difference(DateTime.now()).inDays;
    return diff > 0 ? diff : 0;
  }

  String getSeverityLevel() {
    if (conditions.isEmpty) return 'none';
    final hasSevere = conditions.any((c) => c.severity == 'severe');
    final hasModerate = conditions.any((c) => c.severity == 'moderate');
    if (hasSevere) return 'severe';
    if (hasModerate) return 'moderate';
    return 'mild';
  }
}
