import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../services/language_service.dart';
import '../services/user_profile_service.dart';
import '../config/api_config.dart';

// Fitness chatbot using Gemini AI - restricted to fitness/health topics only
class FitnessChatbotScreen extends StatefulWidget {
  final String uid;
  final UserProfileData? profile;

  const FitnessChatbotScreen({
    super.key,
    required this.uid,
    this.profile,
  });

  @override
  State<FitnessChatbotScreen> createState() => _FitnessChatbotScreenState();
}

class _FitnessChatbotScreenState extends State<FitnessChatbotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  // Gemini API model - initialized lazily
  GenerativeModel? _model;

  // System prompt that restricts Gemini to fitness topics only
  static const String _systemPrompt = '''Kamu adalah asisten kebugaran dan kesehatan.
Kamu HANYA boleh menjawab pertanyaan tentang:
- Latihan fisik dan workout
- Nutrisi dan diet
- Kesehatan dan kebugaran
- Tips fitness
- Program latihan
- Istirahat dan recovery
- Hidrasi
- Gaya hidup sehat

Jika user bertanya tentang topik lain (politik, cuaca, berita, dll), jawab dengan:
"Maaf, saya hanya bisa membantu pertanyaan tentang kebugaran dan kesehatan. Tanya saya tentang latihan, nutrisi, atau tips hidup sehat!"

Selalu jawab dalam bahasa yang sama dengan user. Jika user bicara Indonesia, jawab Indonesia. Jika Inggris, jawab Inggris.''';

  @override
  void initState() {
    super.initState();
    _initializeGemini();
    _addWelcomeMessage();
  }

  void _initializeGemini() {
    // Check if API key is configured
    if (ApiConfig.isGeminiConfigured) {
      try {
        _model = GenerativeModel(
          model: 'gemini-1.5-flash',
          apiKey: ApiConfig.geminiApiKey,
        );
      } catch (e) {
        debugPrint('Failed to initialize Gemini: $e');
      }
    }
  }

  bool get _isApiAvailable => _model != null;

  void _addWelcomeMessage() {
    final lang = LanguageService.getCurrentLanguage();
    _messages.add(ChatMessage(
      isUser: false,
      text: lang == 'id'
          ? 'Halo! 👋 Saya asisten kebugaranmu.\n\nTanya saya tentang:\n• Latihan & workout\n• Nutrisi & diet\n• Tips kesehatan\n• Program latihan'
          : 'Hi! 👋 I\'m your fitness assistant.\n\nAsk me about:\n• Exercise & workout\n• Nutrition & diet\n• Health tips\n• Training programs',
    ));
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isLoading) return;

    // Check API availability
    if (_model == null) {
      _addBotMessage(
        LanguageService.getCurrentLanguage() == 'id'
            ? '⚠️ Fitur chat tidak tersedia.\n\nAPI key belum dikonfigurasi.\n\nHubungi developer untuk setup.'
            : '⚠️ Chat feature unavailable.\n\nAPI key not configured.\n\nContact developer for setup.',
      );
      return;
    }

    // Add user message
    setState(() {
      _messages.add(ChatMessage(isUser: true, text: text));
      _isLoading = true;
    });
    _messageController.clear();

    // Scroll to bottom
    _scrollToBottom();

    try {
      // Build context with user profile if available
      String context = '';
      if (widget.profile != null) {
        final p = widget.profile!;
        context = '''
User context:
- Level: ${p.level}
- Total EXP: ${p.totalExp}
- Streak: ${p.streak} days
- BMI: ${p.bmi?.toStringAsFixed(1) ?? 'Not set'}
${p.heightCm != null ? '- Height: ${p.heightCm}cm' : ''}
${p.weightKg != null ? '- Weight: ${p.weightKg}kg' : ''}
''';
      }

      final fullPrompt = '$_systemPrompt\n\n$context\n\nUser: $text';

      final content = [Content.text(fullPrompt)];
      final response = await _model!.generateContent(content);

      if (response.text != null && response.text!.isNotEmpty) {
        _addBotMessage(response.text!);
      } else {
        _addBotMessage(
          LanguageService.getCurrentLanguage() == 'id'
              ? 'Maaf, saya tidak bisa menjawab saat ini.'
              : 'Sorry, I cannot answer at the moment.',
        );
      }
    } catch (e) {
      debugPrint('Gemini Error: $e');
      _addBotMessage(
        LanguageService.getCurrentLanguage() == 'id'
            ? 'Maaf, terjadi kesalahan saat memproses jawaban.'
            : 'Sorry, an error occurred while processing.',
      );
    }

    setState(() => _isLoading = false);
    _scrollToBottom();
  }

  void _addBotMessage(String text) {
    setState(() {
      _messages.add(ChatMessage(isUser: false, text: text));
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = LanguageService.getCurrentLanguage();
    final isId = lang == 'id';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF111111),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.fitness_center, color: Color(0xFF10B981), size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isId ? 'Asisten Kebugaran' : 'Fitness Assistant',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  _isApiAvailable ? 'AI powered' : 'Setup required',
                  style: TextStyle(
                    fontSize: 11,
                    color: _isApiAvailable ? Colors.grey.shade500 : Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Topic restriction notice
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFF1A1A1A),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Color(0xFF10B981), size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isId
                        ? 'Tanya tentang: latihan, nutrisi, kesehatan'
                        : 'Ask about: exercise, nutrition, health',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          // Chat messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildMessageBubble(msg);
              },
            ),
          ),

          // Loading indicator
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Input field
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF111111),
              border: Border(
                top: BorderSide(color: Colors.grey.shade800),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: isId ? 'Tanya tentang kebugaran...' : 'Ask about fitness...',
                        hintStyle: TextStyle(color: Colors.grey.shade600),
                        filled: true,
                        fillColor: const Color(0xFF1A1A1A),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _isLoading ? null : _sendMessage,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _isLoading ? Colors.grey.shade700 : const Color(0xFF10B981),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Icon(
                        Icons.send,
                        color: _isLoading ? Colors.grey : Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: msg.isUser ? const Color(0xFF10B981) : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(msg.isUser ? 16 : 4),
            bottomRight: Radius.circular(msg.isUser ? 4 : 16),
          ),
        ),
        child: Text(
          msg.text,
          style: TextStyle(
            color: msg.isUser ? Colors.black : Colors.white,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class ChatMessage {
  final bool isUser;
  final String text;
  final DateTime timestamp;

  ChatMessage({
    required this.isUser,
    required this.text,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}
