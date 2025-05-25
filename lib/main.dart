import 'package:diplom/database/db_helper.dart';
import 'package:diplom/screens/login.dart';
import 'package:diplom/screens/news_feed.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper().database; // Инициализация БД

  runApp(const CorporatePortalApp());
}

class CorporatePortalApp extends StatelessWidget {
  const CorporatePortalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      routes: {
        'news_feed': (context) => NewsFeedScreen(
          user:
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>,
        ),
      },
      title: 'Корпоративный портал',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      home: LoginScreen(),
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
