import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'quest_walk.dart';
import 'firebase_options.dart';
import 'services/language_service.dart';
import 'services/user_profile_service.dart';
import 'services/quest_generation_service.dart';
import 'services/sick_mode_service.dart';
import 'screens/main_nav_screen.dart';
import 'screens/daily_quest_screen.dart';
import 'screens/hydration_quest_screen.dart';
import 'screens/sick_mode_screen.dart';
import 'screens/quest_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await LanguageService.loadLanguage();
  runApp(const FitTaskApp());
}

class FitTaskApp extends StatelessWidget {
  const FitTaskApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FitTask',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        primaryColor: const Color(0xFF10B981),
      ),
      locale: LanguageService.getLocale(),
      home: const SplashScreen(),
    );
  }
}

// ==================== 1. SPLASH SCREEN ====================
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String displayName = user.displayName ?? 'Hunter';
        String? username;
        try {
          final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
          if (doc.exists) {
            displayName = doc.data()?['displayName'] ?? displayName;
            username = doc.data()?['username'];
          }
        } catch (e) {
          // ignore
        }
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MainNavScreen(
              uid: user.uid,
              displayName: displayName,
            ),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(colors: [Color(0xFF064E3B), Colors.black], radius: 1.0),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bolt, size: 120, color: Color(0xFF10B981)),
            const SizedBox(height: 30),
            const Text("FITTASK", style: TextStyle(fontSize: 50, fontWeight: FontWeight.bold, letterSpacing: 10, color: Colors.white)),
            const SizedBox(height: 15),
            Text(
              LanguageService.getCurrentLanguage() == 'id'
                  ? "Level Up Your Life,\nJadi Legenda Nasional"
                  : "Level Up Your Life,\nBecome a National Legend",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Color(0xFF10B981), letterSpacing: 2, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== 2. LOGIN / SIGN UP SCREEN ====================
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isLoginMode = true;
  bool isPasswordVisible = false;
  bool isLoading = false;
  String _currentLang = 'id';

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    clientId: '35591984438-qv5rspvb3q3b82er616ov8b6qi3ecmdv.apps.googleusercontent.com',
  );

  @override
  void initState() {
    super.initState();
    _currentLang = LanguageService.getCurrentLanguage();
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF10B981), width: 1),
        ),
        title: Row(
          children: [
            const Icon(Icons.language, color: Color(0xFF10B981)),
            const SizedBox(width: 8),
            Text(
              _currentLang == 'id' ? 'Pilih Bahasa' : 'Select Language',
              style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLanguageOption('id', 'Bahasa Indonesia', '🇮🇩'),
            const SizedBox(height: 8),
            _buildLanguageOption('en', 'English', '🇺🇸'),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(String code, String name, String flag) {
    final isSelected = _currentLang == code;
    return InkWell(
      onTap: () async {
        await LanguageService.setLanguage(code);
        setState(() => _currentLang = code);
        if (mounted) Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF10B981).withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF10B981) : Colors.grey.shade700,
          ),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  color: isSelected ? const Color(0xFF10B981) : Colors.white,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Color(0xFF10B981)),
          ],
        ),
      ),
    );
  }

  // --- Fungsi Sign Up dengan Email Verifikasi ---
  Future<void> _signUpWithEmail() async {
    setState(() => isLoading = true);
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final name = _nameController.text.trim();
      final username = _usernameController.text.trim();

      if (email.isEmpty || password.isEmpty || name.isEmpty) {
        _showErrorDialog(
          _currentLang == 'id' ? 'Data Tidak Lengkap' : 'Incomplete Data',
          _currentLang == 'id' ? 'Harap isi semua field!' : 'Please fill all fields!'
        );
        setState(() => isLoading = false);
        return;
      }

      // Validate username
      if (username.isEmpty) {
        _showErrorDialog(
          _currentLang == 'id' ? 'Username Diperlukan' : 'Username Required',
          _currentLang == 'id'
              ? 'Harap masukkan username!'
              : 'Please enter a username!'
        );
        setState(() => isLoading = false);
        return;
      }

      if (username.length < 3 || username.length > 20) {
        _showErrorDialog(
          _currentLang == 'id' ? 'Username Tidak Valid' : 'Invalid Username',
          _currentLang == 'id'
              ? 'Username harus 3-20 karakter!'
              : 'Username must be 3-20 characters!'
        );
        setState(() => isLoading = false);
        return;
      }

      if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) {
        _showErrorDialog(
          _currentLang == 'id' ? 'Username Tidak Valid' : 'Invalid Username',
          _currentLang == 'id'
              ? 'Username hanya boleh huruf, angka, dan underscore!'
              : 'Username can only contain letters, numbers, and underscore!'
        );
        setState(() => isLoading = false);
        return;
      }

      // Check if username is available
      final usernameAvailable = await _checkUsernameAvailability(username);
      if (!usernameAvailable) {
        _showErrorDialog(
          _currentLang == 'id' ? 'Username Terpakai' : 'Username Taken',
          _currentLang == 'id'
              ? 'Username "$username" sudah digunakan. Coba yang lain.'
              : 'Username "$username" is already taken. Try another.'
        );
        setState(() => isLoading = false);
        return;
      }

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user!;

      await user.updateDisplayName(name);

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'displayName': name,
        'username': username,
        'usernameLower': username.toLowerCase(),
        'email': email,
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

      await user.sendEmailVerification();

      _showInfoDialog(
        _currentLang == 'id' ? 'Verifikasi Email' : 'Email Verification',
        _currentLang == 'id'
            ? 'Pendaftaran berhasil! ✨\n\n'
                'Tautan verifikasi telah dikirim ke:\n'
                '$email\n\n'
                'Silakan cek kotak masuk email Anda (termasuk folder Spam)\n'
                'untuk mengaktifkan akun FitTask Anda.\n\n'
                'Setelah verifikasi, silakan login kembali.'
            : 'Registration successful! ✨\n\n'
                'Verification link sent to:\n'
                '$email\n\n'
                'Please check your inbox (including Spam folder)\n'
                'to activate your FitTask account.\n\n'
                'After verification, please login again.',
      );

      _emailController.clear();
      _passwordController.clear();
      _nameController.clear();
      _usernameController.clear();

    } on FirebaseAuthException catch (e) {
      String message = _currentLang == 'id' ? 'Terjadi kesalahan.' : 'An error occurred.';
      if (e.code == 'email-already-in-use') {
        message = _currentLang == 'id'
            ? 'Email ini sudah digunakan. Silakan gunakan email lain atau login.'
            : 'This email is already in use. Please use another email or login.';
      } else if (e.code == 'weak-password') {
        message = _currentLang == 'id'
            ? 'Password terlalu lemah. Gunakan minimal 6 karakter.'
            : 'Password too weak. Use at least 6 characters.';
      } else if (e.code == 'invalid-email') {
        message = _currentLang == 'id' ? 'Format email tidak valid.' : 'Invalid email format.';
      } else {
        message = e.message ?? (_currentLang == 'id' ? 'Gagal mendaftar.' : 'Registration failed.');
      }
      _showErrorDialog(_currentLang == 'id' ? 'Sign Up Gagal' : 'Sign Up Failed', message);
    } catch (e) {
      _showErrorDialog(_currentLang == 'id' ? 'Error' : 'Error', e.toString());
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<bool> _checkUsernameAvailability(String username) async {
    try {
      final normalizedUsername = username.toLowerCase().trim();
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('usernameLower', isEqualTo: normalizedUsername)
          .limit(1)
          .get();

      return snapshot.docs.isEmpty;
    } catch (e) {
      debugPrint('Error checking username: $e');
      return true; // Allow if check fails
    }
  }

  // --- Fungsi Login Email ---
  Future<void> _signInWithEmail() async {
    setState(() => isLoading = true);
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      if (email.isEmpty || password.isEmpty) {
        _showErrorDialog(
          _currentLang == 'id' ? 'Data Tidak Lengkap' : 'Incomplete Data',
          _currentLang == 'id' ? 'Harap isi email dan password!' : 'Please enter email and password!'
        );
        setState(() => isLoading = false);
        return;
      }

      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user!;

      if (!user.emailVerified) {
        await user.sendEmailVerification();
        await _auth.signOut();
        _showInfoDialog(
          _currentLang == 'id' ? 'Email Belum Diverifikasi' : 'Email Not Verified',
          _currentLang == 'id'
              ? 'Email Anda belum diverifikasi.\n\n'
                  'Kami telah mengirim ulang tautan verifikasi ke:\n'
                  '$email\n\n'
                  'Silakan cek kotak masuk Anda (termasuk folder Spam).'
              : 'Your email is not yet verified.\n\n'
                  'We have resent the verification link to:\n'
                  '$email\n\n'
                  'Please check your inbox (including Spam folder).',
        );
        setState(() => isLoading = false);
        return;
      }

      String displayName = user.displayName ?? 'Hunter';
      String? username;
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists) {
          displayName = doc.data()?['displayName'] ?? displayName;
          username = doc.data()?['username'];
        }
      } catch (e) {
        // ignore
      }

      _navigateToHome(user.uid, displayName, username: username);
    } on FirebaseAuthException catch (e) {
      String message = _currentLang == 'id' ? 'Terjadi kesalahan.' : 'An error occurred.';
      if (e.code == 'user-not-found') {
        message = _currentLang == 'id'
            ? 'Akun dengan email ini tidak ditemukan.'
            : 'No account found with this email.';
      } else if (e.code == 'wrong-password') {
        message = _currentLang == 'id'
            ? 'Password salah. Silakan coba lagi.'
            : 'Wrong password. Please try again.';
      } else if (e.code == 'invalid-email') {
        message = _currentLang == 'id' ? 'Format email tidak valid.' : 'Invalid email format.';
      } else if (e.code == 'user-disabled') {
        message = _currentLang == 'id' ? 'Akun ini telah dinonaktifkan.' : 'This account has been disabled.';
      } else {
        message = e.message ?? (_currentLang == 'id' ? 'Gagal login.' : 'Login failed.');
      }
      _showErrorDialog(_currentLang == 'id' ? 'Login Gagal' : 'Login Failed', message);
    } catch (e) {
      _showErrorDialog(_currentLang == 'id' ? 'Error' : 'Error', e.toString());
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // --- Fungsi Reset Password (Lupa Password) ---
  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _showErrorDialog(
        _currentLang == 'id' ? 'Email Kosong' : 'Empty Email',
        _currentLang == 'id'
            ? 'Masukkan alamat email Anda terlebih dahulu.'
            : 'Please enter your email address first.'
      );
      return;
    }

    setState(() => isLoading = true);
    try {
      await _auth.sendPasswordResetEmail(email: email);
      _showInfoDialog(
        _currentLang == 'id' ? 'Reset Password' : 'Reset Password',
        _currentLang == 'id'
            ? 'Tautan reset password telah dikirim ke:\n'
                '$email\n\n'
                'Silakan cek kotak masuk email Anda (termasuk folder Spam)\n'
                'untuk membuat password baru.'
            : 'Password reset link sent to:\n'
                '$email\n\n'
                'Please check your inbox (including Spam folder)\n'
                'to create a new password.',
      );
    } on FirebaseAuthException catch (e) {
      String message = _currentLang == 'id' ? 'Terjadi kesalahan.' : 'An error occurred.';
      if (e.code == 'user-not-found') {
        message = _currentLang == 'id' ? 'Tidak ada akun dengan email ini.' : 'No account with this email.';
      } else if (e.code == 'invalid-email') {
        message = _currentLang == 'id' ? 'Format email tidak valid.' : 'Invalid email format.';
      } else {
        message = e.message ?? (_currentLang == 'id' ? 'Gagal mengirim email reset password.' : 'Failed to send password reset email.');
      }
      _showErrorDialog(_currentLang == 'id' ? 'Reset Password Gagal' : 'Reset Password Failed', message);
    } catch (e) {
      _showErrorDialog(_currentLang == 'id' ? 'Error' : 'Error', e.toString());
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // --- Fungsi Google Sign-In ---
  Future<void> _signInWithGoogle() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        if (mounted) setState(() => isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCred = await _auth.signInWithCredential(credential);
      final User user = userCred.user!;

      final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final doc = await docRef.get();
      if (!doc.exists) {
        final displayName = user.displayName ?? 'Hunter';
        await docRef.set({
          'displayName': displayName,
          'email': user.email ?? '',
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

      String displayName = user.displayName ?? 'Hunter';
      String? username;
      if (doc.exists) {
        displayName = doc.data()?['displayName'] ?? displayName;
        username = doc.data()?['username'];
      }

      if (mounted) {
        _navigateToHome(user.uid, displayName, username: username);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String message = _currentLang == 'id' ? 'Terjadi kesalahan autentikasi.' : 'Authentication error occurred.';
        if (e.code == 'account-exists-with-different-credential') {
          message = _currentLang == 'id'
              ? 'Akun dengan email ini sudah terdaftar dengan metode lain.'
              : 'An account with this email already exists with a different method.';
        } else if (e.code == 'invalid-credential') {
          message = _currentLang == 'id' ? 'Kredensial tidak valid. Coba lagi.' : 'Invalid credentials. Try again.';
        } else {
          message = e.message ?? (_currentLang == 'id' ? 'Gagal login dengan Google.' : 'Failed to login with Google.');
        }
        _showErrorDialog(_currentLang == 'id' ? 'Google Sign-In Gagal' : 'Google Sign-In Failed', message);
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog(_currentLang == 'id' ? 'Google Sign-In Gagal' : 'Google Sign-In Failed', e.toString());
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // --- Navigasi ke Home ---
  void _navigateToHome(String uid, String displayName, {String? username}) {
    // Tampilkan welcome popup dengan animasi
    _showWelcomeDialog(uid, displayName, username: username);
  }

  // --- Welcome Dialog dengan tema Game ---
  void _showWelcomeDialog(String uid, String displayName, {String? username}) {
    // Generate random welcome message
    final welcomeMessages = _currentLang == 'id'
        ? [
            'Welcome back, $displayName!',
            'We got you, Hunter! Ready for the quest?',
            'System Online. Welcome, $displayName!',
            'Authorization Confirmed. Let\'s go, Hunter!',
            '$displayName detected. Quest awaits!',
          ]
        : [
            'Welcome back, $displayName!',
            'We got you, Hunter! Ready for the quest?',
            'System Online. Welcome, $displayName!',
            'Authorization Confirmed. Let\'s go, Hunter!',
            '$displayName detected. Quest awaits!',
          ];

    final randomMessage = welcomeMessages[DateTime.now().millisecond % welcomeMessages.length];

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Welcome',
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (context, animation, secondaryAnimation) {
        return _WelcomePopup(
          message: randomMessage,
          username: username,
          onStart: () {
            Navigator.pop(context); // Close dialog
            // Navigate to main screen
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => MainNavScreen(uid: uid, displayName: displayName),
              ),
            );
          },
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
            ),
            child: child,
          ),
        );
      },
    );
  }

  // --- Dialog Error ---
  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.redAccent, width: 1),
        ),
        title: Text(
          title,
          style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Color(0xFF10B981))),
          ),
        ],
      ),
    );
  }

  // --- Dialog Informasi ---
  void _showInfoDialog(String title, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF10B981), width: 1),
        ),
        title: Text(
          title,
          style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold),
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (!isLoginMode) {
                setState(() => isLoginMode = true);
              }
            },
            child: const Text('OK', style: TextStyle(color: Color(0xFF10B981))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Language selector
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(Icons.language, color: Color(0xFF10B981), size: 28),
                    onPressed: _showLanguageDialog,
                  ),
                ),
                const SizedBox(height: 10),
                const Icon(Icons.shield, size: 80, color: Color(0xFF10B981)),
                const SizedBox(height: 20),
                Text(
                  isLoginMode
                      ? (_currentLang == 'id' ? "SYSTEM LOGIN" : "SYSTEM LOGIN")
                      : (_currentLang == 'id' ? "DAFTAR HUNTER" : "HUNTER REGISTRATION"),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2),
                ),
                const SizedBox(height: 10),
                Text(
                  isLoginMode
                      ? (_currentLang == 'id'
                          ? "Selamat datang kembali, Hunter. Masukkan kredensial Anda."
                          : "Welcome back, Hunter. Enter your credentials.")
                      : (_currentLang == 'id'
                          ? "Inisialisasi profil Anda untuk bergabung."
                          : "Initialize your profile to join the system."),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 40),

                // Field Nama (hanya saat Sign Up)
                if (!isLoginMode) ...[
                  _buildTextField(
                    controller: _nameController,
                    icon: Icons.person,
                    hint: _currentLang == 'id' ? "Nama Hunter" : "Hunter Name",
                  ),
                  const SizedBox(height: 15),
                  _buildTextField(
                    controller: _usernameController,
                    icon: Icons.alternate_email,
                    hint: _currentLang == 'id' ? "Username (unik)" : "Username (unique)",
                  ),
                  const SizedBox(height: 15),
                ],

                // Field Email
                _buildTextField(
                  controller: _emailController,
                  icon: Icons.email,
                  hint: _currentLang == 'id' ? "Alamat Email" : "Email Address",
                ),
                const SizedBox(height: 15),

                // Field Password
                _buildTextField(
                  controller: _passwordController,
                  icon: Icons.lock,
                  hint: _currentLang == 'id' ? "Password" : "Password",
                  isPassword: true,
                ),
                const SizedBox(height: 8),

                // Tombol Lupa Password (hanya di mode Login)
                if (isLoginMode) ...[
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: isLoading ? null : _resetPassword,
                      child: Text(
                        _currentLang == 'id' ? 'Lupa Password?' : 'Forgot Password?',
                        style: const TextStyle(
                          color: Color(0xFF10B981),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 10),

                // Tombol Aksi
                isLoading
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
                    : ElevatedButton(
                        onPressed: () {
                          if (isLoginMode) {
                            _signInWithEmail();
                          } else {
                            _signUpWithEmail();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          isLoginMode
                              ? (_currentLang == 'id' ? "MASUK SISTEM" : "ACCESS SYSTEM")
                              : (_currentLang == 'id' ? "INITIALISASI SISTEM" : "INITIALIZE SYSTEM"),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black, letterSpacing: 2),
                        ),
                      ),
                const SizedBox(height: 20),

                // Toggle Login / Sign Up
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isLoginMode
                          ? (_currentLang == 'id' ? "Tidak punya akun? " : "Don't have an account? ")
                          : (_currentLang == 'id' ? "Sudah Hunter? " : "Already a Hunter? "),
                      style: const TextStyle(color: Colors.grey),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => isLoginMode = !isLoginMode),
                      child: Text(
                        isLoginMode
                            ? (_currentLang == 'id' ? "Daftar" : "Sign Up")
                            : (_currentLang == 'id' ? "Masuk" : "Log In"),
                        style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),

                // Divider OR
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.white24)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        _currentLang == 'id' ? "ATAU SAMBUNGKAN DENGAN" : "OR CONNECT WITH",
                        style: const TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 1),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.white24)),
                  ],
                ),
                const SizedBox(height: 25),

                // Tombol Google Full Width
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: isLoading ? null : _signInWithGoogle,
                    icon: const Icon(Icons.g_mobiledata, color: Colors.white, size: 28),
                    label: Text(
                      _currentLang == 'id' ? "Google" : "Google",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFdb4437),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword && !isPasswordVisible,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFF111111),
        prefixIcon: Icon(icon, color: const Color(0xFF10B981)),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
                onPressed: () => setState(() => isPasswordVisible = !isPasswordVisible),
              )
            : null,
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white30),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF10B981))),
      ),
    );
  }
}

