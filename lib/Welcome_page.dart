import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'dart:math';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late Animation<double> _logoAnimation;

  late PageController _pageController;
  int _currentPage = 0;

  final List<String> _slogans = [
    "Swipe. Bite. Delight!",
    "Craving? YumSwipe it!",
    "Feast your eyes, then your plate.",
    "Food that finds you.",
    "A flavor for every swipe.",
    "Taste that tells a story.",
    "YumSwipe — for foodies only.",
    "Scroll less. Eat more.",
  ];

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _logoAnimation = CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    );

    _logoController.forward();

    _pageController = PageController(initialPage: 0);

    Timer.periodic(const Duration(seconds: 3), (Timer timer) {
      if (_currentPage < _slogans.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }

      if (mounted) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      body: Stack(
        children: [
          // 🌄 Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/bgg.jpg', // ✅ Replace with your image path
              fit: BoxFit.cover,
            ),
          ),

          // 🌓 Optional Dark Overlay for contrast
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.05)),
          ),

          // 🍕 Decorative Icons
          ..._buildDecorativeIcons(),

          // 🌟 Main Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 🍽 Logo
                    ScaleTransition(
                      scale: _logoAnimation,
                      child: Hero(
                        tag: 'logo',
                        child: Image.asset(
                          'assets/logo1.png',
                          height: isMobile ? 100 : 180,
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // 🎯 Slogan Carousel
                    SizedBox(
                      height: isMobile ? 150 : 180,
                      width: isMobile ? 300 : 400,
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: _slogans.length,
                        itemBuilder: (context, index) {
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 12),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B0000),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                _slogans[index],
                                textAlign: TextAlign.center,
                                style: GoogleFonts.pacifico(
                                  textStyle: TextStyle(
                                    color: Colors.white,
                                    fontSize: isMobile ? 20 : 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 30),

                    Text(
                      "Welcome to",
                      style: TextStyle(
                        fontSize: isMobile ? 24 : 32,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      "YUMSWIPE",
                      style: TextStyle(
                        fontSize: isMobile ? 36 : 48,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF8B0000),
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Discover and order your favorite food",
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: isMobile ? 14 : 18,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 30),

                    ElevatedButton(
                      onPressed: () => Navigator.pushNamed(context, '/login'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B0000),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 10,
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 40 : 60,
                          vertical: isMobile ? 14 : 20,
                        ),
                      ),
                      child: Text(
                        "Get Started",
                        style: TextStyle(
                          fontSize: isMobile ? 18 : 22,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🍕 Decorative Icons Function
  List<Widget> _buildDecorativeIcons() {
    final iconList = [
      Icons.local_pizza,
      Icons.fastfood,
      Icons.local_drink,
      Icons.icecream,
      Icons.ramen_dining,
      Icons.set_meal,
      Icons.emoji_food_beverage,
      Icons.cake,
      Icons.breakfast_dining,
      Icons.dinner_dining,
    ];

    final rand = Random();
    int numberOfIcons = 20;

    return List.generate(numberOfIcons, (index) {
      final icon = iconList[rand.nextInt(iconList.length)];
      final left = rand.nextDouble() * MediaQuery.of(context).size.width * 0.9;
      final top = rand.nextDouble() * MediaQuery.of(context).size.height * 0.8;

      return Positioned(
        left: left,
        top: top,
        child: Opacity(
          opacity: 0.08,
          child: Icon(icon, size: 60, color: const Color(0xFF8B0000)),
        ),
      );
    });
  }
}
