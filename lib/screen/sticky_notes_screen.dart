import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:lottie/lottie.dart';

class StickyNotesScreen extends StatefulWidget {
  const StickyNotesScreen({super.key});

  @override
  State<StickyNotesScreen> createState() => _StickyNotesScreenState();
}

class _StickyNotesScreenState extends State<StickyNotesScreen> {
  late Box<Map> _notesBox;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  final List<Color> _noteColors = [
    const Color(0xFFFFC857),
    const Color(0xFF25D366),
    const Color(0xFF4FB0FF),
    const Color(0xFF9B59B6),
    const Color(0xFFFF6B6B),
    const Color(0xFF00D9FF),
  ];

  late FlutterLocalNotificationsPlugin _notificationsPlugin;
  DateTime? _filterDate;

  @override
  void initState() {
    super.initState();
    _initNotesBox();
    _initializeNotifications();
  }

  void _initNotesBox() async {
    _notesBox = await Hive.openBox<Map>('stickyNotesBox');
    setState(() {});
  }

  void _initializeNotifications() {
    _notificationsPlugin = FlutterLocalNotificationsPlugin();

    final androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    final iosSettings = DarwinInitializationSettings();
    final initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    _notificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _scheduleNotification(String title, String content) async {
    final androidDetails = AndroidNotificationDetails(
      'sticky_notes_channel',
      'Sticky Notes Notifications',
      channelDescription: 'Reminders for sticky notes',
      importance: Importance.high,
      priority: Priority.high,
    );

    final iosDetails = DarwinNotificationDetails();
    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(0, title, content, notificationDetails);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _showAddNoteDialog({Map? editingNote, dynamic noteKey}) {
    _titleController.text = editingNote?['title'] ?? '';
    _contentController.text = editingNote?['content'] ?? '';
    int selectedColorIndex = editingNote?['colorIndex'] ?? 0;
    DateTime? selectedDate;
    if (editingNote != null && editingNote['eventDate'] != null) {
      try {
        selectedDate = DateTime.parse(editingNote['eventDate']);
      } catch (_) {
        selectedDate = null;
      }
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: Text(
            editingNote != null ? 'Edit Note' : 'Add New Note',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _titleController,
                  style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                  decoration: InputDecoration(
                    hintText: 'Note Title',
                    hintStyle: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                  ),
                  maxLength: 50,
                ),
                const SizedBox(height: 12),
                // Date picker
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final now = DateTime.now();
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate ?? now,
                            firstDate: DateTime(now.year - 5),
                            lastDate: DateTime(now.year + 5),
                            builder: (context, child) => Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: Theme.of(context).brightness == Brightness.dark 
                                  ? ColorScheme.dark(primary: Theme.of(context).primaryColor)
                                  : ColorScheme.light(primary: Theme.of(context).primaryColor),
                              ),
                              child: child!,
                            ),
                          );
                          if (picked != null) {
                            setDialogState(() => selectedDate = picked);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).inputDecorationTheme.fillColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Theme.of(context).dividerColor),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                color: Theme.of(context).iconTheme.color,
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  selectedDate != null
                                      ? DateFormat.yMMMd().format(selectedDate!)
                                      : 'Pick a date (optional)',
                                  style: TextStyle(
                                    color: selectedDate != null
                                        ? Theme.of(context).textTheme.bodyLarge?.color
                                        : Theme.of(context).textTheme.bodySmall?.color,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (selectedDate != null) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(Icons.clear, color: Theme.of(context).iconTheme.color),
                        onPressed: () =>
                            setDialogState(() => selectedDate = null),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _contentController,
                  style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                  decoration: InputDecoration(
                    hintText: 'Note Content',
                    hintStyle: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                  ),
                  maxLines: 5,
                  maxLength: 500,
                ),
                const SizedBox(height: 12),
                Text(
                  'Choose Color:',
                  style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: List.generate(_noteColors.length, (index) {
                    return GestureDetector(
                      onTap: () =>
                          setDialogState(() => selectedColorIndex = index),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _noteColors[index],
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selectedColorIndex == index
                                ? (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black)
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _titleController.clear();
                _contentController.clear();
                Navigator.pop(context);
              },
              child: Text(
                'Cancel',
                style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
              ),
            ),
            TextButton(
              onPressed: () {
                if (_titleController.text.isNotEmpty ||
                    _contentController.text.isNotEmpty) {
                  final noteData = {
                    'title': _titleController.text,
                    'content': _contentController.text,
                    'colorIndex': selectedColorIndex,
                    'createdAt': DateTime.now().toString(),
                    'eventDate': selectedDate?.toIso8601String(),
                  };

                  if (noteKey != null) {
                    _notesBox.put(noteKey, noteData);
                  } else {
                    _notesBox.add(noteData);
                  }

                  _scheduleNotification(
                    _titleController.text,
                    'Don\'t forget to check your note!',
                  );

                  _titleController.clear();
                  _contentController.clear();
                  Navigator.pop(context);
                }
              },
              child: const Text(
                'Save',
                style: TextStyle(color: Color(0xFF25D366)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteNote(dynamic key) {
    _notesBox.delete(key);
  }

  void _showTimetableDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(
          'Create Timetable',
          style: TextStyle(color: Theme.of(context).textTheme.titleLarge?.color),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                Icons.calendar_view_week,
                color: Theme.of(context).iconTheme.color,
              ),
              title: Text(
                'Weekly Timetable',
                style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
              ),
              onTap: () {
                Navigator.pop(context);
                _createTimetable('week');
              },
            ),
            ListTile(
              leading: Icon(Icons.calendar_month, color: Theme.of(context).iconTheme.color),
              title: Text(
                'Monthly Timetable',
                style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
              ),
              onTap: () {
                Navigator.pop(context);
                _createTimetable('month');
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
            ),
          ),
        ],
      ),
    );
  }