// ==================== WELCOME POPUP WIDGET ====================
class _WelcomePopup extends StatefulWidget {
  final String message;
  final String? username;
  final VoidCallback onStart;

  const _WelcomePopup({required this.message, this.username, required this.onStart});

  @override
  State<_WelcomePopup> createState() => _WelcomePopupState();
}

class _WelcomePopupState extends State<_WelcomePopup> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF10B981).withOpacity(0.3),
                Colors.black.withOpacity(0.9),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF10B981), width: 2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withOpacity(0.5),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated icon
              ScaleTransition(
                scale: _pulseAnimation,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF10B981),
                        const Color(0xFF064E3B),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.bolt,
                    color: Colors.white,
                    size: 50,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // System text
              Text(
                'SYSTEM',
                style: TextStyle(
                  color: const Color(0xFF10B981).withOpacity(0.7),
                  fontSize: 12,
                  letterSpacing: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // Welcome message
              AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnimation.value,
                    child: Column(
                      children: [
                        Text(
                          widget.message,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        if (widget.username != null && widget.username!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            '@${widget.username}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: const Color(0xFF10B981).withOpacity(0.7),
                              fontSize: 14,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),

              // Start button
              GestureDetector(
                onTap: widget.onStart,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withOpacity(0.4),
                        blurRadius: 15,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'START QUEST',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== 4. HOME SCREEN ====================
class HomeScreen extends StatefulWidget {
  final String uid;
  final String displayName;

  const HomeScreen({super.key, required this.uid, required this.displayName});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late String playerName;
  String rank = "E - Awakening";
  int level = 1;
  int currentExp = 0;
  int expToNextLevel = 100;
  int totalExp = 0;
  int streak = 0;

  // Health data
  double? heightCm;
  double? weightKg;
  DateTime? birthDate;
  double? bmi;
  int? age;
  double? dailyWaterNeed;

  bool isAiLoading = false;
  bool isDbLoading = true;
  String _currentLang = 'id';

  // Daily EXP tracking
  int dailyExpEarned = 0;
  int dailyExpLimit = 500;

  // Quest data
  List<DailyQuest> dailyQuests = [];
  Map<String, QuestProgress> questProgress = {};
  bool isQuestLoading = true;

  // Sick Mode
  SickModeData? _sickModeData;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    playerName = widget.displayName;
    _currentLang = LanguageService.getCurrentLanguage();
    _loadHunterData();
    _loadDailyQuests();
    _checkSickMode();
  }

  Future<void> _checkSickMode() async {
    try {
      final data = await SickModeService.getSickModeData(widget.uid);
      if (mounted) {
        setState(() => _sickModeData = data);
      }
    } catch (e) {
      debugPrint('Error checking sick mode: $e');
    }
  }

  void _openSickMode() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SickModeScreen(uid: widget.uid),
      ),
    ).then((_) {
      _checkSickMode();
      _loadDailyQuests();
    });
  }

  void _refreshLanguage() {
    setState(() {
      _currentLang = LanguageService.getCurrentLanguage();
    });
  }

  Future<void> _loadHunterData() async {
    try {
      final doc = await _firestore.collection('users').doc(widget.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          rank = data['rank'] ?? 'E - Awakening';
          level = data['level'] ?? 1;
          currentExp = data['currentExp'] ?? 0;
          expToNextLevel = data['expToNextLevel'] ?? 100;
          totalExp = data['totalExp'] ?? 0;
          streak = data['streak'] ?? 0;
          playerName = data['displayName'] ?? playerName;
          _currentLang = data['language'] ?? _currentLang;

          // Load health data
          heightCm = data['heightCm']?.toDouble();
          weightKg = data['weightKg']?.toDouble();
          if (data['birthDate'] is Timestamp) {
            birthDate = (data['birthDate'] as Timestamp).toDate();
          }

          // Calculate derived data
          if (heightCm != null && weightKg != null) {
            bmi = UserProfileService.calculateBMI(heightCm!, weightKg!);
          }
          if (birthDate != null) {
            age = UserProfileService.calculateAge(birthDate!);
          }
          if (weightKg != null) {
            dailyWaterNeed = UserProfileService.calculateDailyWaterNeed(weightKg!);
          }

          // Daily EXP limit
          dailyExpLimit = UserProfileService.getDailyExpLimit(level);

          isDbLoading = false;
        });
      } else {
        await _firestore.collection('users').doc(widget.uid).set({
          'displayName': playerName,
          'rank': rank,
          'level': level,
          'currentExp': currentExp,
          'expToNextLevel': expToNextLevel,
          'totalExp': totalExp,
          'streak': streak,
          'restModeActive': false,
          'language': _currentLang,
          'createdAt': FieldValue.serverTimestamp(),
        });
        setState(() => isDbLoading = false);
      }
    } catch (e) {
      debugPrint('Error load data: $e');
      setState(() => isDbLoading = false);
    }
  }

  Future<void> _loadDailyQuests() async {
    try {
      // Create profile data for quest generation
      final profile = UserProfileData(
        uid: widget.uid,
        displayName: playerName,
        rank: rank,
        level: level,
        currentExp: currentExp,
        expToNextLevel: expToNextLevel,
        totalExp: totalExp,
        streak: streak,
        restModeActive: false,
        language: _currentLang,
        heightCm: heightCm,
        weightKg: weightKg,
        birthDate: birthDate,
        bmi: bmi,
        age: age,
        dailyWaterNeedMl: dailyWaterNeed,
      );

      // Generate or load quests
      final quests = await QuestGenerationService.generateDailyQuests(
        uid: widget.uid,
        profile: profile,
      );

      // Load progress
      final progress = await QuestGenerationService.getQuestProgress(widget.uid);

      // Load daily exp
      final dailyExp = await QuestGenerationService.getDailyExpEarned(widget.uid);

      setState(() {
        dailyQuests = quests;
        questProgress = progress;
        dailyExpEarned = dailyExp;
        isQuestLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading quests: $e');
      // Fallback to default quests
      _loadDefaultQuests();
      setState(() => isQuestLoading = false);
    }
  }

  void _loadDefaultQuests() {
    final waterNeed = weightKg != null ? (weightKg! * 32.5).toInt() : 2000;
    final walkTarget = 5000 + (level * 500);

    dailyQuests = [
      DailyQuest(
        id: 'daily_walk',
        titleId: 'Jalan Kaki $walkTarget Langkah',
        titleEn: 'Walk $walkTarget Steps',
        descriptionId: 'Selesaikan target langkah kaki harian',
        descriptionEn: 'Complete your daily step target',
        type: QuestType.walk,
        difficulty: 'medium',
        target: walkTarget,
        unit: 'steps',
        expReward: 50,
        exerciseId: null,
        sets: null,
        reps: null,
        icon: Icons.directions_walk,
      ),
      DailyQuest(
        id: 'daily_water',
        titleId: 'Minum Air $waterNeed ml',
        titleEn: 'Drink $waterNeed ml Water',
        descriptionId: 'Penuhi kebutuhan hidrasi harian',
        descriptionEn: 'Meet your daily hydration needs',
        type: QuestType.water,
        difficulty: 'easy',
        target: waterNeed,
        unit: 'ml',
        expReward: 20,
        exerciseId: null,
        sets: null,
        reps: null,
        icon: Icons.water_drop,
      ),
      DailyQuest(
        id: 'daily_exercise',
        titleId: 'Latihan Otot Perut',
        titleEn: 'Core Exercise',
        descriptionId: 'Kuatkan otot core dengan crunch',
        descriptionEn: 'Strengthen your core with crunches',
        type: QuestType.exercise,
        difficulty: 'medium',
        target: 30,
        unit: 'reps',
        expReward: 35,
        exerciseId: 'crunch',
        sets: 3,
        reps: 10,
        icon: Icons.fitness_center,
      ),
    ];
  }

  Future<void> _saveHunterDataToCloud() async {
    await _firestore.collection('users').doc(widget.uid).set({
      'level': level,
      'currentExp': currentExp,
      'expToNextLevel': expToNextLevel,
      'totalExp': totalExp,
      'rank': rank,
      'streak': streak,
      'displayName': playerName,
    }, SetOptions(merge: true));
  }

  Future<void> triggerSystemMessage() async {
    setState(() => isAiLoading = true);
    try {
      const apiKey = String.fromEnvironment('GEMINI_API_KEY'); //isi api key disini
      final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);
      final prompt = _currentLang == 'id'
          ? "Kamu adalah 'The System', AI pengawas RPG. Berikan 1 pesan peringatan/motivasi singkat untuk Hunter $playerName. Maks 2 kalimat."
          : "You are 'The System', an RPG supervisor AI. Give 1 brief warning/motivational message for Hunter $playerName. Max 2 sentences.";
      final response = await model.generateContent([Content.text(prompt)]);
      setState(() => isAiLoading = false);
      _showSystemDialog(response.text ?? (_currentLang == 'id' ? "Sistem gagal merespon." : "System failed to respond."));
    } catch (e) {
      setState(() => isAiLoading = false);
      _showSystemDialog(_currentLang == 'id' ? "Koneksi ke Sistem Pusat terputus." : "Connection to Central System lost.");
    }
  }

  void _showSystemDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFF10B981))),
        title: Text(
          _currentLang == 'id' ? "PESAN SISTEM" : "SYSTEM MESSAGE",
          style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold),
        ),
        content: Text(message, style: const TextStyle(color: Colors.white, fontStyle: FontStyle.italic)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              _currentLang == 'id' ? "Terverifikasi" : "Acknowledge",
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  void addExp(int amount) {
    // Check daily limit
    if (dailyExpEarned + amount > dailyExpLimit) {
      _showExpLimitDialog();
      return;
    }

    setState(() {
      currentExp += amount;
      totalExp += amount;
      dailyExpEarned += amount;
      if (currentExp >= expToNextLevel) {
        level++;
        currentExp -= expToNextLevel;
        expToNextLevel = (expToNextLevel * 1.5).toInt();
        dailyExpLimit = UserProfileService.getDailyExpLimit(level);
        _updateRank();
      }
    });
    _saveHunterDataToCloud();
  }

  void _updateRank() {
    if (totalExp >= 75000) rank = 'S - National Legend';
    else if (totalExp >= 35000) rank = 'A - Master';
    else if (totalExp >= 15000) rank = 'B - Elite';
    else if (totalExp >= 5000) rank = 'C - Hardy';
    else if (totalExp >= 1000) rank = 'D - Novice';
    else rank = 'E - Awakening';
  }

  void _showExpLimitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.orange),
        ),
        title: Row(
          children: [
            const Icon(Icons.warning, color: Colors.orange),
            const SizedBox(width: 8),
            Text(
              _currentLang == 'id' ? 'Batas EXP Tercapai' : 'EXP Limit Reached',
              style: const TextStyle(color: Colors.orange),
            ),
          ],
        ),
        content: Text(
          _currentLang == 'id'
              ? 'Batas EXP harian telah tercapai!\n\nIstirahat dulu dan lanjutkan besok.'
              : 'Daily EXP limit reached!\n\nRest and continue tomorrow.',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              _currentLang == 'id' ? 'OK' : 'OK',
              style: const TextStyle(color: Color(0xFF10B981)),
            ),
          ),
        ],
      ),
    );
  }

  void _openDailyQuests() {
    final profile = UserProfileData(
      uid: widget.uid,
      displayName: playerName,
      rank: rank,
      level: level,
      currentExp: currentExp,
      expToNextLevel: expToNextLevel,
      totalExp: totalExp,
      streak: streak,
      restModeActive: false,
      language: _currentLang,
      heightCm: heightCm,
      weightKg: weightKg,
      birthDate: birthDate,
      bmi: bmi,
      age: age,
      dailyWaterNeedMl: dailyWaterNeed,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DailyQuestScreen(
          uid: widget.uid,
          profile: profile,
          onQuestComplete: () {
            _loadDailyQuests();
          },
          onExpEarned: (exp) {
            addExp(exp);
          },
        ),
      ),
    ).then((_) {
      _loadDailyQuests();
    });
  }

  void _openExerciseQuests() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuestListScreen(
          uid: widget.uid,
          addExp: addExp,
          refreshHome: () {
            _loadDailyQuests();
          },
        ),
      ),
    );
  }

  bool _isHealthDataComplete() {
    return heightCm != null && heightCm! > 0 &&
           weightKg != null && weightKg! > 0 &&
           birthDate != null;
  }

  @override
  Widget build(BuildContext context) {
    // Show health data warning if not complete
    Widget? healthWarning;
    if (!_isHealthDataComplete()) {
      healthWarning = Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber, color: Colors.orange, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _currentLang == 'id'
                    ? 'Lengkapi data kesehatan di profil untuk quest personal!'
                    : 'Complete health data in profile for personalized quests!',
                style: const TextStyle(color: Colors.orange, fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }

    // Sick Mode Banner
    Widget? sickModeBanner;
    if (_sickModeData != null && _sickModeData!.isActive) {
      final remainingDays = _sickModeData!.remainingDays ?? 0;
      final conditions = _sickModeData!.conditions.map((c) => c.getName(_currentLang)).take(2).join(', ');

      sickModeBanner = GestureDetector(
        onTap: _openSickMode,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.healing, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentLang == 'id' ? 'Mode Terbatas Aktif' : 'Limited Mode Active',
                      style: const TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _currentLang == 'id'
                          ? '$conditions - $remainingDays hari tersisa'
                          : '$conditions - $remainingDays days remaining',
                      style: const TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.orange, size: 20),
            ],
          ),
        ),
      );
    }

    return isDbLoading || isQuestLoading
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
        : Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _currentLang == 'id' ? 'FitTask System' : 'FitTask System',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                    isAiLoading
                        ? const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Color(0xFF10B981), strokeWidth: 2)),
                          )
                        : IconButton(
                            icon: const Icon(Icons.remove_red_eye, color: Color(0xFF10B981), size: 26),
                            onPressed: triggerSystemMessage,
                          ),
                  ],
                ),
                const SizedBox(height: 12),

                // Sick Mode Banner
                if (sickModeBanner != null) sickModeBanner,

                // Health Warning Banner
                if (healthWarning != null) healthWarning,

                // Profile Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111111),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3), width: 2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(playerName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                          Text(
                            _currentLang == 'id' ? "Lv. $level" : "Lv. $level",
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _currentLang == 'id' ? "Rank: $rank" : "Rank: $rank",
                        style: const TextStyle(color: Colors.amber, fontStyle: FontStyle.italic),
                      ),
                      const SizedBox(height: 20),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: currentExp / expToNextLevel,
                          minHeight: 10,
                          backgroundColor: Colors.white10,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _currentLang == 'id' ? "EXP: $currentExp / $expToNextLevel" : "EXP: $currentExp / $expToNextLevel",
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          Text(
                            _currentLang == 'id'
                                ? 'Harian: $dailyExpEarned / $dailyExpLimit'
                                : 'Daily: $dailyExpEarned / $dailyExpLimit',
                            style: TextStyle(
                              fontSize: 12,
                              color: dailyExpEarned >= dailyExpLimit ? Colors.orange : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Health Data Summary (if complete)
                if (_isHealthDataComplete() && bmi != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF111111),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMiniStat(Icons.monitor_heart, 'BMI', bmi!.toStringAsFixed(1)),
                        _buildMiniStat(Icons.water_drop, _currentLang == 'id' ? 'Air' : 'Water',
                            '${dailyWaterNeed?.toStringAsFixed(0)} ml'),
                        _buildMiniStat(Icons.cake, _currentLang == 'id' ? 'Usia' : 'Age', '$age'),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // Daily Quests Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _currentLang == 'id' ? "Daily Quests" : "Daily Quests",
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white70),
                    ),
                    ElevatedButton.icon(
                      onPressed: _openDailyQuests,
                      icon: const Icon(Icons.auto_awesome, size: 18),
                      label: Text(
                        _currentLang == 'id' ? "Quest Harian" : "Daily Quests",
                        style: const TextStyle(fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981).withOpacity(0.2),
                        foregroundColor: const Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Quick Quest Buttons
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildQuickQuestChip(
                      icon: Icons.directions_walk,
                      label: _currentLang == 'id' ? "Jalan" : "Walk",
                      color: Colors.blue,
                      onTap: () {
                        final walkQuest = dailyQuests.where((q) => q.type == QuestType.walk).firstOrNull;
                        if (walkQuest != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => QuestWalkScreen(
                                uid: widget.uid,
                                targetSteps: walkQuest.target,
                                expReward: walkQuest.expReward,
                                questId: walkQuest.id,
                                onSuccess: () {
                                  addExp(walkQuest.expReward);
                                  QuestGenerationService.addExpToHistory(
                                    uid: widget.uid,
                                    amount: walkQuest.expReward,
                                    source: walkQuest.titleId,
                                  );
                                  _loadDailyQuests();
                                },
                              ),
                            ),
                          );
                        }
                      },
                    ),
                    _buildQuickQuestChip(
                      icon: Icons.water_drop,
                      label: _currentLang == 'id' ? "Air" : "Water",
                      color: Colors.cyan,
                      onTap: () {
                        final waterQuest = dailyQuests.where((q) => q.type == QuestType.water).firstOrNull;
                        if (waterQuest != null && weightKg != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => HydrationQuestScreen(
                                uid: widget.uid,
                                dailyTargetMl: (weightKg! * 32.5).toInt(),
                                expReward: waterQuest.expReward,
                                questId: waterQuest.id,
                                onSuccess: () {
                                  addExp(waterQuest.expReward);
                                  _loadDailyQuests();
                                },
                              ),
                            ),
                          );
                        }
                      },
                    ),
                    _buildQuickQuestChip(
                      icon: Icons.fitness_center,
                      label: _currentLang == 'id' ? "Latihan" : "Exercise",
                      color: Colors.orange,
                      onTap: _openExerciseQuests,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Quest Progress Summary
                Expanded(
                  child: ListView.builder(
                    itemCount: dailyQuests.length,
                    itemBuilder: (context, index) {
                      final quest = dailyQuests[index];
                      final isDone = questProgress[quest.id]?.isCompleted ?? false;
                      final title = _currentLang == 'id' ? quest.titleId : quest.titleEn;

                      return Card(
                        color: isDone ? Colors.black : const Color(0xFF111111),
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: isDone ? Colors.transparent : const Color(0xFF10B981).withOpacity(0.2)),
                        ),
                        child: ListTile(
                          leading: Icon(quest.icon, color: isDone ? Colors.grey : const Color(0xFF10B981)),
                          title: Text(
                            title,
                            style: TextStyle(
                              decoration: isDone ? TextDecoration.lineThrough : null,
                              color: isDone ? Colors.grey : Colors.white,
                              fontSize: 14,
                            ),
                          ),
                          trailing: isDone
                              ? const Icon(Icons.check_circle, color: Colors.green)
                              : Text(
                                  '+${quest.expReward} EXP',
                                  style: const TextStyle(color: Color(0xFF10B981), fontSize: 12),
                                ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
  }

  Widget _buildMiniStat(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF10B981), size: 20),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
      ],
    );
  }

  Widget _buildQuickQuestChip({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}