import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/db_helper.dart'; // Импорт вашего DatabaseHelper

class EventsScreen extends StatefulWidget {
  const EventsScreen({Key? key}) : super(key: key);

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  late Future<List<Map<String, dynamic>>> _eventsFuture;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  void _loadEvents() {
    setState(() {
      _eventsFuture = _dbHelper.getEventsWithOrganizer();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Мероприятия'), centerTitle: true),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _eventsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          }

          final events = snapshot.data!;

          if (events.isEmpty) {
            return const Center(child: Text('Нет предстоящих мероприятий'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: events.length,
            itemBuilder: (context, index) {
              return _buildEventCard(context, events[index]);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _showAddEventForm(context),
      ),
    );
  }

  Widget _buildEventCard(
    BuildContext parentContext,
    Map<String, dynamic> event,
  ) {
    final date = DateTime.parse(event['date']);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateToEventDetails(parentContext, event),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event['title'],
                style: Theme.of(parentContext).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              _buildEventDetailRow(
                Icons.access_time,
                DateFormat('dd.MM.yyyy HH:mm').format(date),
              ),
              _buildEventDetailRow(Icons.location_on, event['location']),
              _buildEventDetailRow(Icons.person, event['organizer']),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }

  void _navigateToEventDetails(
    BuildContext context,
    Map<String, dynamic> event,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (newContext) => EventDetailsScreen(event: event),
      ),
    );
  }

  void _showAddEventForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (modalContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(modalContext).viewInsets.bottom,
          ),
          child: AddEventForm(
            onEventAdded: _loadEvents, // Передаем функцию обновления списка
          ),
        );
      },
    );
  }
}

class EventDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> event;

  const EventDetailsScreen({Key? key, required this.event}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final date = DateTime.parse(event['date']);

    return Scaffold(
      appBar: AppBar(title: Text(event['title'])),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('EEEE, d MMMM y • HH:mm').format(date),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Место проведения', event['location']),
            _buildDetailRow('Организатор', event['organizer']),
            const SizedBox(height: 24),
            Text('Описание', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(event['description']),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class AddEventForm extends StatefulWidget {
  final Function() onEventAdded;

  const AddEventForm({Key? key, required this.onEventAdded}) : super(key: key);

  @override
  State<AddEventForm> createState() => _AddEventFormState();
}

class _AddEventFormState extends State<AddEventForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  DateTime? _selectedDate;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Название мероприятия',
              ),
              validator: (value) => value!.isEmpty ? 'Обязательное поле' : null,
            ),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Описание'),
              maxLines: 3,
            ),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(labelText: 'Место проведения'),
              validator: (value) => value!.isEmpty ? 'Обязательное поле' : null,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _selectDate,
              child: Text(
                _selectedDate == null
                    ? 'Выберите дату и время'
                    : DateFormat('dd.MM.yyyy HH:mm').format(_selectedDate!),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submitForm,
              child: const Text('Создать мероприятие'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (time != null) {
        setState(() {
          _selectedDate = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate() && _selectedDate != null) {
      try {
        // Получаем ID текущего пользователя (пример)
        final currentUserId = AuthService().currentUser?.id ?? 0;

        await DatabaseHelper().createEvent(
          title: _titleController.text,
          location: _locationController.text,
          eventDate: _selectedDate!,
          organizerId: currentUserId, // Передаем ID организатора
          description: _descriptionController.text,
        );

        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка: ${e.toString()}')));
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }
}
