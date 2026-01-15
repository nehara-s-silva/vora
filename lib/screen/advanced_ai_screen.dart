// math not required after UI changes
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/services.dart';
import 'dart:typed_data';
import 'package:vora/models/chat_message.dart';
import 'package:vora/service/chat_service.dart';
import 'package:vora/screen/chat_history_screen.dart';
import 'package:vora/screen/voice_assistant_screen.dart';
import 'package:flutter_tts/flutter_tts.dart';

class AdvancedAiScreen extends StatefulWidget {
  const AdvancedAiScreen({super.key});

  @override
  State<AdvancedAiScreen> createState() => _AdvancedAiScreenState();
}

class _AdvancedAiScreenState extends State<AdvancedAiScreen>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // AppBar area
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/images/logofd.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Vora AI',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Advanced Assistant',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton(
                    icon: Icon(
                      Icons.more_vert_rounded,
                      color:
                          Theme.of(context).iconTheme.color?.withOpacity(0.7),
                    ),
                    color: Theme.of(context).cardColor,
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        onTap: _startNewChat,
                        child: Row(
                          children: [
                            const Icon(Icons.add_rounded,
                                color: Color(0xff38ef8d)),
                            const SizedBox(width: 10),
                            Text(
                              'New Chat',
                              style: TextStyle(
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.color),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        child: Row(
                          children: [
                            const Icon(
                              Icons.history_rounded,
                              color: Color(0xffa78bfa),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'History',
                              style: TextStyle(
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.color),
                            ),
                          ],
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ChatHistoryScreen(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Messages area
            Expanded(
              child: _messages.isEmpty
                  ? Center(
                      child: Text(
                        'No messages yet',
                        style: TextStyle(
                            color: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.color
                                ?.withOpacity(0.5)),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController, // Keep controller
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      itemCount: _messages.length + (_isLoading ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _messages.length && _isLoading) {
                          return _buildLoadingIndicator();
                        }
                        return _buildMessageBubble(_messages[index]);
                      },
                    ),
            ),
            // Input area
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  late ChatService _chatService;
  bool _isLoading = false;
  late AnimationController _animationController;

  String _currentSessionId = '';

  late FlutterTts _flutterTts;
  final bool _isListening = false;
  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
    _chatService = ChatService();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _flutterTts = FlutterTts();

    _initializeChat();
  }

  void _initializeChat() {
    _currentSessionId = DateTime.now().millisecondsSinceEpoch.toString();
    _messages.add(
      ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content:
            "Hello! I'm Vora, your advanced AI assistant. I can help you with:\n\n📝 Writing and generating code\n📂 Analyzing uploaded files\n🧠 Solving complex problems\n💬 Answering questions\n\nWhat would you like help with?",
        isUser: false,
        role: 'assistant',
        timestamp: DateTime.now(),
      ),
    );
  }

  Future<void> _sendMessage() async {
    final userMessage = _messageController.text.trim();
    if (userMessage.isEmpty) return;

    setState(() {
      _messages.add(
        ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: userMessage,
          isUser: true,
          role: 'user',
          timestamp: DateTime.now(),
        ),
      );
      _isLoading = true;
    });

    // No TTS for user message

    _messageController.clear();
    _scrollToBottom();

    try {
      final response = await _chatService.sendMessage(userMessage);
      setState(() {
        _messages.add(response);
        _isLoading = false;
      });

      // Save to history
      await _chatService.updateChatSession(_currentSessionId, _messages);
    } catch (e) {
      setState(() {
        _messages.add(
          ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            content: '⚠️ Error: ${e.toString()}',
            isUser: false,
            role: 'assistant',
            timestamp: DateTime.now(),
          ),
        );
        _isLoading = false;
      });
    }

    _scrollToBottom();
  }

  Future<void> _uploadAndAnalyzeFile() async {
    try {
      final file = await _chatService.pickFile();
      if (file == null) return;

      setState(() {
        _messages.add(
          ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            content:
                '📁 Analyzing: ${(file.path ?? 'file').split('/').last}...',
            isUser: true,
            role: 'user',
            timestamp: DateTime.now(),
            fileName: (file.path ?? 'file').split('/').last,
          ),
        );
        _isLoading = true;
      });

      _scrollToBottom();

      final fileName = file.path?.split('/').last ?? 'file';
      final fileBytes = file.bytes ?? Uint8List(0);
      final response = await _chatService.analyzeFile(fileName, fileBytes);
      setState(() {
        _messages.add(response);
        _isLoading = false;
      });

      await _chatService.updateChatSession(_currentSessionId, _messages);
    } catch (e) {
      setState(() {
        _messages.add(
          ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            content: '❌ File analysis failed: ${e.toString()}',
            isUser: false,
            role: 'assistant',
            timestamp: DateTime.now(),
          ),
        );
        _isLoading = false;
      });
    }

    _scrollToBottom();
  }

  void _showCodeGenerationDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String language = 'Dart';
        final requirementController = TextEditingController();

        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: Text(
            '🚀 Generate Code',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton<String>(
                  value: language,
                  dropdownColor: Theme.of(context).cardColor,
                  style: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge?.color),
                  items: [
                    'Dart',
                    'Python',
                    'JavaScript',
                    'TypeScript',
                    'Java',
                    'C++',
                    'Go',
                    'Rust',
                  ]
                      .map(
                        (lang) => DropdownMenuItem(
                          value: lang,
                          child: Text(lang),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      language = value;
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: requirementController,
                  maxLines: 5,
                  style: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge?.color),
                  decoration: InputDecoration(
                    hintText: 'Describe what code you need...',
                    hintStyle: TextStyle(
                        color: Theme.of(context).textTheme.bodySmall?.color),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Theme.of(context).dividerColor.withOpacity(0.3),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color),
              ),
            ),
            TextButton(
              onPressed: () async {
                if (requirementController.text.isEmpty) return;

                Navigator.pop(context);
                await _generateCode(language, requirementController.text);
              },
              child: const Text(
                'Generate',
                style: TextStyle(
                  color: Color(0xff38ef8d),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _generateCode(String language, String requirement) async {
    try {
      setState(() {
        _messages.add(
          ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            content: '💻 Generating $language code...',
            isUser: true,
            role: 'user',
            timestamp: DateTime.now(),
          ),
        );
        _isLoading = true;
      });

      _scrollToBottom();

      final response = await _chatService.generateCode(requirement, language);
      setState(() {
        _messages.add(response);
        _isLoading = false;
      });

      await _chatService.updateChatSession(_currentSessionId, _messages);
    } catch (e) {
      setState(() {
        _messages.add(
          ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            content: '❌ Code generation failed: ${e.toString()}',
            isUser: false,
            role: 'assistant',
            timestamp: DateTime.now(),
          ),
        );
        _isLoading = false;
      });
    }

    _scrollToBottom();
  }

  void _showProblemSolverDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final problemController = TextEditingController();

        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: Text(
            '🧩 Solve a Problem',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: problemController,
            maxLines: 6,
            style:
                TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
            decoration: InputDecoration(
              hintText: 'Describe the problem you need to solve...',
              hintStyle: TextStyle(
                  color: Theme.of(context).textTheme.bodySmall?.color),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                    color: Theme.of(context).dividerColor.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color),
              ),
            ),
            TextButton(
              onPressed: () async {
                if (problemController.text.isEmpty) return;

                Navigator.pop(context);
                await _solveProblem(problemController.text);
              },
              child: const Text(
                'Solve',
                style: TextStyle(
                  color: Color(0xff38ef8d),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _solveProblem(String problem) async {
    try {
      setState(() {
        _messages.add(
          ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            content: '🧠 Analyzing problem...',
            isUser: true,
            role: 'user',
            timestamp: DateTime.now(),
          ),
        );
        _isLoading = true;
      });

      _scrollToBottom();

      final response = await _chatService.solveProblem(problem);
      setState(() {
        _messages.add(response);
        _isLoading = false;
      });

      await _chatService.updateChatSession(_currentSessionId, _messages);
    } catch (e) {
      setState(() {
        _messages.add(
          ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            content: '❌ Error solving problem: ${e.toString()}',
            isUser: false,
            role: 'assistant',
            timestamp: DateTime.now(),
          ),
        );
        _isLoading = false;
      });
    }

    _scrollToBottom();
  }

  void _startNewChat() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(
          'Start New Chat?',
          style:
              TextStyle(color: Theme.of(context).textTheme.titleLarge?.color),
        ),
        content: Text(
          'Current chat will be saved. Start a new conversation?',
          style:
              TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _chatService.resetForNewChat();
                _messages.clear();
                _currentSessionId =
                    DateTime.now().millisecondsSinceEpoch.toString();
                _initializeChat();
              });
            },
            child: const Text(
              'Start New',
              style: TextStyle(
                color: Color(0xff38ef8d),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildAvatar(bool isUser) {
    if (!isUser) {
      // AI avatar: vora logo, no glow
      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(18)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Image.asset('assets/images/logofd.png', fit: BoxFit.cover),
        ),
      );
    } else {
      // User avatar: Lottie profile, no glow
      final box =
          Hive.isBoxOpen('userProfileBox') ? Hive.box('userProfileBox') : null;
      final profileData = box?.get('currentUser');
      final photoUrl = profileData?['photoUrl'] as String?;
      const lottieKeys = ['female_one', 'female_two', 'male_one', 'male_two'];
      if (photoUrl != null && lottieKeys.contains(photoUrl)) {
        return Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(18)),
          child: ClipOval(
            child: Lottie.asset(
              'assets/lottie/$photoUrl.json',
              fit: BoxFit.cover,
            ),
          ),
        );
      }
      // fallback icon
      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(18)),
        child: Icon(Icons.person,
            color: Theme.of(context).iconTheme.color, size: 18),
      );
    }
  }

  // dot indicator removed (replaced by Lottie typing animation)

  Widget _buildMessageBubble(ChatMessage msg) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            msg.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!msg.isUser) _buildAvatar(false),
          const SizedBox(width: 8),
          Flexible(
            child: GestureDetector(
              onLongPress: () {
                Clipboard.setData(ClipboardData(text: msg.content));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copied to clipboard')),
                );
              },
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: msg.isUser
                      ? const LinearGradient(
                          colors: [Color(0xff667eea), Color(0xff764ba2)],
                        )
                      : LinearGradient(
                          colors: [
                            Theme.of(context).cardColor,
                            Theme.of(context).cardColor.withOpacity(0.8),
                          ],
                        ),
                  borderRadius: BorderRadius.circular(18),
                  border: msg.isUser
                      ? null
                      : Border.all(
                          color:
                              Theme.of(context).dividerColor.withOpacity(0.2),
                          width: 1,
                        ),
                  boxShadow: [
                    BoxShadow(
                      color: msg.isUser
                          ? const Color(0xff667eea).withOpacity(0.2)
                          : Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (msg.fileName != null) ...[
                      Text(
                        '📄 ${msg.fileName}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                    Text(
                      msg.content,
                      style: TextStyle(
                        color: msg.isUser
                            ? Colors.white
                            : Theme.of(context).textTheme.bodyLarge?.color,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                    if (msg.hasCode) ...[
                      const SizedBox(height: 10),
                      _buildCodeHighlight(msg),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (msg.isUser) _buildAvatar(true),
        ],
      ),
    );
  }

  Widget _buildCodeHighlight(ChatMessage msg) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xff38ef8d).withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                msg.codeLanguage ?? 'Code',
                style: const TextStyle(
                  color: Color(0xff38ef8d),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: msg.codeContent ?? ''));
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Code copied!')));
                },
                child: const Icon(
                  Icons.copy_rounded,
                  color: Color(0xff38ef8d),
                  size: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 150),
            child: SingleChildScrollView(
              child: Text(
                msg.codeContent ?? '',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 11,
                  fontFamily: 'Courier New',
                  height: 1.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    // show thinking animation while loading
    if (_isLoading) {
      _animationController.repeat();
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            _buildAvatar(false),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 60,
                    height: 28,
                    child: Lottie.asset(
                      'assets/lottie/thinking.json',
                      repeat: true,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Vora is thinking…',
                    style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      _animationController.stop();
      return const SizedBox.shrink();
    }
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withOpacity(0.5),
        border: Border(
          top: BorderSide(
              color: Theme.of(context).dividerColor.withOpacity(0.1), width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Action buttons
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildActionButton(
                  icon: Icons.upload_file_rounded,
                  label: 'Upload File',
                  onTap: _uploadAndAnalyzeFile,
                  color: const Color(0xff667eea),
                ),
                const SizedBox(width: 8),
                _buildActionButton(
                  icon: Icons.code_rounded,
                  label: 'Generate Code',
                  onTap: _showCodeGenerationDialog,
                  color: const Color(0xff38ef8d),
                ),
                const SizedBox(width: 8),
                _buildActionButton(
                  icon: Icons.lightbulb_rounded,
                  label: 'Solve Problem',
                  onTap: _showProblemSolverDialog,
                  color: const Color(0xffff6b6b),
                ),
                const SizedBox(width: 8),
                _buildActionButton(
                  icon: Icons.history_rounded,
                  label: 'History',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ChatHistoryScreen(),
                    ),
                  ),
                  color: const Color(0xffa78bfa),
                ),
                const SizedBox(width: 8),
                _buildActionButton(
                  icon: Icons.event,
                  label: 'Make Your Future',
                  onTap: _addEventToCalendar,
                  color: const Color(0xff4caf50),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (_isListening)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.red,
                      strokeWidth: 3,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Listening...',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          if (_isSpeaking)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.green,
                      strokeWidth: 3,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'AI Speaking...',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                    onPressed: _stopSpeaking,
                    icon: const Icon(Icons.stop),
                    label: const Text('Stop'),
                  ),
                ],
              ),
            ),
          // Message input
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.mic, color: Colors.green),
                onPressed: _openVoiceAssistant,
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).inputDecorationTheme.fillColor,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TextField(
                    controller: _messageController,
                    style: Theme.of(context).textTheme.bodyLarge,
                    maxLines: null,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(
                              color: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.color
                                  ?.withOpacity(0.5)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _isLoading ? null : _sendMessage,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: _isLoading
                        ? LinearGradient(
                            colors: [
                              Colors.grey.withOpacity(0.2),
                              Colors.grey.withOpacity(0.1),
                            ],
                          )
                        : const LinearGradient(
                            colors: [Color(0xff38ef8d), Color(0xff11998e)],
                          ),
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: _isLoading
                        ? []
                        : [
                            BoxShadow(
                              color: const Color(0xff38ef8d).withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                  ),
                  child: Icon(
                    _isLoading
                        ? Icons.hourglass_empty_rounded
                        : Icons.send_rounded,
                    color: _isLoading ? Colors.grey : Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // listening now handled by voice assistant screen; functions removed

  Future<void> _stopSpeaking() async {
    await _flutterTts.stop();
    setState(() => _isSpeaking = false);
  }

  // Open the voice assistant screen when mic icon is pressed
  void _openVoiceAssistant() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const VoiceAssistantScreen()),
    );
  }

  // Placeholder for the calendar event feature
  Future<void> _addEventToCalendar() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Calendar integration coming soon!')),
    );
  }
}
