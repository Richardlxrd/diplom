import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseHelper {
  static const String _databaseName = 'corporate_portal.db';
  static const int _databaseVersion = 5;

  // Таблицы и колонки
  static const String tableUsers = 'users';
  static const String tableNews = 'news';
  static const String tableComments = 'comments';
  static const String tableNotifications = 'notifications';
  static const String tableEvents = 'events';

  // Singleton
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Инициализация для десктопных платформ
    if (_isDesktopPlatform()) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<List<Map<String, dynamic>>> getEventsWithOrganizer() async {
    final db = await database;
    return await db.rawQuery('''
    SELECT 
      e.*,
      u.name as organizer_name
    FROM events e
    JOIN users u ON e.organizer_id = u.id
    ORDER BY e.event_date ASC
  ''');
  }

  Future<int> createEvent({
    required String title,
    required String location,
    required DateTime eventDate,
    required int organizerId,
    String? description,
  }) async {
    final db = await database;

    return await db.insert('events', {
      'title': title,
      'description': description,
      'location': location,
      'event_date': eventDate.toIso8601String(),
      'organizer_id': organizerId, // Важно: organizer_id, а не organizer
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<int> updateEvent(Map<String, dynamic> event) async {
    final db = await database;
    return await db.update(
      'events',
      event,
      where: 'id = ?',
      whereArgs: [event['id']],
    );
  }

  Future<int> deleteEvent(int id) async {
    final db = await database;
    return await db.delete('events', where: 'id = ?', whereArgs: [id]);
  }

  bool _isDesktopPlatform() {
    return !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux ||
            defaultTargetPlatform == TargetPlatform.macOS);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.transaction((txn) async {
      await txn.execute('''
        CREATE TABLE $tableUsers (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          email TEXT UNIQUE NOT NULL,
          password TEXT NOT NULL,
          position TEXT,
          department TEXT,
          avatar_url TEXT,
          last_login TEXT
        )
      ''');
      await db.execute('''
    CREATE TABLE events (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      description TEXT,
      location TEXT NOT NULL,
      event_date TEXT NOT NULL,
      organizer_id INTEGER NOT NULL,
      created_at TEXT NOT NULL,
      participants TEXT DEFAULT '[]'
    )
  ''');
      await txn.execute('''
       CREATE TABLE $tableNews (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      content TEXT NOT NULL,
      author_id INTEGER NOT NULL,
      category TEXT,
      image_url TEXT,
      like_count INTEGER DEFAULT 0,
      created_at TEXT NOT NULL,
      FOREIGN KEY (author_id) REFERENCES $tableUsers(id) ON DELETE CASCADE
    )
  ''');

      await txn.execute('''
        CREATE TABLE $tableComments (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          news_id INTEGER NOT NULL,
          user_id INTEGER NOT NULL,
          text TEXT NOT NULL,
          created_at TEXT NOT NULL,
          FOREIGN KEY (news_id) REFERENCES $tableNews(id) ON DELETE CASCADE,
          FOREIGN KEY (user_id) REFERENCES $tableUsers(id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
    CREATE TABLE IF NOT EXISTS events (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      description TEXT,
      location TEXT NOT NULL,
      event_date TEXT NOT NULL,
      organizer_id INTEGER NOT NULL,
      created_at TEXT NOT NULL,
      FOREIGN KEY (organizer_id) REFERENCES users(id)
    )
  ''');

      // Добавляем тестового администратора
      await txn.insert(tableUsers, {
        'name': 'Администратор',
        'email': 'admin@company.com',
        'password': ('admin123'),
        'position': 'Системный администратор',
        'avatar_url': '',
      });
    });
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE $tableUsers ADD COLUMN department TEXT');
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE $tableNotifications (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          title TEXT NOT NULL,
          message TEXT NOT NULL,
          is_read INTEGER DEFAULT 0,
          created_at TEXT NOT NULL,
          FOREIGN KEY (user_id) REFERENCES $tableUsers(id) ON DELETE CASCADE
        )
      ''');
    }
  }

  // Аутентификация
  Future<Map<String, dynamic>?>? authenticate(
    String email,
    String password,
  ) async {
    final db = await database;
    final result = await db.query(
      tableUsers,
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );
    return result.isNotEmpty ? result.first : null;
  }

  // Новости
  Future<List<Map<String, dynamic>>> getNewsFeed() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT n.*, u.name as author_name, u.avatar_url as author_avatar
      FROM $tableNews n
      JOIN $tableUsers u ON n.author_id = u.id
      ORDER BY n.created_at DESC
    ''');
  }

  Future<int> createNews({
    required String title,
    required String content,
    required int authorId,
    String? category,
    String? imageUrl,
  }) async {
    final db = await database;
    return await db.insert(tableNews, {
      'title': title,
      'content': content,
      'author_id': authorId,
      'category': category ?? 'Общее',
      'image_url': imageUrl,
      'created_at': DateTime.now().toIso8601String(),
      'like_count': 0,
    });
  }

  // Остальные методы остаются без изменений...
  Future<int> addNewsLike(int newsId) async {
    final db = await database;
    return await db.rawUpdate(
      '''
      UPDATE $tableNews 
      SET like_count = like_count + 1 
      WHERE id = ?
    ''',
      [newsId],
    );
  }

  Future<List<Map<String, dynamic>>> getNewsComments(int newsId) async {
    final db = await database;
    return await db.rawQuery(
      '''
      SELECT c.*, u.name as user_name, u.avatar_url as user_avatar
      FROM $tableComments c
      JOIN $tableUsers u ON c.user_id = u.id
      WHERE c.news_id = ?
      ORDER BY c.created_at DESC
    ''',
      [newsId],
    );
  }

  Future<List<Map<String, dynamic>>> getUserNotifications(int userId) async {
    final db = await database;
    return await db.query(
      tableNotifications,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
  }
}
