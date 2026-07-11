import 'package:flutter/material.dart';

class Exercise {
  final String id;
  final String nameId;
  final String nameEn;
  final String category;
  final List<String> targetMusclesId;
  final List<String> targetMusclesEn;
  final List<String> secondaryMusclesId;
  final List<String> secondaryMusclesEn;
  final String equipment;
  final String difficulty;
  final String descriptionId;
  final String descriptionEn;
  final List<String> instructionsId;
  final List<String> instructionsEn;
  final List<String> tipsId;
  final List<String> tipsEn;
  final String? startingImageAsset;
  final String? endingImageAsset;
  final IconData icon;
  final Color color;
  final bool requiresGymEquipment;

  const Exercise({
    required this.id,
    required this.nameId,
    required this.nameEn,
    required this.category,
    required this.targetMusclesId,
    required this.targetMusclesEn,
    required this.secondaryMusclesId,
    required this.secondaryMusclesEn,
    required this.equipment,
    required this.difficulty,
    required this.descriptionId,
    required this.descriptionEn,
    required this.instructionsId,
    required this.instructionsEn,
    required this.tipsId,
    required this.tipsEn,
    this.startingImageAsset,
    this.endingImageAsset,
    required this.icon,
    required this.color,
    this.requiresGymEquipment = false,
  });

  String getName(String langCode) => langCode == 'id' ? nameId : nameEn;
  List<String> getTargetMuscles(String langCode) =>
      langCode == 'id' ? targetMusclesId : targetMusclesEn;
  List<String> getSecondaryMuscles(String langCode) =>
      langCode == 'id' ? secondaryMusclesId : secondaryMusclesEn;
  String getDescription(String langCode) =>
      langCode == 'id' ? descriptionId : descriptionEn;
  List<String> getInstructions(String langCode) =>
      langCode == 'id' ? instructionsId : instructionsEn;
  List<String> getTips(String langCode) =>
      langCode == 'id' ? tipsId : tipsEn;
}

class ExerciseDatabase {
  static const List<String> categories = [
    'chest',
    'back',
    'shoulders',
    'arms',
    'legs',
    'core',
    'cardio',
    'full_body',
    'gym',
    'no_equipment',
  ];

  // Image URLs dari musclewiki.com
  static const _images = {
    'push_up': {
      'start': 'https://media.musclewiki.com/media/uploads/2023/11/30153353/male-bodyweight-pushup-front.mp4/0.jpg',
      'end': 'https://media.musclewiki.com/media/uploads/2023/11/30153353/male-bodyweight-pushup-front.mp4/30.jpg',
    },
    'wide_push_up': {
      'start': 'https://media.musclewiki.com/media/uploads/2023/11/30153353/male-bodyweight-pushup-front.mp4/0.jpg',
      'end': 'https://media.musclewiki.com/media/uploads/2023/11/30153353/male-bodyweight-pushup-front.mp4/30.jpg',
    },
    'diamond_push_up': {
      'start': 'https://media.musclewiki.com/media/uploads/2023/11/30153353/male-bodyweight-pushup-front.mp4/0.jpg',
      'end': 'https://media.musclewiki.com/media/uploads/2023/11/30153353/male-bodyweight-pushup-front.mp4/30.jpg',
    },
    'incline_push_up': {
      'start': 'https://media.musclewiki.com/media/uploads/2023/11/30153353/male-incline-pushup-front.mp4/0.jpg',
      'end': 'https://media.musclewiki.com/media/uploads/2023/11/30153353/male-incline-pushup-front.mp4/30.jpg',
    },
    'sit_up': {
      'start': 'https://media.musclewiki.com/media/uploads/2023/11/30152150/male-sit-up-front.mp4/0.jpg',
      'end': 'https://media.musclewiki.com/media/uploads/2023/11/30152150/male-sit-up-front.mp4/30.jpg',
    },
    'crunch': {
      'start': 'https://media.musclewiki.com/media/uploads/2023/11/30152303/male-crunches-front.mp4/0.jpg',
      'end': 'https://media.musclewiki.com/media/uploads/2023/11/30152303/male-crunches-front.mp4/30.jpg',
    },
    'leg_raise': {
      'start': 'https://media.musclewiki.com/media/uploads/2023/11/30152436/male-lying-legraise-front.mp4/0.jpg',
      'end': 'https://media.musclewiki.com/media/uploads/2023/11/30152436/male-lying-legraise-front.mp4/30.jpg',
    },
    'plank': {
      'start': 'https://media.musclewiki.com/media/uploads/2023/11/30152605/male-plank-front.mp4/0.jpg',
      'end': 'https://media.musclewiki.com/media/uploads/2023/11/30152605/male-plank-front.mp4/30.jpg',
    },
    'side_plank': {
      'start': 'https://media.musclewiki.com/media/uploads/2023/11/30152624/male-side-plank-side.mp4/0.jpg',
      'end': 'https://media.musclewiki.com/media/uploads/2023/11/30152624/male-side-plank-side.mp4/30.jpg',
    },
    'squat': {
      'start': 'https://media.musclewiki.com/media/uploads/2023/11/30152839/male-bodyweight-squat-front.mp4/0.jpg',
      'end': 'https://media.musclewiki.com/media/uploads/2023/11/30152839/male-bodyweight-squat-front.mp4/30.jpg',
    },
    'squat_jump': {
      'start': 'https://media.musclewiki.com/media/uploads/2023/11/30152903/male-jump-squat-front.mp4/0.jpg',
      'end': 'https://media.musclewiki.com/media/uploads/2023/11/30152903/male-jump-squat-front.mp4/30.jpg',
    },
    'lunge': {
      'start': 'https://media.musclewiki.com/media/uploads/2023/11/30153004/male-lunge-front.mp4/0.jpg',
      'end': 'https://media.musclewiki.com/media/uploads/2023/11/30153004/male-lunge-front.mp4/30.jpg',
    },
    'wall_sit': {
      'start': 'https://media.musclewiki.com/media/uploads/2023/11/30153043/male-wall-sit-side.mp4/0.jpg',
      'end': 'https://media.musclewiki.com/media/uploads/2023/11/30153043/male-wall-sit-side.mp4/30.jpg',
    },
    'calf_raise': {
      'start': 'https://media.musclewiki.com/media/uploads/2023/11/30153117/male-calf-raise-front.mp4/0.jpg',
      'end': 'https://media.musclewiki.com/media/uploads/2023/11/30153117/male-calf-raise-front.mp4/30.jpg',
    },
    'glute_bridge': {
      'start': 'https://media.musclewiki.com/media/uploads/2023/11/30153219/male-glute-bridge-front.mp4/0.jpg',
      'end': 'https://media.musclewiki.com/media/uploads/2023/11/30153219/male-glute-bridge-front.mp4/30.jpg',
    },
    'jumping_jack': {
      'start': 'https://media.musclewiki.com/media/uploads/2023/11/30152135/male-jumping-jacks-front.mp4/0.jpg',
      'end': 'https://media.musclewiki.com/media/uploads/2023/11/30152135/male-jumping-jacks-front.mp4/30.jpg',
    },
    'high_knees': {
      'start': 'https://media.musclewiki.com/media/uploads/2023/11/30152147/male-high-knees-front.mp4/0.jpg',
      'end': 'https://media.musclewiki.com/media/uploads/2023/11/30152147/male-high-knees-front.mp4/30.jpg',
    },
    'mountain_climber': {
      'start': 'https://media.musclewiki.com/media/uploads/2023/11/30152459/male-mountain-climber-front.mp4/0.jpg',
      'end': 'https://media.musclewiki.com/media/uploads/2023/11/30152459/male-mountain-climber-front.mp4/30.jpg',
    },
    'burpee': {
      'start': 'https://media.musclewiki.com/media/uploads/2023/11/30152209/male-burpee-front.mp4/0.jpg',
      'end': 'https://media.musclewiki.com/media/uploads/2023/11/30152209/male-burpee-front.mp4/30.jpg',
    },
    'superman': {
      'start': 'https://media.musclewiki.com/media/uploads/2023/11/30153242/male-superman-back.mp4/0.jpg',
      'end': 'https://media.musclewiki.com/media/uploads/2023/11/30153242/male-superman-back.mp4/30.jpg',
    },
    'tricep_dip': {
      'start': 'https://media.musclewiki.com/media/uploads/2023/11/30153334/male-tricep-dips-front.mp4/0.jpg',
      'end': 'https://media.musclewiki.com/media/uploads/2023/11/30153334/male-tricep-dips-front.mp4/30.jpg',
    },
    'russian_twist': {
      'start': 'https://media.musclewiki.com/media/uploads/2023/11/30152704/male-russian-twist-front.mp4/0.jpg',
      'end': 'https://media.musclewiki.com/media/uploads/2023/11/30152704/male-russian-twist-front.mp4/30.jpg',
    },
    'bicycle_crunch': {
      'start': 'https://media.musclewiki.com/media/uploads/2023/11/30152257/male-bicycle-crunches-front.mp4/0.jpg',
      'end': 'https://media.musclewiki.com/media/uploads/2023/11/30152257/male-bicycle-crunches-front.mp4/30.jpg',
    },
    'flutter_kick': {
      'start': 'https://media.musclewiki.com/media/uploads/2023/11/30152357/male-flutter-kicks-front.mp4/0.jpg',
      'end': 'https://media.musclewiki.com/media/uploads/2023/11/30152357/male-flutter-kicks-front.mp4/30.jpg',
    },
    'v_up': {
      'start': 'https://media.musclewiki.com/media/uploads/2023/11/30152752/male-v-up-front.mp4/0.jpg',
      'end': 'https://media.musclewiki.com/media/uploads/2023/11/30152752/male-v-up-front.mp4/30.jpg',
    },
    // Gym exercises
    'bench_press': {
      'start': 'https://media.musclewiki.com/media/uploads/2023/11/30153342/male-barbell-bench-press-front.mp4/0.jpg',
      'end': 'https://media.musclewiki.com/media/uploads/2023/11/30153342/male-barbell-bench-press-front.mp4/30.jpg',
    },
    'deadlift': {
      'start': 'https://media.musclewiki.com/media/uploads/2023/11/30153238/male-barbell-deadlift-front.mp4/0.jpg',
      'end': 'https://media.musclewiki.com/media/uploads/2023/11/30153238/male-barbell-deadlift-front.mp4/30.jpg',
    },
    'lat_pulldown': {
      'start': 'https://media.musclewiki.com/media/uploads/2023/11/30152828/male-cable-lat-pulldown-front.mp4/0.jpg',
      'end': 'https://media.musclewiki.com/media/uploads/2023/11/30152828/male-cable-lat-pulldown-front.mp4/30.jpg',
    },
    'leg_press': {
      'start': 'https://media.musclewiki.com/media/uploads/2023/11/30153029/male-leg-press-side.mp4/0.jpg',
      'end': 'https://media.musclewiki.com/media/uploads/2023/11/30153029/male-leg-press-side.mp4/30.jpg',
    },
    'bicep_curl': {
      'start': 'https://media.musclewiki.com/media/uploads/2023/11/30152229/male-barbell-curl-front.mp4/0.jpg',
      'end': 'https://media.musclewiki.com/media/uploads/2023/11/30152229/male-barbell-curl-front.mp4/30.jpg',
    },
    'overhead_press': {
      'start': 'https://media.musclewiki.com/media/uploads/2023/11/30152655/male-barbell-shrugs-front.mp4/0.jpg',
      'end': 'https://media.musclewiki.com/media/uploads/2023/11/30152655/male-barbell-shrugs-front.mp4/30.jpg',
    },
  };

