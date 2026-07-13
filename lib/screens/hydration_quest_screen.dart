import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/quest_generation_service.dart';
import '../services/language_service.dart';

class HydrationQuestScreen extends StatefulWidget {
  final String uid;
  final int dailyTargetMl;
  final int expReward;
  final String questId;
  final VoidCallback onSuccess;

  const HydrationQuestScreen({
    super.key,
    required this.uid,
    required this.dailyTargetMl,
    required this.expReward,
    required this.questId,
    required this.onSuccess,
  });

  @override
  State<HydrationQuestScreen> createState() => _HydrationQuestScreenState();
}

class _HydrationQuestScreenState extends State<HydrationQuestScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int _currentIntakeMl = 0;
  bool _isLoading = true;
  bool _isSaving = false;
  String _currentLang = 'id';

  // Predefined glass sizes
  final List<int> _glassSizes = [250, 350, 500, 750, 1000]; // ml

  @override
  void initState() {
    super.initState();
    _currentLang = LanguageService.getCurrentLanguage();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(widget.uid)
          .collection('hydration')
          .doc('today')
          .get();

      if (doc.exists) {
        setState(() {
          _currentIntakeMl = doc.data()?['intakeMl'] ?? 0;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addWater(int ml) async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      _currentIntakeMl += ml;
      if (_currentIntakeMl > widget.dailyTargetMl) {
        _currentIntakeMl = widget.dailyTargetMl;
      }

      await _saveProgress();

      // Check if target reached
      if (_currentIntakeMl >= widget.dailyTargetMl) {
        await _onTargetReached();
      }
    } catch (e) {
      debugPrint('Error adding water: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _removeWater(int ml) async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      _currentIntakeMl -= ml;
      if (_currentIntakeMl < 0) _currentIntakeMl = 0;
      await _saveProgress();
    } catch (e) {
      debugPrint('Error removing water: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _saveProgress() async {
    try {
      await _firestore
          .collection('users')
          .doc(widget.uid)
          .collection('hydration')
          .doc('today')
          .set({
        'intakeMl': _currentIntakeMl,
        'targetMl': widget.dailyTargetMl,
        'date': DateTime.now().toIso8601String().substring(0, 10),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Also update quest progress
      await QuestGenerationService.updateQuestProgress(
        uid: widget.uid,
        questId: widget.questId,
        currentProgress: _currentIntakeMl,
        isCompleted: _currentIntakeMl >= widget.dailyTargetMl,
      );
    } catch (e) {
      debugPrint('Error saving progress: $e');
    }
  }

  Future<void> _onTargetReached() async {
    // Mark quest as completed
    await QuestGenerationService.updateQuestProgress(
      uid: widget.uid,
      questId: widget.questId,
      currentProgress: _currentIntakeMl,
      isCompleted: true,
    );

    // Add to EXP history
    await QuestGenerationService.addExpToHistory(
      uid: widget.uid,
      amount: widget.expReward,
      source: 'Hydration Quest',
    );

    if (mounted) {
      _showCompletionDialog();
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF10B981)),
        ),
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF10B981)),
            const SizedBox(width: 8),
            Text(
              _currentLang == 'id' ? 'TARGET TERCAPAI!' : 'TARGET REACHED!',
              style: const TextStyle(color: Color(0xFF10B981)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.water_drop,
              color: Colors.cyan,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              _currentLang == 'id'
                  ? 'Kamu telah memenuhi kebutuhan air harian!'
                  : 'You have met your daily water needs!',
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.stars, color: Color(0xFF10B981)),
                  const SizedBox(width: 8),
                  Text(
                    '+${widget.expReward} EXP',
                    style: const TextStyle(
                      color: Color(0xFF10B981),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              widget.onSuccess();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
            ),
            child: Text(_currentLang == 'id' ? 'OK' : 'OK'),
          ),
        ],
      ),
    );
  }

  double get _progressPercent {
    return (_currentIntakeMl / widget.dailyTargetMl).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final isTargetReached = _currentIntakeMl >= widget.dailyTargetMl;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(
          _currentLang == 'id' ? 'Quest Hidrasi' : 'Hydration Quest',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
          : SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: screenHeight - MediaQuery.of(context).padding.top - 100,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Water Progress Card
                      _buildProgressCard(isTargetReached),
                      const SizedBox(height: 20),

                      // Quick Add Buttons
                      _buildQuickAddSection(),
                      const SizedBox(height: 20),

                      // Custom Amount
                      _buildCustomAmountSection(),
                      const SizedBox(height: 20),

                      // Tips
                      _buildTipsSection(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildProgressCard(bool isTargetReached) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.cyan.withOpacity(0.2),
            const Color(0xFF111111),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isTargetReached
              ? Colors.green.withOpacity(0.5)
              : Colors.cyan.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          // Water Icon with Progress
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: CircularProgressIndicator(
                  value: _progressPercent,
                  strokeWidth: 8,
                  backgroundColor: Colors.white10,
                  color: Colors.cyan,
                ),
              ),
              Column(
                children: [
                  const Icon(
                    Icons.water_drop,
                    color: Colors.cyan,
                    size: 32,
                  ),
                  Text(
                    '${(_progressPercent * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Current Intake
          Text(
            '$_currentIntakeMl',
            style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: Colors.cyan,
            ),
          ),
          Text(
            _currentLang == 'id' ? 'ml diminum' : 'ml consumed',
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _currentLang == 'id'
                ? 'Target: ${widget.dailyTargetMl} ml'
                : 'Target: ${widget.dailyTargetMl} ml',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),

          if (isTargetReached) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _currentLang == 'id'
                        ? 'Target Tercapai!'
                        : 'Target Reached!',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickAddSection() {
    final isTargetReached = _currentIntakeMl >= widget.dailyTargetMl;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _currentLang == 'id'
                  ? 'Tambah Air Cepat'
                  : 'Quick Add Water',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (isTargetReached)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock, color: Colors.green, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      _currentLang == 'id' ? 'Selesai' : 'Completed',
                      style: const TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: _glassSizes.map((size) {
            return _buildGlassButton(size, isTargetReached);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCustomAmountSection() {
    final isTargetReached = _currentIntakeMl >= widget.dailyTargetMl;
    final isDisabled = isTargetReached || _isSaving;

    return Column(
      children: [
        Text(
          _currentLang == 'id'
              ? 'Atau masukkan jumlah lain'
              : 'Or enter custom amount',
          style: TextStyle(
            color: isDisabled ? Colors.grey : Colors.grey,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: isDisabled ? null : () => _removeWater(100),
              icon: Icon(
                Icons.remove_circle_outline,
                color: isDisabled ? Colors.grey : Colors.red,
                size: 32,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 100,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDisabled ? Colors.grey.withOpacity(0.3) : Colors.cyan.withOpacity(0.3)
                ),
              ),
              child: Text(
                '$_currentIntakeMl ml',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDisabled ? Colors.grey : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              onPressed: isDisabled ? null : () => _addWater(100),
              icon: Icon(
                Icons.add_circle_outline,
                color: isDisabled ? Colors.grey : Colors.cyan,
                size: 32,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTipsSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.lightbulb_outline,
            color: Colors.amber,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _currentLang == 'id'
                  ? 'Tips: Minum air secara teratur sepanjang hari lebih baik daripada minum banyak sekaligus.'
                  : 'Tip: Drinking water regularly throughout the day is better than drinking a lot at once.',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassButton(int ml, bool isLocked) {
    IconData icon;
    String label;

    if (ml <= 250) {
      icon = Icons.local_cafe;
      label = '$ml ml';
    } else if (ml <= 350) {
      icon = Icons.coffee;
      label = '$ml ml';
    } else if (ml <= 500) {
      icon = Icons.local_drink;
      label = '$ml ml';
    } else if (ml <= 750) {
      icon = Icons.water;
      label = '$ml ml';
    } else {
      icon = Icons.sports_bar;
      label = '$ml ml';
    }

    // Disable button if target is already reached
    final bool isDisabled = isLocked || _isSaving;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isDisabled ? null : () => _addWater(ml),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 70,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isDisabled ? const Color(0xFF111111).withOpacity(0.5) : const Color(0xFF111111),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDisabled ? Colors.grey.withOpacity(0.3) : Colors.cyan.withOpacity(0.3),
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isDisabled ? Colors.grey : Colors.cyan,
                size: 24,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: isDisabled ? Colors.grey : Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
