import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../../../shared/models/note_model.dart';
import '../../../shared/models/khata_model.dart';
import '../../../shared/models/reminder_model.dart';
import '../../../shared/models/todo_model.dart';
import '../../../shared/models/chat_message_model.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'assist.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE notes (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL DEFAULT '',
        content TEXT NOT NULL DEFAULT '',
        color TEXT NOT NULL DEFAULT '#1E1E2E',
        tags TEXT NOT NULL DEFAULT '[]',
        is_pinned INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE khata_entries (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        category TEXT NOT NULL DEFAULT '',
        description TEXT NOT NULL DEFAULT '',
        person_name TEXT NOT NULL DEFAULT '',
        date INTEGER NOT NULL,
        is_settled INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE reminders (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL DEFAULT '',
        description TEXT NOT NULL DEFAULT '',
        reminder_time INTEGER NOT NULL,
        is_recurring INTEGER NOT NULL DEFAULT 0,
        recurrence_type TEXT NOT NULL DEFAULT '',
        is_completed INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE todos (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL DEFAULT '',
        description TEXT NOT NULL DEFAULT '',
        priority TEXT NOT NULL DEFAULT 'medium',
        due_date INTEGER,
        is_completed INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE chat_messages (
        id TEXT PRIMARY KEY,
        role TEXT NOT NULL,
        content TEXT NOT NULL DEFAULT '',
        session_id TEXT NOT NULL DEFAULT '',
        timestamp INTEGER NOT NULL
      )
    ''');

    // Indexes
    await db.execute(
        'CREATE INDEX idx_notes_updated ON notes(updated_at DESC)');
    await db.execute(
        'CREATE INDEX idx_khata_date ON khata_entries(date DESC)');
    await db.execute(
        'CREATE INDEX idx_reminders_time ON reminders(reminder_time ASC)');
    await db.execute(
        'CREATE INDEX idx_todos_created ON todos(created_at DESC)');
    await db.execute(
        'CREATE INDEX idx_chat_session ON chat_messages(session_id, timestamp)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle migrations here as app evolves
  }

  // ─── NOTES ───────────────────────────────────────────────────────────────

  Future<String> insertNote(NoteModel note) async {
    final db = await database;
    await db.insert('notes', note.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    return note.id;
  }

  Future<List<NoteModel>> getAllNotes() async {
    final db = await database;
    final rows = await db.query('notes',
        orderBy: 'is_pinned DESC, updated_at DESC');
    return rows.map(NoteModel.fromMap).toList();
  }

  Future<NoteModel?> getNoteById(String id) async {
    final db = await database;
    final rows = await db.query('notes', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return NoteModel.fromMap(rows.first);
  }

  Future<List<NoteModel>> searchNotes(String query) async {
    final db = await database;
    final q = '%$query%';
    final rows = await db.query(
      'notes',
      where: 'title LIKE ? OR content LIKE ?',
      whereArgs: [q, q],
      orderBy: 'updated_at DESC',
    );
    return rows.map(NoteModel.fromMap).toList();
  }

  Future<void> updateNote(NoteModel note) async {
    final db = await database;
    await db.update('notes', note.toMap(),
        where: 'id = ?', whereArgs: [note.id]);
  }

  Future<void> deleteNote(String id) async {
    final db = await database;
    await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> togglePinNote(String id, bool isPinned) async {
    final db = await database;
    await db.update(
      'notes',
      {'is_pinned': isPinned ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ─── KHATA ENTRIES ───────────────────────────────────────────────────────

  Future<String> insertKhataEntry(KhataEntry entry) async {
    final db = await database;
    await db.insert('khata_entries', entry.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    return entry.id;
  }

  Future<List<KhataEntry>> getAllKhataEntries() async {
    final db = await database;
    final rows =
        await db.query('khata_entries', orderBy: 'date DESC');
    return rows.map(KhataEntry.fromMap).toList();
  }

  Future<List<KhataEntry>> getKhataEntriesByType(String type) async {
    final db = await database;
    final rows = await db.query('khata_entries',
        where: 'type = ?', whereArgs: [type], orderBy: 'date DESC');
    return rows.map(KhataEntry.fromMap).toList();
  }

  Future<List<KhataEntry>> getKhataEntriesByMonth(int year, int month) async {
    final start = DateTime(year, month, 1).millisecondsSinceEpoch;
    final end = DateTime(year, month + 1, 1).millisecondsSinceEpoch;
    final db = await database;
    final rows = await db.query(
      'khata_entries',
      where: 'date >= ? AND date < ?',
      whereArgs: [start, end],
      orderBy: 'date DESC',
    );
    return rows.map(KhataEntry.fromMap).toList();
  }

  Future<void> updateKhataEntry(KhataEntry entry) async {
    final db = await database;
    await db.update('khata_entries', entry.toMap(),
        where: 'id = ?', whereArgs: [entry.id]);
  }

  Future<void> deleteKhataEntry(String id) async {
    final db = await database;
    await db.delete('khata_entries', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> settleUdhari(String id) async {
    final db = await database;
    await db.update(
      'khata_entries',
      {'is_settled': 1},
      where: 'id = ? AND type = ?',
      whereArgs: [id, 'udhari'],
    );
  }

  Future<Map<String, double>> getKhataSummary() async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT 
        SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END) as total_income,
        SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END) as total_expense,
        SUM(CASE WHEN type = 'udhari' AND is_settled = 0 THEN amount ELSE 0 END) as total_udhari
      FROM khata_entries
    ''');
    if (rows.isEmpty) {
      return {'income': 0, 'expense': 0, 'udhari': 0};
    }
    final row = rows.first;
    return {
      'income': (row['total_income'] as num?)?.toDouble() ?? 0,
      'expense': (row['total_expense'] as num?)?.toDouble() ?? 0,
      'udhari': (row['total_udhari'] as num?)?.toDouble() ?? 0,
    };
  }

  // ─── REMINDERS ───────────────────────────────────────────────────────────

  Future<String> insertReminder(ReminderModel reminder) async {
    final db = await database;
    await db.insert('reminders', reminder.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    return reminder.id;
  }

  Future<List<ReminderModel>> getAllReminders() async {
    final db = await database;
    final rows =
        await db.query('reminders', orderBy: 'reminder_time ASC');
    return rows.map(ReminderModel.fromMap).toList();
  }

  Future<List<ReminderModel>> getPendingReminders() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final db = await database;
    final rows = await db.query(
      'reminders',
      where: 'reminder_time >= ? AND is_completed = 0',
      whereArgs: [now],
      orderBy: 'reminder_time ASC',
    );
    return rows.map(ReminderModel.fromMap).toList();
  }

  Future<void> updateReminder(ReminderModel reminder) async {
    final db = await database;
    await db.update('reminders', reminder.toMap(),
        where: 'id = ?', whereArgs: [reminder.id]);
  }

  Future<void> completeReminder(String id) async {
    final db = await database;
    await db.update(
      'reminders',
      {'is_completed': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteReminder(String id) async {
    final db = await database;
    await db.delete('reminders', where: 'id = ?', whereArgs: [id]);
  }

  // ─── TODOS ────────────────────────────────────────────────────────────────

  Future<String> insertTodo(TodoModel todo) async {
    final db = await database;
    await db.insert('todos', todo.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    return todo.id;
  }

  Future<List<TodoModel>> getAllTodos() async {
    final db = await database;
    final rows = await db.query('todos', orderBy: 'created_at DESC');
    return rows.map(TodoModel.fromMap).toList();
  }

  Future<List<TodoModel>> getPendingTodos() async {
    final db = await database;
    final rows = await db.query('todos',
        where: 'is_completed = 0', orderBy: 'created_at DESC');
    return rows.map(TodoModel.fromMap).toList();
  }

  Future<void> updateTodo(TodoModel todo) async {
    final db = await database;
    await db.update('todos', todo.toMap(),
        where: 'id = ?', whereArgs: [todo.id]);
  }

  Future<void> toggleTodo(String id, bool isCompleted) async {
    final db = await database;
    await db.update(
      'todos',
      {'is_completed': isCompleted ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteTodo(String id) async {
    final db = await database;
    await db.delete('todos', where: 'id = ?', whereArgs: [id]);
  }

  // ─── CHAT MESSAGES ────────────────────────────────────────────────────────

  Future<String> insertChatMessage(ChatMessage message) async {
    final db = await database;
    await db.insert('chat_messages', message.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    return message.id;
  }

  Future<List<ChatMessage>> getChatMessages(String sessionId,
      {int limit = 50}) async {
    final db = await database;
    final rows = await db.query(
      'chat_messages',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'timestamp ASC',
      limit: limit,
    );
    return rows.map(ChatMessage.fromMap).toList();
  }

  Future<List<ChatMessage>> getAllChatMessages({int limit = 100}) async {
    final db = await database;
    final rows = await db.query(
      'chat_messages',
      orderBy: 'timestamp ASC',
      limit: limit,
    );
    return rows.map(ChatMessage.fromMap).toList();
  }

  Future<void> deleteChatMessage(String id) async {
    final db = await database;
    await db.delete('chat_messages', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearChatSession(String sessionId) async {
    final db = await database;
    await db.delete('chat_messages',
        where: 'session_id = ?', whereArgs: [sessionId]);
  }

  // ─── UTILITY ─────────────────────────────────────────────────────────────

  Future<void> close() async {
    _db?.close();
    _db = null;
  }
}
