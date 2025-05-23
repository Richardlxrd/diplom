import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart'
    if (dart.library.html) 'dart:html';

/// Главный класс для работы с базой данных
class DatabaseHelper {
  // Настройки базы данных
  static const String _databaseName = 'corporate_portal.db';
  static const int _databaseVersion = 2;

  // Таблица пользователей
  static const String tableUsers = 'users';
  static const String columnUserId = 'id';
  static const String columnUserName = 'name';
  static const String columnUserEmail = 'email';
  static const String columnUserPassword = 'password';
  static const String columnUserPosition = 'position';
  static const String columnUserAvatar = 'avatar';

  // Таблица новостей
  static const String tableNews = 'news';
  static const String columnNewsId = 'id';
  static const String columnNewsTitle = 'title';
  static const String columnNewsContent = 'content';
  static const String columnNewsAuthorId = 'author_id';
  static const String columnNewsDate = 'date';
  static const String columnNewsImage = 'image';

  // Таблица задач
  static const String tableTasks = 'tasks';
  static const String columnTaskId = 'id';
  static const String columnTaskTitle = 'title';
  static const String columnTaskDescription = 'description';
  static const String columnTaskAssigneeId = 'assignee_id';
  static const String columnTaskStatus = 'status';
  static const String columnTaskDeadline = 'deadline';
  static const String columnTaskPriority = 'priority';

  // Singleton экземпляр
  static Database? _database;
  static final DatabaseHelper instance = DatabaseHelper._internal();

  factory DatabaseHelper() => instance;

  DatabaseHelper._internal();

  /// Инициализация базы данных с проверкой платформы
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Инициализация базы данных
  Future<Database> _initDatabase() async {
    // Инициализация для десктопных платформ
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux ||
            defaultTargetPlatform == TargetPlatform.macOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    try {
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
    } catch (e) {
      throw Exception('Failed to initialize database: $e');
    }
  }

  /// Создание таблиц при первом запуске
  Future<void> _onCreate(Database db, int version) async {
    await db.transaction((txn) async {
      // Таблица пользователей
      await txn.execute('''
        CREATE TABLE $tableUsers (
          $columnUserId INTEGER PRIMARY KEY AUTOINCREMENT,
          $columnUserName TEXT NOT NULL,
          $columnUserEmail TEXT NOT NULL UNIQUE,
          $columnUserPassword TEXT NOT NULL,
          $columnUserPosition TEXT,
          $columnUserAvatar TEXT
        )
      ''');

      // Таблица новостей
      await txn.execute('''
        CREATE TABLE $tableNews (
          $columnNewsId INTEGER PRIMARY KEY AUTOINCREMENT,
          $columnNewsTitle TEXT NOT NULL,
          $columnNewsContent TEXT NOT NULL,
          $columnNewsAuthorId INTEGER NOT NULL,
          $columnNewsDate TEXT NOT NULL,
          $columnNewsImage TEXT,
          FOREIGN KEY ($columnNewsAuthorId) REFERENCES $tableUsers ($columnUserId) ON DELETE CASCADE
        )
      ''');

      // Таблица задач
      await txn.execute('''
        CREATE TABLE $tableTasks (
          $columnTaskId INTEGER PRIMARY KEY AUTOINCREMENT,
          $columnTaskTitle TEXT NOT NULL,
          $columnTaskDescription TEXT,
          $columnTaskAssigneeId INTEGER,
          $columnTaskStatus TEXT NOT NULL DEFAULT 'pending',
          $columnTaskDeadline TEXT,
          $columnTaskPriority INTEGER DEFAULT 1,
          FOREIGN KEY ($columnTaskAssigneeId) REFERENCES $tableUsers ($columnUserId) ON DELETE SET NULL
        )
      ''');

      // Тестовые данные
      await _insertTestData(txn);
    });
  }

  /// Миграция базы данных при обновлении версии
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE $tableUsers ADD COLUMN $columnUserAvatar TEXT',
      );
    }
  }

  /// Вставка тестовых данных
  Future<void> _insertTestData(DatabaseExecutor db) async {
    // Тестовый администратор
    final adminId = await db.insert(tableUsers, {
      columnUserName: 'Администратор',
      columnUserEmail: 'admin@company.com',
      columnUserPassword: 'admin123',
      columnUserPosition: 'Системный администратор',
      columnUserAvatar: '',
    });

    // Тестовые новости
    await db.insert(tableNews, {
      columnNewsTitle: 'Добро пожаловать в корпоративный портал!',
      columnNewsContent: 'Это ваша первая новость в системе.',
      columnNewsAuthorId: adminId,
      columnNewsDate: DateTime.now().toIso8601String(),
    });

    // Тестовая задача
    await db.insert(tableTasks, {
      columnTaskTitle: 'Ознакомиться с системой',
      columnTaskDescription: 'Изучить все возможности портала',
      columnTaskAssigneeId: adminId,
      columnTaskStatus: 'in_progress',
      columnTaskDeadline: DateTime.now()
          .add(const Duration(days: 7))
          .toIso8601String(),
      columnTaskPriority: 2,
    });
  }

  // ==================== CRUD операции ====================

  /// Добавление нового пользователя
  Future<int> insertUser(Map<String, dynamic> user) async {
    final db = await instance.database;
    return await db.insert(tableUsers, user);
  }

  /// Получение пользователя по email
  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final db = await instance.database;
    final result = await db.query(
      tableUsers,
      where: '$columnUserEmail = ?',
      whereArgs: [email],
    );
    return result.isNotEmpty ? result.first : null;
  }

  /// Получение всех новостей с информацией об авторе
  Future<List<Map<String, dynamic>>> getAllNews() async {
    final db = await instance.database;
    return await db.rawQuery('''
      SELECT n.*, u.$columnUserName as author_name 
      FROM $tableNews n 
      JOIN $tableUsers u ON n.$columnNewsAuthorId = u.$columnUserId
      ORDER BY n.$columnNewsDate DESC
    ''');
  }

  /// Получение задач пользователя
  Future<List<Map<String, dynamic>>> getUserTasks(int userId) async {
    final db = await instance.database;
    return await db.query(
      tableTasks,
      where: '$columnTaskAssigneeId = ?',
      whereArgs: [userId],
      orderBy: columnTaskPriority,
    );
  }

  /// Обновление статуса задачи
  Future<int> updateTaskStatus(int taskId, String status) async {
    final db = await instance.database;
    return await db.update(
      tableTasks,
      {columnTaskStatus: status},
      where: '$columnTaskId = ?',
      whereArgs: [taskId],
    );
  }

  /// Закрытие соединения с базой данных
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
