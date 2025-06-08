import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../database/db_helper.dart';

class NewsDetailScreen extends StatefulWidget {
  final Map<String, dynamic> news;

  const NewsDetailScreen({super.key, required this.news});

  @override
  State<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen> {
  late Future<List<Map<String, dynamic>>> _commentsFuture;
  final _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _commentsFuture = DatabaseHelper().getNewsComments(widget.news['id']);
  }

  Future<void> _addComment() async {
    if (_commentController.text.isEmpty) return;

    setState(() {
      _commentsFuture = DatabaseHelper().getNewsComments(widget.news['id']);
      _commentController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final date = DateTime.parse(widget.news['created_at']);
    final formattedDate = DateFormat('dd.MM.yyyy HH:mm').format(date);

    return Scaffold(
      appBar: AppBar(title: Text('Новость')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.news['image_url'] != null)
                    CachedNetworkImage(
                      imageUrl: widget.news['image_url'],
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.news['title'],
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundImage: CachedNetworkImageProvider(
                                widget.news['author_avatar'] ?? '',
                              ),
                            ),
                            SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(widget.news['author_name']),
                                Text(
                                  formattedDate,
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Text(
                          widget.news['content'],
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        SizedBox(height: 24),
                        Text(
                          'Комментарии',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        SizedBox(height: 8),
                        FutureBuilder<List<Map<String, dynamic>>>(
                          future: _commentsFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Center(child: CircularProgressIndicator());
                            }

                            if (!snapshot.hasData || snapshot.data!.isEmpty) {
                              return Text('Комментариев пока нет');
                            }

                            return ListView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemCount: snapshot.data!.length,
                              itemBuilder: (context, index) {
                                final comment = snapshot.data![index];
                                return _CommentItem(comment: comment);
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildCommentInput(),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: 'Написать комментарий...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
          IconButton(icon: Icon(Icons.send), onPressed: _addComment),
        ],
      ),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
    );
  }
}

class _CommentItem extends StatelessWidget {
  final Map<String, dynamic> comment;

  const _CommentItem({required this.comment});

  @override
  Widget build(BuildContext context) {
    final date = DateTime.parse(comment['created_at']);
    final formattedDate = DateFormat('dd.MM.yyyy HH:mm').format(date);

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(
              comment['user_avatar'] ?? '',
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  comment['user_name'],
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(comment['text']),
                Text(
                  formattedDate,
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
