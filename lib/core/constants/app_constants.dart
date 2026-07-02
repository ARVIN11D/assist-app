// ASSIST App Constants
// All API keys are stored via Settings screen → SharedPreferences (not hardcoded here)
class AppConstants {
  AppConstants._();

  static const String appName = 'ASSIST';
  static const String appTagline = 'Your AI Personal Secretary';
  static const String appVersion = '1.0.0';

  // ── Supabase (set via Settings screen, stored in SharedPreferences) ──
  // Leave empty – user enters these in Settings → API Settings
  static const String supabaseUrl = '';
  static const String supabaseAnonKey = '';

  // ── SharedPreferences keys ─────────────────────────────────────────
  static const String geminiApiKeyPref = 'gemini_api_key';
  static const String supabaseUrlPref = 'supabase_url';
  static const String supabaseKeyPref = 'supabase_key';
  static const String userNamePref = 'user_name';
  static const String onboardedPref = 'is_onboarded';
  static const String themeModePref = 'theme_mode';
  static const String chatSessionIdPref = 'chat_session_id';
  static const String biometricEnabledPref = 'biometric_enabled';

  // ── Database ────────────────────────────────────────────────────────
  static const String dbName = 'assist.db';
  static const int dbVersion = 1;

  // ── Notification Channels ──────────────────────────────────────────
  static const String reminderChannelId = 'assist_reminders';
  static const String reminderChannelName = 'Reminders';
  static const String alarmChannelId = 'assist_alarms';
  static const String alarmChannelName = 'Alarms';

  // ── Khata Categories ───────────────────────────────────────────────
  static const List<String> incomeCategories = [
    'Salary',
    'Business',
    'Consultation',
    'Rent',
    'Investment',
    'Freelance',
    'Other',
  ];

  static const List<String> expenseCategories = [
    'Food & Grocery',
    'Medical',
    'Transport',
    'Fuel',
    'Shopping',
    'Utilities',
    'Education',
    'Entertainment',
    'Home',
    'Clothing',
    'Medicines',
    'Other',
  ];

  // ── Gemini AI System Prompt ────────────────────────────────────────
  static const String aiSystemPrompt = '''
You are ASSIST, an intelligent AI personal secretary for an Indian user. Your personality is:
- Helpful, concise, and professional yet warm
- Knowledgeable about Indian context (currency in ₹, dates in Indian format, common Indian expenses)
- Proactive in suggesting actions (e.g., "Want me to set a reminder for that?")
- You can help with: notes, expenses (Khata), reminders, todos, and general queries

When the user wants to track finances, use ₹ (Indian Rupee).
When you detect an intent to create a note/expense/todo/reminder, acknowledge it clearly.
Keep responses concise and actionable. If uncertain, ask for clarification.
You understand Hindi words mixed with English (Hinglish) and Marathi.
''';
}
