import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/hawk_header.dart';
import '../models/task.dart';
import '../widgets/tasks_reminders_overview_widget.dart';
import 'dart:async';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final TextEditingController _habitController = TextEditingController();
  final TextEditingController _focusController = TextEditingController();
  final TextEditingController _goalController = TextEditingController();
  
  String _habitCategory = 'Health';
  String _focusCategory = 'Work';
  String? _focusLinkedGoal;
  String _goalCategory = 'Personal';
  
  bool _showDoneTasks = false;
  Timer? _midnightTimer;
  Set<String> _processingTasks = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      if (user != null) {
        Provider.of<TaskProvider>(context, listen: false).fetchTasks(user.id);
      }
    });

    _midnightTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkRollover();
    });
  }
  
  void _checkRollover() {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final todayStr = DateTime.now().toIso8601String().split('T')[0];
    
    for (var task in taskProvider.tasks) {
      if (task.isRegular && task.completed && task.completedAt != null) {
        final completedDateStr = task.completedAt!.split('T')[0];
        if (completedDateStr != todayStr) {
          final updated = Task(
             id: task.id, text: task.text, category: task.category, priority: task.priority,
             isRegular: task.isRegular, isGoal: task.isGoal, completed: false, completedAt: null,
             challengeId: task.challengeId, challengeName: task.challengeName,
             subtasks: task.subtasks, order: task.order
          );
          taskProvider.updateTask(updated);
        }
      }
    }
  }

  @override
  void dispose() {
    _habitController.dispose();
    _focusController.dispose();
    _goalController.dispose();
    _midnightTimer?.cancel();
    super.dispose();
  }

  void _addTask(String text, {bool isRegular = false, bool isGoal = false, required String category, String? linkedGoalId, required VoidCallback onDone}) {
    if (text.trim().isEmpty) return;
    
    final newTask = Task(
      id: '',
      text: text,
      category: category,
      priority: 'medium',
      isRegular: isRegular,
      isGoal: isGoal,
      linkedGoalId: linkedGoalId,
      completed: false,
      subtasks: [],
      order: DateTime.now().millisecondsSinceEpoch.toDouble(),
    );
    
    Provider.of<TaskProvider>(context, listen: false).addTask(newTask);
    onDone();
  }

  Future<void> _toggleTask(Task task, TaskProvider provider) async {
    setState(() => _processingTasks.add(task.id));
    final updated = Task(
      id: task.id,
      text: task.text,
      category: task.category,
      priority: task.priority,
      isRegular: task.isRegular,
      isGoal: task.isGoal,
      completed: !task.completed,
      completedAt: !task.completed ? DateTime.now().toIso8601String() : null,
      challengeId: task.challengeId,
      challengeName: task.challengeName,
      subtasks: task.subtasks,
      order: task.order,
    );
    await provider.updateTask(updated);
    setState(() => _processingTasks.remove(task.id));
  }

  Future<void> _deleteTask(String id, TaskProvider provider) async {
    setState(() => _processingTasks.add(id));
    await provider.deleteTask(id);
    setState(() => _processingTasks.remove(id));
  }
  
  Future<void> _moveTask(Task task, String direction, List<Task> contextTasks, TaskProvider provider) async {
    setState(() => _processingTasks.add(task.id));
    final currentIndex = contextTasks.indexWhere((t) => t.id == task.id);
    if (currentIndex == -1) {
      setState(() => _processingTasks.remove(task.id));
      return;
    }

    double newOrder = task.order;

    if (direction == 'up' && currentIndex > 0) {
      final prevTask = contextTasks[currentIndex - 1];
      if (currentIndex > 1) {
        final prevPrevTask = contextTasks[currentIndex - 2];
        newOrder = (prevTask.order + prevPrevTask.order) / 2;
      } else {
        newOrder = prevTask.order - 1000;
      }
    } else if (direction == 'down' && currentIndex < contextTasks.length - 1) {
      final nextTask = contextTasks[currentIndex + 1];
      if (currentIndex < contextTasks.length - 2) {
        final nextNextTask = contextTasks[currentIndex + 2];
        newOrder = (nextTask.order + nextNextTask.order) / 2;
      } else {
        newOrder = nextTask.order + 1000;
      }
    } else {
      setState(() => _processingTasks.remove(task.id));
      return;
    }

    final updated = Task(
      id: task.id, text: task.text, category: task.category, priority: task.priority,
      isRegular: task.isRegular, isGoal: task.isGoal, completed: task.completed, completedAt: task.completedAt,
      challengeId: task.challengeId, challengeName: task.challengeName,
      subtasks: task.subtasks, order: newOrder,
    );
    await provider.updateTask(updated);
    setState(() => _processingTasks.remove(task.id));
  }

  void _showEditModal(Task task, TaskProvider provider) {
    // Basic edit modal for task text and subtasks if goal
    final _editController = TextEditingController(text: task.text);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 16, right: 16, top: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _editController,
                decoration: const InputDecoration(labelText: 'Task Name'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  final updated = Task(
                    id: task.id, text: _editController.text, category: task.category, priority: task.priority,
                    isRegular: task.isRegular, isGoal: task.isGoal, completed: task.completed, completedAt: task.completedAt,
                    challengeId: task.challengeId, challengeName: task.challengeName,
                    subtasks: task.subtasks, order: task.order,
                  );
                  provider.updateTask(updated);
                  Navigator.pop(ctx);
                },
                child: const Text('Save'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      }
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildTaskCard(Task task, List<Task> contextTasks, TaskProvider provider) {
    final themeProvider = Provider.of<ThemeProvider?>(context);
    final isDark = themeProvider?.isDarkMode ?? true;
    final surface = themeProvider?.surface ?? (isDark ? const Color(0xFF131B2E) : Colors.white);
    final border = themeProvider?.border ?? (isDark ? const Color(0x1AFFFFFF) : const Color(0x0D000000));
    final textPrimary = themeProvider?.textPrimary ?? (isDark ? const Color(0xFFDAE2FD) : Colors.black87);
    final textSecondary = themeProvider?.textSecondary ?? (isDark ? const Color(0xFF908FA0) : Colors.grey);

    final isProcessing = _processingTasks.contains(task.id);
    return Card(
      color: surface,
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: border)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Transform.scale(
          scale: 1.2,
          child: isProcessing 
            ? const Padding(padding: EdgeInsets.all(8), child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)))
            : Checkbox(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                activeColor: const Color(0xFF8083FF),
                value: task.completed,
                onChanged: (val) => _toggleTask(task, provider),
              ),
        ),
        title: Text(
          task.text,
          style: TextStyle(
            fontSize: 16, 
            fontWeight: FontWeight.w500, 
            color: task.completed ? textSecondary : textPrimary, 
            decoration: task.completed ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Row(
          children: [
            const Text('• ', style: TextStyle(fontSize: 12, color: Color(0xFF8083FF))),
            Text(task.category, style: const TextStyle(fontSize: 12, color: Color(0xFF8083FF))),
            if (task.challengeName != null) ...[
              const SizedBox(width: 8),
              Text(task.challengeName!, style: const TextStyle(fontSize: 12, color: Colors.orangeAccent)),
            ]
          ]
        ),
        trailing: task.challengeId != null 
          ? const Tooltip(message: 'Challenge Task', child: Icon(Icons.emoji_events, color: Colors.orangeAccent))
          : PopupMenuButton<String>(
              iconColor: textSecondary,
              color: surface,
              onSelected: (val) {
                if (val == 'delete') _deleteTask(task.id, provider);
                else if (val == 'edit') _showEditModal(task, provider);
                else if (val == 'up' || val == 'down') _moveTask(task, val, contextTasks, provider);
              },
              itemBuilder: (ctx) => [
                PopupMenuItem(value: 'up', child: Text('Move Up', style: TextStyle(color: textPrimary))),
                PopupMenuItem(value: 'down', child: Text('Move Down', style: TextStyle(color: textPrimary))),
                PopupMenuItem(value: 'edit', child: Text('Edit', style: TextStyle(color: textPrimary))),
                const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
              ],
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final themeProvider = Provider.of<ThemeProvider?>(context);
    final isDark = themeProvider?.isDarkMode ?? true;

    final bg = themeProvider?.bg ?? (isDark ? const Color(0xFF0B1326) : const Color(0xFFF8F9FF));
    final surface = themeProvider?.surface ?? (isDark ? const Color(0xFF131B2E) : Colors.white);
    final textPrimary = themeProvider?.textPrimary ?? (isDark ? const Color(0xFFDAE2FD) : Colors.black87);
    final textSecondary = themeProvider?.textSecondary ?? (isDark ? const Color(0xFF908FA0) : Colors.grey);

    if (taskProvider.isLoading) return Scaffold(backgroundColor: bg, body: const Center(child: CircularProgressIndicator()));
    if (taskProvider.error != null) {
      return Scaffold(
        backgroundColor: bg,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: ${taskProvider.error}', style: TextStyle(color: textPrimary)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  final user = Provider.of<AuthProvider>(context, listen: false).user;
                  if (user != null) taskProvider.fetchTasks(user.id);
                },
                child: const Text('Retry'),
              )
            ],
          ),
        ),
      );
    }

    final allTasks = taskProvider.tasks;
    final pendingTasks = allTasks.where((t) => !t.completed).toList();
    final doneTasks = allTasks.where((t) => t.completed).toList();

    // Sort by order
    pendingTasks.sort((a, b) => a.order.compareTo(b.order));
    doneTasks.sort((a, b) => a.order.compareTo(b.order));

    final habits = pendingTasks.where((t) => t.isRegular && !t.isGoal && t.challengeId == null).toList();
    final focusTasks = pendingTasks.where((t) => !t.isRegular && !t.isGoal && t.challengeId == null).toList();
    final goals = pendingTasks.where((t) => t.isGoal && t.challengeId == null).toList();
    final challengeTasks = pendingTasks.where((t) => t.challengeId != null).toList();

    // Ensure _focusLinkedGoal is valid
    if (_focusLinkedGoal != null && !goals.any((g) => g.id == _focusLinkedGoal)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() => _focusLinkedGoal = null);
      });
    }

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // 1. HawkHeader
            const HawkHeader(
              title: 'Tasks',
              subtitle: 'Task Manager & Habits',
            ),

            // 2. Task List
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  final user = Provider.of<AuthProvider>(context, listen: false).user;
                  if (user != null) await taskProvider.fetchTasks(user.id);
                },
                color: const Color(0xFF8083FF),
                backgroundColor: surface,
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
            const TasksRemindersOverviewWidget(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => setState(() => _showDoneTasks = !_showDoneTasks),
                  icon: Icon(_showDoneTasks ? Icons.visibility_off : Icons.visibility, color: textSecondary),
                  label: Text(_showDoneTasks ? 'Hide Done Tasks' : 'Show Done Tasks', style: TextStyle(color: textSecondary)),
                ),
              ],
            ),
            
            if (_showDoneTasks) ...[
              _buildSectionHeader('Done Tasks', Icons.check_circle, Colors.green),
              if (doneTasks.isEmpty) const Padding(padding: EdgeInsets.all(8.0), child: Text('No completed tasks yet.', style: TextStyle(color: Colors.grey))),
              ...doneTasks.map((t) => _buildTaskCard(t, doneTasks, taskProvider)),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 8),
            ],

            _buildSectionHeader('Daily Habits', Icons.repeat, Colors.purple),
            _buildHabitInput(),
            ...habits.map((t) => _buildTaskCard(t, habits, taskProvider)),
            const SizedBox(height: 24),
            
            _buildSectionHeader('Deep Focus', Icons.center_focus_strong, Colors.blue),
            _buildFocusInput(goals),
            ...focusTasks.map((t) => _buildTaskCard(t, focusTasks, taskProvider)),
            const SizedBox(height: 24),
            
            if (challengeTasks.isNotEmpty) ...[
              _buildSectionHeader('Challenges', Icons.emoji_events, Colors.orangeAccent),
              ...challengeTasks.map((t) => _buildTaskCard(t, challengeTasks, taskProvider)),
              const SizedBox(height: 24),
            ],

            _buildSectionHeader('My Goals', Icons.flag, Colors.orange),
            _buildGoalInput(),
            ...goals.map((t) => _buildTaskCard(t, goals, taskProvider)),
            const SizedBox(height: 40),
          ],
        ),
      ),
    ),
  ],
),
),
);
  }

  Widget _buildHabitInput() {
    final themeProvider = Provider.of<ThemeProvider?>(context);
    final isDark = themeProvider?.isDarkMode ?? true;
    final surface = themeProvider?.surface ?? (isDark ? const Color(0xFF131B2E) : Colors.white);
    final border = themeProvider?.border ?? (isDark ? const Color(0x1AFFFFFF) : const Color(0x0D000000));
    final textPrimary = themeProvider?.textPrimary ?? (isDark ? const Color(0xFFDAE2FD) : Colors.black87);
    final textSecondary = themeProvider?.textSecondary ?? (isDark ? const Color(0xFF908FA0) : Colors.grey);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          TextField(
            controller: _habitController,
            style: TextStyle(color: textPrimary),
            decoration: InputDecoration(
              hintText: 'Add a new daily habit...',
              hintStyle: TextStyle(color: textSecondary),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                DropdownButton<String>(
                  value: _habitCategory,
                  dropdownColor: surface,
                  style: TextStyle(color: textPrimary, fontSize: 12),
                  onChanged: (v) => setState(() => _habitCategory = v!),
                  items: ['Health', 'Wealth', 'Knowledge'].map((c) => DropdownMenuItem(value: c, child: Text(c, style: TextStyle(color: textPrimary, fontSize: 12)))).toList(),
                  underline: const SizedBox(),
                ),
                ElevatedButton(
                  onPressed: () => _addTask(_habitController.text, isRegular: true, category: _habitCategory, onDone: () => _habitController.clear()),
                  child: const Text('Add'),
                )
              ]
            ),
          )
        ],
      )
    );
  }

  Widget _buildFocusInput(List<Task> goals) {
    final themeProvider = Provider.of<ThemeProvider?>(context);
    final isDark = themeProvider?.isDarkMode ?? true;
    final surface = themeProvider?.surface ?? (isDark ? const Color(0xFF131B2E) : Colors.white);
    final border = themeProvider?.border ?? (isDark ? const Color(0x1AFFFFFF) : const Color(0x0D000000));
    final textPrimary = themeProvider?.textPrimary ?? (isDark ? const Color(0xFFDAE2FD) : Colors.black87);
    final textSecondary = themeProvider?.textSecondary ?? (isDark ? const Color(0xFF908FA0) : Colors.grey);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          TextField(
            controller: _focusController,
            style: TextStyle(color: textPrimary),
            decoration: InputDecoration(
              hintText: 'What do you need to focus on?',
              hintStyle: TextStyle(color: textSecondary),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    DropdownButton<String>(
                      value: _focusCategory,
                      dropdownColor: surface,
                      style: TextStyle(color: textPrimary, fontSize: 12),
                      onChanged: (v) => setState(() => _focusCategory = v!),
                      items: ['Work', 'Personal', 'General', 'Health', 'Wealth', 'Knowledge'].map((c) => DropdownMenuItem(value: c, child: Text(c, style: TextStyle(color: textPrimary, fontSize: 12)))).toList(),
                      underline: const SizedBox(),
                    ),
                    const SizedBox(width: 8),
                    if (goals.isNotEmpty)
                      DropdownButton<String?>(
                        value: _focusLinkedGoal,
                        dropdownColor: surface,
                        style: TextStyle(color: textPrimary, fontSize: 12),
                        hint: Text('No Goal', style: TextStyle(fontSize: 12, color: textSecondary)),
                        onChanged: (v) => setState(() => _focusLinkedGoal = v),
                        items: [
                          DropdownMenuItem<String?>(value: null, child: Text('No Goal', style: TextStyle(fontSize: 12, color: textSecondary))),
                          ...goals.map((g) => DropdownMenuItem<String?>(value: g.id, child: Text(g.text, style: TextStyle(fontSize: 12, color: textPrimary))))
                        ],
                        underline: const SizedBox(),
                      ),
                  ]
                ),
                ElevatedButton(
                  onPressed: () => _addTask(_focusController.text, category: _focusCategory, linkedGoalId: _focusLinkedGoal, onDone: () { _focusController.clear(); _focusLinkedGoal = null; }),
                  child: const Text('Add'),
                )
              ]
            ),
          )
        ],
      )
    );
  }

  Widget _buildGoalInput() {
    final themeProvider = Provider.of<ThemeProvider?>(context);
    final isDark = themeProvider?.isDarkMode ?? true;
    final surface = themeProvider?.surface ?? (isDark ? const Color(0xFF131B2E) : Colors.white);
    final border = themeProvider?.border ?? (isDark ? const Color(0x1AFFFFFF) : const Color(0x0D000000));
    final textPrimary = themeProvider?.textPrimary ?? (isDark ? const Color(0xFFDAE2FD) : Colors.black87);
    final textSecondary = themeProvider?.textSecondary ?? (isDark ? const Color(0xFF908FA0) : Colors.grey);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          TextField(
            controller: _goalController,
            style: TextStyle(color: textPrimary),
            decoration: InputDecoration(
              hintText: 'Add a new goal...',
              hintStyle: TextStyle(color: textSecondary),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                DropdownButton<String>(
                  value: _goalCategory,
                  dropdownColor: surface,
                  style: TextStyle(color: textPrimary, fontSize: 12),
                  onChanged: (v) => setState(() => _goalCategory = v!),
                  items: ['Personal', 'Work', 'Health', 'Wealth', 'Knowledge'].map((c) => DropdownMenuItem(value: c, child: Text(c, style: TextStyle(color: textPrimary, fontSize: 12)))).toList(),
                  underline: const SizedBox(),
                ),
                ElevatedButton(
                  onPressed: () => _addTask(_goalController.text, isGoal: true, category: _goalCategory, onDone: () => _goalController.clear()),
                  child: const Text('Add'),
                )
              ]
            ),
          )
        ],
      )
    );
  }
}
