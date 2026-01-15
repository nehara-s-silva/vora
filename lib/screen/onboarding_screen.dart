import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:vora/helper/global.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:vora/models/onboard.dart';
import 'package:vora/screen/home_screen.dart'; // 1. Import hive_flutter

// 2. Define Hive constants
const String ONBOARDING_BOX = 'onboardingBox';
const String ONBOARDING_KEY = 'hasSeenOnboarding';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<Onboard> _list = [
    Onboard(
      title: 'Welcome to Vora',
      subtitle:
          'Explore your school books and past papers — all in one smart, easy-to-use app.',
      lottie: 'reading_book',
      color: const Color(0xFF25D366), // WhatsApp green
    ),
    Onboard(
      title: 'About Us',
      subtitle: 'Vora is designed to make learning simple, helpful, and enjoyable for every student.',
      lottie: 'about_us',
      color: const Color(0xFF34B7F1), // Light cyan blue
    ),
    Onboard(
      title: 'About the Creator',
      subtitle:
          "Hi, I'm Nehara Sandeepa Silva — a Grade 10 student at Baragedara College, passionate about creating apps that help others learn.",
      lottie: 'about_me',
      color: const Color(0xFF128C7E), // Dark green accent
    ),
  ];

  void _nextPage() {
    if (_currentPage == _list.length - 1) {
      // 🚀 LAST PAGE: Set the flag in Hive and navigate to HomeScreen
      final onboardingBox = Hive.box(ONBOARDING_BOX);
      // Set the flag to true so the screen won't show on future launches
      onboardingBox.put(ONBOARDING_KEY, true); 

      // Navigate to the main app screen
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => HomeScreen(books: books, papers: papers)));
    } else {
      // ➡️ Not the last page: Go to the next page
      _controller.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    mq = MediaQuery.of(context).size;

    return Scaffold(
      // backgroundColor: const Color(0xFF121B22), // dark WhatsApp-style background
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _list.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (ctx, ind) {
                  final data = _list[ind];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 60),
                        // Lottie Animation
                        Lottie.asset(
                          'assets/lottie/${data.lottie}.json',
                          width: mq.width * 0.8,
                          height: mq.height * 0.4,
                        ),
                        const SizedBox(height: 40),

                        // Title
                        Text(
                          data.title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.titleLarge?.color,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Subtitle
                        Text(
                          data.subtitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: Theme.of(context).textTheme.bodyMedium?.color,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Page Indicator Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _list.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  height: 8,
                  width: _currentPage == index ? 24 : 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? const Color(0xFF25D366)
                        : Theme.of(context).dividerColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Button
            Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  shape: const StadiumBorder(),
                  elevation: 4,
                  minimumSize: Size(mq.width * 0.7, 50),
                  shadowColor: Colors.black.withOpacity(0.4),
                ),
                onPressed: _nextPage,
                child: Text(
                  _currentPage == _list.length - 1 ? 'Get Started' : 'Next',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}