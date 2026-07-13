import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/language_service.dart';

/// Step-by-step onboarding wizard for new users
///
/// This wizard guides users through profile setup with detailed explanations
/// for each step, similar to banking apps or games.
class OnboardingWizard extends StatefulWidget {
  final String uid;
  final VoidCallback onComplete;

  const OnboardingWizard({
    super.key,
    required this.uid,
    required this.onComplete,
  });

  @override
  State<OnboardingWizard> createState() => _OnboardingWizardState();
}

class _OnboardingWizardState extends State<OnboardingWizard> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  String _currentLang = 'id';

  // Form data
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  DateTime? _birthDate;
  bool _cameraPermissionGranted = false;
  bool _activityPermissionGranted = false;

  // Steps data - initialized in initState
  late List<OnboardingStep> _steps;

  @override
  void initState() {
    super.initState();
    _currentLang = LanguageService.getCurrentLanguage();
    _initSteps();
  }

  void _initSteps() {
    _steps = [
      // Step 0: Welcome
      OnboardingStep(
        id: 'welcome',
        icon: Icons.shield,
        titleId: 'Selamat Datang, Hunter!',
        titleEn: 'Welcome, Hunter!',
        subtitleId: 'Mari kita setup profilmu',
        subtitleEn: "Let's set up your profile",
        descriptionId: 'Ikuti langkah-langkah berikut untuk membuat profil sempurna kamu. Ini akan membantu kami memberikan quest yang sesuai untukmu.',
        descriptionEn: 'Follow the steps below to create your perfect profile. This will help us provide quests that are right for you.',
        color: const Color(0xFF10B981),
        builder: _buildWelcomeStep,
      ),

      // Step 1: Basic Info
      OnboardingStep(
        id: 'basic_info',
        icon: Icons.person,
        titleId: 'Informasi Dasar',
        titleEn: 'Basic Information',
        subtitleId: 'Namamu adalah identitasmu',
        subtitleEn: 'Your name is your identity',
        descriptionId: 'Nama ini akan muncul di profil dan leaderboard. Username digunakan teman untuk mencari kamu.',
        descriptionEn: 'This name will appear on your profile and leaderboard. Username is used by friends to find you.',
        color: const Color(0xFF3B82F6),
        builder: _buildBasicInfoStep,
      ),

      // Step 2: Health Data
      OnboardingStep(
        id: 'health_data',
        icon: Icons.monitor_heart,
        titleId: 'Data Kesehatan',
        titleEn: 'Health Data',
        subtitleId: 'Ini penting untuk quest personal',
        subtitleEn: 'This is important for personalized quests',
        descriptionId: 'Data ini digunakan AI kami untuk membuatkan quest yang sesuai kemampuan dan kebutuhanmu. BMI (Body Mass Index) dihitung dari tinggi dan berat badan.',
        descriptionEn: 'This data is used by our AI to create quests that match your abilities and needs. BMI (Body Mass Index) is calculated from height and weight.',
        color: const Color(0xFFEF4444),
        builder: _buildHealthDataStep,
      ),

      // Step 3: Permissions
      OnboardingStep(
        id: 'permissions',
        icon: Icons.security,
        titleId: 'Izin Akses',
        titleEn: 'Access Permissions',
        subtitleId: 'Diperlukan untuk fitur tertentu',
        subtitleEn: 'Required for certain features',
        descriptionId: 'Izin ini diperlukan untuk menghitung langkah kaki dan mengambil foto profil. Semua data disimpan aman dan hanya kamu yang bisa melihat.',
        descriptionEn: 'These permissions are needed to count your steps and take profile photos. All data is stored securely and only you can see it.',
        color: const Color(0xFFF97316),
        builder: _buildPermissionsStep,
      ),

      // Step 4: Features Tour
      OnboardingStep(
        id: 'features_tour',
        icon: Icons.auto_awesome,
        titleId: 'Fitur Utama',
        titleEn: 'Main Features',
        subtitleId: 'Kenalkan fitur-fitur keren!',
        subtitleEn: 'Meet the cool features!',
        descriptionId: 'Pahami fitur-fitur utama yang akan membantumu menjadi lebih sehat.',
        descriptionEn: 'Understand the main features that will help you become healthier.',
        color: const Color(0xFF8B5CF6),
        builder: _buildFeaturesTourStep,
      ),

      // Step 5: Ready
      OnboardingStep(
        id: 'ready',
        icon: Icons.celebration,
        titleId: 'Kamu Siap!',
        titleEn: "You're Ready!",
        subtitleId: 'Quest pertama menunggumu',
        subtitleEn: 'Your first quest awaits',
        descriptionId: 'Semua sudah siap! Sekarang kamu adalah Hunter. Raih rank tertinggi dan jadi Legenda!',
        descriptionEn: 'Everything is ready! Now you are a Hunter. Reach the highest rank and become a Legend!',
        color: const Color(0xFF10B981),
        builder: _buildReadyStep,
      ),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _usernameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0: // Welcome - can always proceed
        return true;
      case 1: // Basic Info - name required
        return _nameController.text.trim().isNotEmpty;
      case 2: // Health Data - all optional but encouraged
        return true;
      case 3: // Permissions - optional but encouraged
        return true;
      case 4: // Features Tour - can always proceed
        return true;
      case 5: // Ready - always proceed
        return true;
      default:
        return true;
    }
  }

  Future<void> _completeOnboarding() async {
    // Save all collected data to Firestore
    await _saveData();

    // Mark onboarding as complete
    widget.onComplete();
  }

  Future<void> _saveData() async {
    try {
      final updates = <String, dynamic>{};

      // Save name
      if (_nameController.text.trim().isNotEmpty) {
        updates['displayName'] = _nameController.text.trim();
      }

      // Save username
      if (_usernameController.text.trim().isNotEmpty) {
        updates['username'] = _usernameController.text.trim().toLowerCase();
        updates['usernameLower'] = _usernameController.text.trim().toLowerCase();
      }

      // Save health data
      if (_heightController.text.isNotEmpty) {
        final height = double.tryParse(_heightController.text);
        if (height != null) {
          updates['heightCm'] = height;
        }
      }

      if (_weightController.text.isNotEmpty) {
        final weight = double.tryParse(_weightController.text);
        if (weight != null) {
          updates['weightKg'] = weight;
        }
      }

      if (_birthDate != null) {
        updates['birthDate'] = Timestamp.fromDate(_birthDate!);
      }

      // Calculate BMI if possible
      final height = double.tryParse(_heightController.text);
      final weight = double.tryParse(_weightController.text);
      if (height != null && weight != null && height > 0) {
        final bmi = weight / ((height / 100) * (height / 100));
        updates['bmi'] = bmi;
      }

      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .update(updates);

      // Also save to SharedPreferences for local tracking
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_completed', true);
    } catch (e) {
      debugPrint('Error saving onboarding data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            _buildProgressBar(),

            // Step content
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentStep = index);
                },
                physics: const ClampingScrollPhysics(),
                children: _steps.map((step) => step.builder()).toList(),
              ),
            ),

            // Navigation buttons
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Back button
              if (_currentStep > 0)
                IconButton(
                  onPressed: _previousStep,
                  icon: const Icon(Icons.arrow_back, color: Colors.white54),
                )
              else
                const SizedBox(width: 48),

              // Step indicator
              Text(
                '${_currentStep + 1} / ${_steps.length}',
                style: const TextStyle(color: Colors.white54, fontSize: 14),
              ),

              // Skip/Close button
              if (_currentStep < _steps.length - 1)
                TextButton(
                  onPressed: _completeOnboarding,
                  child: Text(
                    _currentLang == 'id' ? 'Lewati' : 'Skip',
                    style: const TextStyle(color: Colors.white54),
                  ),
                )
              else
                const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 12),

          // Progress dots
          Row(
            children: List.generate(_steps.length, (index) {
              return Expanded(
                child: Container(
                  height: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: index <= _currentStep
                        ? _steps[_currentStep].color
                        : Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    final step = _steps[_currentStep];
    final canProceed = _canProceed();

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).padding.bottom + 16,
        top: 16,
      ),
      child: Row(
        children: [
          // Why do I need this? button (for info steps)
          if (_currentStep == 1 || _currentStep == 2)
            Expanded(
              child: OutlinedButton(
                onPressed: () => _showWhyDialog(_currentStep),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: step.color.withOpacity(0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.help_outline, color: step.color, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      _currentLang == 'id' ? 'Kenapa?' : 'Why?',
                      style: TextStyle(color: step.color),
                    ),
                  ],
                ),
              ),
            )
          else
            const Expanded(child: SizedBox()),

          if (_currentStep == 1 || _currentStep == 2) const SizedBox(width: 12),

          // Next/Finish button
          Expanded(
            flex: _currentStep == 1 || _currentStep == 2 ? 1 : 2,
            child: ElevatedButton(
              onPressed: canProceed ? _nextStep : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: step.color,
                disabledBackgroundColor: step.color.withOpacity(0.3),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _currentStep == _steps.length - 1
                    ? (_currentLang == 'id' ? 'Mulai Quest!' : 'Start Quest!')
                    : (_currentLang == 'id' ? 'Lanjut' : 'Next'),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showWhyDialog(int step) {
    String title;
    String content;

    if (step == 1) {
      title = _currentLang == 'id' ? 'Kenapa perlu data ini?' : 'Why do we need this?';
      content = _currentLang == 'id'
          ? '📌 **Nama Display**\nDigunakan untuk menampilkan identitasmu di profil dan leaderboard.\n\n'
              '📌 **Username**\nUsername unik seperti "@namamu" yang digunakan teman untuk mencari dan menambahkan kamu sebagai teman.'
          : '📌 **Display Name**\nUsed to display your identity on your profile and leaderboard.\n\n'
              '📌 **Username**\nA unique username like "@yourname" that friends use to find and add you.';
    } else {
      title = _currentLang == 'id' ? 'Kenapa perlu data ini?' : 'Why do we need this?';
      content = _currentLang == 'id'
          ? '📌 **Tinggi & Berat Badan**\nDigunakan untuk menghitung BMI dan menyesuaikan difficulty quest untukmu.\n\n'
              '📌 **Tanggal Lahir**\nBerguna untuk mengkategorikan jenis latihan yang sesuai usiamu.\n\n'
              '💡 Kamu bisa mengisi ini nanti di Profil, tapi quest akan lebih personal jika diisi sekarang.'
          : '📌 **Height & Weight**\nUsed to calculate BMI and adjust quest difficulty for you.\n\n'
              '📌 **Birth Date**\nUseful for categorizing exercise types suitable for your age.\n\n'
              '💡 You can fill this later in Profile, but quests will be more personalized if filled now.';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF111111),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: _steps[step].color),
        ),
        title: Row(
          children: [
            Icon(Icons.help, color: _steps[step].color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Text(
          content,
          style: const TextStyle(color: Colors.white70, height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: TextStyle(color: _steps[step].color),
            ),
          ),
        ],
      ),
    );
  }

  // ========== STEP WIDGETS ==========

  Widget _buildWelcomeStep() {
    final step = _steps[0];
    return _buildStepLayout(
      step: step,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated icon
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.8, end: 1.0),
            duration: const Duration(seconds: 1),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: child,
              );
            },
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    step.color.withOpacity(0.3),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: step.color.withOpacity(0.2),
                    border: Border.all(color: step.color, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: step.color.withOpacity(0.5),
                        blurRadius: 30,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Icon(
                    step.icon,
                    size: 60,
                    color: step.color,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 48),
          Text(
            _currentLang == 'id' ? step.titleId : step.titleEn,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: step.color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _currentLang == 'id' ? step.subtitleId : step.subtitleEn,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _currentLang == 'id' ? step.descriptionId : step.descriptionEn,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white54,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),

          // Info card
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: step.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: step.color.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: step.color, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _currentLang == 'id'
                        ? 'Waktu: ~2 menit'
                        : 'Time: ~2 minutes',
                    style: TextStyle(color: step.color, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoStep() {
    final step = _steps[1];
    return _buildStepLayout(
      step: step,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),

            // Name field
            _buildInputField(
              controller: _nameController,
              label: _currentLang == 'id' ? 'Nama Display' : 'Display Name',
              hint: _currentLang == 'id' ? 'Contoh: Hunter Sejahtera' : 'Example: John Hunter',
              icon: Icons.person,
              color: step.color,
              isRequired: true,
            ),
            const SizedBox(height: 20),

            // Username field
            _buildInputField(
              controller: _usernameController,
              label: _currentLang == 'id' ? 'Username' : 'Username',
              hint: _currentLang == 'id' ? 'Contoh: hunter123' : 'Example: hunter123',
              icon: Icons.alternate_email,
              color: step.color,
              isRequired: true,
            ),
            const SizedBox(height: 12),
            Text(
              _currentLang == 'id'
                  ? 'Username digunakan teman untuk mencari kamu'
                  : 'Username is used by friends to find you',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 24),

            // Info cards
            _buildInfoCard(
              icon: Icons.visibility,
              title: _currentLang == 'id' ? 'Tampil di Leaderboard' : 'Shown on Leaderboard',
              description: _currentLang == 'id'
                  ? 'Nama ini akan terlihat oleh semua hunter lain'
                  : 'This name will be visible to all other hunters',
              color: step.color,
            ),
            const SizedBox(height: 12),
            _buildInfoCard(
              icon: Icons.shield,
              title: _currentLang == 'id' ? 'Pribadi' : 'Private',
              description: _currentLang == 'id'
                  ? 'Email dan password tidak pernah ditampilkan'
                  : 'Email and password are never shown',
              color: step.color,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthDataStep() {
    final step = _steps[2];
    return _buildStepLayout(
      step: step,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),

            // Height field
            _buildInputField(
              controller: _heightController,
              label: _currentLang == 'id' ? 'Tinggi Badan (cm)' : 'Height (cm)',
              hint: '170',
              icon: Icons.height,
              color: step.color,
              keyboardType: TextInputType.number,
              suffix: 'cm',
            ),
            const SizedBox(height: 16),

            // Weight field
            _buildInputField(
              controller: _weightController,
              label: _currentLang == 'id' ? 'Berat Badan (kg)' : 'Weight (kg)',
              hint: '65',
              icon: Icons.monitor_weight,
              color: step.color,
              keyboardType: TextInputType.number,
              suffix: 'kg',
            ),
            const SizedBox(height: 16),

            // Birth date picker
            _buildDatePicker(step.color),
            const SizedBox(height: 24),

            // Preview BMI
            if (_heightController.text.isNotEmpty && _weightController.text.isNotEmpty)
              _buildBMIPreview(),

            const SizedBox(height: 16),

            // Info cards
            _buildInfoCard(
              icon: Icons.auto_awesome,
              title: _currentLang == 'id' ? 'Quest Personal' : 'Personalized Quests',
              description: _currentLang == 'id'
                  ? 'AI kami membuatkan quest sesuai kemampuanmu'
                  : 'Our AI creates quests that match your abilities',
              color: step.color,
            ),
            const SizedBox(height: 12),
            _buildInfoCard(
              icon: Icons.security,
              title: _currentLang == 'id' ? 'Data Aman' : 'Data Secure',
              description: _currentLang == 'id'
                  ? 'Hanya kamu yang bisa melihat data kesehatan ini'
                  : 'Only you can see this health data',
              color: step.color,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBMIPreview() {
    final height = double.tryParse(_heightController.text);
    final weight = double.tryParse(_weightController.text);

    if (height == null || weight == null || height <= 0) {
      return const SizedBox.shrink();
    }

    final bmi = weight / ((height / 100) * (height / 100));
    String category;
    Color categoryColor;

    if (bmi < 18.5) {
      category = _currentLang == 'id' ? 'Kurus' : 'Underweight';
      categoryColor = Colors.blue;
    } else if (bmi < 25) {
      category = _currentLang == 'id' ? 'Normal' : 'Normal';
      categoryColor = Colors.green;
    } else if (bmi < 30) {
      category = _currentLang == 'id' ? 'Gemuk' : 'Overweight';
      categoryColor = Colors.orange;
    } else {
      category = _currentLang == 'id' ? 'Obesitas' : 'Obese';
      categoryColor = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: categoryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: categoryColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.monitor_heart, color: categoryColor),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'BMI: ${bmi.toStringAsFixed(1)}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              Text(
                category,
                style: TextStyle(color: categoryColor, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionsStep() {
    final step = _steps[3];
    return _buildStepLayout(
      step: step,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 24),

            // Activity permission
            _buildPermissionCard(
              title: _currentLang == 'id' ? 'Sensor Langkah Kaki' : 'Step Counter Sensor',
              description: _currentLang == 'id'
                  ? 'Menghitung langkah kaki untuk Walking Quest tanpa menggunakan GPS (baterai hemat).'
                  : 'Count your steps for Walking Quest without using GPS (battery efficient).',
              icon: Icons.directions_walk,
              color: step.color,
              isGranted: _activityPermissionGranted,
              onRequest: () async {
                final status = await Permission.activityRecognition.request();
                setState(() {
                  _activityPermissionGranted = status.isGranted;
                });
              },
            ),
            const SizedBox(height: 16),

            // Camera permission
            _buildPermissionCard(
              title: _currentLang == 'id' ? 'Kamera' : 'Camera',
              description: _currentLang == 'id'
                  ? 'Mengambil foto untuk profil dan merekam form latihan yang benar.'
                  : 'Take photos for your profile and record correct exercise form.',
              icon: Icons.camera_alt,
              color: step.color,
              isGranted: _cameraPermissionGranted,
              onRequest: () async {
                final status = await Permission.camera.request();
                setState(() {
                  _cameraPermissionGranted = status.isGranted;
                });
              },
            ),
            const SizedBox(height: 24),

            // Privacy info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock, color: Colors.blue, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _currentLang == 'id'
                          ? 'Semua data disimpan di server aman. Kami tidak menjual atau membagikan data pribadimu.'
                          : 'All data is stored on secure servers. We do not sell or share your personal data.',
                      style: const TextStyle(color: Colors.blue, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesTourStep() {
    final step = _steps[4];
    return _buildStepLayout(
      step: step,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 16),

            // Feature cards
            _buildFeatureCard(
              icon: Icons.flag,
              title: 'Daily Quests',
              description: _currentLang == 'id'
                  ? 'Quest harian personal: Jalan kaki, minum air, dan latihan otot.'
                  : 'Personal daily quests: Walking, hydration, and muscle exercises.',
              color: const Color(0xFF10B981),
            ),
            const SizedBox(height: 12),
            _buildFeatureCard(
              icon: Icons.timer,
              title: 'Focus Check',
              description: _currentLang == 'id'
                  ? 'Pastikan kamu benar-benar fokus saat plank quest.'
                  : 'Ensures you are truly focused during plank quests.',
              color: const Color(0xFFEF4444),
            ),
            const SizedBox(height: 12),
            _buildFeatureCard(
              icon: Icons.people,
              title: 'Shadow Circle',
              description: _currentLang == 'id'
                  ? 'Lihat peringkat kamu di antara teman-teman.'
                  : 'See your ranking among friends.',
              color: const Color(0xFFEC4899),
            ),
            const SizedBox(height: 12),
            _buildFeatureCard(
              icon: Icons.local_fire_department,
              title: 'Streak System',
              description: _currentLang == 'id'
                  ? 'Jangan patah semangat! Jaga streakmu setiap hari.'
                  : "Don't lose momentum! Keep your streak every day.",
              color: const Color(0xFFF97316),
            ),
            const SizedBox(height: 12),
            _buildFeatureCard(
              icon: Icons.trending_up,
              title: 'Rank System',
              description: _currentLang == 'id'
                  ? 'Naik rank dari E ke S dan jadi National Legend!'
                  : 'Climb ranks from E to S and become a National Legend!',
              color: const Color(0xFF8B5CF6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadyStep() {
    final step = _steps[5];
    return _buildStepLayout(
      step: step,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Celebration animation
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 800),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: child,
              );
            },
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    step.color.withOpacity(0.5),
                    step.color.withOpacity(0.2),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: step.color.withOpacity(0.3),
                    border: Border.all(color: step.color, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: step.color.withOpacity(0.6),
                        blurRadius: 40,
                        spreadRadius: 15,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.emoji_events,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 48),
          Text(
            _currentLang == 'id' ? step.titleId : step.titleEn,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: step.color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _currentLang == 'id' ? step.descriptionId : step.descriptionEn,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white70,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),

          // Quick tips
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF111111),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: step.color.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentLang == 'id' ? 'Tips untuk pemula:' : 'Tips for beginners:',
                  style: TextStyle(
                    color: step.color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _buildTipItem(Icons.water_drop, _currentLang == 'id'
                    ? 'Mulai dari quest mudah dulu'
                    : 'Start with easy quests first'),
                _buildTipItem(Icons.schedule, _currentLang == 'id'
                    ? 'Lakukan quest di waktu yang sama setiap hari'
                    : 'Do quests at the same time every day'),
                _buildTipItem(Icons.group, _currentLang == 'id'
                    ? 'Tambahkan teman untuk semangat bersama'
                    : 'Add friends for mutual motivation'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.white54, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // ========== HELPER WIDGETS ==========

  Widget _buildStepLayout({required OnboardingStep step, required Widget child}) {
    return Column(
      children: [
        // Step header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: step.color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(step.icon, color: step.color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentLang == 'id' ? step.titleId : step.titleEn,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: step.color,
                      ),
                    ),
                    Text(
                      _currentLang == 'id' ? step.subtitleId : step.subtitleEn,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Step content
        Expanded(child: child),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required Color color,
    TextInputType? keyboardType,
    String? suffix,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
            ),
            if (isRequired)
              Text(
                ' *',
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white),
          onChanged: (value) => setState(() {}),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF111111),
            prefixIcon: Icon(icon, color: color),
            suffixText: suffix,
            suffixStyle: const TextStyle(color: Colors.white54),
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white30),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: color),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker(Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _currentLang == 'id' ? 'Tanggal Lahir' : 'Birth Date',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _birthDate ?? DateTime(2000, 1, 1),
              firstDate: DateTime(1940),
              lastDate: DateTime.now().subtract(const Duration(days: 365 * 10)),
              builder: (context, child) {
                return Theme(
                  data: ThemeData.dark().copyWith(
                    colorScheme: ColorScheme.dark(
                      primary: color,
                      surface: const Color(0xFF111111),
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              setState(() => _birthDate = picked);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF111111),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _birthDate != null ? color : Colors.grey.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: color),
                const SizedBox(width: 12),
                Text(
                  _birthDate != null
                      ? '${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}'
                      : _currentLang == 'id' ? 'Pilih tanggal' : 'Select date',
                  style: TextStyle(
                    color: _birthDate != null ? Colors.white : Colors.white30,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  description,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required bool isGranted,
    required VoidCallback onRequest,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isGranted ? Colors.green.withOpacity(0.5) : color.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: isGranted ? Colors.green : color, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: isGranted ? Colors.green : Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (isGranted)
                const Icon(Icons.check_circle, color: Colors.green)
              else
                TextButton(
                  onPressed: onRequest,
                  child: Text(
                    _currentLang == 'id' ? 'Izinkan' : 'Allow',
                    style: TextStyle(color: color),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Model for onboarding step
class OnboardingStep {
  final String id;
  final IconData icon;
  final String titleId;
  final String titleEn;
  final String subtitleId;
  final String subtitleEn;
  final String descriptionId;
  final String descriptionEn;
  final Color color;
  final Widget Function() builder;

  OnboardingStep({
    required this.id,
    required this.icon,
    required this.titleId,
    required this.titleEn,
    required this.subtitleId,
    required this.subtitleEn,
    required this.descriptionId,
    required this.descriptionEn,
    required this.color,
    required this.builder,
  });
}