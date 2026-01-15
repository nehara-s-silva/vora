import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:lottie/lottie.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../models/user_profile.dart';
import '../theme/theme_provider.dart';

const String profileBoxName = 'userProfileBox';
const String profileKey = 'currentUser';

/// Helper function to add points to the current user
Future<void> addPointsToUser(int points) async {
  try {
    if (!Hive.isBoxOpen(profileBoxName)) {
      await Hive.initFlutter();
      await Hive.openBox(profileBoxName);
    }
    final box = Hive.box(profileBoxName);
    final data = box.get(profileKey);
    UserProfile profile;

    if (data != null) {
      // Handle both Map and UserProfile object if Hive stored it directly (though we use toJson)
      if (data is Map) {
        profile = UserProfile.fromJson(data);
      } else {
        // Fallback or error
        profile = UserProfile(username: 'User', email: 'user@example.com');
      }
    } else {
      profile = UserProfile(username: 'User', email: 'user@example.com');
    }

    profile.points += points;
    await box.put(profileKey, profile.toJson());
  } catch (e) {
    debugPrint("Error adding points: $e");
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  UserProfile? _currentProfile;
  bool _isLoading = true;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _initHiveAndLoadProfile();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _initHiveAndLoadProfile() async {
    try {
      if (!Hive.isBoxOpen(profileBoxName)) {
        await Hive.initFlutter();
        await Hive.openBox(profileBoxName);
      }
      if (mounted) {
        await _loadProfile();
      }
    } catch (e) {
      debugPrint("Hive error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadProfile() async {
    final box = Hive.box(profileBoxName);
    final data = box.get(profileKey);

    if (data != null && data is Map) {
      _currentProfile = UserProfile.fromJson(data);
    } else {
      _currentProfile = UserProfile(
        username: 'New User',
        email: 'user@example.com',
        photoUrl: null,
        points: 0,
      );
      await _saveProfile(showSuccess: false);
    }

    _usernameController.text = _currentProfile!.username;
    _emailController.text = _currentProfile!.email;

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _saveProfile({bool showSuccess = true}) async {
    if (_currentProfile == null) return;

    final email = _emailController.text.trim();
    if (_validateEmail(email) != null) {
      _showSnackBar("Enter a valid email.");
      return;
    }

    _currentProfile!.username = _usernameController.text.trim();
    _currentProfile!.email = email;

    final newPassword = _passwordController.text;
    if (newPassword.isNotEmpty) {
      try {
        final bytes = utf8.encode(newPassword);
        final digest = sha256.convert(bytes).toString();
        await _secureStorage.write(key: 'user_password_hash', value: digest);
        if (mounted) {
          _passwordController.clear();
        }
      } catch (e) {
        if (mounted) {
          _showSnackBar('Could not securely save password.');
        }
      }
    }

    final box = Hive.box(profileBoxName);
    await box.put(profileKey, _currentProfile!.toJson());

    if (mounted && showSuccess) {
      _showSnackBar("Profile updated!");
      setState(() {});
    }
  }

  Future<void> _openAvatarPicker() async {
    final selected = await showDialog<String?>(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Choose an Avatar',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  children: [
                    _avatarOption('female_one'),
                    _avatarOption('female_two'),
                    _avatarOption('male_one'),
                    _avatarOption('male_two'),
                  ],
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(null),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected != null && _currentProfile != null && mounted) {
      final String newPhotoUrl =
          selected.endsWith('.json') ? selected : '$selected.json';
      setState(() => _currentProfile!.photoUrl = newPhotoUrl);
      await _saveProfile();
    }
  }

  Widget _avatarOption(String key) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(key),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Lottie.asset('assets/lottie/$key.json', fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            key.replaceAll('_', ' ').toUpperCase(),
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _showPinDialog() async {
    final pinController = TextEditingController();
    final confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: const Text('Set/Change PIN'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: pinController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                obscureText: true,
                style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color),
                decoration: const InputDecoration(
                  labelText: 'PIN (4-6 digits)',
                ),
                validator: (v) {
                  if (v == null || v.trim().length < 4) {
                    return 'Enter a 4+ digit PIN';
                  }
                  if (!RegExp(r'^\d+$').hasMatch(v)) {
                    return 'PIN must be numeric';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: confirmController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6,
                style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color),
                decoration: const InputDecoration(labelText: 'Confirm PIN'),
                validator: (v) {
                  if (v != pinController.text) return 'PINs do not match';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                final pin = pinController.text.trim();
                final hash = sha256.convert(utf8.encode(pin)).toString();
                try {
                  await _secureStorage.write(key: 'user_pin_hash', value: hash);
                  if (ctx.mounted) Navigator.of(ctx).pop(true);
                } catch (e) {
                  if (ctx.mounted) Navigator.of(ctx).pop(false);
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true && mounted) _showSnackBar('PIN saved securely');
  }

  Future<void> _clearCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: const Text('Clear Cache'),
        content: const Text(
          'This will remove your saved profile photo and local profile data. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final box = Hive.box(profileBoxName);
      await box.delete(profileKey);

      if (_currentProfile?.photoUrl != null) {
        final avatarKey = _currentProfile!.photoUrl!;
        const lottieKeys = [
          'female_one',
          'female_two',
          'male_one',
          'male_two',
          'female_one.json',
          'female_two.json',
          'male_one.json',
          'male_two.json'
        ];

        if (!lottieKeys.contains(avatarKey) && !kIsWeb) {
          final f = File(avatarKey);
          if (await f.exists()) await f.delete();
        }
      }

      await _secureStorage.delete(key: 'user_pin_hash');
      await _secureStorage.delete(key: 'user_password_hash');

      if (!mounted) return;

      _currentProfile = UserProfile(
        username: 'New User',
        email: 'user@example.com',
      );
      _usernameController.text = _currentProfile!.username;
      _emailController.text = _currentProfile!.email;

      setState(() {});
      _showSnackBar('Cache cleared');
    } catch (e) {
      if (mounted) _showSnackBar('Failed to clear cache');
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final box = Hive.box(profileBoxName);
      await box.delete(profileKey);
      await _secureStorage.deleteAll();
      if (!mounted) return;
      _showSnackBar('Logged out');
      Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      if (mounted) _showSnackBar('Logout failed');
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String? _validateEmail(String value) {
    if (value.isEmpty) return 'Email cannot be empty.';
    final reg = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!reg.hasMatch(value)) return 'Invalid email';
    return null;
  }

  Widget _buildAvatarWidget() {
    final String? photoUrl = _currentProfile?.photoUrl;

    if (photoUrl == null || photoUrl.isEmpty) {
      return _circleContainer(
          Lottie.asset('assets/lottie/male_one.json', fit: BoxFit.cover));
    }

    if (photoUrl.endsWith('.json')) {
      return _circleContainer(
          Lottie.asset('assets/lottie/$photoUrl', fit: BoxFit.cover));
    }

    if (photoUrl.startsWith('http') || photoUrl.startsWith('https')) {
      return _circleContainer(Image.network(
        photoUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            const Icon(Icons.person, size: 60, color: Colors.white54),
      ));
    }

    if (kIsWeb) {
      return _circleContainer(
          Lottie.asset('assets/lottie/male_one.json', fit: BoxFit.cover));
    }

    return _circleContainer(Image.file(
      File(photoUrl),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) =>
          const Icon(Icons.person, size: 60, color: Colors.white54),
    ));
  }

  Widget _circleContainer(Widget child) {
    return Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).cardColor,
          border: Border.all(color: Theme.of(context).primaryColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
              blurRadius: 15,
              spreadRadius: 2,
            )
          ]),
      child: ClipOval(child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final int points = _currentProfile?.points ?? 0;

    return SafeArea(
      child: Scaffold(
        body: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).scaffoldBackgroundColor,
                    Theme.of(context)
                        .scaffoldBackgroundColor
                        .withValues(alpha: 0.9),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 100),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // Title Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Profile",
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Profile Card
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      color: Theme.of(context).cardColor,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _openAvatarPicker,
                          child: _buildAvatarWidget(),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _currentProfile?.username ?? "User",
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _currentProfile?.email ?? "",
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 12),

                        TextButton(
                          onPressed: _openAvatarPicker,
                          child: Text(
                            "Change Avatar",
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        Divider(
                            color: Theme.of(context).dividerColor, height: 24),

                        // Stats Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStatItem("Points", "$points",
                                Icons.stars_rounded, const Color(0xFFFFD700)),
                            Container(
                                width: 1,
                                height: 40,
                                color: Theme.of(context).dividerColor),
                            _buildStatItem(
                                "Rank",
                                "#1",
                                Icons.leaderboard_rounded,
                                Theme.of(context).colorScheme.secondary),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Theme Toggle
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Theme.of(context)
                                  .dividerColor
                                  .withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Provider.of<ThemeProvider>(context)
                                            .isDarkMode
                                        ? Icons.dark_mode_rounded
                                        : Icons.light_mode_rounded,
                                    color: Theme.of(context).primaryColor,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Theme',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium,
                                      ),
                                      Text(
                                        Provider.of<ThemeProvider>(context)
                                                .isDarkMode
                                            ? 'Dark Mode'
                                            : 'Light Mode',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Consumer<ThemeProvider>(
                                builder: (context, provider, _) {
                                  return AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 300),
                                    transitionBuilder: (child, animation) {
                                      return ScaleTransition(
                                          scale: animation, child: child);
                                    },
                                    child: Switch(
                                      key: ValueKey(provider.isDarkMode),
                                      value: provider.isDarkMode,
                                      onChanged: (_) {
                                        provider.toggleTheme();
                                      },
                                      activeColor:
                                          Theme.of(context).primaryColor,
                                      inactiveThumbColor: Colors.grey,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _showPinDialog,
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                      color: Theme.of(context).primaryColor),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: Text('Set PIN',
                                    style: TextStyle(
                                        color: Theme.of(context).primaryColor)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _logout,
                                style: OutlinedButton.styleFrom(
                                  side:
                                      const BorderSide(color: Colors.redAccent),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: const Text('Logout',
                                    style: TextStyle(color: Colors.redAccent)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: _clearCache,
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                  color: Theme.of(context).dividerColor),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text('Clear Cache',
                                style: TextStyle(
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.color)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Leaderboard Preview
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.emoji_events,
                                color: Color(0xFFFFD700)),
                            const SizedBox(width: 8),
                            Text(
                              "Your Ranking",
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        _buildLeaderboardItem(
                            1, _currentProfile?.username ?? "Me", points, true),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Inputs
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Edit Profile",
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 10),
                        _buildInput(
                          "Username",
                          _usernameController,
                          Icons.person_rounded,
                        ),
                        const SizedBox(height: 18),

                        _buildInput(
                          "Email",
                          _emailController,
                          Icons.email_rounded,
                          keyboard: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 18),

                        _buildInput(
                          "Password",
                          _passwordController,
                          Icons.lock_rounded,
                          obscure: true,
                          hint: "New password (optional)",
                        ),
                        const SizedBox(height: 30),

                        // Save Button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _saveProfile,
                            child: const Text(
                              "Save Changes",
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildLeaderboardItem(int rank, String name, int pts, bool isMe) {
    Color rankColor = const Color(0xFFFFD700);
    Color badgeColor = const Color(0xFFFFD700);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isMe
            ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
            : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: isMe
            ? Border.all(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.5))
            : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(
              "#$rank",
              style: TextStyle(
                  color: rankColor, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
                  fontSize: 16),
            ),
          ),
          Icon(Icons.workspace_premium, color: badgeColor, size: 16),
          const SizedBox(width: 4),
          Text(
            "$pts pts",
            style: const TextStyle(
                color: Color(0xFFFFD700), fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildInput(
    String label,
    TextEditingController controller,
    IconData icon, {
    TextInputType? keyboard,
    bool obscure = false,
    String? hint,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).inputDecorationTheme.fillColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboard,
        style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Theme.of(context).primaryColor),
          labelText: label,
          labelStyle:
              TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
          hintText: hint,
          hintStyle:
              TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
          border: InputBorder.none,
          filled: false,
        ),
      ),
    );
  }
}
