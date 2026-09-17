class Task {
  final String id;
  final String text;
  final String category;
  final String priority;
  final bool isRegular;
  final bool isGoal;
  final bool completed;
  final String? completedAt;
  final String? linkedGoalId;
  final List<Subtask> subtasks;
  final double order;

  Task({
    required this.id,
    required this.text,
    required this.category,
    required this.priority,
    required this.isRegular,
    required this.isGoal,
    required this.completed,
    this.completedAt,
    this.linkedGoalId,
    required this.subtasks,
    required this.order,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['_id'] ?? json['id'] ?? '',
      text: json['text'] ?? '',
      category: json['category'] ?? 'General',
      priority: json['priority'] ?? 'medium',
      isRegular: json['isRegular'] ?? false,
      isGoal: json['isGoal'] ?? false,
      completed: json['completed'] ?? false,
      completedAt: json['completedAt'],
      linkedGoalId: json['linkedGoalId'],
      subtasks: (json['subtasks'] as List<dynamic>?)
              ?.map((e) => Subtask.fromJson(e))
              .toList() ??
          [],
      order: (json['order'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) '_id': id,
      'text': text,
      'category': category,
      'priority': priority,
      'isRegular': isRegular,
      'isGoal': isGoal,
      'completed': completed,
      'completedAt': completedAt,
      'linkedGoalId': linkedGoalId,
      'subtasks': subtasks.map((e) => e.toJson()).toList(),
      'order': order,
    };
  }
}

class Subtask {
  final String id;
  final String text;
  final bool completed;

  Subtask({
    required this.id,
    required this.text,
    required this.completed,
  });

  factory Subtask.fromJson(Map<String, dynamic> json) {
    return Subtask(
      id: json['id'] ?? '',
      text: json['text'] ?? '',
      completed: json['completed'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'completed': completed,
    };
  }
}
