import 'package:cloud_firestore/cloud_firestore.dart';

/// Service untuk mengelola profil pengguna termasuk data kesehatan
/// Data kesehatan meliputi: tinggi badan, berat badan, tanggal lahir
class UserProfileService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Data profil pengguna termasuk kesehatan
  static Future<UserProfileData?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserProfileData.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Update profil kesehatan pengguna
  static Future<bool> updateHealthProfile({
    required String uid,
    double? heightCm,
    double? weightKg,
    DateTime? birthDate,
  }) async {
    try {
      final updateData = <String, dynamic>{};

      if (heightCm != null) {
        updateData['heightCm'] = heightCm;
      }
      if (weightKg != null) {
        updateData['weightKg'] = weightKg;
      }
      if (birthDate != null) {
        updateData['birthDate'] = Timestamp.fromDate(birthDate);
      }

      if (updateData.isEmpty) return false;

      await _firestore.collection('users').doc(uid).update(updateData);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Hitung BMI dari tinggi dan berat badan
  /// BMI = berat(kg) / (tinggi(m))^2
  static double? calculateBMI(double heightCm, double weightKg) {
    if (heightCm <= 0 || weightKg <= 0) return null;
    final heightM = heightCm / 100;
    return weightKg / (heightM * heightM);
  }

  /// Kategori BMI berdasarkan nilai BMI
  static BMICategory getBMICategory(double bmi) {
    if (bmi < 18.5) return BMICategory.underweight;
    if (bmi < 25) return BMICategory.normal;
    if (bmi < 30) return BMICategory.overweight;
    return BMICategory.obese;
  }

  /// Hitung usia dari tanggal lahir
  static int? calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  /// Hitung kebutuhan air harian dalam ml
  /// Rumus: 30-35 ml per kg berat badan (titik tengah 32.5 ml)
  static double calculateDailyWaterNeed(double weightKg) {
    return weightKg * 32.5;
  }

  /// Kategori usia untuk rekomendasi quest
  static AgeCategory getAgeCategory(int age) {
    if (age < 18) return AgeCategory.teenager;
    if (age < 30) return AgeCategory.youngAdult;
    if (age < 45) return AgeCategory.adult;
    if (age < 60) return AgeCategory.middleAge;
    return AgeCategory.senior;
  }

  /// Dapatkan batas EXP harian berdasarkan level
  static int getDailyExpLimit(int level) {
    // Batas EXP harian meningkat seiring level
    // Base: 500 EXP/hari + bonus per level
    return 500 + (level * 50);
  }
}

/// Model data profil pengguna
class UserProfileData {
  final String uid;
  final String displayName;
  final String rank;
  final int level;
  final int currentExp;
  final int expToNextLevel;
  final int totalExp;
  final int streak;
  final bool restModeActive;
  final DateTime? createdAt;
  final String language;

  // Data kesehatan
  final double? heightCm;
  final double? weightKg;
  final DateTime? birthDate;

  // Data turunan
  final double? bmi;
  final int? age;
  final double? dailyWaterNeedMl;

  UserProfileData({
    required this.uid,
    required this.displayName,
    required this.rank,
    required this.level,
    required this.currentExp,
    required this.expToNextLevel,
    required this.totalExp,
    required this.streak,
    required this.restModeActive,
    this.createdAt,
    required this.language,
    this.heightCm,
    this.weightKg,
    this.birthDate,
    this.bmi,
    this.age,
    this.dailyWaterNeedMl,
  });

  factory UserProfileData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    double? height = data['heightCm']?.toDouble();
    double? weight = data['weightKg']?.toDouble();
    DateTime? birthDate;
    if (data['birthDate'] is Timestamp) {
      birthDate = (data['birthDate'] as Timestamp).toDate();
    }

    // Hitung BMI jika data tersedia
    double? bmi;
    if (height != null && weight != null) {
      bmi = UserProfileService.calculateBMI(height, weight);
    }

    // Hitung usia jika tanggal lahir tersedia
    int? age;
    if (birthDate != null) {
      age = UserProfileService.calculateAge(birthDate);
    }

    // Hitung kebutuhan air jika berat badan tersedia
    double? waterNeed;
    if (weight != null) {
      waterNeed = UserProfileService.calculateDailyWaterNeed(weight);
    }

    return UserProfileData(
      uid: doc.id,
      displayName: data['displayName'] ?? 'Hunter',
      rank: data['rank'] ?? 'E - Awakening',
      level: data['level'] ?? 1,
      currentExp: data['currentExp'] ?? 0,
      expToNextLevel: data['expToNextLevel'] ?? 100,
      totalExp: data['totalExp'] ?? 0,
      streak: data['streak'] ?? 0,
      restModeActive: data['restModeActive'] ?? false,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      language: data['language'] ?? 'id',
      heightCm: height,
      weightKg: weight,
      birthDate: birthDate,
      bmi: bmi,
      age: age,
      dailyWaterNeedMl: waterNeed,
    );
  }

  /// Cek apakah profil kesehatan sudah lengkap
  bool get isHealthProfileComplete {
    return heightCm != null && heightCm! > 0 &&
           weightKg != null && weightKg! > 0 &&
           birthDate != null;
  }

  /// Dapatkan kategori BMI dalam teks
  String getBMICategoryText(String langCode) {
    if (bmi == null) return '';
    final category = UserProfileService.getBMICategory(bmi!);
    return category.getDisplayName(langCode);
  }

  /// Dapatkan kategori usia dalam teks
  String getAgeCategoryText(String langCode) {
    if (age == null) return '';
    final category = UserProfileService.getAgeCategory(age!);
    return category.getDisplayName(langCode);
  }
}

/// Kategori BMI
enum BMICategory {
  underweight,
  normal,
  overweight,
  obese;

  String getDisplayName(String langCode) {
    switch (this) {
      case BMICategory.underweight:
        return langCode == 'id' ? 'Kurus' : 'Underweight';
      case BMICategory.normal:
        return langCode == 'id' ? 'Normal' : 'Normal';
      case BMICategory.overweight:
        return langCode == 'id' ? 'Gemuk' : 'Overweight';
      case BMICategory.obese:
        return langCode == 'id' ? 'Obesitas' : 'Obese';
    }
  }
}

/// Kategori Usia
enum AgeCategory {
  teenager,    // < 18
  youngAdult,  // 18-29
  adult,       // 30-44
  middleAge,   // 45-59
  senior;      // 60+

  String getDisplayName(String langCode) {
    switch (this) {
      case AgeCategory.teenager:
        return langCode == 'id' ? 'Remaja' : 'Teenager';
      case AgeCategory.youngAdult:
        return langCode == 'id' ? 'Dewasa Muda' : 'Young Adult';
      case AgeCategory.adult:
        return langCode == 'id' ? 'Dewasa' : 'Adult';
      case AgeCategory.middleAge:
        return langCode == 'id' ? 'Paruh Baya' : 'Middle Age';
      case AgeCategory.senior:
        return langCode == 'id' ? 'Lansia' : 'Senior';
    }
  }
}