  void _createTimetable(String type) {
    // Placeholder for timetable creation logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Timetable created!',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Color(0xFF25D366),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: const Color(0xff121B22),
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).iconTheme.color),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Sticky Notes',
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
        actions: [
          IconButton(
            icon: Icon(
              _filterDate == null ? Icons.calendar_month : Icons.calendar_today,
              color: Theme.of(context).iconTheme.color,
            ),
            onPressed: () async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: _filterDate ?? now,
                firstDate: DateTime(now.year - 5),
                lastDate: DateTime(now.year + 5),
                builder: (context, child) => Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: Theme.of(context).brightness == Brightness.dark 
                        ? ColorScheme.dark(primary: Theme.of(context).primaryColor)
                        : ColorScheme.light(primary: Theme.of(context).primaryColor),
                  ),
                  child: child!,
                ),
              );
              if (picked != null) {
                setState(() => _filterDate = picked);
              }
            },
          ),
          if (_filterDate != null)
            IconButton(
              icon: Icon(Icons.close, color: Theme.of(context).iconTheme.color),
              onPressed: () => setState(() => _filterDate = null),
            ),
        ],
        centerTitle: true,
      ),
      body: ValueListenableBuilder(
        valueListenable: _notesBox.listenable(),
        builder: (context, Box<Map> box, _) {
          if (box.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Lottie.asset(
                    'assets/lottie/not_found.json',
                    width: 200,
                    height: 200,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Notes Yet',
                    style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your first sticky note',
                    style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 14),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.0,
            ),
            itemCount: box.length,
            itemBuilder: (context, index) {
              final key = box.keyAt(index);
              final note = box.values.toList()[index];

              return GestureDetector(
                onTap: () {
                  _showAddNoteDialog(editingNote: note, noteKey: key);
                },
                onLongPress: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: Theme.of(context).cardColor,
                      title: Text(
                        'Delete Note?',
                        style: TextStyle(color: Theme.of(context).textTheme.titleLarge?.color),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Cancel',
                            style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            _deleteNote(key);
                            Navigator.pop(context);
                          },
                          child: const Text(
                            'Delete',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color:
                        _noteColors[(note['colorIndex'] ?? 0) %
                                _noteColors.length]
                            .withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        note['title'] ?? 'Untitled',
                        style: const TextStyle(
                          color: Colors.white, // Notes usually have white text on colored bg
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Text(
                          note['content'] ?? '',
                          style: const TextStyle(
                            color: Color(0xFFDDDDDD),
                            fontSize: 13,
                            height: 1.4,
                          ),
                          maxLines: 5,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(Icons.edit, size: 16, color: Colors.white70),
                          Icon(Icons.delete, size: 16, color: Colors.white70),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'timetable',
            backgroundColor: const Color(0xFF4FB0FF),
            onPressed: _showTimetableDialog,
            child: const Icon(Icons.calendar_today, color: Colors.white),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'addNote',
            backgroundColor: const Color(0xFF25D366),
            onPressed: () => _showAddNoteDialog(),
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
