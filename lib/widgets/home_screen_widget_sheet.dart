import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/task_provider.dart';
import '../providers/schedule_provider.dart';
import '../services/widget_service.dart';

class HomeScreenWidgetSheet extends StatefulWidget {
  const HomeScreenWidgetSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const HomeScreenWidgetSheet(),
    );
  }

  @override
  State<HomeScreenWidgetSheet> createState() => _HomeScreenWidgetSheetState();
}

class _HomeScreenWidgetSheetState extends State<HomeScreenWidgetSheet> {
  bool _isPinning = false;
  bool _isSyncing = false;
  bool _showInAppWidget = true;

  @override
  void initState() {
    super.initState();
    _loadInAppWidgetPreference();
  }

  Future<void> _loadInAppWidgetPreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _showInAppWidget = prefs.getBool('show_inapp_overview_widget') ?? true;
    });
  }

  Future<void> _toggleInAppWidget(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('show_inapp_overview_widget', value);
    setState(() {
      _showInAppWidget = value;
    });
  }

  Future<void> _pinWidget() async {
    setState(() => _isPinning = true);
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final scheduleProvider = Provider.of<ScheduleProvider>(context, listen: false);

    // Sync latest data first
    await WidgetService.updateWidgetData(
      tasks: taskProvider.tasks,
      schedules: scheduleProvider.schedules,
    );

    final success = await WidgetService.requestPinWidget();
    setState(() => _isPinning = false);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Widget pin requested! Confirm on your home screen prompt.'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Follow the manual instructions below to place the widget on your home screen.'),
          backgroundColor: Colors.blueAccent,
        ),
      );
    }
  }

  Future<void> _syncWidget() async {
    setState(() => _isSyncing = true);
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final scheduleProvider = Provider.of<ScheduleProvider>(context, listen: false);

    final success = await WidgetService.updateWidgetData(
      tasks: taskProvider.tasks,
      schedules: scheduleProvider.schedules,
    );

    setState(() => _isSyncing = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? 'Widget synchronized with current tasks and reminders!'
            : 'Could not update widget on this device.'),
        backgroundColor: success ? Colors.green : Colors.redAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final scheduleProvider = Provider.of<ScheduleProvider>(context);

    final pendingTasks = taskProvider.tasks.where((t) => !t.completed).toList();
    final schedules = scheduleProvider.schedules;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, scrollController) {
        return Material(
          color: const Color(0xFF0F172A),
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

              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    // Title and Description
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.widgets, color: Colors.blueAccent, size: 28),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Home Screen Widget',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Tasks & reminders right on your phone',
                                style: TextStyle(color: Colors.white70, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Live Widget Preview Section
                    const Text(
                      'WIDGET PREVIEW',
                      style: TextStyle(
                        color: Colors.blueAccent,
                        fontSize: 12,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    _buildWidgetPreview(pendingTasks, schedules),

                    const SizedBox(height: 20),

                    // Primary Action: Add / Pin Widget
                    ElevatedButton.icon(
                      onPressed: _isPinning ? null : _pinWidget,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 4,
                      ),
                      icon: _isPinning
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.add_to_home_screen),
                      label: Text(
                        _isPinning ? 'Requesting Home Screen Pin...' : 'Add Widget to Home Screen',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Secondary Action: Sync Now
                    OutlinedButton.icon(
                      onPressed: _isSyncing ? null : _syncWidget,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: const BorderSide(color: Colors.white24),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: _isSyncing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(color: Colors.white70, strokeWidth: 2),
                            )
                          : const Icon(Icons.sync, size: 20),
                      label: const Text('Sync Widget Data Now'),
                    ),
                    const SizedBox(height: 20),

                    // In-app dashboard widget toggle
                    Material(
                      color: const Color(0xFF1E293B),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(color: Colors.white10),
                      ),
                      child: SwitchListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        title: const Text(
                          'Show in App Dashboard',
                          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        subtitle: const Text(
                          'Display a quick overview widget on your app home screen',
                          style: TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                        value: _showInAppWidget,
                        activeThumbColor: Colors.blueAccent,
                        onChanged: _toggleInAppWidget,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Instructions Accordion
                    Material(
                      color: Colors.transparent,
                      child: ExpansionTile(
                        leading: const Icon(Icons.help_outline, color: Colors.blueAccent),
                        title: const Text(
                          'How to add manually on Android / iOS',
                          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        childrenPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        iconColor: Colors.white70,
                        collapsedIconColor: Colors.white54,
                        children: [
                          _buildInstructionStep(
                            '1',
                            'Android',
                            'Touch and hold any empty space on your phone home screen, tap "Widgets", scroll to "HAWK" and drag the widget to your home screen.',
                          ),
                          const SizedBox(height: 10),
                          _buildInstructionStep(
                            '2',
                            'iOS',
                            'Touch and hold an empty area on your Home Screen until apps jiggle, tap the "+" button in the top corner, search for HAWK and tap "Add Widget".',
                          ),
                          const SizedBox(height: 10),
                          _buildInstructionStep(
                            '3',
                            'Automatic Sync',
                            'Your widget automatically updates whenever you create, complete, or modify tasks and reminders in HAWK.',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWidgetPreview(List<dynamic> pendingTasks, List<dynamic> schedules) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF334155), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Widget Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.bolt, color: Colors.lightBlueAccent, size: 16),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'HAWK Dashboard',
                    style: TextStyle(
                      color: Color(0xFF38BDF8),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Home Widget',
                  style: TextStyle(color: Colors.white60, fontSize: 10),
                ),
              ),
            ],
          ),
          const Divider(color: Color(0xFF334155), height: 20),

          // Section 1: Tasks To Do
          Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 16),
              const SizedBox(width: 6),
              const Text(
                'TASKS TO DO',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${pendingTasks.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (pendingTasks.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Text(
                '✨ All caught up! No pending tasks.',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontStyle: FontStyle.italic),
              ),
            )
          else
            ...pendingTasks.take(3).map((task) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(
                        task.isGoal ? Icons.flag : Icons.radio_button_unchecked,
                        size: 14,
                        color: task.priority == 'high' ? Colors.redAccent : Colors.blueAccent,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          task.text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                )),

          const SizedBox(height: 10),

          // Section 2: Reminders & Schedule
          Row(
            children: [
              const Icon(Icons.notifications_active_outlined, color: Colors.orangeAccent, size: 16),
              const SizedBox(width: 6),
              const Text(
                'REMINDERS & SCHEDULE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orangeAccent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${schedules.length}',
                  style: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (schedules.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Text(
                '📅 No reminders scheduled for today.',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontStyle: FontStyle.italic),
              ),
            )
          else
            ...schedules.take(2).map((schedule) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, size: 14, color: Colors.orangeAccent),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${schedule.startTime.isNotEmpty ? "${schedule.startTime} - " : ""}${schedule.title}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                )),

          const SizedBox(height: 8),
          const Center(
            child: Text(
              'Tap widget to launch HAWK',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionStep(String num, String platform, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 10,
          backgroundColor: Colors.blueAccent.withValues(alpha: 0.3),
          child: Text(num, style: const TextStyle(color: Colors.blueAccent, fontSize: 11, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
              children: [
                TextSpan(text: '$platform: ', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                TextSpan(text: description),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
