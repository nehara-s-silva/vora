// lib/screen/pomodoro_timer_screen.dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:uuid/uuid.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Initialize notifications
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

void addPointsToUser(int points) {
  debugPrint('Points added to user: $points');
}

class PomodoroTimerScreen extends StatefulWidget {
  const PomodoroTimerScreen({super.key});

  @override
  State<PomodoroTimerScreen> createState() => _PomodoroTimerScreenState();
}

class _PomodoroTimerScreenState extends State<PomodoroTimerScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _animationController;
  Timer? _timer;

  final AudioPlayer _audioPlayer = AudioPlayer(playerId: 'ambient_player');
  final AudioPlayer _notificationPlayer = AudioPlayer(playerId: 'notification_player');

  // Pomodoro settings (in seconds)
  int _workDuration = 25 * 60;
  int _shortBreakDuration = 5 * 60;
  int _longBreakDuration = 15 * 60;
  int _sessionsBeforeLongBreak = 4;

  int _sessionsCompleted = 0;
  int _remainingTime = 25 * 60;
  bool _isRunning = false;
  bool _isWorkSession = true;

  late int _currentSessionDuration;

  // App lifecycle tracking for deep focus
  bool _wasInBackground = false;
  DateTime? _backgroundTime;

  bool _deepFocusMode = false;
  bool _whitelistMode = false;
  List<String> _whitelistedApps = ['com.example.notes', 'com.youtube.app'];

  int _totalFocusSecondsToday = 0;
  Map<String, bool> _achievements = {};
  int _userCoins = 0;

  final List<TaskItem> _tasks = [];
  final TextEditingController _taskController = TextEditingController();

  final List<int> customDurations = [15, 20, 25, 30, 45, 60];

  String? _currentGroupCode;
  bool _inGroupSession = false;

  late SharedPreferences _prefs;

  final String _deviceId = const Uuid().v4();

  // YouTube channel
  final String _youtubeChannelUrl = 'https://www.youtube.com/@IslandBoyBeats-k1r';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _currentSessionDuration = _workDuration;

    _animationController = AnimationController(
      duration: Duration(seconds: _currentSessionDuration),
      vsync: this,
    );

    _initializeNotifications();
    _initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    _timer?.cancel();
    _audioPlayer.dispose();
    _notificationPlayer.dispose();
    _taskController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (_deepFocusMode && _isRunning && _isWorkSession) {
      if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
        _wasInBackground = true;
        _backgroundTime = DateTime.now();
        _showDeepFocusWarning();
      } else if (state == AppLifecycleState.resumed) {
        if (_wasInBackground && _backgroundTime != null) {
          final duration = DateTime.now().difference(_backgroundTime!);
          if (duration.inSeconds > 5) {
            _handleDeepFocusFail();
          }
          _wasInBackground = false;
          _backgroundTime = null;
        }
      }
    }
  }

  void _showDeepFocusWarning() {
    _playUiSound('assets/sounds/warning.wav');
  }

  void _handleDeepFocusFail() {
    _pauseTimer();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.red.shade50,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(children: [
          Icon(Icons.warning, color: Colors.red.shade700),
          const SizedBox(width: 8),
          const Text('Deep Focus Failed', style: TextStyle(color: Colors.red)),
        ]),
        content: const Text(
          'You left the app during deep focus mode. Your session has been paused.',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _resetTimer();
            },
            child: const Text('Reset Session'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  Future<void> _initializeNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await flutterLocalNotificationsPlugin.initialize(initSettings);
  }

  Future<void> _showLocalNotification(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'pomodoro_channel',
      'Pomodoro Timer',
      channelDescription: 'Notifications for Pomodoro timer sessions',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      details,
    );
  }

  Future<void> _initialize() async {
    _prefs = await SharedPreferences.getInstance();

    _workDuration = _prefs.getInt('workDuration') ?? _workDuration;
    _shortBreakDuration = _prefs.getInt('shortBreakDuration') ?? _shortBreakDuration;
    _longBreakDuration = _prefs.getInt('longBreakDuration') ?? _longBreakDuration;
    _sessionsBeforeLongBreak = _prefs.getInt('sessionsBeforeLongBreak') ?? _sessionsBeforeLongBreak;

    _remainingTime = _prefs.getInt('remainingTime') ?? _workDuration;
    _isWorkSession = _prefs.getBool('isWorkSession') ?? true;
    _sessionsCompleted = _prefs.getInt('sessionsCompleted') ?? 0;

    _deepFocusMode = _prefs.getBool('deepFocusMode') ?? false;
    _whitelistMode = _prefs.getBool('whitelistMode') ?? false;

    _userCoins = _prefs.getInt('userCoins') ?? 0;

    final String? tasksJson = _prefs.getString('tasks');
    if (tasksJson != null) {
      try {
        final List decoded = jsonDecode(tasksJson) as List;
        _tasks.clear();
        _tasks.addAll(decoded.map((e) => TaskItem.fromJson(Map<String, dynamic>.from(e))));
      } catch (_) {}
    }

    final String? achJson = _prefs.getString('achievements');
    if (achJson != null) {
      try {
        final Map decoded = jsonDecode(achJson) as Map;
        _achievements = decoded.map((k, v) => MapEntry(k.toString(), v as bool));
      } catch (_) {}
    }

    final String today = DateTime.now().toIso8601String().split('T').first;
    final String? lastDate = _prefs.getString('focusDate');
    final int storedSeconds = _prefs.getInt('focusSeconds') ?? 0;
    if (lastDate == today) {
      _totalFocusSecondsToday = storedSeconds;
    } else {
      _totalFocusSecondsToday = 0;
      await _prefs.setString('focusDate', today);
      await _prefs.setInt('focusSeconds', 0);
    }

    _currentSessionDuration = _isWorkSession ? _workDuration : _shortBreakDuration;
    if (!_isWorkSession && _remainingTime == _longBreakDuration) {
      _currentSessionDuration = _longBreakDuration;
    }

    _animationController.duration = Duration(seconds: _currentSessionDuration);

    setState(() {});
  }

  void _persistSettings() {
    _prefs.setInt('workDuration', _workDuration);
    _prefs.setInt('shortBreakDuration', _shortBreakDuration);
    _prefs.setInt('longBreakDuration', _longBreakDuration);
    _prefs.setInt('sessionsBeforeLongBreak', _sessionsBeforeLongBreak);

    _prefs.setInt('remainingTime', _remainingTime);
    _prefs.setBool('isWorkSession', _isWorkSession);
    _prefs.setInt('sessionsCompleted', _sessionsCompleted);

    _prefs.setBool('deepFocusMode', _deepFocusMode);
    _prefs.setBool('whitelistMode', _whitelistMode);

    _prefs.setInt('userCoins', _userCoins);

    final tasksJson = jsonEncode(_tasks.map((t) => t.toJson()).toList());
    _prefs.setString('tasks', tasksJson);

    _prefs.setString('achievements', jsonEncode(_achievements));

    _prefs.setInt('focusSeconds', _totalFocusSecondsToday);
    _prefs.setString('focusDate', DateTime.now().toIso8601String().split('T').first);
  }

  void _startTimer() {
    if (_isRunning) return;

    if (_remainingTime <= 0) {
      _remainingTime = _isWorkSession ? _workDuration : _shortBreakDuration;
    }

    _currentSessionDuration = _isWorkSession ? _workDuration : _shortBreakDuration;
    _animationController.duration = Duration(seconds: _currentSessionDuration);
    _animationController.forward(from: 1 - (_remainingTime / _currentSessionDuration));

    setState(() => _isRunning = true);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingTime > 0) {
          _remainingTime--;
          if (_isWorkSession) {
            _totalFocusSecondsToday++;
          }
          _animationController.value = 1 - (_remainingTime / _currentSessionDuration);
        } else {
          _completeSession();
        }
      });
      _persistSettings();
    });

    _playUiSound('assets/sounds/start.wav');
  }

  void _pauseTimer() {
    _timer?.cancel();
    _animationController.stop();
    setState(() => _isRunning = false);
    _persistSettings();
    _playUiSound('assets/sounds/pause.wav');
  }

  void _stopTimer() {
    _timer?.cancel();
    _animationController.reset();
    setState(() {
      _isRunning = false;
      _remainingTime = _isWorkSession ? _workDuration : _shortBreakDuration;
      _currentSessionDuration = _isWorkSession ? _workDuration : _shortBreakDuration;
    });
    _persistSettings();
    _playUiSound('assets/sounds/stop.wav');
  }

  void _resetTimer() {
    _timer?.cancel();
    _animationController.reset();
    setState(() {
      _isRunning = false;
      _remainingTime = _isWorkSession ? _workDuration : _shortBreakDuration;
      _currentSessionDuration = _isWorkSession ? _workDuration : _shortBreakDuration;
    });
    _persistSettings();
  }

  void _completeSession() {
    _timer?.cancel();
    _animationController.reset();

    if (_isWorkSession) {
      final int pointsEarned = _calculatePointsForDuration(_workDuration);
      addPointsToUser(pointsEarned);

      final int coinsEarned = (pointsEarned / 10).round();
      _userCoins += coinsEarned;

      _checkAchievementsOnComplete(_workDuration, pointsEarned);
      _sessionsCompleted++;
    }

    if (_isWorkSession) {
      if (_sessionsCompleted % _sessionsBeforeLongBreak == 0 && _sessionsCompleted > 0) {
        _isWorkSession = false;
        _currentSessionDuration = _longBreakDuration;
        _remainingTime = _longBreakDuration;
      } else {
        _isWorkSession = false;
        _currentSessionDuration = _shortBreakDuration;
        _remainingTime = _shortBreakDuration;
      }
    } else {
      _isWorkSession = true;
      _currentSessionDuration = _workDuration;
      _remainingTime = _workDuration;
    }

    _isRunning = false;
    _persistSettings();

    final message = _isWorkSession
        ? 'Break time is over! Ready to focus?'
        : 'Great work! Time for a break!';

    showNotification(message);
    _showLocalNotification(
      'Pomodoro Timer',
      message,
    );

    _playUiSound('assets/sounds/session_complete.wav');
  }

  int _calculatePointsForDuration(int seconds) {
    final int durationInMinutes = seconds ~/ 60;
    if (durationInMinutes >= 60) return 120;
    if (durationInMinutes >= 45) return 90;
    if (durationInMinutes >= 30) return 60;
    if (durationInMinutes >= 25) return 50;
    if (durationInMinutes >= 20) return 40;
    if (durationInMinutes >= 15) return 30;
    return durationInMinutes * 2;
  }

  void _checkAchievementsOnComplete(int seconds, int points) {
    final int mins = seconds ~/ 60;

    if (mins >= 25 && (_achievements['first_25_min'] ?? false) == false) {
      _achievements['first_25_min'] = true;
      _showAchievement('First 25-min Session', 'Nice! Keep the streak going.', 5);
    }

    if (_sessionsCompleted >= 5 && (_achievements['5_sessions'] ?? false) == false) {
      _achievements['5_sessions'] = true;
      _showAchievement('5 Sessions Completed', 'Building momentum!', 10);
    }

    if (_sessionsCompleted >= 10 && (_achievements['10_sessions'] ?? false) == false) {
      _achievements['10_sessions'] = true;
      _showAchievement('10 Sessions Completed', 'You are building a habit!', 20);
    }

    if (_sessionsCompleted >= 25 && (_achievements['25_sessions'] ?? false) == false) {
      _achievements['25_sessions'] = true;
      _showAchievement('Quarter Century!', '25 sessions complete!', 50);
    }

    if (_totalFocusSecondsToday >= 3600 && (_achievements['1_hour_day'] ?? false) == false) {
      _achievements['1_hour_day'] = true;
      _showAchievement('1 Hour Focus', 'Focused for 1 hour today!', 15);
    }

    _persistSettings();
  }

  void _showAchievement(String title, String subtitle, int coinReward) {
    _userCoins += coinReward;
    _persistSettings();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(children: [
          const Icon(Icons.star, color: Colors.amber, size: 32),
          const SizedBox(width: 8),
          Expanded(child: Text(title)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(subtitle, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.eco, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(
                    '+$coinReward coins',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Awesome!'),
          )
        ],
      ),
    );

    _playUiSound('assets/sounds/achievement.wav');
  }

  void showNotification(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        backgroundColor: _isWorkSession
            ? const Color(0xFF25D366)
            : const Color(0xFF4FB0FF),
      ),
    );
  }

  void _setCustomDuration(int minutes) {
    _timer?.cancel();
    _animationController.reset();
    setState(() {
      _isRunning = false;
      _workDuration = minutes * 60;
      _isWorkSession = true;
      _remainingTime = _workDuration;
      _currentSessionDuration = _workDuration;
      _animationController.duration = Duration(seconds: _currentSessionDuration);
    });
    _persistSettings();
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> _playAmbientSound(String assetPath, {bool loop = true}) async {
    try {
      await _audioPlayer.setReleaseMode(loop ? ReleaseMode.loop : ReleaseMode.stop);
      await _audioPlayer.setVolume(0.5);
      final String relative = assetPath.replaceFirst('assets/', '');
      await _audioPlayer.play(AssetSource(relative));
      showNotification('Playing ambient sound...');
    } catch (e) {
      debugPrint('Could not play ambient sound: $e');
      showNotification('Error playing sound');
    }
  }

  Future<void> _stopAmbientSound() async {
    try {
      await _audioPlayer.stop();
      showNotification('Ambient sound stopped');
    } catch (e) {
      debugPrint('stop ambient: $e');
    }
  }

  void _toggleDeepFocus(bool val) {
    setState(() {
      _deepFocusMode = val;
    });
    _prefs.setBool('deepFocusMode', _deepFocusMode);

    if (val) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Deep Focus Mode'),
          content: const Text(
            'When enabled, leaving the app during a work session will pause your timer and may affect your progress. Stay focused!',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Got it'),
            ),
          ],
        ),
      );
    }
  }

  void _toggleWhitelistMode(bool val) {
    setState(() {
      _whitelistMode = val;
    });
    _prefs.setBool('whitelistMode', _whitelistMode);
  }

  void _addTask(String title) {
    if (title.trim().isEmpty) return;
    final task = TaskItem(id: const Uuid().v4(), title: title.trim(), completed: false);
    setState(() {
      _tasks.insert(0, task);
      _taskController.clear();
    });
    _persistSettings();
    _playUiSound('assets/sounds/task_add.wav');
  }

  void _toggleTaskCompleted(TaskItem task) {
    setState(() {
      task.completed = !task.completed;
      if (task.completed) {
        _userCoins += 2;
        showNotification('Task completed! +2 coins');
      }
    });
    _persistSettings();
    _playUiSound('assets/sounds/task_complete.wav');
  }

  void _removeTask(TaskItem task) {
    setState(() {
      _tasks.removeWhere((t) => t.id == task.id);
    });
    _persistSettings();
  }

  void _createGroupSession() {
    setState(() {
      _currentGroupCode = const Uuid().v4().split('-').first.toUpperCase();
      _inGroupSession = true;
    });
    showNotification('Group session created! Share code: $_currentGroupCode');
  }

  void _leaveGroupSession() {
    setState(() {
      _currentGroupCode = null;
      _inGroupSession = false;
    });
    showNotification('Left group session');
  }

  void _plantRealTree() {
    if (_userCoins >= 10) {
      setState(() {
        _userCoins -= 10;
      });
      _persistSettings();
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Row(children: [
            const Icon(Icons.eco, color: Colors.green, size: 32),
            const SizedBox(width: 8),
            const Text('Thank you!'),
          ]),
          content: const Text(
            'Your request to plant a real tree has been submitted. Together we can make a difference! 🌳',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Awesome!'),
            ),
          ],
        ),
      );
      _playUiSound('assets/sounds/tree_plant.wav');
    } else {
      showNotification('You need at least 10 coins to plant a real tree.');
    }
  }

  Future<void> _playUiSound(String asset) async {
    try {
      await _notificationPlayer.play(AssetSource(asset.replaceFirst('assets/', '')));
    } catch (e) {
      debugPrint('ui sound error: $e');
    }
  }

  Future<void> _syncNow() async {
    final ts = DateTime.now().toIso8601String();
    await _prefs.setString('lastSyncedAt_$_deviceId', ts);
    showNotification('Synced successfully at ${DateTime.now().hour}:${DateTime.now().minute}');
  }

  Future<void> _openYouTubeChannel() async {
    final uri = Uri.parse(_youtubeChannelUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      showNotification('Could not open YouTube channel');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forest Focus Timer'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: _syncNow,
            tooltip: 'Sync',
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showAboutDialog(),
            tooltip: 'About',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildSessionIndicator(context),
              const SizedBox(height: 20),
              _buildLottieAnimation(),
              const SizedBox(height: 8),
              _buildTimerCircle(context),
              const SizedBox(height: 16),
              _buildStatsCard(context),
              const SizedBox(height: 18),
              _buildControls(),
              const SizedBox(height: 18),
              _buildQuickDurations(),
              const SizedBox(height: 18),
              _buildTasksSection(),
              const SizedBox(height: 18),
              _buildSettingsSection(),
              const SizedBox(height: 18),
              _buildAchievementsSection(),
              const SizedBox(height: 18),
              _buildGroupSessionSection(),
              const SizedBox(height: 20),
              _buildPlantTreeCard(),
              const SizedBox(height: 20),
              _buildYouTubeCard(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLottieAnimation() {
    return SizedBox(
      width: 180,
      height: 180,
      child: _isWorkSession
          ? Lottie.asset(
        'assets/lottie/focus_animation.json',
        fit: BoxFit.contain,
        repeat: _isRunning,
        animate: _isRunning,
      )
          : Lottie.asset(
        'assets/lottie/relax_animation.json',
        fit: BoxFit.contain,
        repeat: true,
      ),
    );
  }

  Widget _buildSessionIndicator(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: _isWorkSession
            ? const Color(0xFF25D366).withOpacity(0.12)
            : const Color(0xFF4FB0FF).withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isWorkSession
              ? const Color(0xFF25D366)
              : const Color(0xFF4FB0FF),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _isWorkSession ? '🎯' : '☕',
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(width: 8),
          Text(
            _isWorkSession ? 'Work Session' : 'Break Time',
            style: TextStyle(
              color: _isWorkSession
                  ? const Color(0xFF25D366)
                  : const Color(0xFF4FB0FF),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerCircle(BuildContext context) {
    final total = _currentSessionDuration > 0
        ? _currentSessionDuration
        : (_isWorkSession ? _workDuration : _shortBreakDuration);
    final progress = total > 0 ? (1 - (_remainingTime / total)) : 0.0;

    return Container(
      width: 260,
      height: 260,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            (_isWorkSession
                ? const Color(0xFF25D366)
                : const Color(0xFF4FB0FF)).withOpacity(0.08),
            (_isWorkSession
                ? const Color(0xFF25D366)
                : const Color(0xFF4FB0FF)).withOpacity(0.03),
          ],
        ),
        border: Border.all(
          color: (_isWorkSession
              ? const Color(0xFF25D366)
              : const Color(0xFF4FB0FF)).withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _formatTime(_remainingTime),
                  style: const TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Courier',
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _isWorkSession ? 'Focus Time' : 'Rest Time',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  'Session ${_sessionsCompleted + 1}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Positioned.fill(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation(
                    _isWorkSession
                        ? const Color(0xFF25D366)
                        : const Color(0xFF4FB0FF),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(BuildContext context) {
    final hours = _totalFocusSecondsToday ~/ 3600;
    final minutes = (_totalFocusSecondsToday % 3600) ~/ 60;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _smallInfoCard(Icons.check_circle, 'Sessions', '$_sessionsCompleted'),
        _smallInfoCard(Icons.timer, 'Focused', '${hours}h ${minutes}m'),
        _smallInfoCard(Icons.eco, 'Coins', '$_userCoins'),
      ],
    );
  }

  Widget _smallInfoCard(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 28, color: Theme.of(context).iconTheme.color),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: _isRunning ? _pauseTimer : _startTimer,
          style: ElevatedButton.styleFrom(
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(18),
            backgroundColor: _isWorkSession
                ? const Color(0xFF25D366)
                : const Color(0xFF4FB0FF),
          ),
          child: Icon(
            _isRunning ? Icons.pause : Icons.play_arrow,
            size: 28,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: _stopTimer,
          style: ElevatedButton.styleFrom(
            shape: const CircleBorder(),
            backgroundColor: Colors.red,
            padding: const EdgeInsets.all(14),
          ),
          child: const Icon(Icons.stop, color: Colors.white),
        ),
        const SizedBox(width: 12),
        OutlinedButton(
          onPressed: _resetTimer,
          style: OutlinedButton.styleFrom(
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(12),
          ),
          child: const Icon(Icons.refresh),
        ),
      ],
    );
  }

  Widget _buildQuickDurations() {
    return Column(
      children: [
        const Text(
          'Quick Set Duration',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: customDurations.map((d) {
            final isActive = _workDuration == d * 60;
            return ChoiceChip(
              label: Text('${d}m'),
              selected: isActive,
              onSelected: (_) => _setCustomDuration(d),
              selectedColor: const Color(0xFF25D366).withOpacity(0.3),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTasksSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tasks',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _taskController,
                  decoration: const InputDecoration(
                    hintText: 'Add a task...',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _addTask(_taskController.text),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _addTask(_taskController.text),
                child: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_tasks.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: Text(
                  'No tasks yet. Add one to get started!',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ..._tasks.map((t) => ListTile(
              leading: Checkbox(
                value: t.completed,
                onChanged: (_) => _toggleTaskCompleted(t),
              ),
              title: Text(
                t.title,
                style: TextStyle(
                  decoration: t.completed
                      ? TextDecoration.lineThrough
                      : null,
                ),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _removeTask(t),
              ),
            )),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Settings',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('Deep Focus Mode'),
            subtitle: const Text(
              'Pauses timer if you leave the app during work sessions',
            ),
            value: _deepFocusMode,
            onChanged: _toggleDeepFocus,
            activeColor: const Color(0xFF25D366),
          ),
          SwitchListTile(
            title: const Text('Whitelist Mode'),
            subtitle: const Text(
              'Allow selected apps while in focus (visual indicator)',
            ),
            value: _whitelistMode,
            onChanged: _toggleWhitelistMode,
            activeColor: const Color(0xFF25D366),
          ),
          if (_whitelistMode) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              children: _whitelistedApps.map(
                    (a) => Chip(label: Text(a, style: const TextStyle(fontSize: 12))),
              ).toList(),
            ),
          ],
          const SizedBox(height: 12),
          const Text(
            'Ambient Sounds',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed: () => _playAmbientSound('assets/sounds/rain.mp3'),
                icon: const Icon(Icons.cloud, size: 18),
                label: const Text('Rain'),
              ),
              ElevatedButton.icon(
                onPressed: () => _playAmbientSound('assets/sounds/forest.mp3'),
                icon: const Icon(Icons.park, size: 18),
                label: const Text('Forest'),
              ),
              OutlinedButton.icon(
                onPressed: _stopAmbientSound,
                icon: const Icon(Icons.stop, size: 18),
                label: const Text('Stop'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.star, color: Colors.amber),
              const SizedBox(width: 8),
              const Text(
                'Achievements',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_achievements.isEmpty)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'Complete sessions to unlock achievements!',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _achievements.entries.map((e) {
                return Chip(
                  label: Text(e.key.replaceAll('_', ' ').toUpperCase()),
                  backgroundColor: e.value
                      ? Colors.amber.shade200
                      : Colors.grey.shade200,
                  avatar: Icon(
                    e.value ? Icons.check_circle : Icons.lock,
                    size: 18,
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildGroupSessionSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.group),
              const SizedBox(width: 8),
              const Text(
                'Group Focus',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (!_inGroupSession)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _createGroupSession,
                    icon: const Icon(Icons.add),
                    label: const Text('Create Group'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => showNotification(
                      'Ask your friend for a group code',
                    ),
                    icon: const Icon(Icons.login),
                    label: const Text('Join Group'),
                  ),
                ),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF25D366).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF25D366)),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Share this code with friends:',
                        style: TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _currentGroupCode ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => showNotification(
                          'Group session active (mock)',
                        ),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Start Together'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: _leaveGroupSession,
                      icon: const Icon(Icons.exit_to_app),
                      label: const Text('Leave'),
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildPlantTreeCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.eco, color: Colors.green, size: 48),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Plant Real Trees',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Spend 10 coins to help plant a real tree and fight climate change! 🌍',
                  style: TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _plantRealTree,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text(
              'Plant\n(10 coins)',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYouTubeCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.red.shade400,
            Colors.red.shade600,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.play_arrow,
              color: Colors.red,
              size: 36,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Island Boy Beats',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Check out my YouTube channel for productivity music & beats! 🎵',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _openYouTubeChannel,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: const Text(
              'Visit',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Forest Focus Timer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Stay focused, grow your forest, and achieve your goals!',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              'Features:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text('• Customizable Pomodoro timer'),
            const Text('• Task management'),
            const Text('• Achievements & rewards'),
            const Text('• Ambient sounds'),
            const Text('• Deep focus mode'),
            const Text('• Group sessions'),
            const SizedBox(height: 16),
            const Text(
              'Created with ❤️',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class TaskItem {
  String id;
  String title;
  bool completed;

  TaskItem({required this.id, required this.title, this.completed = false});

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'completed': completed,
  };

  factory TaskItem.fromJson(Map m) => TaskItem(
    id: m['id'],
    title: m['title'],
    completed: m['completed'] ?? false,
  );
}