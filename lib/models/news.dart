class News {
  final int? id;
  final String title;
  final String content;
  final int? authorId;
  final String? date;

  News({
    this.id,
    required this.title,
    required this.content,
    this.authorId,
    this.date,
  });

  factory News.fromMap(Map<String, dynamic> map) {
    return News(
      id: map['id'],
      title: map['title'],
      content: map['content'],
      authorId: map['authorId'],
      date: map['date'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'authorId': authorId,
      'date': date,
    };
  }
}
