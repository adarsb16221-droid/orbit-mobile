class Schedule {
  final String id;
  final String title;
  final String startTime;
  final String endTime;
  final String color;

  Schedule({
    required this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.color,
  });

  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      color: json['color'] ?? 'primary',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) '_id': id,
      'title': title,
      'startTime': startTime,
      'endTime': endTime,
      'color': color,
    };
  }
}
