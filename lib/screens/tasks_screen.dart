import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../models/task.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final TextEditingController _habitController = TextEditingController();
  final TextEditingController _focusController = TextEditingController();
  final TextEditingController _goalController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TaskProvider>(context, listen: false).fetchTasks();
    });
  }
  
  @override
  void dispose() {
    _habitController.dispose();
    _focusController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  void _addTask(String text, {bool isRegular = false, bool isGoal = false, String category = 'General'}) {
    if (text.trim().isEmpty) return;
    
    final newTask = Task(
      id: '', // Will be assigned by backend
      text: text,
      category: category,
      priority: 'medium',
      isRegular: isRegular,
      isGoal: isGoal,
      completed: false,
      subtasks: [],
      order: 0.0,
    );
    
    Provider.of<TaskProvider>(context, listen: false).addTask(newTask);
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInput(String hint, TextEditingController controller, Function(String) onSubmit) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          suffixIcon: IconButton(
            icon: const Icon(Icons.add_circle, color: Colors.blueAccent),
            onPressed: () {
              onSubmit(controller.text);
              controller.clear();
            },
          ),
        ),
        onSubmitted: (val) {
          onSubmit(val);
          controller.clear();
        },
      ),
    );
  }

  Widget _buildTaskCard(Task task, TaskProvider provider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Transform.scale(
          scale: 1.2,
          child: Checkbox(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            activeColor: Colors.blueAccent,
            value: task.completed,
            onChanged: (bool? value) {
              if (value != null) {
                final updatedTask = Task(
                  id: task.id,
                  text: task.text,
                  category: task.category,
                  priority: task.priority,
                  isRegular: task.isRegular,
                  isGoal: task.isGoal,
                  completed: value,
                  subtasks: task.subtasks,
                  order: task.order,
                );
                provider.updateTask(updatedTask);
              }
            },
          ),
        ),
        title: Text(
          task.text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: task.completed ? Colors.grey : Colors.black87,
            decoration: task.completed ? TextDecoration.lineThrough : null,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          onPressed: () => provider.deleteTask(task.id),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);

    if (taskProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (taskProvider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: ${taskProvider.error}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: taskProvider.fetchTasks,
              child: const Text('Retry'),
            )
          ],
        ),
      );
    }

    final allTasks = taskProvider.tasks;
    final habits = allTasks.where((t) => t.isRegular && !t.isGoal).toList();
    final focusTasks = allTasks.where((t) => !t.isRegular && !t.isGoal).toList();
    final goals = allTasks.where((t) => t.isGoal).toList();

    return RefreshIndicator(
      onRefresh: taskProvider.fetchTasks,
      child: Container(
        color: const Color(0xFFF8F9FA),
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // HABITS SECTION
            _buildSectionHeader('Daily Habits', Icons.repeat, Colors.purple),
            _buildInput('Add a new daily habit...', _habitController, (val) => _addTask(val, isRegular: true, category: 'Health')),
            ...habits.map((t) => _buildTaskCard(t, taskProvider)),
            const SizedBox(height: 24),
            
            // FOCUS SECTION
            _buildSectionHeader('Deep Focus', Icons.center_focus_strong, Colors.blue),
            _buildInput('What do you need to focus on?', _focusController, (val) => _addTask(val, category: 'Work')),
            ...focusTasks.map((t) => _buildTaskCard(t, taskProvider)),
            const SizedBox(height: 24),
            
            // GOALS SECTION
            _buildSectionHeader('My Goals', Icons.flag, Colors.orange),
            _buildInput('Add a new goal...', _goalController, (val) => _addTask(val, isGoal: true, category: 'Personal')),
            ...goals.map((t) => _buildTaskCard(t, taskProvider)),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
