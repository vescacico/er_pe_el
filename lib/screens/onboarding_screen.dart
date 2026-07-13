import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/language_service.dart';

/// Onboarding screen untuk pertama kali user membuka aplikasi
/// Menampilkan fitur-fitur utama dengan animasi
class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  String _currentLang = 'id';

  // Onboarding pages data
  final List<OnboardingPage> _pages = [];

  @override
  void initState() {
    super.initState();
    _currentLang = LanguageService.getCurrentLanguage();
    _initPages();
  }

  void _initPages() {
    _pages.addAll([
      OnboardingPage(
        icon: Icons.shield,
        titleId: 'Selamat Datang, Hunter!',
        titleEn: 'Welcome, Hunter!',
        descriptionId:
            'FitTask adalah asisten kebugaran AI yang akan membantumu mencapai tujuan kesehatan dengan cara yang menyenangkan.',
        descriptionEn:
            'FitTask is an AI fitness assistant that will help you achieve your health goals in a fun way.',
        color: const Color(0xFF10B981),
      ),
      OnboardingPage(
        icon: Icons.auto_awesome,
        titleId: 'Quest Harian Personal',
        titleEn: 'Personalized Daily Quests',
        descriptionId:
            'Quest yang disesuaikan dengan profil kesehatanmu. Jalan kaki, hidrasi, dan latihan otot setiap hari!',
        descriptionEn:
            'Quests tailored to your health profile. Walking, hydration, and muscle exercises every day!',
        color: const Color(0xFF3B82F6),
      ),
      OnboardingPage(
        icon: Icons.trending_up,
        titleId: 'Level & Rank System',
        titleEn: 'Level & Rank System',
        descriptionId:
            'Kumpulkan EXP dan naik level! Dari E (Awakening) hingga S (National Legend).',
        descriptionEn:
            'Collect EXP and level up! From E (Awakening) to S (National Legend).',
        color: const Color(0xFF8B5CF6),
      ),
      OnboardingPage(
        icon: Icons.timer,
        titleId: 'Anti-Cheat System',
        titleEn: 'Anti-Cheat System',
        descriptionId:
            'Focus Check memastikan kamu benar-benar menyelesaikan plank quest dengan fokus penuh!',
        descriptionEn:
            'Focus Check ensures you truly complete plank quests with full focus!',
        color: const Color(0xFFEF4444),
      ),
      OnboardingPage(
        icon: Icons.people,
        titleId: 'Shadow Circle',
        titleEn: 'Shadow Circle',
        descriptionId:
            'Tambahkan teman dan lihat peringkat mereka. Saingi untuk menjadi yang terbaik!',
        descriptionEn:
            'Add friends and see their rankings. Compete to be the best!',
        color: const Color(0xFFEC4899),
      ),
      OnboardingPage(
        icon: Icons.healing,
        titleId: 'AI Rest Mode',
        titleEn: 'AI Rest Mode',
        descriptionId:
            'Cedera atau sakit? Aktifkan Rest Mode untuk membekukan penalti sementara kamu pulih.',
        descriptionEn:
            'Injured or sick? Enable Rest Mode to freeze penalties while you recover.',
        color: const Color(0xFFF97316),
      ),
    ]);
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _skip() {
    _completeOnboarding();
  }

  Future<void> _completeOnboarding() async {
    // Save onboarding completion status
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);

    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: _skip,
                  child: Text(
                    _currentLang == 'id' ? 'Lewati' : 'Skip',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),

            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index]);
                },
              ),
            ),

            // Indicators and Navigation
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pages.length, (index) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? _pages[index].color
                              : Colors.grey.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),

                  // Next/Get Started button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _pages[_currentPage].color,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _currentPage == _pages.length - 1
                            ? (_currentLang == 'id' ? 'Mulai!' : 'Get Started!')
                            : (_currentLang == 'id' ? 'Lanjut' : 'Next'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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

  Widget _buildPage(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon with glow effect
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  page.color.withOpacity(0.3),
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
                  color: page.color.withOpacity(0.2),
                  border: Border.all(color: page.color, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: page.color.withOpacity(0.5),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Icon(
                  page.icon,
                  size: 60,
                  color: page.color,
                ),
              ),
            ),
          ),
          const SizedBox(height: 48),

          // Title
          Text(
            _currentLang == 'id' ? page.titleId : page.titleEn,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: page.color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Description
          Text(
            _currentLang == 'id' ? page.descriptionId : page.descriptionEn,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Model for onboarding page
class OnboardingPage {
  final IconData icon;
  final String titleId;
  final String titleEn;
  final String descriptionId;
  final String descriptionEn;
  final Color color;

  OnboardingPage({
    required this.icon,
    required this.titleId,
    required this.titleEn,
    required this.descriptionId,
    required this.descriptionEn,
    required this.color,
  });
}

/// Helper function to check if onboarding is needed
Future<bool> isOnboardingNeeded() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('onboarding_completed') != true;
}
