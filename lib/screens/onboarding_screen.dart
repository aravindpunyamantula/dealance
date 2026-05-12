import 'package:flutter/material.dart';
import '../utils/app_palette.dart';
import 'auth/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final _pages = const [
    {"title": "Join the Network", "subtitle": "Unlock entrepreneurial opportunity and investment connections.", "image": "assets/images/onboarding1.jpg"},
    {"title": "AI-Powered Insights", "subtitle": "Deep research on your idea — viability, competition, and success rate.", "image": "assets/images/onboarding2.jpg"},
    {"title": "Pitch, Fund & Learn", "subtitle": "Submit ideas, get funded, and learn from expert resources.", "image": "assets/images/onboarding3.jpg"},
  ];

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOutCubic);
    } else {
      _goToLogin();
    }
  }

  void _goToLogin() {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (context, i) {
              final page = _pages[i];
              return Container(
                decoration: BoxDecoration(
                  image: DecorationImage(image: AssetImage(page["image"]!), fit: BoxFit.cover),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.white.withOpacity(0.9), Colors.white],
                      stops: const [0.3, 0.7, 1.0],
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: Column(
                          children: [
                            TweenAnimationBuilder<double>(
                              key: ValueKey('title_$i'),
                              tween: Tween(begin: 0, end: 1),
                              duration: const Duration(milliseconds: 700),
                              curve: Curves.easeOut,
                              builder: (_, val, child) => Opacity(
                                opacity: val,
                                child: Transform.translate(offset: Offset(0, 30 * (1 - val)), child: child),
                              ),
                              child: Text(
                                page["title"]!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontFamily: 'Revalia', fontSize: 24, fontWeight: FontWeight.w700,
                                  color: Colors.black87, letterSpacing: 1.2, height: 1.3,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            TweenAnimationBuilder<double>(
                              key: ValueKey('sub_$i'),
                              tween: Tween(begin: 0, end: 1),
                              duration: const Duration(milliseconds: 900),
                              curve: Curves.easeOut,
                              builder: (_, val, child) => Opacity(
                                opacity: val,
                                child: Transform.translate(offset: Offset(0, 20 * (1 - val)), child: child),
                              ),
                              child: Text(
                                page["subtitle"]!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 14, color: Colors.black54, height: 1.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 130),
                    ],
                  ),
                ),
              );
            },
          ),

          // Bottom controls
          Positioned(
            bottom: 40,
            left: 24,
            right: 24,
            child: Column(
              children: [
                // Dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_pages.length, (i) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 8,
                      width: _currentPage == i ? 24 : 8,
                      decoration: BoxDecoration(
                        color: _currentPage == i ? AppPalette.primary : AppPalette.primary.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    if (_currentPage < _pages.length - 1)
                      TextButton(
                        onPressed: _goToLogin,
                        child: const Text("Skip", style: TextStyle(color: Colors.black54, fontSize: 15)),
                      ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: _next,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppPalette.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: Text(
                        _currentPage == _pages.length - 1 ? "Get Started" : "Next",
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
