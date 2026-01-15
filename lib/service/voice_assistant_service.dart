import 'package:vora/service/chat_service.dart';

class VoiceAssistantService {
  final ChatService _chatService = ChatService();

  Future<String> getAiResponse(String userInput) async {
    try {
      final response = await _chatService.sendMessage(userInput);
      return response.content;
    } catch (e) {
      return 'Sorry, I could not process your request.';
    }
  }
}
