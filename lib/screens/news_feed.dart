import 'package:diplom/screens/event.dart';
import 'package:diplom/screens/login.dart';
import 'package:diplom/screens/news_detail_screen.dart';
import 'package:diplom/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../database/db_helper.dart';

class NewsFeedScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const NewsFeedScreen({super.key, required this.user});

  @override
  State<NewsFeedScreen> createState() => _NewsFeedScreenState();
}

class _NewsFeedScreenState extends State<NewsFeedScreen> {
  late Future<List<Map<String, dynamic>>> _newsFuture;
  final _scrollController = ScrollController();
  int _currentPage = 1;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _newsFuture = _loadNews();
    _scrollController.addListener(_scrollListener);
  }

  Future<List<Map<String, dynamic>>> _loadNews({int page = 1}) async {
    final db = DatabaseHelper();
    final news = await db.getNewsFeed();
    return news;
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent &&
        _hasMore) {
      _loadMoreNews();
    }
  }

  Future<void> _loadMoreNews() async {
    setState(() => _currentPage++);
    final moreNews = await _loadNews(page: _currentPage);
    setState(() {
      if (moreNews.isEmpty) {
        _hasMore = false;
      }
    });
  }

  Future<void> _refreshNews() async {
    setState(() {
      _currentPage = 1;
      _hasMore = true;
      _newsFuture = _loadNews();
    });
  }

  void _showSearchDialog(BuildContext context) {
    final searchController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Поиск новостей',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              SizedBox(height: 16),
              TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Введите ключевые слова...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                autofocus: true,
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('ОТМЕНА'),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 24),
                    ),
                    onPressed: () {
                      // Реализация поиска
                      Navigator.pop(context);
                    },
                    child: Text('НАЙТИ'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNotifications(BuildContext context) {
    // Navigator.push(
    //   context
    //   // MaterialPageRoute(
    //   //   builder: (context) => NotificationsScreen(userId: widget.user['id']),
    //   // ),
    // );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Новости компании'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () => _showSearchDialog(context),
          ),
          _buildNotificationBadge(),
        ],
      ),
      drawer: _buildDrawer(context, widget),
      body: RefreshIndicator(
        onRefresh: _refreshNews,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _newsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Ошибка загрузки новостей'));
            }

            final newsList = snapshot.data!;

            return ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.all(8),
              itemCount: newsList.length + (_hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= newsList.length) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                return _NewsCard(news: newsList[index]);
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () => _showAddNewsDialog(context),
      ),
    );
  }

  Widget _buildNotificationBadge() {
    return FutureBuilder(
      future: DatabaseHelper().getUserNotifications(widget.user['id']),
      builder: (context, snapshot) {
        final count = snapshot.hasData ? snapshot.data!.length : 0;
        return Stack(
          children: [
            IconButton(
              icon: Icon(Icons.notifications),
              onPressed: () => _showNotifications(context),
            ),
            if (count > 0)
              Positioned(
                right: 8,
                top: 8,
                child: CircleAvatar(
                  radius: 10,
                  backgroundColor: Colors.red,
                  child: Text('$count', style: TextStyle(fontSize: 10)),
                ),
              ),
          ],
        );
      },
    );
  }

  void _showAddNewsDialog(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    final _titleController = TextEditingController();
    final _contentController = TextEditingController();
    String? _selectedCategory;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Добавить новость'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(labelText: 'Заголовок'),
                  validator: (value) =>
                      value!.isEmpty ? 'Введите заголовок' : null,
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  items: ['Общее', 'Новости', 'Объявления', 'Мероприятия']
                      .map(
                        (category) => DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => _selectedCategory = value,
                  decoration: InputDecoration(labelText: 'Категория'),
                  validator: (value) =>
                      value == null ? 'Выберите категорию' : null,
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _contentController,
                  maxLines: 5,
                  decoration: InputDecoration(labelText: 'Содержание'),
                  validator: (value) => value!.isEmpty ? 'Введите текст' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                await DatabaseHelper().createNews(
                  title: _titleController.text,
                  content: _contentController.text,
                  authorId: widget.user['id'],
                  category: _selectedCategory!,
                );
                _refreshNews();
                Navigator.pop(context);
              }
            },
            child: Text('Опубликовать'),
          ),
        ],
      ),
    );
  }
}

