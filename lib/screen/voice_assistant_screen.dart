import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:lottie/lottie.dart';
import 'package:vora/service/voice_assistant_service.dart';

class VoiceAssistantScreen extends StatefulWidget {
  const VoiceAssistantScreen({super.key});

  @override
  State<VoiceAssistantScreen> createState() => _VoiceAssistantScreenState();
}

class _VoiceAssistantScreenState extends State<VoiceAssistantScreen>
    with SingleTickerProviderStateMixin {
  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;
  bool _isListening = false;
  bool _isSpeaking = false;
  String _voiceInput = '';
  String _aiResponse = '';
  late AnimationController _circleController;
  final VoiceAssistantService _voiceService = VoiceAssistantService();

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();
    _circleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _speech.stop();
    _flutterTts.stop();
    _circleController.dispose();
    super.dispose();
  }

  Future<void> _startListening() async {
    bool available = await _speech.initialize();
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (result) {
          setState(() => _voiceInput = result.recognizedWords);
        },
      );
    }
  }

  Future<void> _stopListening() async {
    setState(() => _isListening = false);
    await _speech.stop();
    if (_voiceInput.isNotEmpty) {
      setState(() {
        _aiResponse = '';
      });
      final aiText = await _voiceService.getAiResponse(_voiceInput);
      setState(() {
        _aiResponse = aiText;
      });
      _speak(aiText);
    }
  }

  Future<void> _speak(String text) async {
    setState(() => _isSpeaking = true);
    await _flutterTts.speak(text);
    setState(() => _isSpeaking = false);
  }

  Future<void> _stopSpeaking() async {
    await _flutterTts.stop();
    setState(() => _isSpeaking = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff121B22),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Voice Assistant',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _isListening
                ? Lottie.asset(
                    'assets/lottie/voice_animation.json',
                    width: 160,
                    height: 160,
                    repeat: true,
                  )
                : Container(
                    width: 120,
                    height: 120,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xff232323),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.mic_none,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                  ),
            const SizedBox(height: 32),
            Text(
              _isListening
                  ? 'Listening...'
                  : _isSpeaking
                  ? 'AI Speaking...'
                  : 'Tap the mic to start',
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 24),
            if (_voiceInput.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  'You: $_voiceInput',
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            if (_aiResponse.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 12,
                ),
                child: Text(
                  'AI: $_aiResponse',
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FloatingActionButton(
                  backgroundColor: _isListening ? Colors.red : Colors.green,
                  onPressed: _isListening ? _stopListening : _startListening,
                  child: Icon(_isListening ? Icons.stop : Icons.mic),
                ),
                const SizedBox(width: 24),
                if (_isSpeaking)
                  FloatingActionButton(
                    backgroundColor: Colors.red,
                    onPressed: _stopSpeaking,
                    child: const Icon(Icons.stop),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