  static Map<String, String>? _getImages(String id) {
    return _images[id];
  }

  /// Get image URLs for an exercise
  /// Returns a map with 'start' and 'end' keys for starting and ending positions
  static Map<String, String>? getExerciseImages(String id) {
    return _images[id];
  }

  static const List<Exercise> exercises = [
    // ==================== CHEST EXERCISES ====================
    Exercise(
      id: 'push_up',
      nameId: 'Push Up',
      nameEn: 'Push Up',
      category: 'chest',
      targetMusclesId: ['Otot Dada (Pectoralis Major)', 'Otot Trisep (Triceps)'],
      targetMusclesEn: ['Chest (Pectoralis Major)', 'Triceps'],
      secondaryMusclesId: ['Otot Bahu (Deltoid Anterior)', 'Otot Inti (Core)'],
      secondaryMusclesEn: ['Anterior Deltoid', 'Core'],
      equipment: 'Tanpa Alat',
      difficulty: 'beginner',
      descriptionId:
          'Push up adalah latihan dasar yang melatih otot dada, bahu, dan lengan atas. Latihan ini menggunakan berat badan sendiri sebagai beban.',
      descriptionEn:
          'Push up is a fundamental exercise that strengthens chest, shoulders, and upper arms. Uses bodyweight as resistance.',
      instructionsId: [
        '📌 Posisi awal: Tubuh lurus, telapak tangan di lantai selebar bahu',
        '📌 Turunkan tubuh dengan menekuk siku hingga dada hampir menyentuh lantai',
        '📌 Dorong kembali ke atas hingga lengan lurus',
        '📌 Jaga tubuh tetap lurus sepanjang gerakan',
      ],
      instructionsEn: [
        '📌 Starting position: Body straight, palms on floor shoulder-width apart',
        '📌 Lower body by bending elbows until chest nearly touches floor',
        '📌 Push back up until arms are straight',
        '📌 Keep body straight throughout the movement',
      ],
      tipsId: [
        'Jaga pinggul tidak turun saat menurunkan badan',
        'Tarik napas saat turun, hembuskan saat mendorong ke atas',
      ],
      tipsEn: [
        'Keep hips from sagging during the movement',
        'Breathe in when lowering, exhale when pushing up',
      ],
      icon: Icons.fitness_center,
      color: Color(0xFFE53935),
    ),
    Exercise(
      id: 'wide_push_up',
      nameId: 'Push Up Lebar',
      nameEn: 'Wide Push Up',
      category: 'chest',
      targetMusclesId: ['Otot Dada Luar (Outer Chest)', 'Otot Dada Utama'],
      targetMusclesEn: ['Outer Chest', 'Pectoralis Major'],
      secondaryMusclesId: ['Otot Bahu (Deltoid)', 'Otot Trisep'],
      secondaryMusclesEn: ['Deltoids', 'Triceps'],
      equipment: 'Tanpa Alat',
      difficulty: 'beginner',
      descriptionId:
          'Variasi push up dengan posisi tangan lebih lebar untuk lebih fokus pada otot dada bagian luar.',
      descriptionEn:
          'A push up variation with wider hand placement to target outer chest muscles.',
      instructionsId: [
        '📌 Posisi awal: Tangan dilebar 1.5x lebar bahu',
        '📌 Jari tangan menghadap keluar membentuk sudut 45°',
        '📌 Turunkan badan dengan kontrol',
        '📌 Dorong ke atas dengan fokus pada otot dada',
      ],
      instructionsEn: [
        '📌 Starting position: Hands wider than shoulder width (1.5x)',
        '📌 Fingers pointing outward at 45° angle',
        '📌 Lower body with control',
        '📌 Push up focusing on chest contraction',
      ],
      tipsId: [
        'Jaga siku mengarah ke luar, bukan ke belakang',
      ],
      tipsEn: [
        'Keep elbows pointing outward, not backward',
      ],
      icon: Icons.fitness_center,
      color: Color(0xFFE53935),
    ),
    Exercise(
      id: 'diamond_push_up',
      nameId: 'Push Up Diamond',
      nameEn: 'Diamond Push Up',
      category: 'chest',
      targetMusclesId: ['Otot Trisep (Triceps)', 'Otot Dada Dalam'],
      targetMusclesEn: ['Triceps', 'Inner Chest'],
      secondaryMusclesId: ['Otot Dada (Pectoralis)', 'Otot Bahu'],
      secondaryMusclesEn: ['Pectoralis', 'Shoulders'],
      equipment: 'Tanpa Alat',
      difficulty: 'intermediate',
      descriptionId:
          'Push up dengan tangan membentuk bentuk diamond (belah ketupat) untuk melatih trisep lebih fokus.',
      descriptionEn:
          'Push up with hands forming a diamond shape under the chest to target triceps more intensely.',
      instructionsId: [
        '📌 Posisi awal: Tangan di bawah dada, jari telunjuk & jempol bertemu',
        '📌 Bentuk diamond dengan kedua tangan',
        '📌 Turunkan badan dengan siku dekat tubuh',
        '📌 Dorong ke atas fokus pada kontraksi trisep',
      ],
      instructionsEn: [
        '📌 Starting position: Hands under chest, index fingers & thumbs touching',
        '📌 Form diamond shape with both hands',
        '📌 Lower body with elbows close to body',
        '📌 Push up focusing on tricep contraction',
      ],
      tipsId: [
        'Jaga siku dekat dengan tubuh sepanjang gerakan',
      ],
      tipsEn: [
        'Keep elbows close to body throughout the movement',
      ],
      icon: Icons.fitness_center,
      color: Color(0xFFE53935),
    ),
    Exercise(
      id: 'incline_push_up',
      nameId: 'Push Up Incline',
      nameEn: 'Incline Push Up',
      category: 'chest',
      targetMusclesId: ['Otot Dada Bawah (Lower Chest)', 'Otot Bahu'],
      targetMusclesEn: ['Lower Chest', 'Shoulders'],
      secondaryMusclesId: ['Otot Trisep', 'Otot Dada Atas'],
      secondaryMusclesEn: ['Triceps', 'Upper Chest'],
      equipment: 'Bangku/Platform',
      difficulty: 'beginner',
      descriptionId:
          'Push up dengan kaki lebih tinggi dari tangan. Cocok untuk pemula.',
      descriptionEn:
          'Push up with feet elevated higher than hands. Great for beginners.',
      instructionsId: [
        '📌 Posisi awal: Tangan di lantai, kaki di atas bangku',
        '📌 Tubuh membentuk garis lurus',
        '📌 Turunkan dada ke arah bangku',
        '📌 Dorong kembali ke atas',
      ],
      instructionsEn: [
        '📌 Starting position: Hands on floor, feet on bench',
        '📌 Body forms straight line',
        '📌 Lower chest toward the bench',
        '📌 Push back up',
      ],
      tipsId: [
        'Semakin tinggi platform, semakin mudah',
      ],
      tipsEn: [
        'Higher platform makes the exercise easier',
      ],
      icon: Icons.fitness_center,
      color: Color(0xFFE53935),
    ),

    // ==================== CORE/ABS EXERCISES ====================
    Exercise(
      id: 'sit_up',
      nameId: 'Sit Up',
      nameEn: 'Sit Up',
      category: 'core',
      targetMusclesId: ['Otot Perut (Rectus Abdominis)', 'Otot Perut Bawah'],
      targetMusclesEn: ['Rectus Abdominis (Abs)', 'Lower Abs'],
      secondaryMusclesId: ['Otot Hip Flexor', 'Otot Obliques'],
      secondaryMusclesEn: ['Hip Flexors', 'Obliques'],
      equipment: 'Tanpa Alat',
      difficulty: 'beginner',
      descriptionId:
          'Sit up adalah latihan klasik untuk otot perut dengan gerakan mengangkat badan dari berbaring ke duduk.',
      descriptionEn:
          'Sit up is a classic exercise for abdominal muscles.',
      instructionsId: [
        '📌 Posisi awal: Berbaring telentang, lutut ditekuk, kaki rata di lantai',
        '📌 Tangan di belakang kepala atau di dada',
        '📌 Angkat badan ke atas menggunakan otot perut',
        '📌 Turunkan badan dengan kontrol',
      ],
      instructionsEn: [
        '📌 Starting position: Lying on back, knees bent, feet flat on floor',
        '📌 Hands behind head or on chest',
        '📌 Lift upper body using abdominal muscles',
        '📌 Lower body with control',
      ],
      tipsId: [
        'Hindari menarik leher - fokus menggunakan otot perut',
        'Jaga kaki tetap di lantai',
      ],
      tipsEn: [
        'Avoid pulling neck - focus on using abdominal muscles',
        'Keep feet flat on floor',
      ],
      icon: Icons.accessibility_new,
      color: Color(0xFF43A047),
    ),
    Exercise(
      id: 'crunch',
      nameId: 'Crunch',
      nameEn: 'Crunch',
      category: 'core',
      targetMusclesId: ['Otot Perut Atas (Upper Abs)', 'Rectus Abdominis'],
      targetMusclesEn: ['Upper Abs', 'Rectus Abdominis'],
      secondaryMusclesId: ['Otot Obliques'],
      secondaryMusclesEn: ['Obliques'],
      equipment: 'Tanpa Alat',
      difficulty: 'beginner',
      descriptionId:
          'Crunch adalah versi mini dari sit up yang lebih fokus pada otot perut bagian atas.',
      descriptionEn:
          'Crunch is a mini version of sit up focusing more on upper abdominal muscles.',
      instructionsId: [
        '📌 Posisi awal: Berbaring telentang, lutut ditekuk, tangan di belakang kepala',
        '📌 Jaga lengan rileks, jangan menarik kepala',
        '📌 Angkat kepala & bahu dari lantai dengan kontraksi otot perut',
        '📌 Angkat hingga tulang belikat离开 lantai',
      ],
      instructionsEn: [
        '📌 Starting position: Lying on back, knees bent, hands behind head',
        '📌 Keep arms relaxed, do not pull head',
        '📌 Lift head and shoulders off floor with abs contraction',
        '📌 Lift until shoulder blades leave floor',
      ],
      tipsId: [
        'Gerakan kecil tapi terkontrol lebih efektif',
      ],
      tipsEn: [
        'Small, controlled movements are more effective',
      ],
      icon: Icons.accessibility_new,
      color: Color(0xFF43A047),
    ),
    Exercise(
      id: 'leg_raise',
      nameId: 'Leg Raise',
      nameEn: 'Leg Raise',
      category: 'core',
      targetMusclesId: ['Otot Perut Bawah (Lower Abs)', 'Hip Flexors'],
      targetMusclesEn: ['Lower Abs', 'Hip Flexors'],
      secondaryMusclesId: ['Otot Perut Obliques', 'Quadriceps'],
      secondaryMusclesEn: ['Obliques', 'Quadriceps'],
      equipment: 'Tanpa Alat',
      difficulty: 'intermediate',
      descriptionId:
          'Leg raise melatih otot perut bagian bawah dengan mengangkat kaki dari posisi berbaring.',
      descriptionEn:
          'Leg raise targets lower abdominal muscles by lifting legs from lying position.',
      instructionsId: [
        '📌 Posisi awal: Berbaring telentang, tangan di samping atau di bawah bokong',
        '📌 Kaki lurus, telapak kaki menghadap ke atas',
        '📌 Angkat kedua kaki hingga membentuk sudut 90°',
        '📌 Turunkan dengan lambat dan terkontrol',
      ],
      instructionsEn: [
        '📌 Starting position: Lying on back, hands at sides or under buttocks',
        '📌 Legs straight, feet pointing up',
        '📌 Lift both legs to 90 degree angle',
        '📌 Lower slowly and controlled',
      ],
      tipsId: [
        'Jika punggung bawah naik dari lantai, hentikan lebih awal',
      ],
      tipsEn: [
        'If lower back lifts off floor, stop earlier',
      ],
      icon: Icons.accessibility_new,
      color: Color(0xFF43A047),
    ),
    Exercise(
      id: 'plank',
      nameId: 'Plank',
      nameEn: 'Plank',
      category: 'core',
      targetMusclesId: ['Otot Core Keseluruhan', 'Transverse Abdominis'],
      targetMusclesEn: ['Overall Core', 'Transverse Abdominis'],
      secondaryMusclesId: ['Otot Bahu', 'Punggung Bawah', 'Glutes'],
      secondaryMusclesEn: ['Shoulders', 'Lower Back', 'Glutes'],
      equipment: 'Tanpa Alat',
      difficulty: 'beginner',
      descriptionId:
          'Plank adalah latihan isometris yang melatih seluruh otot core dan stabilitas tubuh.',
      descriptionEn:
          'Plank is an isometric exercise that strengthens the entire core and body stability.',
      instructionsId: [
        '📌 Posisi awal: Siku di bawah bahu, forearms rata di lantai',
        '📌 Tubuh membentuk garis lurus dari kepala hingga tumit',
        '📌 Tahan posisi ini, jaga pinggul tidak naik atau turun',
        '📌 Bernapas secara teratur, jangan menahan napas',
      ],
      instructionsEn: [
        '📌 Starting position: Elbows under shoulders, forearms flat on floor',
        '📌 Body forms straight line from head to heels',
        '📌 Hold position, keep hips from rising or sagging',
        '📌 Breathe regularly, do not hold breath',
      ],
      tipsId: [
        'Jaga leher netral - lihat ke lantai antara siku',
        'Kencangkan otot perut dan glutes',
      ],
      tipsEn: [
        'Keep neck neutral - look at floor between elbows',
        'Tighten abs and glutes for stability',
      ],
      icon: Icons.accessibility_new,
      color: Color(0xFF43A047),
    ),
    Exercise(
      id: 'side_plank',
      nameId: 'Side Plank',
      nameEn: 'Side Plank',
      category: 'core',
      targetMusclesId: ['Otot Obliques', 'Otot Core Samping'],
      targetMusclesEn: ['Obliques', 'Side Core'],
      secondaryMusclesId: ['Otot Bahu', 'Hip Abductors', 'Glutes'],
      secondaryMusclesEn: ['Shoulders', 'Hip Abductors', 'Glutes'],
      equipment: 'Tanpa Alat',
      difficulty: 'intermediate',
      descriptionId:
          'Side plank melatih otot core samping (obliques) dan stabilitas tubuh secara lateral.',
      descriptionEn:
          'Side plank targets side core muscles (obliques) and lateral body stability.',
      instructionsId: [
        '📌 Posisi awal: Berbaring miring, siku bawah di bawah bahu',
        '📌 Angkat pinggul hingga tubuh membentuk garis lurus',
        '📌 Tumpukan kaki satu sama lain (atau tekuk lutut untuk pemula)',
        '📌 Tahan posisi, jaga tubuh tidak turun',
      ],
      instructionsEn: [
        '📌 Starting position: Lying on side, elbow under shoulder',
        '📌 Lift hips until body forms straight line',
        '📌 Stack feet (or bend knees for beginners)',
        '📌 Hold position, keep body from dropping',
      ],
      tipsId: [
        'Untuk pemula, tekuk lutut dan tumpukan lutut',
      ],
      tipsEn: [
        'For beginners, bend knees and stack knees instead of feet',
      ],
      icon: Icons.accessibility_new,
      color: Color(0xFF43A047),
    ),
    Exercise(
      id: 'russian_twist',
      nameId: 'Russian Twist',
      nameEn: 'Russian Twist',
      category: 'core',
      targetMusclesId: ['Otot Obliques', 'Otot Perut Samping'],
      targetMusclesEn: ['Obliques', 'Side Abs'],
      secondaryMusclesId: ['Otot Perut Rectus', 'Hip Flexors'],
      secondaryMusclesEn: ['Rectus Abdominis', 'Hip Flexors'],
      equipment: 'Tanpa Alat (atau Beban)',
      difficulty: 'intermediate',
      descriptionId:
          'Russian twist melatih otot perut samping dengan gerakan memutar tubuh dari posisi duduk.',
      descriptionEn:
          'Russian twist targets side abdominal muscles with a rotating movement from seated position.',
      instructionsId: [
        '📌 Posisi awal: Duduk dengan lutut ditekuk, kaki sedikit diangkat',
        '📌 Condongkan badan sedikit ke belakang (45°)',
        '📌 Putar tubuh ke kanan, sentuh lantai dengan tangan',
        '📌 Putar tubuh ke kiri, sentuh lantai dengan tangan',
      ],
      instructionsEn: [
        '📌 Starting position: Sit with knees bent, feet slightly off floor',
        '📌 Lean body back slightly (45 degree angle)',
        '📌 Rotate torso to right, tap floor with hand',
        '📌 Rotate torso to left, tap floor with hand',
      ],
      tipsId: [
        'Gerakan berasal dari core, bukan lengan',
      ],
      tipsEn: [
        'Movement comes from core, not arms',
      ],
      icon: Icons.accessibility_new,
      color: Color(0xFF43A047),
    ),
    Exercise(
      id: 'bicycle_crunch',
      nameId: 'Bicycle Crunch',
      nameEn: 'Bicycle Crunch',
      category: 'core',
      targetMusclesId: ['Otot Obliques', 'Otot Perut', 'Rectus Abdominis'],
      targetMusclesEn: ['Obliques', 'Abs', 'Rectus Abdominis'],
      secondaryMusclesId: ['Hip Flexors', 'Quadriceps'],
      secondaryMusclesEn: ['Hip Flexors', 'Quadriceps'],
      equipment: 'Tanpa Alat',
      difficulty: 'intermediate',
      descriptionId:
          'Bicycle crunch mengkombinasikan crunch dengan gerakan pedal sepeda.',
      descriptionEn:
          'Bicycle crunch combines crunch with bicycle pedaling motion.',
      instructionsId: [
        '📌 Posisi awal: Berbaring telentang, tangan di belakang kepala',
        '📌 Angkat kaki dengan lutut ditekuk 90°',
        '📌 Dekatkan siku kanan ke lutut kiri dengan memutar tubuh',
        '📌 Lanjutkan bergantian seperti mengayuh sepeda',
      ],
      instructionsEn: [
        '📌 Starting position: Lying on back, hands behind head',
        '📌 Lift legs with knees bent at 90 degrees',
        '📌 Bring right elbow toward left knee by rotating',
        '📌 Continue alternating like pedaling a bicycle',
      ],
      tipsId: [
        'Lakukan gerakan dengan lambat dan terkontrol',
      ],
      tipsEn: [
        'Perform movement slowly and controlled',
      ],
      icon: Icons.accessibility_new,
      color: Color(0xFF43A047),
    ),

    // ==================== LEG EXERCISES ====================
    Exercise(
      id: 'squat',
      nameId: 'Squat',
      nameEn: 'Squat',
      category: 'legs',
      targetMusclesId: ['Otot Quadriceps (Paha Depan)', 'Glutes (Bokong)'],
      targetMusclesEn: ['Quadriceps (Front Thigh)', 'Glutes (Buttocks)'],
      secondaryMusclesId: ['Hamstrings (Paha Belakang)', 'Calf', 'Core'],
      secondaryMusclesEn: ['Hamstrings (Back Thigh)', 'Calves', 'Core'],
      equipment: 'Tanpa Alat',
      difficulty: 'beginner',
      descriptionId:
          'Squat adalah latihan fundamental untuk otot kaki dan bokong.',
      descriptionEn:
          'Squat is a fundamental exercise for leg and buttock muscles.',
      instructionsId: [
        '📌 Posisi awal: Berdiri tegak, kaki selebar bahu',
        '📌 Turunkan tubuh dengan menekuk lutut & mendorong pinggul ke belakang',
        '📌 Turunkan hingga paha sejajar dengan lantai',
        '📌 Dorong melalui tumit untuk kembali berdiri',
      ],
      instructionsEn: [
        '📌 Starting position: Stand upright, feet shoulder-width apart',
        '📌 Lower body by bending knees and pushing hips back',
        '📌 Lower until thighs parallel to floor',
        '📌 Drive through heels to return to standing',
      ],
      tipsId: [
        'Pastikan lutut mengikuti arah jari kaki',
        'Jaga beban di tumit',
      ],
      tipsEn: [
        'Ensure knees follow toe direction',
        'Keep weight on heels, not toes',
      ],
      icon: Icons.directions_walk,
      color: Color(0xFF1E88E5),
    ),
    Exercise(
      id: 'squat_jump',
      nameId: 'Squat Jump',
      nameEn: 'Squat Jump',
      category: 'legs',
      targetMusclesId: ['Otot Quadriceps', 'Glutes', 'Calf'],
      targetMusclesEn: ['Quadriceps', 'Glutes', 'Calves'],
      secondaryMusclesId: ['Hamstrings', 'Core', 'Jantung/Paru'],
      secondaryMusclesEn: ['Hamstrings', 'Core', 'Heart/Lungs'],
      equipment: 'Tanpa Alat',
      difficulty: 'advanced',
      descriptionId:
          'Squat jump adalah versi eksplosif dari squat dengan lompatan saat naik.',
      descriptionEn:
          'Squat jump is an explosive version of squat with a jump at the top.',
      instructionsId: [
        '📌 Posisi awal: Berdiri tegak, kaki selebar bahu',
        '📌 Turunkan ke posisi squat',
        '📌 Dorong tubuh ke atas dengan kuat, lompat tinggi',
        '📌 Mendarat dengan lembut di ujung kaki',
      ],
      instructionsEn: [
        '📌 Starting position: Stand upright, feet shoulder-width apart',
        '📌 Lower into squat position',
        '📌 Drive body upward with force, jump high',
        '📌 Land softly on toes',
      ],
      tipsId: [
        'Darat dengan lembut untuk melindungi lutut',
      ],
      tipsEn: [
        'Land softly to protect knees',
      ],
      icon: Icons.directions_walk,
      color: Color(0xFF1E88E5),
    ),
    Exercise(
      id: 'lunge',
      nameId: 'Lunge',
      nameEn: 'Lunge',
      category: 'legs',
      targetMusclesId: ['Otot Quadriceps', 'Glutes', 'Hamstrings'],
      targetMusclesEn: ['Quadriceps', 'Glutes', 'Hamstrings'],
      secondaryMusclesId: ['Calf', 'Core', 'Hip Flexors'],
      secondaryMusclesEn: ['Calves', 'Core', 'Hip Flexors'],
      equipment: 'Tanpa Alat',
      difficulty: 'beginner',
      descriptionId:
          'Lunge melatih keseimbangan dan kekuatan kaki dengan langkah lebar ke depan.',
      descriptionEn:
          'Lunge trains balance and leg strength with a wide step forward.',
      instructionsId: [
        '📌 Posisi awal: Berdiri tegak, kaki rapat',
        '📌 Langkah lebar ke depan dengan kaki kanan',
        '📌 Turunkan tubuh hingga lutut kanan 90°',
        '📌 Dorong kembali ke posisi awal, ganti kaki',
      ],
      instructionsEn: [
        '📌 Starting position: Stand upright, feet together',
        '📌 Step wide forward with right foot',
        '📌 Lower body until right knee is 90 degrees',
        '📌 Push back to starting position, switch legs',
      ],
      tipsId: [
        'Jaga tubuh tegak, jangan condong ke depan',
      ],
      tipsEn: [
        'Keep body upright, do not lean forward',
      ],
      icon: Icons.directions_walk,
      color: Color(0xFF1E88E5),
    ),
    Exercise(
      id: 'wall_sit',
      nameId: 'Wall Sit',
      nameEn: 'Wall Sit',
      category: 'legs',
      targetMusclesId: ['Otot Quadriceps', 'Glutes'],
      targetMusclesEn: ['Quadriceps', 'Glutes'],
      secondaryMusclesId: ['Hamstrings', 'Calf', 'Core'],
      secondaryMusclesEn: ['Hamstrings', 'Calves', 'Core'],
      equipment: 'Dinding',
      difficulty: 'beginner',
      descriptionId:
          'Wall sit adalah latihan isometris untuk otot kaki dengan posisi seperti duduk di dinding.',
      descriptionEn:
          'Wall sit is an isometric exercise for leg muscles in a seated-against-wall position.',
      instructionsId: [
        '📌 Posisi awal: Berdiri menghadap dinding',
        '📌 Dudukkan tubuh ke dinding dengan lutut 90°',
        '📌 Punggung dan bahu rata di dinding',
        '📌 Tahan posisi ini',
      ],
      instructionsEn: [
        '📌 Starting position: Face wall standing',
        '📌 Slide down wall bending knees to 90 degrees',
        '📌 Back and shoulders flat against wall',
        '📌 Hold this position',
      ],
      tipsId: [
        'Pastikan lutut 90°, tidak lebih atau kurang',
      ],
      tipsEn: [
        'Ensure knees at 90 degrees',
      ],
      icon: Icons.directions_walk,
      color: Color(0xFF1E88E5),
    ),
    Exercise(
      id: 'calf_raise',
      nameId: 'Calf Raise',
      nameEn: 'Calf Raise',
      category: 'legs',
      targetMusclesId: ['Gastrocnemius (Calf Utama)', 'Soleus (Calf Bawah)'],
      targetMusclesEn: ['Gastrocnemius (Main Calf)', 'Soleus (Lower Calf)'],
      secondaryMusclesId: ['Ankle Stabilizers'],
      secondaryMusclesEn: ['Ankle Stabilizers'],
      equipment: 'Tanpa Alat (atau Tangga)',
      difficulty: 'beginner',
      descriptionId:
          'Calf raise melatih otot betis dengan gerakan naik turun di ujung kaki.',
      descriptionEn:
          'Calf raise strengthens calf muscles with up-down movement on toes.',
      instructionsId: [
        '📌 Posisi awal: Berdiri tegak, kaki rapat',
        '📌 Naik ke ujung kaki setinggi mungkin',
        '📌 Tahan di posisi atas sebentar',
        '📌 Turunkan tumit perlahan ke lantai',
      ],
      instructionsEn: [
        '📌 Starting position: Stand upright, feet together',
        '📌 Rise up on toes as high as possible',
        '📌 Hold at top briefly',
        '📌 Lower heels slowly back to floor',
      ],
      tipsId: [
        'Gerakan lambat dan terkontrol lebih efektif',
      ],
      tipsEn: [
        'Slow, controlled movement is more effective',
      ],
      icon: Icons.directions_walk,
      color: Color(0xFF1E88E5),
    ),
    Exercise(
      id: 'glute_bridge',
      nameId: 'Glute Bridge',
      nameEn: 'Glute Bridge',
      category: 'legs',
      targetMusclesId: ['Glutes (Bokong)', 'Hamstrings'],
      targetMusclesEn: ['Glutes (Buttocks)', 'Hamstrings'],
      secondaryMusclesId: ['Core', 'Lower Back', 'Quadriceps'],
      secondaryMusclesEn: ['Core', 'Lower Back', 'Quadriceps'],
      equipment: 'Tanpa Alat',
      difficulty: 'beginner',
      descriptionId:
          'Glute bridge melatih otot bokong dan hamstring dengan gerakan mengangkat pinggul.',
      descriptionEn:
          'Glute bridge targets glutes and hamstrings by lifting hips.',
      instructionsId: [
        '📌 Posisi awal: Berbaring telentang, lutut ditekuk, kaki rata di lantai',
        '📌 Angkat pinggul hingga tubuh membentuk garis lurus',
        '📌 Kencangkan glutes di posisi atas',
        '📌 Turunkan pinggul dengan kontrol',
      ],
      instructionsEn: [
        '📌 Starting position: Lying on back, knees bent, feet flat on floor',
        '📌 Lift hips until body forms straight line',
        '📌 Squeeze glutes at top position',
        '📌 Lower hips with control',
      ],
      tipsId: [
        'Jangan dorong pinggul terlalu tinggi (bahaya hyperextension)',
      ],
      tipsEn: [
        'Do not push hips too high (hyperextension risk)',
      ],
      icon: Icons.directions_walk,
      color: Color(0xFF1E88E5),
    ),

    // ==================== CARDIO EXERCISES ====================
    Exercise(
      id: 'jumping_jack',
      nameId: 'Jumping Jack',
      nameEn: 'Jumping Jack',
      category: 'cardio',
      targetMusclesId: ['Jantung/Paru', 'Seluruh Tubuh (Cardio)'],
      targetMusclesEn: ['Heart/Lungs', 'Full Body (Cardio)'],
      secondaryMusclesId: ['Calf', 'Shoulders', 'Core'],
      secondaryMusclesEn: ['Calves', 'Shoulders', 'Core'],
      equipment: 'Tanpa Alat',
      difficulty: 'beginner',
      descriptionId:
          'Jumping jack adalah latihan kardio sederhana dengan gerakan melompat dan membuka tutup kaki.',
      descriptionEn:
          'Jumping jack is a simple cardio exercise with jumping and feet opening/closing.',
      instructionsId: [
        '📌 Posisi awal: Berdiri tegak, kaki rapat, lengan di samping tubuh',
        '📌 Lompat dan buka kaki lebar, angkat tangan ke atas kepala',
        '📌 Tubuh membentuk bintang (star position)',
        '📌 Lompat kembali, kaki rapat, lengan turun',
      ],
      instructionsEn: [
        '📌 Starting position: Stand upright, feet together, arms at sides',
        '📌 Jump and spread legs wide, raise arms overhead',
        '📌 Body forms star position',
        '📌 Jump back, feet together, arms down',
      ],
      tipsId: [
        'Gunakan alas kaki yang tepat untuk menyerap impact',
      ],
      tipsEn: [
        'Use proper footwear to absorb impact',
      ],
      icon: Icons.directions_run,
      color: Color(0xFFFF9800),
    ),
    Exercise(
      id: 'high_knees',
      nameId: 'High Knees',
      nameEn: 'High Knees',
      category: 'cardio',
      targetMusclesId: ['Hip Flexors', 'Quadriceps', 'Cardio System'],
      targetMusclesEn: ['Hip Flexors', 'Quadriceps', 'Cardio System'],
      secondaryMusclesId: ['Calf', 'Core', 'Glutes'],
      secondaryMusclesEn: ['Calves', 'Core', 'Glutes'],
      equipment: 'Tanpa Alat',
      difficulty: 'intermediate',
      descriptionId:
          'High knees adalah latihan kardio intens dengan mengangkat lutut setinggi mungkin.',
      descriptionEn:
          'High knees is an intense cardio exercise lifting knees as high as possible.',
      instructionsId: [
        '📌 Posisi awal: Berdiri tegak, kaki rapat',
        '📌 Angkat lutut kanan setinggi mungkin ke dada',
        '📌 Turunkan kaki kanan, angkat lutut kiri',
        '📌 Lanjutkan bergantian dengan cepat',
      ],
      instructionsEn: [
        '📌 Starting position: Stand upright, feet together',
        '📌 Lift right knee as high as possible to chest',
        '📌 Lower right foot, lift left knee',
        '📌 Continue alternating rapidly',
      ],
      tipsId: [
        'Jaga torso tegak, jangan condong ke depan',
      ],
      tipsEn: [
        'Keep torso upright, do not lean forward',
      ],
      icon: Icons.directions_run,
      color: Color(0xFFFF9800),
    ),
    Exercise(
      id: 'mountain_climber',
      nameId: 'Mountain Climber',
      nameEn: 'Mountain Climber',
      category: 'cardio',
      targetMusclesId: ['Core', 'Shoulders', 'Cardio System'],
      targetMusclesEn: ['Core', 'Shoulders', 'Cardio System'],
      secondaryMusclesId: ['Chest', 'Triceps', 'Hip Flexors', 'Quadriceps'],
      secondaryMusclesEn: ['Chest', 'Triceps', 'Hip Flexors', 'Quadriceps'],
      equipment: 'Tanpa Alat',
      difficulty: 'intermediate',
      descriptionId:
          'Mountain climber adalah latihan kardio dinamis dengan posisi plank dan gerakan kaki seperti berlari.',
      descriptionEn:
          'Mountain climber is a dynamic cardio exercise in plank position with running leg movements.',
      instructionsId: [
        '📌 Posisi awal: Push up/plank tinggi, tangan di bawah bahu',
        '📌 Tarik kaki kanan dekat ke tangan kanan',
        '📌 Kembalikan kaki ke posisi plank',
        '📌 Tarik kaki kiri dekat ke tangan kiri',
      ],
      instructionsEn: [
        '📌 Starting position: High push up/plank, hands under shoulders',
        '📌 Bring right foot close to right hand',
        '📌 Return foot to plank position',
        '📌 Bring left foot close to left hand',
      ],
      tipsId: [
        'Jaga pinggul tidak naik tinggi saat kaki bergerak',
      ],
      tipsEn: [
        'Keep hips from rising too high when legs move',
      ],
      icon: Icons.directions_run,
      color: Color(0xFFFF9800),
    ),
    Exercise(
      id: 'burpee',
      nameId: 'Burpee',
      nameEn: 'Burpee',
      category: 'cardio',
      targetMusclesId: ['Seluruh Tubuh', 'Cardio System'],
      targetMusclesEn: ['Full Body', 'Cardio System'],
      secondaryMusclesId: ['Chest', 'Shoulders', 'Triceps', 'Core', 'Legs'],
      secondaryMusclesEn: ['Chest', 'Shoulders', 'Triceps', 'Core', 'Legs'],
      equipment: 'Tanpa Alat',
      difficulty: 'advanced',
      descriptionId:
          'Burpee adalah latihan seluruh tubuh yang sangat intens.',
      descriptionEn:
          'Burpee is a highly intense full body exercise.',
      instructionsId: [
        '📌 Posisi awal: Berdiri tegak',
        '📌 Drop ke squat, letakkan tangan di lantai',
        '📌 Jump kaki ke belakang ke posisi plank',
        '📌 (Opsional) Push up',
        '📌 Jump kaki ke depan, lalu lompat tinggi',
      ],
      instructionsEn: [
        '📌 Starting position: Stand upright',
        '📌 Drop to squat, place hands on floor',
        '📌 Jump feet back to plank position',
        '📌 (Optional) Push up',
        '📌 Jump feet forward, then jump high',
      ],
      tipsId: [
        'Latihan kardio TERBERAT - mulai dengan versi tanpa push up dan jump',
      ],
      tipsEn: [
        'HARDEST cardio exercise - start with version without push up and jump',
      ],
      icon: Icons.directions_run,
      color: Color(0xFFFF9800),
    ),

    // ==================== BACK EXERCISES ====================
    Exercise(
      id: 'superman',
      nameId: 'Superman',
      nameEn: 'Superman',
      category: 'back',
      targetMusclesId: ['Otot Punggung Bawah (Erector Spinae)', 'Glutes'],
      targetMusclesEn: ['Lower Back (Erector Spinae)', 'Glutes'],
      secondaryMusclesId: ['Hamstrings', 'Shoulders', 'Core'],
      secondaryMusclesEn: ['Hamstrings', 'Shoulders', 'Core'],
      equipment: 'Tanpa Alat',
      difficulty: 'beginner',
      descriptionId:
          'Superman melatih otot punggung bawah dan glutes dengan posisi tengkurap dan mengangkat tubuh.',
      descriptionEn:
          'Superman targets lower back and glutes with prone position and body lifting.',
      instructionsId: [
        '📌 Posisi awal: Berbaring tengkurap, lengan di depan kepala',
        '📌 Kaki lurus dan rapat',
        '📌 Angkat tangan, kaki, dan dada dari lantai bersamaan',
        '📌 Tahan di posisi atas, kencangkan otot punggung bawah',
      ],
      instructionsEn: [
        '📌 Starting position: Lying face down, arms extended in front',
        '📌 Keep legs straight and together',
        '📌 Lift arms, legs, and chest off floor simultaneously',
        '📌 Hold at top, squeeze lower back muscles',
      ],
      tipsId: [
        'Latihan yang bagus untuk counter duduk terlalu lama',
      ],
      tipsEn: [
        'Great exercise to counter sitting too long',
      ],
      icon: Icons.airline_seat_flat,
      color: Color(0xFF8E24AA),
    ),

    // ==================== ARMS EXERCISES ====================
    Exercise(
      id: 'tricep_dip',
      nameId: 'Tricep Dip',
      nameEn: 'Tricep Dip',
      category: 'arms',
      targetMusclesId: ['Otot Trisep (Triceps)', 'Pectoralis Minor'],
      targetMusclesEn: ['Triceps', 'Pectoralis Minor'],
      secondaryMusclesId: ['Deltoids', 'Core'],
      secondaryMusclesEn: ['Deltoids', 'Core'],
      equipment: 'Kursi/Bangku',
      difficulty: 'intermediate',
      descriptionId:
          'Tricep dip melatih otot trisep dengan menggunakan kursi atau bangku sebagai tumpuan.',
      descriptionEn:
          'Tricep dip targets triceps using a chair or bench as support.',
      instructionsId: [
        '📌 Posisi awal: Duduk di tepi kursi, tangan pegang kursi di samping tubuh',
        '📌 Angkat tubuh dari kursi, geser ke depan',
        '📌 Turunkan tubuh dengan menekuk siku 90°',
        '📌 Dorong tubuh kembali ke atas',
      ],
      instructionsEn: [
        '📌 Starting position: Sit on edge of chair, hands gripping seat at sides',
        '📌 Lift body off chair, slide forward',
        '📌 Lower body by bending elbows to 90 degrees',
        '📌 Push body back up',
      ],
      tipsId: [
        'Jaga siku mengarah ke belakang, bukan ke samping',
      ],
      tipsEn: [
        'Keep elbows pointing backward, not outward',
      ],
      icon: Icons.fitness_center,
      color: Color(0xFF00ACC1),
    ),

    // ==================== GYM EXERCISES (WITH EQUIPMENT) ====================
    Exercise(
      id: 'bench_press',
      nameId: 'Bench Press',
      nameEn: 'Bench Press',
      category: 'gym',
      targetMusclesId: ['Otot Dada (Pectoralis)', 'Otot Trisep', 'Otot Bahu'],
      targetMusclesEn: ['Chest (Pectoralis)', 'Triceps', 'Shoulders'],
      secondaryMusclesId: ['Core'],
      secondaryMusclesEn: ['Core'],
      equipment: 'Barbell + Bench',
      difficulty: 'intermediate',
      requiresGymEquipment: true,
      descriptionId:
          'Bench press adalah latihan chest fundamental dengan barbell di bangku datar.',
      descriptionEn:
          'Bench press is a fundamental chest exercise with barbell on flat bench.',
      instructionsId: [
        '📌 Posisi awal: Berbaring di bangku, pegang barbell selebar bahu',
        '📌 Turunkan barbell ke dada bagian tengah',
        '📌 Dorong barbell ke atas hingga lengan lurus',
        '📌 Jaga siku sedikit fleksi,不要 kunci完全',
      ],
      instructionsEn: [
        '📌 Starting position: Lying on bench, grip barbell shoulder-width',
        '📌 Lower barbell to mid-chest',
        '📌 Push barbell up until arms are straight',
        '📌 Keep elbows slightly bent, do not lock out',
      ],
      tipsId: [
        'Jaga punggung bawah sedikit melengkung di bangku',
      ],
      tipsEn: [
        'Keep lower back slightly arched on the bench',
      ],
      icon: Icons.fitness_center,
      color: Color(0xFFE53935),
    ),
    Exercise(
      id: 'deadlift',
      nameId: 'Deadlift',
      nameEn: 'Deadlift',
      category: 'gym',
      targetMusclesId: ['Otot Punggung', 'Glutes', 'Hamstrings'],
      targetMusclesEn: ['Back', 'Glutes', 'Hamstrings'],
      secondaryMusclesId: ['Core', 'Quadriceps', 'Forearms'],
      secondaryMusclesEn: ['Core', 'Quadriceps', 'Forearms'],
      equipment: 'Barbell',
      difficulty: 'advanced',
      requiresGymEquipment: true,
      descriptionId:
          'Deadlift adalah latihan compound untuk punggung bawah, glutes, dan hamstrings.',
      descriptionEn:
          'Deadlift is a compound exercise for lower back, glutes, and hamstrings.',
      instructionsId: [
        '📌 Posisi awal: Berdiri dengan kaki selebar bahu di depan barbell',
        '📌 Tekuk lutut dan pinggul, pegang barbell dengan agarre yang kokoh',
        '📌 Angkat barbell dengan mendorong pinggul ke depan',
        '📌 Berdiri tegak dengan barbell di depan paha',
      ],
      instructionsEn: [
        '📌 Starting position: Stand with feet shoulder-width over barbell',
        '📌 Bend knees and hips, grip barbell with firm grip',
        '📌 Lift barbell by pushing hips forward',
        '📌 Stand upright with barbell in front of thighs',
      ],
      tipsId: [
        'Jaga punggung tetap netral sepanjang gerakan',
      ],
      tipsEn: [
        'Keep back neutral throughout the movement',
      ],
      icon: Icons.fitness_center,
      color: Color(0xFF8E24AA),
    ),
    Exercise(
      id: 'lat_pulldown',
      nameId: 'Lat Pulldown',
      nameEn: 'Lat Pulldown',
      category: 'gym',
      targetMusclesId: ['Otot Punggung (Latissimus Dorsi)', 'Biceps'],
      targetMusclesEn: ['Back (Latissimus Dorsi)', 'Biceps'],
      secondaryMusclesId: ['Shoulders', 'Core'],
      secondaryMusclesEn: ['Shoulders', 'Core'],
      equipment: 'Cable Machine',
      difficulty: 'beginner',
      requiresGymEquipment: true,
      descriptionId:
          'Lat pulldown melatih otot punggung bagian atas dengan menarik cable ke dada.',
      descriptionEn:
          'Lat pulldown targets upper back muscles by pulling cable to chest.',
      instructionsId: [
        '📌 Posisi awal: Duduk, pegang bar dengan agarre lebar',
        '📌 Kencangkan otot perut, condongkan badan sedikit ke belakang',
        '📌 Tarik bar ke bawah ke arah dada atas',
        '📌 Perlahan naikkan kembali ke posisi awal',
      ],
      instructionsEn: [
        '📌 Starting position: Seated, grip bar with wide grip',
        '📌 Tighten abs, lean torso slightly back',
        '📌 Pull bar down toward upper chest',
        '📌 Slowly return to starting position',
      ],
      tipsId: [
        'Fokus untuk merasakan otot punggung bekerja',
      ],
      tipsEn: [
        'Focus on feeling the back muscles working',
      ],
      icon: Icons.fitness_center,
      color: Color(0xFF8E24AA),
    ),
    Exercise(
      id: 'leg_press',
      nameId: 'Leg Press',
      nameEn: 'Leg Press',
      category: 'gym',
      targetMusclesId: ['Otot Quadriceps', 'Glutes', 'Hamstrings'],
      targetMusclesEn: ['Quadriceps', 'Glutes', 'Hamstrings'],
      secondaryMusclesId: ['Calf'],
      secondaryMusclesEn: ['Calves'],
      equipment: 'Leg Press Machine',
      difficulty: 'beginner',
      requiresGymEquipment: true,
      descriptionId:
          'Leg press melatih otot kaki dengan mendorong platform dengan kaki.',
      descriptionEn:
          'Leg press targets leg muscles by pushing platform with legs.',
      instructionsId: [
        '📌 Posisi awal: Duduk di mesin, punggung rata di sandaran',
        '📌 Kaki di platform selebar bahu',
        '📌 Dorong platform dengan meluruskan kaki',
        '📌 Turunkan dengan kontrol hingga lutut 90°',
      ],
      instructionsEn: [
        '📌 Starting position: Seated on machine, back flat against pad',
        '📌 Feet on platform shoulder-width apart',
        '📌 Push platform by straightening legs',
        '📌 Lower with control until knees at 90 degrees',
      ],
      tipsId: [
        'Jangan kunci lutut sepenuhnya di posisi atas',
      ],
      tipsEn: [
        'Do not lock knees fully at top position',
      ],
      icon: Icons.fitness_center,
      color: Color(0xFF1E88E5),
    ),
    Exercise(
      id: 'bicep_curl',
      nameId: 'Bicep Curl',
      nameEn: 'Bicep Curl',
      category: 'gym',
      targetMusclesId: ['Otot Bisep (Biceps)'],
      targetMusclesEn: ['Biceps'],
      secondaryMusclesId: ['Forearms'],
      secondaryMusclesEn: ['Forearms'],
      equipment: 'Barbell/Dumbbell',
      difficulty: 'beginner',
      requiresGymEquipment: true,
      descriptionId:
          'Bicep curl melatih otot bisep dengan mengangkat beban ke arah bahu.',
      descriptionEn:
          'Bicep curl targets biceps by lifting weight toward shoulder.',
      instructionsId: [
        '📌 Posisi awal: Berdiri tegak, pegang barbell dengan agarre supinasi',
        '📌 Siku di samping tubuh',
        '📌 Angkat barbell ke arah bahu dengan menekuk siku',
        '📌 Turunkan dengan kontrol ke posisi awal',
      ],
      instructionsEn: [
        '📌 Starting position: Stand upright, grip barbell with supinated grip',
        '📌 Elbows at sides of body',
        '📌 Lift barbell toward shoulder by bending elbows',
        '📌 Lower with control to starting position',
      ],
      tipsId: [
        'Jangan ayunkan badan untuk membantu mengangkat',
      ],
      tipsEn: [
        'Do not swing body to help lift',
      ],
      icon: Icons.fitness_center,
      color: Color(0xFF00ACC1),
    ),
    Exercise(
      id: 'overhead_press',
      nameId: 'Overhead Press',
      nameEn: 'Overhead Press',
      category: 'gym',
      targetMusclesId: ['Otot Bahu (Deltoids)', 'Triceps'],
      targetMusclesEn: ['Shoulders (Deltoids)', 'Triceps'],
      secondaryMusclesId: ['Core', 'Upper Chest'],
      secondaryMusclesEn: ['Core', 'Upper Chest'],
      equipment: 'Barbell',
      difficulty: 'intermediate',
      requiresGymEquipment: true,
      descriptionId:
          'Overhead press melatih otot bahu dengan mendorong barbell ke atas kepala.',
      descriptionEn:
          'Overhead press targets shoulder muscles by pushing barbell overhead.',
      instructionsId: [
        '📌 Posisi awal: Berdiri tegak, barbell di depan bahu',
        '📌 Kaki selebar bahu',
        '📌 Dorong barbell ke atas hingga lengan lurus di atas kepala',
        '📌 Turunkan dengan kontrol ke posisi bahu',
      ],
      instructionsEn: [
        '📌 Starting position: Stand upright, barbell in front of shoulders',
        '📌 Feet shoulder-width apart',
        '📌 Push barbell up until arms straight overhead',
        '📌 Lower with control back to shoulder position',
      ],
      tipsId: [
        'Jaga otot perut kencang untuk stabilitas',
      ],
      tipsEn: [
        'Keep abs tight for stability',
      ],
      icon: Icons.fitness_center,
      color: Color(0xFFFF9800),
    ),

    // ==================== FULL BODY EXERCISES ====================
    Exercise(
      id: 'flutter_kick',
      nameId: 'Flutter Kick',
      nameEn: 'Flutter Kick',
      category: 'core',
      targetMusclesId: ['Otot Perut Bawah', 'Hip Flexors'],
      targetMusclesEn: ['Lower Abs', 'Hip Flexors'],
      secondaryMusclesId: ['Core', 'Glutes', 'Lower Back'],
      secondaryMusclesEn: ['Core', 'Glutes', 'Lower Back'],
      equipment: 'Tanpa Alat',
      difficulty: 'intermediate',
      descriptionId:
          'Flutter kick melatih otot perut bawah dengan gerakan menendang kaki bergantian.',
      descriptionEn:
          'Flutter kick targets lower abs with alternating leg kicks.',
      instructionsId: [
        '📌 Posisi awal: Berbaring telentang, tangan di bawah bokong',
        '📌 Angkat kedua kaki sedikit dari lantai (±15 cm)',
        '📌 Naik-turunkan kaki kanan dan kiri bergantian',
        '📌 Gerakan cepat dan terkontrol',
      ],
      instructionsEn: [
        '📌 Starting position: Lying on back, hands under buttocks',
        '📌 Lift both legs slightly off floor (±15 cm)',
        '📌 Alternate raising and lowering right and left legs',
        '📌 Movement should be quick and controlled',
      ],
      tipsId: [
        'Jaga punggung bawah tetap rata di lantai',
      ],
      tipsEn: [
        'Keep lower back flat on floor',
      ],
      icon: Icons.waves,
      color: Color(0xFF00897B),
    ),
    Exercise(
      id: 'v_up',
      nameId: 'V-Up',
      nameEn: 'V-Up',
      category: 'core',
      targetMusclesId: ['Rectus Abdominis', 'Hip Flexors'],
      targetMusclesEn: ['Rectus Abdominis', 'Hip Flexors'],
      secondaryMusclesId: ['Core', 'Shoulders'],
      secondaryMusclesEn: ['Core', 'Shoulders'],
      equipment: 'Tanpa Alat',
      difficulty: 'advanced',
      descriptionId:
          'V-up adalah latihan intensif yang melatih seluruh otot perut dengan gerakan membentuk huruf V.',
      descriptionEn:
          'V-up is an intensive exercise targeting entire abdominal muscles with V-shaped movement.',
      instructionsId: [
        '📌 Posisi awal: Berbaring telentang, kaki lurus, tangan di atas kepala',
        '📌 Angkat kaki dan tubuh bersamaan',
        '📌 Gerakan harus membentuk huruf V dengan tangan menyentuh kaki',
        '📌 Tahan di posisi atas sebentar',
      ],
      instructionsEn: [
        '📌 Starting position: Lying on back, legs straight, arms overhead',
        '📌 Lift legs and body simultaneously',
        '📌 Movement should form V-shape with hands touching feet',
        '📌 Hold at top briefly',
      ],
      tipsId: [
        'Latihan tingkat lanjut - mulailah dengan crunch standar',
      ],
      tipsEn: [
        'Advanced exercise - start with standard crunches',
      ],
      icon: Icons.accessibility_new,
      color: Color(0xFF43A047),
    ),
  ];

