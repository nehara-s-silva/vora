import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:carousel_slider/carousel_slider.dart' as cs;
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';

import 'book_screen.dart';
import 'paper_screen.dart';
import 'advanced_ai_screen.dart';
import 'profile_screen.dart';
import 'pomodoro_timer_screen.dart';
import 'sticky_notes_screen.dart';
import 'camera_notes_screen.dart';
import 'pdf_creator_screen.dart';
import '../models/book_model.dart';
import '../models/paper_model.dart';
import '../helper/global.dart';

class HomeScreen extends StatefulWidget {
  final List<BookModel> books;
  final List<PaperModel> papers;

  const HomeScreen({super.key, required this.books, required this.papers});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation =
        CurvedAnimation(parent: _animationController, curve: Curves.easeIn);
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Bottom nav icons
  final List<String> _icons = [
    'assets/icons/home.svg',
    'assets/icons/books.svg',
    'assets/icons/papers.svg',
    'assets/icons/ai.svg',
    'assets/icons/profile.svg',
  ];

  final List<String> _labels = [
    'Home',
    'Books',
    'Papers',
    'AI',
    'Profile',
  ];

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;
    setState(() => _selectedIndex = index);
    _animationController.reset();
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    // Screens for tabs
    final List<Widget> screens = [
      homeContent(),
      const BookScreen(),
      const PaperScreen(),
      const AdvancedAiScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      extendBody: true,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: screens[_selectedIndex],
      ),
      bottomNavigationBar: _buildModernBottomNavBar(),
    );
  }

  Widget _buildModernBottomNavBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF121212), // Dark background as per photo
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_icons.length, (index) {
            final bool isActive = index == _selectedIndex;
            return GestureDetector(
              onTap: () => _onItemTapped(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFF1A392A) // Dark green pill background
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset(
                      _icons[index],
                      width: 24,
                      height: 24,
                      colorFilter: ColorFilter.mode(
                        isActive
                            ? const Color(0xFF4CAF50) // Bright green icon
                            : Colors.white70,
                        BlendMode.srcIn,
                      ),
                    ),
                    if (isActive)
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Text(
                          _labels[index],
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // Get greeting based on time of day
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Night';
  }

  // Get emoji based on greeting
  String _getGreetingEmoji() {
    final hour = DateTime.now().hour;
    if (hour < 12) return '🌅';
    if (hour < 17) return '☀️';
    return '🌙';
  }

  // Get user profile data
  Future<Map<String, dynamic>> _getUserProfile() async {
    if (!Hive.isBoxOpen('userProfileBox')) {
      await Hive.initFlutter();
      await Hive.openBox('userProfileBox');
    }
    final box = Hive.box('userProfileBox');
    final profileData = box.get('currentUser');
    // Handle both Map and UserProfile object (via toJson)
    if (profileData is Map) {
      return {
        'username': profileData['username'] ?? 'User',
        'photoUrl': profileData['photoUrl'],
        'email': profileData['email'] ?? 'user@example.com',
      };
    }
    return {
      'username': 'User',
      'photoUrl': null,
      'email': 'user@example.com',
    };
  }

  // Home tab content
  Widget homeContent() {
    final Size mq = MediaQuery.of(context).size;

    final favoriteBooks = widget.books.where((b) => b.isFavorite).toList();
    final favoritePapers = widget.papers.where((p) => p.isFavorite).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding:
            const EdgeInsets.only(top: 20, left: 16, right: 16, bottom: 100),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Profile Header Slider
              FutureBuilder<Map<String, dynamic>>(
                future: _getUserProfile(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const SizedBox(height: 80);
                  }

                  final userData = snapshot.data!;
                  final username = userData['username'] as String;
                  final photoUrl = userData['photoUrl'] as String?;
                  final greeting = _getGreeting();
                  final emoji = _getGreetingEmoji();
                  final dateStr = DateFormat(
                    'EEEE, MMMM d, yyyy',
                  ).format(DateTime.now());

                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color:
                              Theme.of(context).dividerColor.withOpacity(0.1),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Theme.of(context)
                                  .primaryColor
                                  .withOpacity(0.1),
                              border: Border.all(
                                color: Theme.of(context).primaryColor,
                                width: 2,
                              ),
                            ),
                            child: ClipOval(
                              child: _buildProfileImage(photoUrl),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$greeting $emoji',
                                  style: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  username,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  dateStr,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) => const ProfileScreen()),
                              ),
                              icon: Icon(
                                Icons.settings_outlined,
                                color: Theme.of(context).iconTheme.color,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              // Search bar
              FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: TextField(
                    onChanged: (_) => setState(() {}),
                    style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color),
                    decoration: InputDecoration(
                      hintText: 'Search books, papers or AI...',
                      hintStyle: TextStyle(
                          color: Theme.of(context).textTheme.bodySmall?.color),
                      prefixIcon: Icon(Icons.search,
                          color: Theme.of(context).primaryColor),
                      filled: true,
                      fillColor: Theme.of(context).cardColor,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                            color: Theme.of(context)
                                .dividerColor
                                .withOpacity(0.1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide:
                            BorderSide(color: Theme.of(context).primaryColor),
                      ),
                    ),
                  ),
                ),
              ),

              // Quick actions - Horizontal List
              SizedBox(
                height: 110,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    actionButton(
                      label: 'PDF Maker',
                      icon: Icons.picture_as_pdf_rounded,
                      color: const Color(0xFFFF4081),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const PdfCreatorScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    actionButton(
                      label: 'Timer',
                      icon: Icons.timer_rounded,
                      color: const Color(0xFFFF6B6B),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const PomodoroTimerScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    actionButton(
                      label: 'Notes',
                      icon: Icons.edit_note_rounded,
                      color: const Color(0xFFFFC857),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const StickyNotesScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    actionButton(
                      label: 'Camera',
                      icon: Icons.camera_alt_rounded,
                      color: const Color(0xFF00D9FF),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const CameraNotesScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    actionButton(
                      label: 'AI Chat',
                      icon: Icons.smart_toy_rounded,
                      color: const Color(0xFF25D366),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AdvancedAiScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    actionButton(
                      label: 'Papers',
                      icon: Icons.article_rounded,
                      color: const Color(0xFF4FB0FF),
                      points: '10',
                      onTap: () => Navigator.of(
                        context,
                      ).push(MaterialPageRoute(
                          builder: (_) => const PaperScreen())),
                    ),
                    const SizedBox(width: 16),
                    actionButton(
                      label: 'Books',
                      icon: Icons.menu_book_rounded,
                      color: const Color(0xFF9B59B6),
                      points: '15',
                      onTap: () => Navigator.of(
                        context,
                      ).push(MaterialPageRoute(
                          builder: (_) => const BookScreen())),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Carousel
              cs.CarouselSlider(
                options: cs.CarouselOptions(
                  height: mq.height * 0.22,
                  autoPlay: true,
                  enlargeCenterPage: true,
                  viewportFraction: 0.92,
                  autoPlayAnimationDuration: const Duration(milliseconds: 800),
                  autoPlayCurve: Curves.fastOutSlowIn,
                ),
                items: _buildCarouselItems(mq),
              ),
              const SizedBox(height: 32),

              // recently added papers section
              if (favoritePapers.isNotEmpty) ...[
                sectionTitle('📝 Recent Papers'),
                SizedBox(
                  height: 180,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: favoritePapers.length,
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (ctx, i) {
                      final p = favoritePapers[i];
                      return Container(
                        width: 200,
                        margin:
                            const EdgeInsets.only(right: 16, bottom: 8, top: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .primaryColor
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(Icons.description,
                                      color: Theme.of(context).primaryColor,
                                      size: 20),
                                ),
                                const Spacer(),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      togglePaperFavorite(p);
                                    });
                                  },
                                  child: Icon(
                                    p.isFavorite
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: const Color(0xFFFF4081),
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              p.subject,
                              style: TextStyle(
                                color: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.color,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${p.grade} • ${p.year}',
                              style: TextStyle(
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.color,
                                fontSize: 12,
                              ),
                            ),
                            const Spacer(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFD700)
                                        .withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.stars_rounded,
                                          color: Color(0xFFFFD700), size: 14),
                                      SizedBox(width: 4),
                                      Text("10",
                                          style: TextStyle(
                                              color: Color(0xFFFFD700),
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                                InkWell(
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const PaperScreen(),
                                    ),
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  child: CircleAvatar(
                                    radius: 16,
                                    backgroundColor: Theme.of(context)
                                        .primaryColor
                                        .withOpacity(0.1),
                                    child: Icon(
                                      Icons.arrow_forward_rounded,
                                      color: Theme.of(context).primaryColor,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Recently added books
              if (favoriteBooks.isNotEmpty) ...[
                sectionTitle('✨ Recent Books'),
                SizedBox(
                  height: 180,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: favoriteBooks.length,
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (ctx, i) {
                      final b = favoriteBooks[i];
                      return Container(
                        width: 200,
                        margin:
                            const EdgeInsets.only(right: 16, bottom: 8, top: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF9B59B6)
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.menu_book_rounded,
                                      color: Color(0xFF9B59B6), size: 20),
                                ),
                                const Spacer(),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      toggleBookFavorite(b);
                                    });
                                  },
                                  child: Icon(
                                    b.isFavorite
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: const Color(0xFFFF4081),
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              b.title,
                              style: TextStyle(
                                color: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.color,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${b.grade} • ${b.subject}',
                              style: TextStyle(
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.color,
                                fontSize: 12,
                              ),
                            ),
                            const Spacer(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFD700)
                                        .withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.stars_rounded,
                                          color: Color(0xFFFFD700), size: 14),
                                      SizedBox(width: 4),
                                      Text("15",
                                          style: TextStyle(
                                              color: Color(0xFFFFD700),
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                                InkWell(
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const BookScreen(),
                                    ),
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  child: CircleAvatar(
                                    radius: 16,
                                    backgroundColor: const Color(0xFF9B59B6)
                                        .withOpacity(0.1),
                                    child: const Icon(
                                      Icons.arrow_forward_rounded,
                                      color: Color(0xFF9B59B6),
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to build profile image
  Widget _buildProfileImage(String? photoUrl) {
    if (photoUrl == null || photoUrl.isEmpty) {
      return Lottie.asset(
        'assets/lottie/male_one.json',
        fit: BoxFit.cover,
      );
    }

    if (photoUrl.endsWith('.json')) {
      return Lottie.asset(
        'assets/lottie/$photoUrl',
        fit: BoxFit.cover,
      );
    }

    if (photoUrl.startsWith('http') || photoUrl.startsWith('https')) {
      return Image.network(
        photoUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Lottie.asset(
          'assets/lottie/male_one.json',
          fit: BoxFit.cover,
        ),
      );
    }

    // Local file - check for Web
    if (kIsWeb) {
      return Lottie.asset(
        'assets/lottie/male_one.json',
        fit: BoxFit.cover,
      );
    } else {
      return Image.file(
        File(photoUrl),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Lottie.asset(
          'assets/lottie/male_one.json',
          fit: BoxFit.cover,
        ),
      );
    }
  }

  List<Widget> _buildCarouselItems(Size mq) {
    final List<String> sliderImages = [
      'assets/images/ai_banner.jpg',
      'assets/images/book_banner.jpg',
      'assets/images/news3.jpg',
    ];

    List<Widget> items = [];

    for (int i = 0; i < sliderImages.length; i++) {
      items.add(
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(sliderImages[i], fit: BoxFit.cover),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        "Featured",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      i == 0
                          ? "Master AI with Vora"
                          : i == 1
                              ? "Explore All Books"
                              : "Stay Updated",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
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

    return items;
  }

  Widget actionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    String? points,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                  border: Border.all(
                    color: color.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Icon(icon, size: 28, color: color),
              ),
              if (points != null)
                Positioned(
                  right: -6,
                  top: -6,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 4)
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.stars_rounded,
                            size: 10, color: Colors.black),
                        const SizedBox(width: 2),
                        Text(
                          points,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge?.color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Theme.of(context).textTheme.headlineMedium?.color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Icon(Icons.arrow_forward_ios_rounded,
              size: 16, color: Theme.of(context).dividerColor),
        ],
      ),
    );
  }
}
