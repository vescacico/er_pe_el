import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/sick_mode_service.dart';
import '../services/language_service.dart';

class SickModeScreen extends StatefulWidget {
  final String uid;

  const SickModeScreen({super.key, required this.uid});

  @override
  State<SickModeScreen> createState() => _SickModeScreenState();
}

class _SickModeScreenState extends State<SickModeScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  SickModeData? _sickModeData;
  Set<String> _selectedConditions = {};
  final TextEditingController _customNoteController = TextEditingController();
  int _durationDays = 7;
  String _currentLang = 'id';

  @override
  void initState() {
    super.initState();
    _currentLang = LanguageService.getCurrentLanguage();
    _loadSickModeData();
  }

  @override
  void dispose() {
    _customNoteController.dispose();
    super.dispose();
  }

  Future<void> _loadSickModeData() async {
    setState(() => _isLoading = true);

    try {
      final data = await SickModeService.getSickModeData(widget.uid);
      setState(() {
        _sickModeData = data;
        if (data != null) {
          _selectedConditions = data.conditions.map((c) => c.id).toSet();
          _customNoteController.text = data.customNote ?? '';
          if (data.endDate != null) {
            _durationDays = data.endDate!.difference(DateTime.now()).inDays;
            if (_durationDays < 1) _durationDays = 1;
          }
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _activateSickMode() async {
    if (_selectedConditions.isEmpty) {
      _showErrorDialog(
        _currentLang == 'id' ? 'Pilih Kondisi' : 'Select Condition',
        _currentLang == 'id'
            ? 'Pilih setidaknya satu kondisi kesehatan.'
            : 'Select at least one health condition.',
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await SickModeService.activateSickMode(
        uid: widget.uid,
        conditionIds: _selectedConditions.toList(),
        customNote: _customNoteController.text.isNotEmpty
            ? _customNoteController.text
            : null,
        durationDays: _durationDays,
      );

      await _loadSickModeData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _currentLang == 'id'
                  ? 'Mode terbatas berhasil diaktifkan!'
                  : 'Limited mode activated!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showErrorDialog(
        _currentLang == 'id' ? 'Error' : 'Error',
        e.toString(),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _deactivateSickMode() async {
    setState(() => _isSaving = true);

    try {
      await SickModeService.deactivateSickMode(widget.uid);
      setState(() {
        _selectedConditions.clear();
        _customNoteController.clear();
        _durationDays = 7;
        _sickModeData = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _currentLang == 'id'
                  ? 'Mode terbatas dinonaktifkan. Quest kembali normal!'
                  : 'Limited mode deactivated. Quests are back to normal!',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      _showErrorDialog(
        _currentLang == 'id' ? 'Error' : 'Error',
        e.toString(),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.red),
        ),
        title: Text(title, style: const TextStyle(color: Colors.red)),
        content: Text(message, style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(
          _currentLang == 'id' ? 'Mode Terbatas' : 'Limited Mode',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    final isActive = _sickModeData?.isActive ?? false;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info Banner
          _buildInfoBanner(isActive),
          const SizedBox(height: 24),

          // Current Status
          if (isActive) ...[
            _buildCurrentStatus(),
            const SizedBox(height: 24),
          ],

          // Condition Selection
          Text(
            _currentLang == 'id' ? 'Pilih Kondisi Kesehatan' : 'Select Health Conditions',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _currentLang == 'id'
                ? 'Pilih kondisi yang sedang kamu alami. Quest akan disesuaikan.'
                : 'Select conditions you are experiencing. Quests will be adjusted.',
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 16),

          // Conditions List
          _buildConditionsList(),
          const SizedBox(height: 24),

          // Custom Note
          Text(
            _currentLang == 'id' ? 'Catatan Tambahan (Opsional)' : 'Additional Note (Optional)',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _customNoteController,
            maxLines: 3,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: _currentLang == 'id'
                  ? 'Contoh: operation lutut 2 minggu lalu...'
                  : 'Example: knee operation 2 weeks ago...',
              hintStyle: const TextStyle(color: Colors.grey),
              filled: true,
              fillColor: const Color(0xFF111111),
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
          const SizedBox(height: 24),

          // Duration Selection
          if (!isActive) ...[
            Text(
              _currentLang == 'id' ? 'Durasi Mode Terbatas' : 'Limited Mode Duration',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildDurationSelector(),
            const SizedBox(height: 24),
          ],

          // Action Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving
                  ? null
                  : (isActive ? _deactivateSickMode : _activateSickMode),
              style: ElevatedButton.styleFrom(
                backgroundColor: isActive ? Colors.orange : const Color(0xFF10B981),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      isActive
                          ? (_currentLang == 'id' ? 'Nonaktifkan Mode' : 'Deactivate Mode')
                          : (_currentLang == 'id' ? 'Aktifkan Mode Terbatas' : 'Activate Limited Mode'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),

          // Warning
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber, color: Colors.amber, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _currentLang == 'id'
                        ? 'Mode terbatas tidak menipu sistem. Quest hanya disesuaikan agar sesuai dengan kondisi kamu.'
                        : 'Limited mode is not cheating. Quests are adjusted to match your condition.',
                    style: const TextStyle(color: Colors.amber, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBanner(bool isActive) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isActive
              ? [Colors.orange.withOpacity(0.2), const Color(0xFF111111)]
              : [Colors.blue.withOpacity(0.2), const Color(0xFF111111)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? Colors.orange.withOpacity(0.5)
              : Colors.blue.withOpacity(0.5),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isActive ? Icons.healing : Icons.medical_services,
            color: isActive ? Colors.orange : Colors.blue,
            size: 40,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isActive
                      ? (_currentLang == 'id' ? 'Mode Terbatas Aktif' : 'Limited Mode Active')
                      : (_currentLang == 'id' ? 'Mode Terbatas' : 'Limited Mode'),
                  style: TextStyle(
                    color: isActive ? Colors.orange : Colors.blue,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isActive
                      ? (_currentLang == 'id'
                          ? 'Quest kamu sedang disesuaikan dengan kondisi kesehatanmu.'
                          : 'Your quests are being adjusted to match your health conditions.')
                      : (_currentLang == 'id'
                          ? ' Aktifkan jika kamu sedang tidak bisa melakukan quest normal karena kondisi kesehatan.'
                          : ' Activate if you cannot do normal quests due to health conditions.'),
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStatus() {
    final data = _sickModeData!;
    final remainingDays = data.remainingDays ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              Text(
                _currentLang == 'id' ? 'Status Saat Ini' : 'Current Status',
                style: const TextStyle(
                  color: Colors.orange,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (remainingDays > 0)
            _buildStatusRow(
              Icons.timer,
              _currentLang == 'id' ? 'Sisa Waktu' : 'Time Remaining',
              '$remainingDays ${_currentLang == 'id' ? 'hari' : 'days'}',
            ),
          const SizedBox(height: 8),
          _buildStatusRow(
            Icons.healing,
            _currentLang == 'id' ? 'Kondisi' : 'Conditions',
            data.conditions.map((c) => c.getName(_currentLang)).join(', '),
          ),
          const SizedBox(height: 8),
          _buildStatusRow(
            Icons.speed,
            _currentLang == 'id' ? 'Tingkat' : 'Severity',
            _getSeverityText(data.getSeverityLevel()),
            color: _getSeverityColor(data.getSeverityLevel()),
          ),
          if (data.customNote != null && data.customNote!.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildStatusRow(
              Icons.note,
              _currentLang == 'id' ? 'Catatan' : 'Note',
              data.customNote!,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusRow(IconData icon, String label, String value, {Color? color}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.grey, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
              Text(
                value,
                style: TextStyle(color: color ?? Colors.white, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getSeverityText(String severity) {
    switch (severity) {
      case 'severe':
        return _currentLang == 'id' ? 'Berat' : 'Severe';
      case 'moderate':
        return _currentLang == 'id' ? 'Sedang' : 'Moderate';
      case 'mild':
        return _currentLang == 'id' ? 'Ringan' : 'Mild';
      default:
        return '-';
    }
  }

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'severe':
        return Colors.red;
      case 'moderate':
        return Colors.orange;
      case 'mild':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Widget _buildConditionsList() {
    final categories = ['joint', 'back', 'heart', 'respiratory', 'general', 'other'];

    return Column(
      children: categories.map((category) {
        final conditions = HealthConditionDatabase.getByCategory(category);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Text(
                HealthConditionDatabase.getCategoryName(category, _currentLang),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: conditions.map((condition) {
                final isSelected = _selectedConditions.contains(condition.id);
                return _buildConditionChip(condition, isSelected);
              }).toList(),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildConditionChip(HealthCondition condition, bool isSelected) {
    Color chipColor;
    switch (condition.severity) {
      case 'severe':
        chipColor = Colors.red;
        break;
      case 'moderate':
        chipColor = Colors.orange;
        break;
      default:
        chipColor = Colors.green;
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedConditions.remove(condition.id);
          } else {
            _selectedConditions.add(condition.id);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? chipColor.withOpacity(0.3) : const Color(0xFF111111),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? chipColor : Colors.grey.shade700,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              Icon(Icons.check, color: chipColor, size: 16),
              const SizedBox(width: 4),
            ],
            Text(
              condition.getName(_currentLang),
              style: TextStyle(
                color: isSelected ? chipColor : Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationSelector() {
    final durations = [
      {'days': 1, 'label': _currentLang == 'id' ? '1 Hari' : '1 Day'},
      {'days': 3, 'label': _currentLang == 'id' ? '3 Hari' : '3 Days'},
      {'days': 7, 'label': _currentLang == 'id' ? '1 Minggu' : '1 Week'},
      {'days': 14, 'label': _currentLang == 'id' ? '2 Minggu' : '2 Weeks'},
      {'days': 30, 'label': _currentLang == 'id' ? '1 Bulan' : '1 Month'},
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: durations.map((d) {
        final isSelected = _durationDays == d['days'];
        return GestureDetector(
          onTap: () => setState(() => _durationDays = d['days'] as int),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF10B981).withOpacity(0.2)
                  : const Color(0xFF111111),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? const Color(0xFF10B981) : Colors.grey.shade700,
              ),
            ),
            child: Text(
              d['label'] as String,
              style: TextStyle(
                color: isSelected ? const Color(0xFF10B981) : Colors.white70,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
