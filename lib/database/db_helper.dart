import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseHelper {
  static const String _databaseName = 'corporate_portal.db';
  static const int _databaseVersion = 3;

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

  Future<List<Map<String, dynamic>>> getEvents(dynamic instance) async {
    final db = await instance.database;
    return await db.query('events');
  }

  Future<void> createEvent(Map<String, dynamic> event, dynamic instance) async {
    final db = await instance.database;
    await db.insert('events', event);
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
    location TEXT,
    date TEXT NOT NULL,
    organizer_id INTEGER NOT NULL
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

      await txn.execute('''
        CREATE TABLE $tableEvents (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          description TEXT,
          start_time TEXT NOT NULL,
          end_time TEXT NOT NULL,
          location TEXT,
          organizer_id INTEGER,
          FOREIGN KEY (organizer_id) REFERENCES $tableUsers(id) ON DELETE SET NULL
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

  Future<List<Map<String, dynamic>>> getUpcomingEvents() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT e.*, u.name as organizer_name
      FROM $tableEvents e
      LEFT JOIN $tableUsers u ON e.organizer_id = u.id
      WHERE e.start_time > datetime('now')
      ORDER BY e.start_time ASC
      LIMIT 10
    ''');
  }
}
