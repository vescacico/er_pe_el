import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService {
  static const String _languageKey = 'selected_language';

  static final Map<String, Map<String, String>> _translations = {
    'id': {
      // General
      'app_name': 'FitTask',
      'loading': 'Memuat...',
      'save': 'Simpan',
      'cancel': 'Batal',
      'confirm': 'Konfirmasi',
      'done': 'Selesai',
      'error': 'Error',
      'success': 'Berhasil',

      // Login/Signup
      'system_login': 'SYSTEM LOGIN',
      'hunter_registration': 'DAFTAR HUNTER',
      'welcome_back': 'Selamat datang kembali, Hunter. Masukkan kredensial Anda.',
      'initialize_profile': 'Inisialisasi profil Anda untuk bergabung.',
      'hunter_name': 'Nama Hunter',
      'email_address': 'Alamat Email',
      'password': 'Password',
      'forgot_password': 'Lupa Password?',
      'access_system': 'MASUK SISTEM',
      'initialize_system': 'INITIALISASI SISTEM',
      'dont_have_account': 'Tidak punya akun? ',
      'already_hunter': 'Sudah Hunter? ',
      'sign_up': 'Daftar',
      'log_in': 'Masuk',
      'or_connect_with': 'ATAU SAMBUNGKAN DENGAN',
      'google': 'Google',

      // Home
      'daily_quests': 'Quest Harian',
      'main_quest': 'Main Quest',
      'weekly_quest': 'Quest Mingguan',
      'streak': 'Streak',
      'total_exp': 'Total EXP',
      'level': 'Level',
      'rank': 'Rank',

      // Quest Types
      'walking_quest': 'Quest Jalan Kaki',
      'walking_quest_desc': 'Selesaikan target langkah kaki harian',
      'target_steps': 'Target: {steps} langkah',
      'current_steps': 'Langkah Saat Ini',
      'claim_exp': 'KLAIM EXP',
      'not_completed': 'BELUM SELESAI',
      'complete_target_to_claim': 'Selesaikan target untuk mengklaim EXP',
      'quest_completed': 'Quest Selesai!',
      'quest_already_done': 'Quest sudah selesai!',
      'you_completed_quest': 'Anda sudah menyelesaikan quest ini.',
      'exp_claimed': 'EXP berhasil diklaim!',

      // Plank Quest
      'plank_quest': 'Quest Plank',
      'start': 'MULAI',
      'quest_clear': 'QUEST SELESAI!',
      'quest_failed': 'QUEST GAGAL',
      'you_survived': 'Kamu berhasil bertahan!',
      'failed_focus': 'Gagal fokus!',

      // Profile
      'hunter_profile': 'Profil Hunter',
      'hunter_statistics': 'Statistik Hunter',
      'settings': 'Pengaturan',
      'language': 'Bahasa',
      'select_language': 'Pilih Bahasa',
      'ai_rest_mode': 'AI Rest Mode',
      'rest_mode_desc': 'Bekukan penalti saat cedera/sakit',
      'logout': 'Keluar',
      'delete_account': 'Hapus Akun',
      'rest_mode_activated': 'Rest Mode diaktifkan',
      'rest_mode_deactivated': 'Rest Mode dinonaktifkan',
      'logout_confirm': 'Keluar dari akun?',
      'delete_account_confirm': 'Hapus Akun?',
      'delete_account_warning': 'Semua data Anda akan dihapus permanen. Yakin?',
      'account_deleted': 'Akun berhasil dihapus',

      // Exercise Quests
      'exercise_quests': 'Quest Latihan',
      'view_details': 'Lihat Detail',
      'start_exercise': 'Mulai Latihan',
      'sets': 'Set',
      'reps': 'Repetisi',
      'duration': 'Durasi',
      'seconds': 'detik',
      'minutes': 'menit',
      'target_muscles': 'Otot Target',
      'secondary_muscles': 'Otot Sekunder',
      'equipment': 'Alat',
      'difficulty': 'Kesulitan',
      'easy': 'Mudah',
      'medium': 'Sedang',
      'hard': 'Sulit',
      'beginner': 'Pemula',
      'intermediate': 'Menengah',
      'advanced': 'Lanjutan',
      'instructions': 'Instruksi',
      'starting_position': 'Posisi Awal',
      'ending_position': 'Posisi Akhir',
      'tips': 'Tips',
      'repetitions': ' repetisi',
      'sets_count': ' set',
      'rest_between_sets': 'Istirahat antar set',
      'complete_all_sets': 'Selesaikan semua set untuk menyelesaikan quest!',
      'exercise_in_progress': 'Latihan Sedang Berlangsung',
      'set_completed': 'Set {current}/{total} selesai!',
      'all_sets_completed': 'Semua set selesai! Quest selesai!',
      'hold_position': 'Tahan posisi ini',
      'countdown': 'Hitung mundur',
      'great_job': 'Kerja bagus!',

      // Quest Categories
      'category_chest': 'Dada',
      'category_back': 'Punggung',
      'category_shoulders': 'Bahu',
      'category_arms': 'Lengan',
      'category_legs': 'Kaki',
      'category_core': 'Perut/Core',
      'category_cardio': 'Kardio',
      'category_full_body': 'Seluruh Tubuh',

      // Hydration
      'hydration_quest': 'Quest Hidrasi',
      'drink_water': 'Minum Air',
      'target_water': 'Target: {ml} ml',
      'glasses': 'gelas',
      'stay_hydrated': 'Tetap terhidrasi!',

      // Exercise Names
      'exercise_sit_up': 'Sit Up',
      'exercise_push_up': 'Push Up',
      'exercise_squat': 'Squat',
      'exercise_plank': 'Plank',
      'exercise_lunge': 'Lunge',
      'exercise_jumping_jack': 'Jumping Jack',
      'exercise_mountain_climber': 'Mountain Climber',
      'exercise_burpee': 'Burpee',
      'exercise_crunch': 'Crunch',
      'exercise_leg_raise': 'Leg Raise',
      'exercise_wall_sit': 'Wall Sit',
      'exercise_diamond_push_up': 'Push Up Diamond',
      'exercise_wide_push_up': 'Push Up Lebar',
      'exercise_incline_push_up': 'Push Up Incline',
      'exercise_decline_push_up': 'Push Up Decline',
      'exercise_squat_jump': 'Squat Jump',
      'exercise_calf_raise': 'Calf Raise',
      'exercise_glute_bridge': 'Glute Bridge',
      'exercise_superman': 'Superman',
      'exercise_side_plank': 'Side Plank',
      'exercise_bicycle_crunch': 'Bicycle Crunch',
      'exercise_high_knees': 'High Knees',
      'exercise_box_jump': 'Box Jump',
      'exercise_tricep_dip': 'Tricep Dip',
      'exercise_pull_up': 'Pull Up',
      'exercise_chin_up': 'Chin Up',
      'exercise_flutter_kick': 'Flutter Kick',
      'exercise_heel_touch': 'Heel Touch',
      'exercise_v_up': 'V-Up',
      'exercise_russian_twist': 'Russian Twist',

      // Permission
      'permission_required': 'Izin Diperlukan',
      'permission_activity': 'Aplikasi membutuhkan izin untuk mengakses sensor langkah kaki.',
      'permission_instructions': 'Silakan aktifkan izin "Aktivitas fisik" di pengaturan perangkat.',
      'permission_denied': 'Izin ditolak',
      'grant_permission': 'Berikan Izin',

      // Notifications
      'quest_reminder': 'Pengingat Quest',
      'complete_daily_quests': 'Jangan lupa selesaikan quest harian Anda!',

      // Settings
      'notifications': 'Notifikasi',
      'sound': 'Suara',
      'vibration': 'Getar',
      'dark_mode': 'Mode Gelap',
      'about': 'Tentang',
      'version': 'Versi',
      'privacy_policy': 'Kebijakan Privasi',
      'terms_of_service': 'Syarat Layanan',
      'help_support': 'Bantuan & Dukungan',
      'contact_us': 'Hubungi Kami',
      'rate_app': 'Beri Rating Aplikasi',

      // System Message
      'system_message': 'PESAN SISTEM',
      'acknowledge': 'Terverifikasi',
      'system_unavailable': 'Koneksi ke Sistem Pusat terputus.',
    },
    'en': {
      // General
      'app_name': 'FitTask',
      'loading': 'Loading...',
      'save': 'Save',
      'cancel': 'Cancel',
      'confirm': 'Confirm',
      'done': 'Done',
      'error': 'Error',
      'success': 'Success',

      // Login/Signup
      'system_login': 'SYSTEM LOGIN',
      'hunter_registration': 'HUNTER REGISTRATION',
      'welcome_back': 'Welcome back, Hunter. Enter your credentials.',
      'initialize_profile': 'Initialize your profile to join the system.',
      'hunter_name': 'Hunter Name',
      'email_address': 'Email Address',
      'password': 'Password',
      'forgot_password': 'Forgot Password?',
      'access_system': 'ACCESS SYSTEM',
      'initialize_system': 'INITIALIZE SYSTEM',
      'dont_have_account': "Don't have an account? ",
      'already_hunter': 'Already a Hunter? ',
      'sign_up': 'Sign Up',
      'log_in': 'Log In',
      'or_connect_with': 'OR CONNECT WITH',
      'google': 'Google',

      // Home
      'daily_quests': 'Daily Quests',
      'main_quest': 'Main Quest',
      'weekly_quest': 'Weekly Quest',
      'streak': 'Streak',
      'total_exp': 'Total EXP',
      'level': 'Level',
      'rank': 'Rank',

      // Quest Types
      'walking_quest': 'Walking Quest',
      'walking_quest_desc': 'Complete your daily step target',
      'target_steps': 'Target: {steps} steps',
      'current_steps': 'Current Steps',
      'claim_exp': 'CLAIM EXP',
      'not_completed': 'NOT COMPLETED',
      'complete_target_to_claim': 'Complete target to claim EXP',
      'quest_completed': 'Quest Completed!',
      'quest_already_done': 'Quest Already Done!',
      'you_completed_quest': 'You have already completed this quest.',
      'exp_claimed': 'EXP claimed successfully!',

      // Plank Quest
      'plank_quest': 'Plank Quest',
      'start': 'START',
      'quest_clear': 'QUEST CLEAR!',
      'quest_failed': 'QUEST FAILED',
      'you_survived': 'You survived!',
      'failed_focus': 'Failed to focus!',

      // Profile
      'hunter_profile': 'Hunter Profile',
      'hunter_statistics': 'Hunter Statistics',
      'settings': 'Settings',
      'language': 'Language',
      'select_language': 'Select Language',
      'ai_rest_mode': 'AI Rest Mode',
      'rest_mode_desc': 'Freeze penalties when injured/sick',
      'logout': 'Logout',
      'delete_account': 'Delete Account',
      'rest_mode_activated': 'Rest Mode activated',
      'rest_mode_deactivated': 'Rest Mode deactivated',
      'logout_confirm': 'Logout from account?',
      'delete_account_confirm': 'Delete Account?',
      'delete_account_warning': 'All your data will be permanently deleted. Are you sure?',
      'account_deleted': 'Account deleted successfully',

      // Exercise Quests
      'exercise_quests': 'Exercise Quests',
      'view_details': 'View Details',
      'start_exercise': 'Start Exercise',
      'sets': 'Sets',
      'reps': 'Reps',
      'duration': 'Duration',
      'seconds': 'seconds',
      'minutes': 'minutes',
      'target_muscles': 'Target Muscles',
      'secondary_muscles': 'Secondary Muscles',
      'equipment': 'Equipment',
      'difficulty': 'Difficulty',
      'easy': 'Easy',
      'medium': 'Medium',
      'hard': 'Hard',
      'beginner': 'Beginner',
      'intermediate': 'Intermediate',
      'advanced': 'Advanced',
      'instructions': 'Instructions',
      'starting_position': 'Starting Position',
      'ending_position': 'Ending Position',
      'tips': 'Tips',
      'repetitions': ' reps',
      'sets_count': ' sets',
      'rest_between_sets': 'Rest between sets',
      'complete_all_sets': 'Complete all sets to finish the quest!',
      'exercise_in_progress': 'Exercise In Progress',
      'set_completed': 'Set {current}/{total} completed!',
      'all_sets_completed': 'All sets completed! Quest finished!',
      'hold_position': 'Hold this position',
      'countdown': 'Countdown',
      'great_job': 'Great job!',

      // Quest Categories
      'category_chest': 'Chest',
      'category_back': 'Back',
      'category_shoulders': 'Shoulders',
      'category_arms': 'Arms',
      'category_legs': 'Legs',
      'category_core': 'Core/Abs',
      'category_cardio': 'Cardio',
      'category_full_body': 'Full Body',

      // Hydration
      'hydration_quest': 'Hydration Quest',
      'drink_water': 'Drink Water',
      'target_water': 'Target: {ml} ml',
      'glasses': 'glasses',
      'stay_hydrated': 'Stay hydrated!',

      // Exercise Names
      'exercise_sit_up': 'Sit Up',
      'exercise_push_up': 'Push Up',
      'exercise_squat': 'Squat',
      'exercise_plank': 'Plank',
      'exercise_lunge': 'Lunge',
      'exercise_jumping_jack': 'Jumping Jack',
      'exercise_mountain_climber': 'Mountain Climber',
      'exercise_burpee': 'Burpee',
      'exercise_crunch': 'Crunch',
      'exercise_leg_raise': 'Leg Raise',
      'exercise_wall_sit': 'Wall Sit',
      'exercise_diamond_push_up': 'Diamond Push Up',
      'exercise_wide_push_up': 'Wide Push Up',
      'exercise_incline_push_up': 'Incline Push Up',
      'exercise_decline_push_up': 'Decline Push Up',
      'exercise_squat_jump': 'Squat Jump',
      'exercise_calf_raise': 'Calf Raise',
      'exercise_glute_bridge': 'Glute Bridge',
      'exercise_superman': 'Superman',
      'exercise_side_plank': 'Side Plank',
      'exercise_bicycle_crunch': 'Bicycle Crunch',
      'exercise_high_knees': 'High Knees',
      'exercise_box_jump': 'Box Jump',
      'exercise_tricep_dip': 'Tricep Dip',
      'exercise_pull_up': 'Pull Up',
      'exercise_chin_up': 'Chin Up',
      'exercise_flutter_kick': 'Flutter Kick',
      'exercise_heel_touch': 'Heel Touch',
      'exercise_v_up': 'V-Up',
      'exercise_russian_twist': 'Russian Twist',

      // Permission
      'permission_required': 'Permission Required',
      'permission_activity': 'The app needs permission to access the step counter sensor.',
      'permission_instructions': 'Please enable "Physical activity" permission in device settings.',
      'permission_denied': 'Permission denied',
      'grant_permission': 'Grant Permission',

      // Notifications
      'quest_reminder': 'Quest Reminder',
      'complete_daily_quests': "Don't forget to complete your daily quests!",

      // Settings
      'notifications': 'Notifications',
      'sound': 'Sound',
      'vibration': 'Vibration',
      'dark_mode': 'Dark Mode',
      'about': 'About',
      'version': 'Version',
      'privacy_policy': 'Privacy Policy',
      'terms_of_service': 'Terms of Service',
      'help_support': 'Help & Support',
      'contact_us': 'Contact Us',
      'rate_app': 'Rate App',

      // System Message
      'system_message': 'SYSTEM MESSAGE',
      'acknowledge': 'Acknowledge',
      'system_unavailable': 'Connection to Central System lost.',
    },
  };

  static String getCurrentLanguage() {
    return _currentLanguage;
  }

  static String _currentLanguage = 'id';

  static Future<void> loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLanguage = prefs.getString(_languageKey) ?? 'id';
  }

  static Future<void> setLanguage(String languageCode) async {
    _currentLanguage = languageCode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, languageCode);
  }

  static String translate(String key) {
    return _translations[_currentLanguage]?[key] ??
           _translations['id']?[key] ??
           key;
  }

  static String translateWithParams(String key, Map<String, String> params) {
    String result = translate(key);
    params.forEach((param, value) {
      result = result.replaceAll('{$param}', value);
    });
    return result;
  }

  static Locale getLocale() {
    return Locale(_currentLanguage);
  }

  static List<Map<String, String>> getAvailableLanguages() {
    return [
      {'code': 'id', 'name': 'Bahasa Indonesia', 'flag': '🇮🇩'},
      {'code': 'en', 'name': 'English', 'flag': '🇺🇸'},
    ];
  }
}

// Helper function for easy access
String t(String key) => LanguageService.translate(key);