  static List<Exercise> getExercisesByCategory(String category) {
    if (category == 'all') return exercises;
    if (category == 'no_equipment') {
      return exercises.where((e) => !e.requiresGymEquipment).toList();
    }
    if (category == 'gym') {
      return exercises.where((e) => e.requiresGymEquipment).toList();
    }
    return exercises.where((exercise) => exercise.category == category).toList();
  }

  static Exercise? getExerciseById(String id) {
    try {
      return exercises.firstWhere((exercise) => exercise.id == id);
    } catch (e) {
      return null;
    }
  }

  static List<Exercise> getExercisesByDifficulty(String difficulty) {
    return exercises.where((exercise) => exercise.difficulty == difficulty).toList();
  }

  static List<Exercise> getRandomExercises(int count) {
    final shuffled = List<Exercise>.from(exercises)..shuffle();
    return shuffled.take(count).toList();
  }

  static String getCategoryName(String category, String langCode) {
    final categoryMap = {
      'chest': {'id': 'Dada', 'en': 'Chest'},
      'back': {'id': 'Punggung', 'en': 'Back'},
      'shoulders': {'id': 'Bahu', 'en': 'Shoulders'},
      'arms': {'id': 'Lengan', 'en': 'Arms'},
      'legs': {'id': 'Kaki', 'en': 'Legs'},
      'core': {'id': 'Perut/Core', 'en': 'Core/Abs'},
      'cardio': {'id': 'Kardio', 'en': 'Cardio'},
      'full_body': {'id': 'Seluruh Tubuh', 'en': 'Full Body'},
      'gym': {'id': 'Alat Gym', 'en': 'Gym Equipment'},
      'no_equipment': {'id': 'Tanpa Alat', 'en': 'No Equipment'},
    };
    return categoryMap[category]?[langCode] ?? category;
  }

  static IconData getCategoryIcon(String category) {
    final iconMap = {
      'chest': Icons.fitness_center,
      'back': Icons.airline_seat_flat,
      'shoulders': Icons.accessibility_new,
      'arms': Icons.fitness_center,
      'legs': Icons.directions_walk,
      'core': Icons.accessibility_new,
      'cardio': Icons.directions_run,
      'full_body': Icons.sports_martial_arts,
      'gym': Icons.fitness_center,
      'no_equipment': Icons.accessibility_new,
    };
    return iconMap[category] ?? Icons.fitness_center;
  }

  static Color getCategoryColor(String category) {
    final colorMap = {
      'chest': Color(0xFFE53935),
      'back': Color(0xFF8E24AA),
      'shoulders': Color(0xFFFF9800),
      'arms': Color(0xFF00ACC1),
      'legs': Color(0xFF1E88E5),
      'core': Color(0xFF43A047),
      'cardio': Color(0xFFFF9800),
      'full_body': Color(0xFF00897B),
      'gym': Color(0xFF9C27B0),
      'no_equipment': Color(0xFF10B981),
    };
    return colorMap[category] ?? Color(0xFF10B981);
  }
}
