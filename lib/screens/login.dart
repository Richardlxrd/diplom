import 'package:flutter/material.dart';
import 'package:diplom/database/db_helper.dart';
import 'package:diplom/models/user.dart';
import 'package:diplom/screens/home.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final dbHelper = DatabaseHelper.instance;
    final user = await dbHelper.getUserByEmail(_emailController.text);

    if (user == null || user['password'] != _passwordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Неверный email или пароль')),
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => HomeScreen(user: User.fromMap(user))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Вход в систему')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Введите email';
                  if (!value.contains('@')) return 'Некорректный email';
                  return null;
                },
              ),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Пароль'),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Введите пароль';
                  if (value.length < 6) return 'Пароль слишком короткий';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _login, child: const Text('Войти')),
            ],
          ),
        ),
      ),
    );
  }
}
