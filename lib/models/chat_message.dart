import 'package:hive/hive.dart';

part 'chat_message.g.dart';

@HiveType(typeId: 0)
class ChatMessage extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String content;

  @HiveField(2)
  late bool isUser;

  @HiveField(3)
  late String role; // 'user' or 'assistant'

  @HiveField(4)
  late DateTime timestamp;

  @HiveField(5)
  late String? codeContent;

  @HiveField(6)
  late String? codeLanguage;

  @HiveField(7)
  late String? fileName;

  @HiveField(8)
  late String? fileType;

  ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.role,
    required this.timestamp,
    this.codeContent,
    this.codeLanguage,
    this.fileName,
    this.fileType,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      content: json['content'] as String,
      isUser: json['isUser'] as bool,
      role: json['role'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      codeContent: json['codeContent'] as String?,
      codeLanguage: json['codeLanguage'] as String?,
      fileName: json['fileName'] as String?,
      fileType: json['fileType'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'isUser': isUser,
      'role': role,
      'timestamp': timestamp.toIso8601String(),
      'codeContent': codeContent,
      'codeLanguage': codeLanguage,
      'fileName': fileName,
      'fileType': fileType,
    };
  }

  bool get hasCode => codeContent != null && codeContent!.isNotEmpty;
}
