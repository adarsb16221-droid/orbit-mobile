import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';

class DoneTasksSheet extends StatelessWidget {
  const DoneTasksSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const DoneTasksSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final completedTasks = taskProvider.tasks.where((t) => t.completed).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      builder: (_, scrollController) {
        return Material(
          color: const Color(0xFF131B2E),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: Column(
            children: [
              // Handle
              const SizedBox(height: 12),
              Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 16),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.task_alt, color: Color(0xFF8083FF), size: 24),
                        SizedBox(width: 10),
                        Text(
                          'Done Tasks',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white10, height: 20),

              // Tasks List or Empty State
              Expanded(
                child: completedTasks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox_outlined, size: 48, color: Colors.white.withValues(alpha: 0.3)),
                            const SizedBox(height: 12),
                            const Text(
                              'No completed tasks yet.',
                              style: TextStyle(color: Color(0xFF908FA0), fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        itemCount: completedTasks.length,
                        itemBuilder: (ctx, index) {
                          final task = completedTasks[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF171F33),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        task.text,
                                        style: const TextStyle(
                                          color: Color(0xFF908FA0),
                                          fontSize: 13,
                                          decoration: TextDecoration.lineThrough,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        task.category.toUpperCase(),
                                        style: TextStyle(
                                          color: const Color(0xFF8083FF).withValues(alpha: 0.8),
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    final restored = Task(
                                      id: task.id,
                                      text: task.text,
                                      category: task.category,
                                      priority: task.priority,
                                      isRegular: task.isRegular,
                                      isGoal: task.isGoal,
                                      completed: false,
                                      completedAt: null,
                                      linkedGoalId: task.linkedGoalId,
                                      challengeId: task.challengeId,
                                      challengeName: task.challengeName,
                                      subtasks: task.subtasks,
                                      order: task.order,
                                    );
                                    taskProvider.updateTask(restored);
                                  },
                                  style: TextButton.styleFrom(
                                    backgroundColor: const Color(0xFF8083FF).withValues(alpha: 0.15),
                                    foregroundColor: const Color(0xFFC0C1FF),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    minimumSize: Size.zero,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: const Text('Undo', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
