import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class YumSwipeChatbotApp extends StatelessWidget {
  const YumSwipeChatbotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YumSwipe Chatbot',
      theme: ThemeData(
        primaryColor: const Color(0xFF8B0000),
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const YumSwipeChatScreen(),
    );
  }
}

class YumSwipeChatScreen extends StatefulWidget {
  const YumSwipeChatScreen({super.key});

  @override
  State<YumSwipeChatScreen> createState() => _YumSwipeChatScreenState();
}

class _YumSwipeChatScreenState extends State<YumSwipeChatScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  static const String apiKey = 'AIzaSyACWNxLIurljmOrEuY1KnCszNFuwxuwU0g';
  static final String apiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey';

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.2, end: 0.8).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _glowController.dispose();
    super.dispose();
  }

  Future<void> sendMessage(String message) async {
    setState(() {
      _isLoading = true;
      _messages.add({'sender': 'You', 'text': message});
    });

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": message},
              ],
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final responseJson = jsonDecode(response.body);
        final reply =
            responseJson['candidates'][0]['content']['parts'][0]['text'];

        setState(() {
          _messages.add({'sender': 'YumSwipe Bot', 'text': reply});
        });
      } else {
        setState(() {
          _messages.add({
            'sender': 'YumSwipe Bot',
            'text': '❌ Oops! Failed to get response.',
          });
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({
          'sender': 'YumSwipe Bot',
          'text': '⚠️ Error: ${e.toString()}',
        });
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildChatBubble(String sender, String text) {
    final isUser = sender == 'You';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser)
            AnimatedBuilder(
              animation: _glowAnimation,
              builder:
                  (_, child) => Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF8B0000,
                          ).withOpacity(_glowAnimation.value),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const CircleAvatar(
                      radius: 18,
                      backgroundImage: AssetImage('assets/chat_bg.png'),
                    ),
                  ),
            ),
          if (!isUser) const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: isUser ? const Color(0xFFFFE27C) : Colors.white,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: isUser ? const Radius.circular(18) : Radius.zero,
                  bottomRight: isUser ? Radius.zero : const Radius.circular(18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                text,
                style: const TextStyle(fontSize: 16, height: 1.4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    final random = Random();
    List<Positioned> scatteredImages = List.generate(12, (index) {
      final double top = random.nextDouble() * 700;
      final double left = random.nextDouble() * 350;
      final double size = random.nextBool() ? 60 : 80;

      return Positioned(
        top: top,
        left: left,
        child: Opacity(
          opacity: 0.25, // Higher opacity for better visibility
          child: Image.asset('assets/chat_bg.png', width: size, height: size),
        ),
      );
    });

    return Stack(children: scatteredImages);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          _buildBackground(),
          Column(
            children: [
              Container(
                padding: const EdgeInsets.only(
                  top: 50,
                  left: 16,
                  right: 16,
                  bottom: 16,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF8B0000), Color(0xFFB22222)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'YumSwipe Chatbot 🤖',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 22,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    return _buildChatBubble(msg['sender']!, msg['text']!);
                  },
                ),
              ),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(8),
                  child: CircularProgressIndicator(),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          hintText: "Type your message...",
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        final message = _controller.text.trim();
                        if (message.isNotEmpty) {
                          _controller.clear();
                          sendMessage(message);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B0000),
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(14),
                        elevation: 6,
                        shadowColor: Colors.black45,
                      ),
                      child: const Icon(Icons.send, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
