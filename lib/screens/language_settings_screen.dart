import 'package:flutter/material.dart';
import '../services/language_service.dart';

class LanguageSettingsScreen extends StatefulWidget {
  final VoidCallback onLanguageChanged;

  const LanguageSettingsScreen({
    super.key,
    required this.onLanguageChanged,
  });

  @override
  State<LanguageSettingsScreen> createState() => _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends State<LanguageSettingsScreen> {
  String _selectedLanguage = LanguageService.getCurrentLanguage();

  @override
  Widget build(BuildContext context) {
    final languages = LanguageService.getAvailableLanguages();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(
          t('select_language'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pilih bahasa yang Anda inginkan untuk aplikasi ini.',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 8),
            const Text(
              'Select your preferred language for the app.',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ...languages.map((lang) {
              final isSelected = lang['code'] == _selectedLanguage;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF111111),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF10B981)
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: ListTile(
                  onTap: () async {
                    setState(() => _selectedLanguage = lang['code']!);
                    await LanguageService.setLanguage(lang['code']!);
                    widget.onLanguageChanged();
                  },
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        lang['flag']!,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  title: Text(
                    lang['name']!,
                    style: TextStyle(
                      color: isSelected
                          ? const Color(0xFF10B981)
                          : Colors.white,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(
                    lang['code']!.toUpperCase(),
                    style: const TextStyle(color: Colors.grey),
                  ),
                  trailing: isSelected
                      ? const Icon(
                          Icons.check_circle,
                          color: Color(0xFF10B981),
                        )
                      : const Icon(
                          Icons.circle_outlined,
                          color: Colors.grey,
                        ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
