import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/user_profile_service.dart';
import '../services/language_service.dart';
import '../services/quest_generation_service.dart';
import '../services/friend_service.dart';
import 'language_settings_screen.dart';
import '../main.dart';

class ProfileScreen extends StatefulWidget {
  final String uid;
  final VoidCallback onLanguageChanged;
  final VoidCallback? onProfileUpdated;

  const ProfileScreen({
    super.key,
    required this.uid,
    required this.onLanguageChanged,
    this.onProfileUpdated,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  String _playerName = 'Hunter';
  String? _username;
  String _rank = 'E - Awakening';
  int _level = 1;
  int _currentExp = 0;
  int _expToNext = 100;
  int _totalExp = 0;
  int _streak = 0;
  bool _restModeActive = false;
  DateTime? _joinDate;
  String _currentLang = 'id';
  String? _photoUrl;
  String? _bio;
  DateTime? _lastUsernameChange;

  // Health data
  double? _heightCm;
  double? _weightKg;
  DateTime? _birthDate;
  double? _bmi;
  int? _age;
  double? _dailyWaterNeed;

  // Daily EXP tracking
  int _dailyExpEarned = 0;
  int _dailyExpLimit = 500;

  @override
  void initState() {
    super.initState();
    _currentLang = LanguageService.getCurrentLanguage();
    _loadProfile();
  }

  void _refreshLanguage() {
    setState(() {
      _currentLang = LanguageService.getCurrentLanguage();
    });
    widget.onLanguageChanged();
  }

  Future<void> _loadProfile() async {
    try {
      final doc = await _firestore.collection('users').doc(widget.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _playerName = data['displayName'] ?? 'Hunter';
          _username = data['username'];
          _rank = data['rank'] ?? 'E - Awakening';
          _level = data['level'] ?? 1;
          _currentExp = data['currentExp'] ?? 0;
          _expToNext = data['expToNextLevel'] ?? 100;
          _totalExp = data['totalExp'] ?? 0;
          _streak = data['streak'] ?? 0;
          _restModeActive = data['restModeActive'] ?? false;
          _joinDate = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
          _currentLang = data['language'] ?? _currentLang;
          _photoUrl = data['photoUrl'];
          _bio = data['bio'];
          _lastUsernameChange = data['lastUsernameChange'] != null
              ? (data['lastUsernameChange'] as Timestamp).toDate()
              : null;

          // Load health data
          _heightCm = data['heightCm']?.toDouble();
          _weightKg = data['weightKg']?.toDouble();
          if (data['birthDate'] is Timestamp) {
            _birthDate = (data['birthDate'] as Timestamp).toDate();
          }

          // Calculate derived data
          if (_heightCm != null && _weightKg != null) {
            _bmi = UserProfileService.calculateBMI(_heightCm!, _weightKg!);
          }
          if (_birthDate != null) {
            _age = UserProfileService.calculateAge(_birthDate!);
          }
          if (_weightKg != null) {
            _dailyWaterNeed = UserProfileService.calculateDailyWaterNeed(_weightKg!);
          }

          // Daily EXP limit
          _dailyExpLimit = UserProfileService.getDailyExpLimit(_level);

          _isLoading = false;
        });

        // Load daily EXP earned
        _loadDailyExp();
      } else {
        await _createDefaultProfile();
        _loadProfile();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_currentLang == 'id' ? 'Gagal memuat profil' : 'Failed to load profile')),
      );
    }
  }

  Future<void> _createDefaultProfile() async {
    await _firestore.collection('users').doc(widget.uid).set({
      'displayName': 'Hunter',
      'rank': 'E - Awakening',
      'level': 1,
      'currentExp': 0,
      'expToNextLevel': 100,
      'totalExp': 0,
      'streak': 0,
      'restModeActive': false,
      'language': _currentLang,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _loadDailyExp() async {
    final earned = await QuestGenerationService.getDailyExpEarned(widget.uid);
    setState(() {
      _dailyExpEarned = earned;
    });
  }

  Future<void> _toggleRestMode(bool value) async {
    // If activating, show confirmation dialog first
    if (value) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.black87,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.amber),
          ),
          title: Row(
            children: [
              const Icon(Icons.warning_amber, color: Colors.amber),
              const SizedBox(width: 8),
              Text(
                _currentLang == 'id' ? 'Aktifkan Rest Mode?' : 'Activate Rest Mode?',
                style: const TextStyle(color: Colors.amber),
              ),
            ],
          ),
          content: Text(
            _currentLang == 'id'
                ? 'Rest Mode akan membekukan penalti saat kamu tidak bisa menyelesaikan quest.\n\nApakah kamu yakin ingin mengaktifkannya?'
                : 'Rest Mode will freeze penalties when you cannot complete quests.\n\nAre you sure you want to activate it?',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                _currentLang == 'id' ? 'Batal' : 'Cancel',
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
              child: Text(
                _currentLang == 'id' ? 'Ya, Aktifkan' : 'Yes, Activate',
                style: const TextStyle(color: Colors.black),
              ),
            ),
          ],
        ),
      );

      if (confirmed != true) {
        // User cancelled, revert the switch
        setState(() => _restModeActive = _restModeActive);
        return;
      }
    }

    try {
      await _firestore.collection('users').doc(widget.uid).update({
        'restModeActive': value,
      });
      setState(() => _restModeActive = value);

      // Show snackbar for 3 seconds only
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(value
              ? (_currentLang == 'id' ? 'Rest Mode diaktifkan' : 'Rest Mode activated')
              : (_currentLang == 'id' ? 'Rest Mode dinonaktifkan' : 'Rest Mode deactivated')),
          backgroundColor: value ? Colors.amber : Colors.green,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      setState(() => _restModeActive = !value); // Revert on error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_currentLang == 'id' ? 'Gagal update Rest Mode' : 'Failed to update Rest Mode'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _showHealthDataDialog() async {
    final heightController = TextEditingController(
      text: _heightCm?.toStringAsFixed(1) ?? '',
    );
    final weightController = TextEditingController(
      text: _weightKg?.toStringAsFixed(1) ?? '',
    );
    DateTime selectedDate = _birthDate ?? DateTime(2000, 1, 1);

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.black87,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF10B981)),
          ),
          title: Row(
            children: [
              const Icon(Icons.monitor_heart, color: Color(0xFF10B981)),
              const SizedBox(width: 8),
              Text(
                _currentLang == 'id' ? 'Data Kesehatan' : 'Health Data',
                style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentLang == 'id'
                      ? 'Lengkapi data kesehatan Anda untuk quest yang dipersonalisasi.'
                      : 'Complete your health data for personalized quests.',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 20),

                // Height Input
                _buildInputField(
                  controller: heightController,
                  label: _currentLang == 'id' ? 'Tinggi Badan (cm)' : 'Height (cm)',
                  icon: Icons.height,
                  hint: '170',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 16),

                // Weight Input
                _buildInputField(
                  controller: weightController,
                  label: _currentLang == 'id' ? 'Berat Badan (kg)' : 'Weight (kg)',
                  icon: Icons.monitor_weight,
                  hint: '70',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 16),

                // Birth Date Picker
                Text(
                  _currentLang == 'id' ? 'Tanggal Lahir' : 'Birth Date',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(1940),
                      lastDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
                      builder: (context, child) {
                        return Theme(
                          data: ThemeData.dark().copyWith(
                            colorScheme: const ColorScheme.dark(
                              primary: Color(0xFF10B981),
                              surface: Color(0xFF111111),
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null) {
                      setDialogState(() => selectedDate = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF111111),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade700),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Color(0xFF10B981)),
                        const SizedBox(width: 12),
                        Text(
                          '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(_currentLang == 'id' ? 'Batal' : 'Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final height = double.tryParse(heightController.text);
                final weight = double.tryParse(weightController.text);

                if (height == null || weight == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(_currentLang == 'id'
                        ? 'Masukkan angka yang valid'
                        : 'Please enter valid numbers')),
                  );
                  return;
                }

                if (height < 50 || height > 300) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(_currentLang == 'id'
                        ? 'Tinggi badan tidak valid'
                        : 'Invalid height')),
                  );
                  return;
                }

                if (weight < 20 || weight > 500) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(_currentLang == 'id'
                        ? 'Berat badan tidak valid'
                        : 'Invalid weight')),
                  );
                  return;
                }

                // Save to Firestore
                final success = await UserProfileService.updateHealthProfile(
                  uid: widget.uid,
                  heightCm: height,
                  weightKg: weight,
                  birthDate: selectedDate,
                );

                if (success) {
                  Navigator.pop(context);
                  _loadProfile();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(_currentLang == 'id'
                        ? 'Data kesehatan disimpan!'
                        : 'Health data saved!')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(_currentLang == 'id'
                        ? 'Gagal menyimpan data'
                        : 'Failed to save data')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
              ),
              child: Text(_currentLang == 'id' ? 'Simpan' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    TextInputType? keyboardType,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          enabled: enabled,
          style: TextStyle(color: enabled ? Colors.white : Colors.white38),
          inputFormatters: keyboardType == const TextInputType.numberWithOptions(decimal: true)
              ? [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))]
              : null,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF111111),
            prefixIcon: Icon(icon, color: const Color(0xFF10B981)),
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white30),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF10B981)),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        title: Text(
          _currentLang == 'id' ? 'Hapus Akun?' : 'Delete Account?',
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          _currentLang == 'id'
              ? 'Semua data Anda akan dihapus permanen. Yakin?'
              : 'All your data will be permanently deleted. Are you sure?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              _currentLang == 'id' ? 'Batal' : 'Cancel',
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              _currentLang == 'id' ? 'Hapus' : 'Delete',
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await _firestore.collection('users').doc(widget.uid).delete();
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) await user.delete();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_currentLang == 'id' ? 'Akun berhasil dihapus' : 'Account deleted successfully')),
        );
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_currentLang == 'id' ? 'Gagal hapus akun' : 'Failed to delete account')),
        );
      }
    }
  }

  bool get _isHealthDataComplete {
    return _heightCm != null && _heightCm! > 0 &&
           _weightKg != null && _weightKg! > 0 &&
           _birthDate != null;
  }

  /// Check if username is empty (for old users)
  bool get _needsUsername {
    return _username == null || _username!.isEmpty;
  }

  /// Check if user can change username (30 days cooldown)
  bool get _canChangeUsername {
    if (_lastUsernameChange == null) return true;
    final daysSinceChange = DateTime.now().difference(_lastUsernameChange!).inDays;
    return daysSinceChange >= 30;
  }

  /// Get days until next username change
  int get _daysUntilUsernameChange {
    if (_lastUsernameChange == null) return 0;
    final daysSinceChange = DateTime.now().difference(_lastUsernameChange!).inDays;
    return (30 - daysSinceChange).clamp(0, 30);
  }

  /// Show edit profile dialog
  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: _playerName);
    final usernameController = TextEditingController(text: _username ?? '');
    final bioController = TextEditingController(text: _bio ?? '');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.black87,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF10B981)),
          ),
          title: Row(
            children: [
              const Icon(Icons.edit, color: Color(0xFF10B981)),
              const SizedBox(width: 8),
              Text(
                _currentLang == 'id' ? 'Edit Profil' : 'Edit Profile',
                style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Username Warning for old users
                if (_needsUsername) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _currentLang == 'id'
                                ? 'Username wajib diisi untuk menggunakan fitur teman!'
                                : 'Username is required for friend features!',
                            style: const TextStyle(color: Colors.red, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Photo Section
                Center(
                  child: GestureDetector(
                    onTap: () => _pickImage(setDialogState),
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: const Color(0xFF10B981).withOpacity(0.2),
                          backgroundImage: _photoUrl != null ? NetworkImage(_photoUrl!) : null,
                          child: _photoUrl == null
                              ? const Icon(Icons.person, size: 50, color: Color(0xFF10B981))
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Name Input
                _buildInputField(
                  controller: nameController,
                  label: _currentLang == 'id' ? 'Nama' : 'Name',
                  icon: Icons.person,
                  hint: 'Hunter Name',
                ),
                const SizedBox(height: 16),

                // Username Input
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInputField(
                      controller: usernameController,
                      label: _currentLang == 'id' ? 'Username' : 'Username',
                      icon: Icons.alternate_email,
                      hint: 'hunter123',
                      enabled: _canChangeUsername || _needsUsername,
                    ),
                    if (!_canChangeUsername && !_needsUsername)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          _currentLang == 'id'
                              ? 'Bisa diganti dalam $_daysUntilUsernameChange hari'
                              : 'Can change in $_daysUntilUsernameChange days',
                          style: const TextStyle(color: Colors.orange, fontSize: 11),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Bio Input
                TextField(
                  controller: bioController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 3,
                  maxLength: 150,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFF111111),
                    prefixIcon: const Icon(Icons.info_outline, color: Color(0xFF10B981)),
                    hintText: _currentLang == 'id' ? 'Bio (opsional)' : 'Bio (optional)',
                    hintStyle: const TextStyle(color: Colors.white30),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF10B981)),
                    ),
                    counterStyle: const TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                _currentLang == 'id' ? 'Batal' : 'Cancel',
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final username = usernameController.text.trim();
                final bio = bioController.text.trim();

                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(_currentLang == 'id'
                        ? 'Nama tidak boleh kosong'
                        : 'Name cannot be empty')),
                  );
                  return;
                }

                // Validate username if changed
                if ((username != _username) && (username.isNotEmpty || _needsUsername)) {
                  if (username.length < 3 || username.length > 20) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(_currentLang == 'id'
                          ? 'Username harus 3-20 karakter'
                          : 'Username must be 3-20 characters')),
                    );
                    return;
                  }

                  if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(_currentLang == 'id'
                          ? 'Username hanya boleh huruf, angka, underscore'
                          : 'Username can only contain letters, numbers, underscore')),
                    );
                    return;
                  }

                  // Check availability
                  final available = await _checkUsernameAvailability(username);
                  if (!available) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(_currentLang == 'id'
                          ? 'Username sudah digunakan'
                          : 'Username is already taken')),
                    );
                    return;
                  }
                }

                // Update profile
                await _updateProfile(name, username, bio);
                if (mounted) {
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
              ),
              child: Text(
                _currentLang == 'id' ? 'Simpan' : 'Save',
                style: const TextStyle(color: Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _checkUsernameAvailability(String username) async {
    try {
      final normalizedUsername = username.toLowerCase().trim();
      final snapshot = await _firestore
          .collection('users')
          .where('usernameLower', isEqualTo: normalizedUsername)
          .limit(1)
          .get();
      return snapshot.docs.isEmpty;
    } catch (e) {
      return true;
    }
  }

  Future<void> _pickImage(StateSetter setDialogState) async {
    final picker = ImagePicker();
    final source = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        title: Text(
          _currentLang == 'id' ? 'Pilih Sumber' : 'Select Source',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'camera'),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.camera_alt, color: Color(0xFF10B981)),
                const SizedBox(width: 8),
                Text(_currentLang == 'id' ? 'Kamera' : 'Camera'),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'gallery'),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.photo_library, color: Color(0xFF10B981)),
                const SizedBox(width: 8),
                Text(_currentLang == 'id' ? 'Galeri' : 'Gallery'),
              ],
            ),
          ),
        ],
      ),
    );

    if (source == null) return;

    try {
      final XFile? image = await picker.pickImage(
        source: source == 'camera' ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (image != null) {
        setDialogState(() {}); // Refresh dialog
        // Upload and update
        await _uploadImage(File(image.path));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_currentLang == 'id'
            ? 'Gagal memilih gambar'
            : 'Failed to pick image')),
      );
    }
  }

  Future<void> _uploadImage(File file) async {
    try {
      final ref = FirebaseStorage.instance.ref().child('profile_photos').child('${widget.uid}.jpg');
      await ref.putFile(file);
      final url = await ref.getDownloadURL();

      await _firestore.collection('users').doc(widget.uid).update({
        'photoUrl': url,
      });

      _loadProfile();
      widget.onProfileUpdated?.call();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_currentLang == 'id'
            ? 'Gagal upload foto'
            : 'Failed to upload photo')),
      );
    }
  }

  Future<void> _updateProfile(String name, String username, String bio) async {
    try {
      final updates = <String, dynamic>{
        'displayName': name,
        'bio': bio,
      };

      // Only update username if changed and allowed
      if (username.isNotEmpty && username != _username) {
        updates['username'] = username;
        updates['usernameLower'] = username.toLowerCase();
        updates['lastUsernameChange'] = FieldValue.serverTimestamp();
      }

      await _firestore.collection('users').doc(widget.uid).update(updates);

      _loadProfile();
      widget.onProfileUpdated?.call();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_currentLang == 'id'
            ? 'Profil berhasil diperbarui!'
            : 'Profile updated!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_currentLang == 'id'
            ? 'Gagal update profil'
            : 'Failed to update profile')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentLang == 'id' ? 'Profil Hunter' : 'Hunter Profile',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Color(0xFF10B981)),
            onPressed: _showEditProfileDialog,
            tooltip: _currentLang == 'id' ? 'Edit Profil' : 'Edit Profile',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Username Warning Banner
                  if (_needsUsername) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning, color: Colors.red),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _currentLang == 'id'
                                      ? 'Username belum diisi!'
                                      : 'Username not set!',
                                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                Text(
                                  _currentLang == 'id'
                                      ? 'Wajib isi username untuk menggunakan fitur teman. Tekan tombol edit di kanan atas.'
                                      : 'Set username to use friend features. Tap edit button on top right.',
                                  style: const TextStyle(color: Colors.red, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.red),
                            onPressed: _showEditProfileDialog,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Profile Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [const Color(0xFF10B981).withOpacity(0.2), Colors.black],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4), width: 2),
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: _showEditProfileDialog,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF10B981).withOpacity(0.3),
                              border: Border.all(color: const Color(0xFF10B981), width: 2),
                              image: _photoUrl != null
                                  ? DecorationImage(
                                      image: NetworkImage(_photoUrl!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: _photoUrl == null
                                ? const Icon(Icons.person, size: 50, color: Color(0xFF10B981))
                                : null,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_playerName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                              if (_username != null && _username!.isNotEmpty)
                                Text('@$_username', style: const TextStyle(color: Color(0xFF10B981), fontSize: 14)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text('Rank: ', style: TextStyle(color: Colors.grey[400])),
                                  Text(_rank, style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)),
                                ],
                              ),
                              Row(
                                children: [
                                  Text(
                                    _currentLang == 'id' ? 'Level: ' : 'Level: ',
                                    style: TextStyle(color: Colors.grey[400]),
                                  ),
                                  Text('$_level', style: const TextStyle(color: Colors.white)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: _currentExp / _expToNext,
                                  minHeight: 8,
                                  backgroundColor: Colors.white10,
                                  color: const Color(0xFF10B981),
                                ),
                              ),
                              Text(
                                _currentLang == 'id' ? 'EXP: $_currentExp / $_expToNext' : 'EXP: $_currentExp / $_expToNext',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Health Data Warning Banner
                  if (!_isHealthDataComplete) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber, color: Colors.orange),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _currentLang == 'id'
                                  ? 'Lengkapi data kesehatan untuk quest personal!'
                                  : 'Complete health data for personalized quests!',
                              style: const TextStyle(color: Colors.orange, fontSize: 13),
                            ),
                          ),
                          TextButton(
                            onPressed: _showHealthDataDialog,
                            child: Text(
                              _currentLang == 'id' ? 'Isi' : 'Fill',
                              style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Health Data Card (if complete)
                  if (_isHealthDataComplete) ...[
                    Text(
                      _currentLang == 'id' ? 'Data Kesehatan' : 'Health Data',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF111111),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _healthDataItem(
                                icon: Icons.height,
                                label: _currentLang == 'id' ? 'Tinggi' : 'Height',
                                value: '${_heightCm?.toStringAsFixed(1)} cm',
                                color: Colors.blue,
                              ),
                              _healthDataItem(
                                icon: Icons.monitor_weight,
                                label: _currentLang == 'id' ? 'Berat' : 'Weight',
                                value: '${_weightKg?.toStringAsFixed(1)} kg',
                                color: Colors.purple,
                              ),
                              _healthDataItem(
                                icon: Icons.cake,
                                label: _currentLang == 'id' ? 'Usia' : 'Age',
                                value: '$_age ${_currentLang == 'id' ? 'th' : 'y'}',
                                color: Colors.orange,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(color: Colors.grey),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _healthDataItem(
                                icon: Icons.monitor_heart,
                                label: 'BMI',
                                value: _bmi != null ? _bmi!.toStringAsFixed(1) : '-',
                                subValue: _getBMICategoryText(),
                                color: _getBMIColor(),
                              ),
                              _healthDataItem(
                                icon: Icons.water_drop,
                                label: _currentLang == 'id' ? 'Kebutuhan Air' : 'Water Need',
                                value: '${_dailyWaterNeed?.toStringAsFixed(0)} ml',
                                subValue: _currentLang == 'id' ? 'per hari' : 'per day',
                                color: Colors.cyan,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: TextButton.icon(
                              onPressed: _showHealthDataDialog,
                              icon: const Icon(Icons.edit, size: 18),
                              label: Text(_currentLang == 'id' ? 'Edit Data Kesehatan' : 'Edit Health Data'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Daily EXP Card
                  Text(
                    _currentLang == 'id' ? 'Batas EXP Harian' : 'Daily EXP Limit',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF111111),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _currentLang == 'id' ? 'EXP Hari Ini' : 'Today\'s EXP',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            Text(
                              '$_dailyExpEarned / $_dailyExpLimit',
                              style: const TextStyle(
                                color: Color(0xFF10B981),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: (_dailyExpEarned / _dailyExpLimit).clamp(0.0, 1.0),
                            minHeight: 10,
                            backgroundColor: Colors.white10,
                            color: _dailyExpEarned >= _dailyExpLimit
                                ? Colors.orange
                                : const Color(0xFF10B981),
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_dailyExpEarned >= _dailyExpLimit)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.info_outline, color: Colors.orange, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                _currentLang == 'id'
                                    ? 'Batas EXP harian tercapai!'
                                    : 'Daily EXP limit reached!',
                                style: const TextStyle(color: Colors.orange, fontSize: 12),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Statistics
                  Text(
                    _currentLang == 'id' ? 'Statistik Hunter' : 'Hunter Statistics',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _statCard(
                        _currentLang == 'id' ? 'Total EXP' : 'Total EXP',
                        '$_totalExp',
                        Icons.stars,
                      ),
                      _statCard(
                        _currentLang == 'id' ? 'Streak' : 'Streak',
                        '$_streak days',
                        Icons.local_fire_department,
                      ),
                      _statCard(
                        _currentLang == 'id' ? 'Bergabung' : 'Joined',
                        _joinDate != null ? '${_joinDate!.day}/${_joinDate!.month}/${_joinDate!.year}' : '-',
                        Icons.calendar_today,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Settings
                  Text(
                    _currentLang == 'id' ? 'Pengaturan' : 'Settings',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  // Health Data Button
                  Card(
                    color: const Color(0xFF111111),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: const Icon(Icons.monitor_heart, color: Color(0xFF10B981)),
                      title: Text(
                        _currentLang == 'id' ? 'Data Kesehatan' : 'Health Data',
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        _isHealthDataComplete
                            ? _currentLang == 'id'
                                ? 'Tinggi: ${_heightCm?.toStringAsFixed(0)}cm, Berat: ${_weightKg?.toStringAsFixed(0)}kg'
                                : 'Height: ${_heightCm?.toStringAsFixed(0)}cm, Weight: ${_weightKg?.toStringAsFixed(0)}kg'
                            : _currentLang == 'id'
                                ? 'Belum diisi'
                                : 'Not filled',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      trailing: Icon(
                        _isHealthDataComplete ? Icons.check_circle : Icons.chevron_right,
                        color: _isHealthDataComplete ? Colors.green : Colors.grey,
                      ),
                      onTap: _showHealthDataDialog,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Language Settings
                  Card(
                    color: const Color(0xFF111111),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: const Icon(Icons.language, color: Color(0xFF10B981)),
                      title: Text(
                        _currentLang == 'id' ? 'Bahasa' : 'Language',
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        _currentLang == 'id' ? 'Pilih bahasa aplikasi' : 'Select app language',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LanguageSettingsScreen(
                              onLanguageChanged: _refreshLanguage,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),

                  Card(
                    color: const Color(0xFF111111),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: SwitchListTile(
                      title: Text(
                        _currentLang == 'id' ? 'AI Rest Mode' : 'AI Rest Mode',
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        _currentLang == 'id'
                            ? 'Bekukan penalti saat cedera/sakit'
                            : 'Freeze penalties when injured/sick',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      value: _restModeActive,
                      onChanged: _toggleRestMode,
                      activeColor: const Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Card(
                    color: const Color(0xFF111111),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: const Icon(Icons.logout, color: Colors.white70),
                      title: Text(
                        _currentLang == 'id' ? 'Keluar' : 'Logout',
                        style: const TextStyle(color: Colors.white),
                      ),
                      onTap: _logout,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Card(
                    color: const Color(0xFF111111),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
                      title: Text(
                        _currentLang == 'id' ? 'Hapus Akun' : 'Delete Account',
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                      onTap: _deleteAccount,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _healthDataItem({
    required IconData icon,
    required String label,
    required String value,
    String? subValue,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        if (subValue != null)
          Text(
            subValue,
            style: TextStyle(color: color, fontSize: 11),
          ),
      ],
    );
  }

  String _getBMICategoryText() {
    if (_bmi == null) return '';
    final category = UserProfileService.getBMICategory(_bmi!);
    return category.getDisplayName(_currentLang);
  }

  Color _getBMIColor() {
    if (_bmi == null) return Colors.grey;
    final category = UserProfileService.getBMICategory(_bmi!);
    switch (category) {
      case BMICategory.underweight:
        return Colors.blue;
      case BMICategory.normal:
        return Colors.green;
      case BMICategory.overweight:
        return Colors.orange;
      case BMICategory.obese:
        return Colors.red;
    }
  }

  Widget _statCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF10B981), size: 24),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}