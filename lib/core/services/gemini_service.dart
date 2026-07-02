import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../constants/app_constants.dart';

class GeminiService {
  final String apiKey;
  late final GenerativeModel _model;

  GeminiService({required this.apiKey}) {
    _model = GenerativeModel(
      model: 'gemini-1.5-pro',
      apiKey: apiKey,
      systemInstruction: Content.system(AppConstants.aiSystemPrompt),
      generationConfig: GenerationConfig(
        temperature: 0.7,
        topP: 0.9,
        maxOutputTokens: 2048,
      ),
    );
  }

  /// Sends a message and returns the AI response text.
  Future<String> sendMessage(
    String message, {
    List<Map<String, String>> history = const [],
  }) async {
    try {
      final geminiHistory = history.map((h) {
        final role = h['role'] == 'user' ? 'user' : 'model';
        return Content(role, [TextPart(h['content'] ?? '')]);
      }).toList();

      final chat = _model.startChat(history: geminiHistory);
      final response = await chat.sendMessage(Content.text(message));
      return response.text ?? 'I could not generate a response. Please try again.';
    } on GenerativeAIException catch (e) {
      return 'AI Error: ${e.message}. Please check your API key in Settings.';
    } catch (e) {
      return 'An unexpected error occurred. Please try again.';
    }
  }

  /// Parses a user message to determine intent and extract structured data.
  /// Returns a Map like: { "intent": "add_expense", "amount": 500, "category": "food" }
  Future<Map<String, dynamic>?> parseIntent(String message) async {
    const intentPrompt = '''
Analyze the following user message and extract structured intent as JSON.
Return ONLY valid JSON. Possible intents:
- add_expense: { "intent": "add_expense", "amount": number, "category": string, "description": string }
- add_income: { "intent": "add_income", "amount": number, "category": string }
- add_note: { "intent": "add_note", "title": string, "content": string }
- add_todo: { "intent": "add_todo", "title": string, "priority": "high"|"medium"|"low" }
- add_reminder: { "intent": "add_reminder", "title": string, "datetime": ISO8601 string }
- udhari: { "intent": "udhari", "amount": number, "person": string, "direction": "give"|"receive" }
- general: { "intent": "general" }

If the message doesn't match a specific intent, return { "intent": "general" }.
User message: ''';

    try {
      final response = await _model.generateContent([
        Content.text('$intentPrompt"$message"'),
      ]);
      final text = response.text ?? '';
      // Extract JSON from response
      final jsonMatch =
          RegExp(r'\{[\s\S]*\}').firstMatch(text);
      if (jsonMatch != null) {
        return jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;
      }
      return {'intent': 'general'};
    } catch (_) {
      return null;
    }
  }

  /// Generates a quick summary of the user's data.
  Future<String> generateDailySummary({
    required int totalTodos,
    required int completedTodos,
    required int upcomingReminders,
    required double balance,
  }) async {
    final prompt =
        'Give me a brief, encouraging daily summary. I have $completedTodos/$totalTodos todos done, '
        '$upcomingReminders upcoming reminders, and my balance is ₹${balance.toStringAsFixed(0)}. '
        'Keep it under 2 sentences, friendly and motivating.';

    return await sendMessage(prompt);
  }
}

// AppConstants is defined in core/constants/app_constants.dart
