import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vora/helper/global.dart';
import 'package:vora/screen/home_screen.dart';
import 'package:vora/screen/onboarding_screen.dart';
import 'package:hive_flutter/hive_flutter.dart';

const String ONBOARDING_BOX = 'onboardingBox';
const String ONBOARDING_KEY = 'hasSeenOnboarding';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Animation setup (slide + fade)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutExpo));

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _controller.forward();

    // Check onboarding status
    Timer(const Duration(seconds: 3), _checkAuthenticationStatus);
  }

  void _checkAuthenticationStatus() {
    final onboardingBox = Hive.box(ONBOARDING_BOX);
    final hasSeenOnboarding = onboardingBox.get(
      ONBOARDING_KEY,
      defaultValue: false,
    );

    final Widget nextScreen = hasSeenOnboarding
        ? HomeScreen(books: books, papers: papers)
        : const OnboardingScreen();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => nextScreen),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    mq = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Image.asset('assets/images/logofd.png', width: mq.width * 0.35),
                const SizedBox(height: 25),

                // App name
                Text(
                  "Vora",
                  style: TextStyle(
                    color: Theme.of(context).textTheme.headlineLarge?.color,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),

                const SizedBox(height: 10),
                Text(
                  "by Nehara S Silva",
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),

                const SizedBox(height: 50),
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor,
                  ),
                  strokeWidth: 2.5,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
