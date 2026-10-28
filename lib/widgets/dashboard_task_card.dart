import 'package:flutter/material.dart';
import '../models/task.dart';

class DashboardTaskCard extends StatefulWidget {
  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final Function(Task updated) onUpdate;
  final bool isLoading;

  const DashboardTaskCard({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onDelete,
    required this.onUpdate,
    this.isLoading = false,
  });

  @override
  State<DashboardTaskCard> createState() => _DashboardTaskCardState();
}

class _DashboardTaskCardState extends State<DashboardTaskCard> {
  bool _isExpanded = false;
  bool _isEditing = false;
  late TextEditingController _editController;
  final TextEditingController _subtaskController = TextEditingController();
  bool _showAddSubtask = false;

  @override
  void initState() {
    super.initState();
    _editController = TextEditingController(text: widget.task.text);
  }

  @override
  void didUpdateWidget(covariant DashboardTaskCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.task.text != widget.task.text) {
      _editController.text = widget.task.text;
    }
  }

  @override
  void dispose() {
    _editController.dispose();
    _subtaskController.dispose();
    super.dispose();
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'work':
        return const Color(0xFF8083FF);
      case 'health':
        return const Color(0xFF4EDEA3);
      case 'wealth':
        return const Color(0xFFFBBF24);
      case 'knowledge':
        return const Color(0xFF60A5FA);
      case 'challenge':
        return const Color(0xFFFB923C);
      case 'personal':
      default:
        return const Color(0xFFFFB783);
    }
  }

  void _saveEdit() {
    final text = _editController.text.trim();
    if (text.isNotEmpty && text != widget.task.text) {
      final updated = Task(
        id: widget.task.id,
        text: text,
        category: widget.task.category,
        priority: widget.task.priority,
        isRegular: widget.task.isRegular,
        isGoal: widget.task.isGoal,
        completed: widget.task.completed,
        completedAt: widget.task.completedAt,
        linkedGoalId: widget.task.linkedGoalId,
        challengeId: widget.task.challengeId,
        challengeName: widget.task.challengeName,
        subtasks: widget.task.subtasks,
        order: widget.task.order,
      );
      widget.onUpdate(updated);
    }
    setState(() => _isEditing = false);
  }

  void _addSubtask() {
    final text = _subtaskController.text.trim();
    if (text.isEmpty) return;

    final newSubtask = Subtask(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      completed: false,
    );
    final updatedSubtasks = [...widget.task.subtasks, newSubtask];

    final updated = Task(
      id: widget.task.id,
      text: widget.task.text,
      category: widget.task.category,
      priority: widget.task.priority,
      isRegular: widget.task.isRegular,
      isGoal: widget.task.isGoal,
      completed: widget.task.completed,
      completedAt: widget.task.completedAt,
      linkedGoalId: widget.task.linkedGoalId,
      challengeId: widget.task.challengeId,
      challengeName: widget.task.challengeName,
      subtasks: updatedSubtasks,
      order: widget.task.order,
    );

    widget.onUpdate(updated);
    _subtaskController.clear();
    setState(() => _showAddSubtask = false);
  }

  void _toggleSubtask(String subtaskId) {
    final updatedSubtasks = widget.task.subtasks.map((st) {
      if (st.id == subtaskId) {
        return Subtask(id: st.id, text: st.text, completed: !st.completed);
      }
      return st;
    }).toList();

    // If all subtasks are done on a non-goal task, mark parent done
    bool allCompleted = updatedSubtasks.isNotEmpty && updatedSubtasks.every((st) => st.completed);

    final updated = Task(
      id: widget.task.id,
      text: widget.task.text,
      category: widget.task.category,
      priority: widget.task.priority,
      isRegular: widget.task.isRegular,
      isGoal: widget.task.isGoal,
      completed: (!widget.task.isGoal && allCompleted) ? true : widget.task.completed,
      completedAt: (!widget.task.isGoal && allCompleted) ? DateTime.now().toIso8601String() : widget.task.completedAt,
      linkedGoalId: widget.task.linkedGoalId,
      challengeId: widget.task.challengeId,
      challengeName: widget.task.challengeName,
      subtasks: updatedSubtasks,
      order: widget.task.order,
    );

    widget.onUpdate(updated);
  }

  void _deleteSubtask(String subtaskId) {
    final updatedSubtasks = widget.task.subtasks.where((st) => st.id != subtaskId).toList();
    final updated = Task(
      id: widget.task.id,
      text: widget.task.text,
      category: widget.task.category,
      priority: widget.task.priority,
      isRegular: widget.task.isRegular,
      isGoal: widget.task.isGoal,
      completed: widget.task.completed,
      completedAt: widget.task.completedAt,
      linkedGoalId: widget.task.linkedGoalId,
      challengeId: widget.task.challengeId,
      challengeName: widget.task.challengeName,
      subtasks: updatedSubtasks,
      order: widget.task.order,
    );
    widget.onUpdate(updated);
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = _getCategoryColor(widget.task.category);
    final subtasks = widget.task.subtasks;
    final completedSubtasksCount = subtasks.where((s) => s.completed).length;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _isExpanded ? const Color(0xFF1E283F) : const Color(0xFF171F33),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _isExpanded ? Colors.white.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main Task Row
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Checkbox
                  if (widget.isLoading)
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF8083FF)),
                    )
                  else
                    InkWell(
                      onTap: widget.onToggle,
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: widget.task.completed
                                ? const Color(0xFF4EDEA3)
                                : Colors.white.withValues(alpha: 0.3),
                            width: 2,
                          ),
                          color: widget.task.completed ? const Color(0xFF4EDEA3) : Colors.transparent,
                        ),
                        child: widget.task.completed
                            ? const Icon(Icons.check, size: 14, color: Color(0xFF0B1326))
                            : null,
                      ),
                    ),
                  const SizedBox(width: 12),

                  // Task Title and Badges
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_isEditing)
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _editController,
                                  style: const TextStyle(color: Colors.white, fontSize: 13),
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(vertical: 4),
                                    border: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF8083FF))),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.check, size: 18, color: Colors.greenAccent),
                                onPressed: _saveEdit,
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 18, color: Colors.white54),
                                onPressed: () => setState(() => _isEditing = false),
                              ),
                            ],
                          )
                        else
                          Text(
                            widget.task.text,
                            style: TextStyle(
                              color: widget.task.completed ? const Color(0xFF908FA0) : const Color(0xFFDAE2FD),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              decoration: widget.task.completed ? TextDecoration.lineThrough : null,
                            ),
                          ),
                        const SizedBox(height: 6),

                        // Badges Row
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            // Category Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: categoryColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: categoryColor.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                widget.task.category.toUpperCase(),
                                style: TextStyle(
                                  color: categoryColor,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),

                            // Challenge Name Badge if applicable
                            if (widget.task.challengeName != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFB923C).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFFFB923C).withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.emoji_events, size: 10, color: Color(0xFFFB923C)),
                                    const SizedBox(width: 3),
                                    Text(
                                      widget.task.challengeName!,
                                      style: const TextStyle(
                                        color: Color(0xFFFB923C),
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            // Subtasks summary
                            if (subtasks.isNotEmpty)
                              Text(
                                '$completedSubtasksCount/${subtasks.length} subtasks',
                                style: const TextStyle(color: Color(0xFF908FA0), fontSize: 10),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Expand Chevron
                  Icon(
                    _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Colors.white38,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          // Expanded Details: Subtasks & Actions
          if (_isExpanded) ...[
            const Divider(color: Colors.white10, height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Subtasks List
                  if (subtasks.isNotEmpty) ...[
                    ...subtasks.map((st) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              InkWell(
                                onTap: () => _toggleSubtask(st.id),
                                child: Icon(
                                  st.completed ? Icons.check_box : Icons.check_box_outline_blank,
                                  size: 16,
                                  color: st.completed ? const Color(0xFF4EDEA3) : Colors.white38,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  st.text,
                                  style: TextStyle(
                                    color: st.completed ? Colors.white38 : Colors.white70,
                                    fontSize: 12,
                                    decoration: st.completed ? TextDecoration.lineThrough : null,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 14, color: Colors.white38),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => _deleteSubtask(st.id),
                              ),
                            ],
                          ),
                        )),
                    const SizedBox(height: 6),
                  ],

                  // Add Subtask Inline Form
                  if (_showAddSubtask)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _subtaskController,
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                              decoration: InputDecoration(
                                hintText: 'New subtask...',
                                hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.05),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          ElevatedButton(
                            onPressed: _addSubtask,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4648D4),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              minimumSize: Size.zero,
                            ),
                            child: const Text('Add', style: TextStyle(fontSize: 11)),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 16, color: Colors.white54),
                            onPressed: () => setState(() => _showAddSubtask = false),
                          ),
                        ],
                      ),
                    ),

                  // Bottom Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        onPressed: () => setState(() => _showAddSubtask = !_showAddSubtask),
                        icon: const Icon(Icons.add, size: 14, color: Color(0xFF8083FF)),
                        label: const Text('Add Subtask', style: TextStyle(color: Color(0xFF8083FF), fontSize: 11)),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, size: 16, color: Colors.white54),
                            tooltip: 'Edit Title',
                            onPressed: () => setState(() => _isEditing = true),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                            tooltip: 'Delete Task',
                            onPressed: widget.onDelete,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
