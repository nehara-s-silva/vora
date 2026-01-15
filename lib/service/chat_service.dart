import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:vora/models/chat_message.dart';
import 'package:vora/models/chat_session.dart';
import 'package:hive_flutter/hive_flutter.dart';

const String CHAT_HISTORY_BOX = 'chatHistoryBox';
const String FACTS_BOX = 'voraFactsBox';

class ChatService {
  static const String _apiKey =
      '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';
  static const String _apiUrl = 'https://openrouter.ai/api/v1/chat/completions';
  static const String _model = 'openai/gpt-3.5-turbo';

  final List<Map<String, String>> _conversationHistory = [];

  ChatService() {
    // Initialize conversation history
  }

  /// Initialize facts box for local verified facts
  static Future<void> initializeFactsBox() async {
    if (!Hive.isBoxOpen(FACTS_BOX)) {
      await Hive.openBox(FACTS_BOX);
    }
  }

  /// Add or update a verified fact (key -> value)
  Future<void> addFact(String key, String value) async {
    try {
      await initializeFactsBox();
      final box = Hive.box(FACTS_BOX);
      await box.put(key, value);
    } catch (e) {
      debugPrint('Failed to add fact: $e');
    }
  }

  /// Remove a fact by key
  Future<void> removeFact(String key) async {
    try {
      await initializeFactsBox();
      final box = Hive.box(FACTS_BOX);
      await box.delete(key);
    } catch (e) {
      debugPrint('Failed to remove fact: $e');
    }
  }

  /// Get all facts as a Map<String,String>
  Future<Map<String, String>> getAllFacts() async {
    await initializeFactsBox();
    final box = Hive.box(FACTS_BOX);
    final Map<String, String> out = {};
    for (final k in box.keys) {
      final v = box.get(k);
      out[k.toString()] = v?.toString() ?? '';
    }
    return out;
  }

  /// Initialize and open chat history box
  static Future<void> initializeChatBox() async {
    if (!Hive.isBoxOpen(CHAT_HISTORY_BOX)) {
      await Hive.openBox<ChatSession>(CHAT_HISTORY_BOX);
    }
  }

