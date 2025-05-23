import 'package:diplom/database/db_helper.dart';
import 'package:diplom/screens/login.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:diplom/database/db_helper.dart';
import 'package:diplom/screens/login.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Инициализация для десктопных платформ
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.linux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Проверка работы базы данных
  try {
    await DatabaseHelper.instance.database;
    runApp(const MyApp());
  } catch (e) {
    runApp(
      MaterialApp(
        home: Scaffold(body: Center(child: Text('Database error: $e'))),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Corporate Portal',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const LoginScreen(),
    );
  }
}