class _NewsCard extends StatelessWidget {
  final Map<String, dynamic> news;

  const _NewsCard({required this.news});

  @override
  Widget build(BuildContext context) {
    final date = DateTime.parse(news['created_at']);
    final formattedDate = DateFormat('dd.MM.yyyy HH:mm').format(date);
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showNewsDetail(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (news['image_url'] != null)
              CachedNetworkImage(
                imageUrl: news['image_url'],
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 200,
                  color: Colors.grey[200],
                  child: Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 200,
                  color: Colors.grey[200],
                  child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
                ),
              ),
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getCategoryColor(news['category']),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          news['category'] ?? 'Общее',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Spacer(),
                      Text(
                        formattedDate,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    news['title'],
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    news['content'],
                    style: theme.textTheme.bodyMedium,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 16),
                  _NewsActions(news: news),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String? category) {
    switch (category) {
      case 'Новости':
        return Colors.blue.shade600;
      case 'Объявления':
        return Colors.green.shade600;
      case 'Мероприятия':
        return Colors.purple.shade600;
      default:
        return Colors.orange.shade600;
    }
  }

  void _showNewsDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NewsDetailScreen(news: news)),
    );
  }
}

class _NewsActions extends StatefulWidget {
  final Map<String, dynamic> news;

  const _NewsActions({required this.news});

  @override
  State<_NewsActions> createState() => _NewsActionsState();
}

class _NewsActionsState extends State<_NewsActions> {
  bool _isLiked = false;
  int _likeCount = 0;

  @override
  void initState() {
    super.initState();
    _likeCount = widget.news['like_count'] ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: Icon(_isLiked ? Icons.favorite : Icons.favorite_border),
          color: _isLiked ? Colors.red : null,
          onPressed: () async {
            if (!_isLiked) {
              await DatabaseHelper().addNewsLike(widget.news['id']);
            }
            setState(() {
              _isLiked = !_isLiked;
              _likeCount += _isLiked ? 1 : -1;
            });
          },
        ),
        Text('$_likeCount'),
        SizedBox(width: 16),
        IconButton(icon: Icon(Icons.comment), onPressed: () {}),
        Spacer(),
        IconButton(icon: Icon(Icons.share), onPressed: () {}),
      ],
    );
  }
}

Widget _buildDrawer(BuildContext context, dynamic widget) {
  return Drawer(
    child: ListView(
      padding: EdgeInsets.zero,
      children: [
        DrawerHeader(
          decoration: BoxDecoration(color: Colors.blue),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage: NetworkImage(widget.user['avatar_url'] ?? ''),
              ),
              SizedBox(height: 10),
              Text(
                widget.user['name'] ?? 'Пользователь',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              Text(
                widget.user['email'] ?? '',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
        ListTile(
          leading: Icon(Icons.newspaper),
          title: Text('Новости'),
          onTap: () {
            Navigator.pop(context); // Закрываем меню
            // Остаемся на текущей странице
          },
        ),
        ListTile(
          leading: Icon(Icons.event),
          title: Text('Мероприятия'),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => EventsScreen()),
            );
          },
        ),
        ListTile(
          leading: Icon(Icons.person),
          title: Text('Профиль'),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfileScreen(user: widget.user),
              ),
            );
          },
        ),
        Divider(),
        ListTile(
          leading: Icon(Icons.exit_to_app),
          title: Text('Выход'),
          onTap: () {
            Navigator.pop(context);
            _logout(context);
          },
        ),
      ],
    ),
  );
}

void _logout(BuildContext context) {
  // Ваш код выхода
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (context) => LoginScreen()),
  );
}
