import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:vora/models/chat_message.dart';
import 'package:vora/models/chat_session.dart';
import 'package:vora/screen/splash_screen.dart';
import 'package:vora/service/app_open_ad_manager.dart';
import 'package:vora/service/chat_service.dart';
import 'package:vora/theme/app_theme.dart';
import 'package:vora/theme/theme_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'helper/global.dart';

const String ONBOARDING_BOX = 'onboardingBox';
const String ONBOARDING_KEY = 'hasSeenOnboarding';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize App Open Ad Manager (stubbed)
  AppOpenAdManager.instance.initialize();

  await Hive.initFlutter();

  Hive.registerAdapter(ChatMessageAdapter());
  Hive.registerAdapter(ChatSessionAdapter());

  await Hive.openBox(ONBOARDING_BOX);
  await Hive.openBox('favoritesBox');
  await ChatService.initializeChatBox();

  // Load favorites from Hive
  initFavorites();

  // Initialize ThemeProvider
  final themeProvider = await ThemeProvider.create();
  runApp(VoraApp(themeProvider: themeProvider));
}

class VoraApp extends StatelessWidget {
  final ThemeProvider themeProvider;

  const VoraApp({super.key, required this.themeProvider});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ThemeProvider>.value(
      value: themeProvider,
      child: Consumer<ThemeProvider>(
        builder: (context, provider, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: provider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
