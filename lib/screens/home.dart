import 'package:flutter/material.dart';
import 'package:diplom/models/user.dart';
import 'package:diplom/widgets/app_drawer.dart';

class HomeScreen extends StatelessWidget {
  final User user;

  const HomeScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Корпоративный портал')),
      drawer: AppDrawer(user: user),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Добро пожаловать, ${user.name}!',
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 20),
            const Text('Здесь будет главная страница'),
          ],
        ),
      ),
    );
  }
}
