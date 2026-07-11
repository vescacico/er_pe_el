import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';

class QuestWalkScreen extends StatefulWidget {
  final String uid;
  final int targetSteps;
  final int expReward;
  final VoidCallback onSuccess;
  final String questId;

  const QuestWalkScreen({
    super.key,
    required this.uid,
    required this.targetSteps,
    required this.expReward,
    required this.onSuccess,
    required this.questId,
  });

  @override
  State<QuestWalkScreen> createState() => _QuestWalkScreenState();
}

class _QuestWalkScreenState extends State<QuestWalkScreen> {
  Stream<StepCount>? _stepCountStream;
  Stream<PedestrianStatus>? _pedestrianStatusStream;
  String _pedestrianStatus = '?';
  
  int _currentSteps = 0;
  int _savedStepCount = 0;
  int _initialAbsoluteSteps = 0;
  bool _isListening = false;
  bool _isCompleted = false;
  bool _isClaiming = false;
  bool _hasPermission = false;
  bool _isLoading = true;
  bool _questAlreadyCompleted = false; // tambahan

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadProgressAndCheck();
  }

  Future<void> _loadProgressAndCheck() async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(widget.uid)
          .collection('quest_progress')
          .doc(widget.questId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        final savedSteps = data['currentSteps'] ?? 0;
        final completed = data['completed'] ?? false;

        // Jika sudah selesai
        if (completed) {
          setState(() {
            _questAlreadyCompleted = true;
            _isLoading = false;
          });
          // Panggil callback agar di HomeScreen quest dianggap selesai
          widget.onSuccess();
          return;
        }

        setState(() {
          _savedStepCount = savedSteps;
          _currentSteps = savedSteps;
          _isLoading = false;
        });

        if (_currentSteps >= widget.targetSteps) {
          _isCompleted = true;
        }
      } else {
        setState(() => _isLoading = false);
      }

      await _checkAndRequestPermission();
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error loading progress: $e');
    }
  }

  Future<void> _saveProgress() async {
    try {
      await _firestore
          .collection('users')
          .doc(widget.uid)
          .collection('quest_progress')
          .doc(widget.questId)
          .set({
        'currentSteps': _currentSteps,
        'targetSteps': widget.targetSteps,
        'lastUpdated': FieldValue.serverTimestamp(),
        'completed': _isCompleted,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving progress: $e');
    }
  }

  Future<void> _checkAndRequestPermission() async {
    PermissionStatus status = await Permission.activityRecognition.status;
    if (status.isGranted) {
      setState(() => _hasPermission = true);
      _initPedometer();
    } else if (status.isDenied || status.isRestricted) {
      PermissionStatus newStatus = await Permission.activityRecognition.request();
      if (newStatus.isGranted) {
        setState(() => _hasPermission = true);
        _initPedometer();
      } else {
        _showPermissionDeniedDialog();
      }
    } else if (status.isPermanentlyDenied) {
      _showPermissionDeniedDialog();
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.redAccent),
        ),
        title: const Text(
          'Izin Diperlukan',
          style: TextStyle(color: Colors.redAccent),
        ),
        content: const Text(
          'Aplikasi membutuhkan izin untuk mengakses sensor langkah kaki.\n\n'
          'Silakan aktifkan izin "Aktivitas fisik" di pengaturan perangkat.',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('OK', style: TextStyle(color: Color(0xFF10B981))),
          ),
        ],
      ),
    );
  }

  void _initPedometer() {
    try {
      _stepCountStream = Pedometer.stepCountStream;
      _stepCountStream!.listen(_onStepCount).onError(_onStepCountError);
      _pedestrianStatusStream = Pedometer.pedestrianStatusStream;
      _pedestrianStatusStream!.listen(_onPedestrianStatus).onError(_onPedestrianStatusError);
    } catch (e) {
      debugPrint('Error init pedometer: $e');
    }
  }

  void _onStepCount(StepCount event) {
    if (!mounted) return;
    setState(() {
      if (!_isListening) {
        _isListening = true;
        _initialAbsoluteSteps = event.steps;
      }
      int delta = event.steps - _initialAbsoluteSteps;
      _currentSteps = _savedStepCount + delta;
      if (_currentSteps < 0) _currentSteps = 0;

      _saveProgress();
      _checkCompletion();
    });
  }

  void _onStepCountError(error) {
    debugPrint('Step count error: $error');
  }

  void _onPedestrianStatus(PedestrianStatus event) {
    if (!mounted) return;
    setState(() {
      _pedestrianStatus = event.status;
    });
  }

  void _onPedestrianStatusError(error) {
    debugPrint('Pedestrian status error: $error');
  }

  void _checkCompletion() {
    if (!_isCompleted && _currentSteps >= widget.targetSteps) {
      _isCompleted = true;
      _saveProgress();
    }
  }

  // --- Tombol CLAIM EXP diklik ---
  void _onClaimPressed() {
    if (_isCompleted) {
      // Progress sudah mencapai target -> klaim EXP
      _claimReward();
    } else {
      // Belum mencapai target -> tampilkan popup
      _showNotCompletedDialog();
    }
  }

  void _showNotCompletedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.orange, width: 1),
        ),
        title: const Text(
          'Quest Belum Selesai',
          style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Target: ${widget.targetSteps} langkah\n'
          'Saat ini: $_currentSteps langkah\n\n'
          'Selesaikan quest terlebih dahulu untuk mendapatkan EXP!',
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

  // --- Klaim EXP ---
  Future<void> _claimReward() async {
    if (_isClaiming) return;
    setState(() => _isClaiming = true);

    try {
      // Tandai selesai di Firestore
      await _firestore
          .collection('users')
          .doc(widget.uid)
          .collection('quest_progress')
          .doc(widget.questId)
          .set({
        'completed': true,
        'currentSteps': _currentSteps,
        'claimedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Update EXP di user profile
      final userDoc = await _firestore.collection('users').doc(widget.uid).get();
      if (userDoc.exists) {
        final data = userDoc.data()!;
        int currentExp = data['currentExp'] ?? 0;
        int totalExp = data['totalExp'] ?? 0;
        int level = data['level'] ?? 1;
        int expToNext = data['expToNextLevel'] ?? 100;

        currentExp += widget.expReward;
        totalExp += widget.expReward;

        while (currentExp >= expToNext) {
          level++;
          currentExp -= expToNext;
          expToNext = (expToNext * 1.5).toInt();
        }

        String rank = _getRank(totalExp);

        await _firestore.collection('users').doc(widget.uid).update({
          'currentExp': currentExp,
          'totalExp': totalExp,
          'level': level,
          'expToNextLevel': expToNext,
          'rank': rank,
        });
      }

      // Panggil callback untuk update HomeScreen
      widget.onSuccess();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Quest selesai! EXP berhasil diklaim!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        Navigator.pop(context); // tutup halaman
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal klaim EXP: $e')),
      );
    } finally {
      setState(() => _isClaiming = false);
    }
  }

  String _getRank(int totalExp) {
    if (totalExp >= 75000) return 'S - National Legend';
    if (totalExp >= 35000) return 'A - Master';
    if (totalExp >= 15000) return 'B - Elite';
    if (totalExp >= 5000) return 'C - Hardy';
    if (totalExp >= 1000) return 'D - Novice';
    return 'E - Awakening';
  }

  @override
  void dispose() {
    _stepCountStream?.drain();
    _pedestrianStatusStream?.drain();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Color(0xFF10B981))),
      );
    }

    if (_questAlreadyCompleted) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Walking Quest', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.black,
          elevation: 0,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, color: Color(0xFF10B981), size: 80),
              SizedBox(height: 16),
              Text(
                'Quest sudah selesai!',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
              Text(
                'Anda sudah menyelesaikan quest ini.',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    final progress = _currentSteps / widget.targetSteps;
    final isTargetReached = _currentSteps >= widget.targetSteps;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Walking Quest', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.directions_walk, size: 80, color: Color(0xFF10B981)),
            const SizedBox(height: 16),
            const Text(
              'WALKING QUEST',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Target: ${widget.targetSteps} langkah',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 30),

            // Status
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _hasPermission
                        ? (_pedestrianStatus == 'walking'
                            ? Icons.directions_walk
                            : Icons.accessibility_new)
                        : Icons.warning_amber_rounded,
                    color: _hasPermission
                        ? (_pedestrianStatus == 'walking'
                            ? const Color(0xFF10B981)
                            : Colors.grey)
                        : Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    !_hasPermission
                        ? '⚠️ Izin sensor belum diberikan'
                        : (_pedestrianStatus == 'walking'
                            ? '🟢 Sedang berjalan...'
                            : '⚪ Belum terdeteksi gerakan'),
                    style: TextStyle(
                      color: !_hasPermission
                          ? Colors.orange
                          : (_pedestrianStatus == 'walking'
                              ? const Color(0xFF10B981)
                              : Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Counter
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isTargetReached
                      ? const Color(0xFF10B981)
                      : Colors.grey.withOpacity(0.2),
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    '$_currentSteps',
                    style: TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.bold,
                      color: isTargetReached
                          ? const Color(0xFF10B981)
                          : Colors.white,
                    ),
                  ),
                  const Text(
                    'LANGKAH',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress > 1.0 ? 1.0 : progress,
                      minHeight: 12,
                      backgroundColor: Colors.white10,
                      color: isTargetReached
                          ? const Color(0xFF10B981)
                          : Colors.amber,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(progress * 100).clamp(0.0, 100.0).toStringAsFixed(1)}%',
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Reward
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF10B981).withOpacity(0.2),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Reward EXP:',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  Text(
                    '+${widget.expReward} EXP',
                    style: const TextStyle(
                      color: Color(0xFF10B981),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // === TOMBOL CLAIM EXP ===
            ElevatedButton(
              onPressed: _isClaiming ? null : _onClaimPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: isTargetReached
                    ? const Color(0xFF10B981)
                    : Colors.grey.shade800,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isClaiming
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      isTargetReached ? 'CLAIM EXP' : 'BELUM SELESAI',
                      style: TextStyle(
                        color: isTargetReached ? Colors.black : Colors.white54,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 2,
                      ),
                    ),
            ),
            const SizedBox(height: 8),
            if (!isTargetReached)
              Text(
                'Selesaikan target untuk mengklaim EXP',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
          ],
        ),
      ),
    );
  }
}