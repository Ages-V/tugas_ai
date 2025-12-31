import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class AiNotifier extends StateNotifier<ChatState> {
  AiNotifier() : super(const ChatState(messages: [])) {
    _initModel();
  }

  late final GenerativeModel _model;

  void _initModel() {
    final String? apiKey = dotenv.env['GEMINI_API_KEY'];

    if (apiKey == null || apiKey.isEmpty) {
      state = state.copyWith(
        messages: const [
          ChatMessage(
            text: 'Error: GEMINI_API_KEY tidak ditemukan',
            isUser: false,
          ),
        ],
      );
      return;
    }

    _model = GenerativeModel(model: 'gemini-3-flash-preview', apiKey: apiKey);
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMessage = ChatMessage(text: text, isUser: true);

    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
    );

    try {
      final response = await _model.generateContent([Content.text(text)]);

      final aiMessage = ChatMessage(
        text:
            response.text ?? 'Maaf, saya tidak dapat menjawab pertanyaan ini.',
        isUser: false,
      );

      state = state.copyWith(
        messages: [...state.messages, aiMessage],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        messages: [
          ...state.messages,
          ChatMessage(text: 'Terjadi kesalahan: $e', isUser: false),
        ],
        isLoading: false,
      );
    }
  }
}

final aiProvider = StateNotifierProvider<AiNotifier, ChatState>((ref) {
  return AiNotifier();
});

class ChatMessage {
  final String text;
  final bool isUser;

  const ChatMessage({required this.text, required this.isUser});
}

class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;

  const ChatState({required this.messages, this.isLoading = false});

  ChatState copyWith({List<ChatMessage>? messages, bool? isLoading}) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
