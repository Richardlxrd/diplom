import 'package:flutter/material.dart';
import 'package:diplom/models/user.dart';

class AppDrawer extends StatelessWidget {
  final User user;

  const AppDrawer({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(user.name),
            accountEmail: Text(user.email),
            currentAccountPicture: const CircleAvatar(
              child: Icon(Icons.person),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Главная'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.article),
            title: const Text('Новости'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.task),
            title: const Text('Задачи'),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.exit_to_app),
            title: const Text('Выход'),
            onTap: () => Navigator.popUntil(context, (route) => route.isFirst),
          ),
        ],
      ),
    );
  }
}
