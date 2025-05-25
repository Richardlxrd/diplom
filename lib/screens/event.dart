import 'package:flutter/material.dart';

class EventsScreen extends StatelessWidget {
  final Map<String, dynamic> user;

  const EventsScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Мероприятия')),
      body: Center(child: Text('Список мероприятий')),
    );
  }
}