  /// Generate a unique ID
  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        Random().nextInt(10000).toString();
  }

  /// Save chat session to Hive
  Future<void> saveChatSession(
    String sessionId,
    String title,
    List<ChatMessage> messages,
  ) async {
    await initializeChatBox();
    final box = Hive.box<ChatSession>(CHAT_HISTORY_BOX);

    final messagesMaps = messages.map((m) => m.toJson()).toList();

    final session = ChatSession(
      id: sessionId,
      title: title,
      createdAt: DateTime.now(),
      lastModified: DateTime.now(),
      messages: messagesMaps,
    );

    await box.put(sessionId, session);
  }

  /// Update existing chat session
  Future<void> updateChatSession(
    String sessionId,
    List<ChatMessage> messages,
  ) async {
    await initializeChatBox();
    final box = Hive.box<ChatSession>(CHAT_HISTORY_BOX);

    final session = box.get(sessionId);
    if (session != null) {
      session.lastModified = DateTime.now();
      session.messages = messages.map((m) => m.toJson()).toList();
      await session.save();
    }
  }

  /// Get all chat sessions
  Future<List<ChatSession>> getAllChatSessions() async {
    await initializeChatBox();
    final box = Hive.box<ChatSession>(CHAT_HISTORY_BOX);
    return box.values.toList()
      ..sort((a, b) => b.lastModified.compareTo(a.lastModified));
  }

  /// Delete a chat session
  Future<void> deleteChatSession(String sessionId) async {
    await initializeChatBox();
    final box = Hive.box<ChatSession>(CHAT_HISTORY_BOX);
    await box.delete(sessionId);
  }

  /// Get a specific chat session
  Future<ChatSession?> getChatSession(String sessionId) async {
    await initializeChatBox();
    final box = Hive.box<ChatSession>(CHAT_HISTORY_BOX);
    return box.get(sessionId);
  }

  /// Call OpenRouter API
  Future<Map<String, dynamic>> _callOpenRouterApi(
    String message, {
    String? systemPrompt,
  }) async {
    try {
      _conversationHistory.add({'role': 'user', 'content': message});

      // Load local facts (if any) and include them as a high-priority system message.
      String? factsPrompt;
      try {
        if (Hive.isBoxOpen(FACTS_BOX)) {
          final box = Hive.box(FACTS_BOX);
          if (box.isNotEmpty) {
            final buffer = StringBuffer();
            buffer.writeln('Verified facts (from device):');
            for (final key in box.keys) {
              final val = box.get(key)?.toString();
              if (val != null && val.isNotEmpty) buffer.writeln('- $key: $val');
            }
            factsPrompt = buffer.toString();
          }
        }
      } catch (_) {
        // ignore facts loading errors — proceed without local facts
      }

      final defaultSystem = systemPrompt ??
          'You are Vora, an advanced AI assistant. You can help with coding, file analysis, problem-solving, and general questions. When providing code, format it clearly with language identifiers. Be concise but thorough.';

      final messages = [
        if (factsPrompt != null) {'role': 'system', 'content': factsPrompt},
        {'role': 'system', 'content': defaultSystem},
        ..._conversationHistory,
      ];

      final headers = {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
        'HTTP-Referer': 'https://vora.chat.com',
        'X-title': 'Vora',
      };

      final body = jsonEncode({
        'model': _model,
        'messages': messages,
        'max_tokens': 2000,
        'temperature': 0.7,
      });

      final client = http.Client();
      final response = await client
          .post(Uri.parse(_apiUrl), headers: headers, body: body)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'] ?? '';

        _conversationHistory.add({'role': 'assistant', 'content': content});

        return {'success': true, 'content': content, 'usage': data['usage']};
      } else {
        debugPrint('API Error ${response.statusCode}: ${response.body}');
        return {
          'success': false,
          'error':
              'API Error: ${response.statusCode}. Check your internet connection and API key configuration.',
          'details': response.body,
        };
      }
    } catch (e) {
      debugPrint('Chat Service Error: $e');
      final errorMsg = e.toString();
      if (errorMsg.contains('Failed host lookup') ||
          errorMsg.contains('No address')) {
        return {
          'success': false,
          'error':
              'Network Error: No internet connection or unable to reach the AI service. Please check your WiFi/mobile data connection.',
        };
      }
      return {'success': false, 'error': 'Error: $e'};
    }
  }

  /// Send a general message
  Future<ChatMessage> sendMessage(String message) async {
    final response = await _callOpenRouterApi(message);

    if (response['success']) {
      return ChatMessage(
        id: _generateId(),
        content: response['content'],
        isUser: false,
        role: 'assistant',
        timestamp: DateTime.now(),
      );
    } else {
      throw Exception(response['error']);
    }
  }

  /// Analyze code from file
  Future<ChatMessage> analyzeFile(
    String fileName,
    Uint8List fileBytes,
  ) async {
    try {
      // Decode bytes to string
      final content = utf8.decode(fileBytes);

      // Use the provided file name
      final extension = fileName.split('.').last.toLowerCase();

      final languageMap = {
        'dart': 'Dart',
        'py': 'Python',
        'js': 'JavaScript',
        'ts': 'TypeScript',
        'java': 'Java',
        'cpp': 'C++',
        'c': 'C',
        'cs': 'C#',
        'go': 'Go',
        'rs': 'Rust',
        'swift': 'Swift',
        'kt': 'Kotlin',
      };

      final language = languageMap[extension] ?? 'Unknown';

      final prompt = '''Analyze this $language code file and provide:
1. Summary of what it does
2. Potential issues or improvements
3. Code complexity assessment
4. Security concerns (if any)
5. Performance suggestions

File: $fileName

Code:
```$extension
$content
```''';

      final response = await _callOpenRouterApi(prompt);

      if (response['success']) {
        return ChatMessage(
          id: _generateId(),
          content: response['content'],
          isUser: false,
          role: 'assistant',
          timestamp: DateTime.now(),
          fileName: fileName,
          fileType: language,
        );
      } else {
        throw Exception(response['error']);
      }
    } catch (e) {
      throw Exception('Error analyzing file: $e');
    }
  }

  /// Generate code based on requirements
  Future<ChatMessage> generateCode(String requirement, String language) async {
    final prompt =
        '''Generate complete, production-ready $language code based on this requirement:

$requirement

Requirements:
- Use best practices and design patterns
- Include comments for clarity
- Handle error cases
- Make it complete and runnable
- Follow $language conventions

Provide only the code with a brief explanation.''';

    final response = await _callOpenRouterApi(prompt);

    if (response['success']) {
      final content = response['content'];

      // Extract code from response
      final codeMatch = RegExp(
        r'```\w*\n(.*?)\n```',
        dotAll: true,
      ).firstMatch(content);
      final code = codeMatch?.group(1) ?? content;

      return ChatMessage(
        id: _generateId(),
        content: content,
        isUser: false,
        role: 'assistant',
        timestamp: DateTime.now(),
        codeContent: code,
        codeLanguage: language,
      );
    } else {
      throw Exception(response['error']);
    }
  }

  /// Solve a problem
  Future<ChatMessage> solveProblem(String problem) async {
    final prompt = '''Please solve this problem step by step:

$problem

Provide:
1. Problem analysis
2. Step-by-step solution
3. Code example (if applicable)
4. Explanation of approach
5. Alternative solutions (if any)''';

    final response = await _callOpenRouterApi(prompt);

    if (response['success']) {
      return ChatMessage(
        id: _generateId(),
        content: response['content'],
        isUser: false,
        role: 'assistant',
        timestamp: DateTime.now(),
      );
    } else {
      throw Exception(response['error']);
    }
  }

  /// Pick and upload file
  Future<PlatformFile?> pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        withData: true, // Important for web to get bytes
        allowedExtensions: [
          'dart',
          'py',
          'js',
          'ts',
          'java',
          'cpp',
          'c',
          'cs',
          'go',
          'rs',
          'swift',
          'kt',
          'txt',
          'json',
          'xml',
          'yaml',
        ],
      );

      if (result != null && result.files.isNotEmpty) {
        return result.files.single;
      }
      return null;
    } catch (e) {
      debugPrint('File picker error: $e');
      return null;
    }
  }

  /// Clear conversation history
  void clearHistory() {
    _conversationHistory.clear();
  }

  /// Reset for new chat
  void resetForNewChat() {
    _conversationHistory.clear();
  }

  /// Get conversation history
  List<Map<String, String>> getConversationHistory() =>
      List.from(_conversationHistory);
}
