class Journal {
  final String id;
  final String date;
  final String content;

  Journal({
    required this.id,
    required this.date,
    required this.content,
  });

  factory Journal.fromJson(Map<String, dynamic> json) {
    return Journal(
      id: json['_id'] ?? json['id'] ?? '',
      date: json['date'] ?? '',
      content: json['content'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) '_id': id,
      'date': date,
      'content': content,
    };
  }
}
