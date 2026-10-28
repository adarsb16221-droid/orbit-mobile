import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/schedule.dart';
import '../models/task.dart';
import '../providers/auth_provider.dart';
import '../providers/schedule_provider.dart';
import '../providers/task_provider.dart';
import '../providers/theme_provider.dart';
import '../services/widget_service.dart';
import '../widgets/dashboard_pomodoro.dart';
import '../widgets/dashboard_task_card.dart';
import '../widgets/done_tasks_sheet.dart';
import '../widgets/hawk_header.dart';
import '../widgets/home_screen_widget_sheet.dart';

import 'analytics_screen.dart';
import 'challenges_screen.dart';
import 'chat_screen.dart';
import 'community_screen.dart';
import 'expenses_screen.dart';
import 'focus_screen.dart';
import 'journal_screen.dart';
import 'links_screen.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'schedules_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Habit Add State
  bool _showAddHabit = false;
  final TextEditingController _habitInputController = TextEditingController();
  String _habitCategory = 'Health';

  // Focus Task Add State
  bool _showAddFocus = false;
  final TextEditingController _focusInputController = TextEditingController();
  String _focusCategory = 'Work';
  String? _focusLinkedGoal;

  // Goal Add State
  bool _showAddGoal = false;
  final TextEditingController _goalInputController = TextEditingController();
  String _goalCategory = 'Personal';

  // Section Filter: 'all', 'habits', 'focus', 'goals', 'challenges'
  String _activeSectionFilter = 'all';

  Timer? _scheduleCheckTimer;
  Schedule? _currentBlock;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });

    _scheduleCheckTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _updateCurrentScheduleBlock();
    });
  }

  @override
  void dispose() {
    _scheduleCheckTimer?.cancel();
    _habitInputController.dispose();
    _focusInputController.dispose();
    _goalInputController.dispose();
    super.dispose();
  }

  void _loadData() {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user != null) {
      Provider.of<TaskProvider>(context, listen: false).fetchTasks(user.id);
      Provider.of<ScheduleProvider>(context, listen: false).fetchSchedules();
    }
    _syncHomeWidget();
    _updateCurrentScheduleBlock();
  }

  void _syncHomeWidget() {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final scheduleProvider = Provider.of<ScheduleProvider>(context, listen: false);
    WidgetService.updateWidgetData(
      tasks: taskProvider.tasks,
      schedules: scheduleProvider.schedules,
    );
  }

  void _updateCurrentScheduleBlock() {
    final scheduleProvider = Provider.of<ScheduleProvider>(context, listen: false);
    final schedules = scheduleProvider.schedules;
    if (schedules.isEmpty) {
      if (_currentBlock != null) setState(() => _currentBlock = null);
      return;
    }

    final now = DateTime.now();
    final h = now.hour.toString().padLeft(2, '0');
    final m = now.minute.toString().padLeft(2, '0');
    final currentTime = '$h:$m';

    Schedule? active;
    for (var b in schedules) {
      if (currentTime.compareTo(b.startTime) >= 0 && currentTime.compareTo(b.endTime) <= 0) {
        active = b;
        break;
      }
    }

    if (active?.id != _currentBlock?.id) {
      setState(() => _currentBlock = active);
    }
  }

  String _formatTime12h(String time24) {
    if (time24.isEmpty) return '';
    final parts = time24.split(':');
    if (parts.isEmpty) return time24;
    int h = int.tryParse(parts[0]) ?? 0;
    final m = parts.length > 1 ? parts[1] : '00';
    final ampm = h >= 12 ? 'PM' : 'AM';
    h = h % 12;
    if (h == 0) h = 12;
    return '$h:$m $ampm';
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }

  TextStyle _outfit({double? fontSize, FontWeight? fontWeight, Color? color, double? letterSpacing}) {
    try {
      return GoogleFonts.outfit(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
      );
    } catch (_) {
      return TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
      );
    }
  }

  // Add Task Handlers
  void _addHabit() {
    final text = _habitInputController.text.trim();
    if (text.isEmpty) return;

    final newTask = Task(
      id: '',
      text: text,
      category: _habitCategory,
      priority: 'medium',
      isRegular: true,
      isGoal: false,
      completed: false,
      subtasks: [],
      order: DateTime.now().millisecondsSinceEpoch.toDouble(),
    );

    Provider.of<TaskProvider>(context, listen: false).addTask(newTask);
    _habitInputController.clear();
    setState(() => _showAddHabit = false);
  }

  void _addFocusTask() {
    final text = _focusInputController.text.trim();
    if (text.isEmpty) return;

    final newTask = Task(
      id: '',
      text: text,
      category: _focusCategory,
      priority: 'medium',
      isRegular: false,
      isGoal: false,
      linkedGoalId: _focusLinkedGoal?.isNotEmpty == true ? _focusLinkedGoal : null,
      completed: false,
      subtasks: [],
      order: DateTime.now().millisecondsSinceEpoch.toDouble(),
    );

    Provider.of<TaskProvider>(context, listen: false).addTask(newTask);
    _focusInputController.clear();
    setState(() {
      _focusLinkedGoal = null;
      _showAddFocus = false;
    });
  }

  void _addGoal() {
    final text = _goalInputController.text.trim();
    if (text.isEmpty) return;

    final newTask = Task(
      id: '',
      text: text,
      category: _goalCategory,
      priority: 'medium',
      isRegular: false,
      isGoal: true,
      completed: false,
      subtasks: [],
      order: DateTime.now().millisecondsSinceEpoch.toDouble(),
    );

    Provider.of<TaskProvider>(context, listen: false).addTask(newTask);
    _goalInputController.clear();
    setState(() => _showAddGoal = false);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider?>(context);
    final user = authProvider.user;

    // Define all app screens
    final screens = [
      _buildDashboardView(), // Tab 0: The website-exact Dashboard!
      const ChatScreen(),
      const SchedulesScreen(),
      const JournalScreen(),
      const LinksScreen(),
      const AnalyticsScreen(),
      const ChallengesScreen(),
      const CommunityScreen(),
      const ProfileScreen(),
      const ExpensesScreen(),
      const FocusScreen(),
    ];

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: themeProvider?.bg ?? const Color(0xFF0B1326),
      drawer: _buildDrawer(user, authProvider),
      body: SafeArea(
        child: screens[_currentIndex < screens.length ? _currentIndex : 0],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // -------------------------------------------------------------
  // DASHBOARD VIEW (Exact UI as my-app/app/(dashboard)/page.js)
  // -------------------------------------------------------------
  Widget _buildDashboardView() {
    final taskProvider = Provider.of<TaskProvider>(context);
    final scheduleProvider = Provider.of<ScheduleProvider>(context);
    final themeProvider = Provider.of<ThemeProvider?>(context);
    final isDark = themeProvider?.isDarkMode ?? true;
    final user = Provider.of<AuthProvider>(context).user;

    final allTasks = taskProvider.tasks;
    final dailyTasks = allTasks.where((t) => t.isRegular && !t.completed && t.challengeId == null).toList();
    final oneOffTasks = allTasks.where((t) => !t.isRegular && !t.isGoal && !t.completed && t.challengeId == null).toList();
    final goalTasks = allTasks.where((t) => t.isGoal && !t.completed && t.challengeId == null).toList();
    final challengeTasks = allTasks.where((t) => t.challengeId != null && !t.completed).toList();
    final completedTasks = allTasks.where((t) => t.completed).toList();

    return Column(
      children: [
        HawkHeader(
          title: 'Dashboard',
          subtitle: 'Health, Wealth & Knowledge',
          actions: [
            // Done Tasks Pill Button
            InkWell(
              onTap: () => DoneTasksSheet.show(context),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF4648D4),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4648D4).withValues(alpha: 0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.task_alt, size: 13, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'Done Tasks',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),
            // Phone Widget Button
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: themeProvider?.circleBtnBg ?? (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
                border: Border.all(color: themeProvider?.circleBtnBorder ?? (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1))),
              ),
              child: IconButton(
                icon: Icon(Icons.widgets_outlined, size: 18, color: isDark ? const Color(0xFFC0C1FF) : const Color(0xFF4648D4)),
                tooltip: 'Home Screen Widget',
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                padding: EdgeInsets.zero,
                onPressed: () => HomeScreenWidgetSheet.show(context),
              ),
            ),
          ],
          showThemeToggle: true,
          showMenu: true,
          onMenu: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        Expanded(
          child: RefreshIndicator(
            color: const Color(0xFF8083FF),
            backgroundColor: themeProvider?.surfaceContainer ?? (isDark ? const Color(0xFF171F33) : Colors.white),
            onRefresh: () async {
              if (user != null) {
                await Future.wait([
                  taskProvider.fetchTasks(user.id),
                  scheduleProvider.fetchSchedules(),
                ]);
                _updateCurrentScheduleBlock();
              }
            },
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                // 1. Website Header Component
                _buildWebsiteHeader(user?.name ?? 'User', completedTasks.length),
                const SizedBox(height: 16),

                // 2. Mobile Home Screen Widget Status Card (Keep the Mobile Widget)
                _buildMobileWidgetCard(oneOffTasks.length + dailyTasks.length, scheduleProvider.schedules.length),
                const SizedBox(height: 16),

                // 3. Section Filter Chips (All, Habits, Focus, Goals, Challenges)
                _buildSectionFilterTabs(
                  habitsCount: dailyTasks.length,
                  focusCount: oneOffTasks.length,
                  goalsCount: goalTasks.length,
                  challengesCount: challengeTasks.length,
                ),
                const SizedBox(height: 16),

                // 4. Challenge Tasks Section
                if (_activeSectionFilter == 'all' || _activeSectionFilter == 'challenges') ...[
                  _buildChallengeSection(challengeTasks, taskProvider),
                  const SizedBox(height: 20),
                ],

                // 5. Daily Habits Section
                if (_activeSectionFilter == 'all' || _activeSectionFilter == 'habits') ...[
                  _buildDailyHabitsSection(dailyTasks, taskProvider),
                  const SizedBox(height: 20),
                ],

                // 6. Focus Tasks (One-off Tasks) Section
                if (_activeSectionFilter == 'all' || _activeSectionFilter == 'focus') ...[
                  _buildFocusTasksSection(oneOffTasks, goalTasks, taskProvider),
                  const SizedBox(height: 20),
                ],

                // 7. Long Term Goals Section
                if (_activeSectionFilter == 'all' || _activeSectionFilter == 'goals') ...[
                  _buildLongTermGoalsSection(goalTasks, taskProvider),
                  const SizedBox(height: 24),
                ],

                // 8. Pomodoro Widget (Exact UI as website Pomodoro)
                const DashboardPomodoro(),
                const SizedBox(height: 36),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // 1. HEADER (Exact UI as Header.jsx on website)
  // -------------------------------------------------------------
  Widget _buildWebsiteHeader(String userName, int tasksCompleted) {
    final themeProvider = Provider.of<ThemeProvider?>(context);
    final isDark = themeProvider?.isDarkMode ?? true;
    final dateStr = DateFormat('MMM d, yyyy').format(DateTime.now());
    final greeting = _getGreeting();
    final firstName = userName.split(' ')[0];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeProvider?.surface ?? (isDark ? const Color(0xFF131B2E) : Colors.white),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: themeProvider?.cardBorder ?? (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date String
          Text(
            dateStr,
            style: TextStyle(
              color: themeProvider?.textSecondary ?? (isDark ? const Color(0xFF908FA0) : const Color(0xFF64748B)),
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 4),

          // Greeting with Gradient Text
          Row(
            children: [
              Text(
                'Good ',
                style: _outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: themeProvider?.textPrimary ?? (isDark ? const Color(0xFFDAE2FD) : const Color(0xFF0D1C2E)),
                ),
              ),
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFF818CF8), Color(0xFF38BDF8)],
                ).createShader(bounds),
                child: Text(
                  greeting,
                  style: _outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Text(
                ', $firstName',
                style: _outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: themeProvider?.textPrimary ?? (isDark ? const Color(0xFFDAE2FD) : const Color(0xFF0D1C2E)),
                ),
              ),
            ],
          ),

          // Tasks Completed Badge
          if (tasksCompleted > 0) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF4EDEA3).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF4EDEA3).withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, size: 13, color: Color(0xFF4EDEA3)),
                  const SizedBox(width: 5),
                  Text(
                    '$tasksCompleted Tasks Completed',
                    style: const TextStyle(
                      color: Color(0xFF4EDEA3),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Current Schedule Block (if active)
          if (_currentBlock != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF4648D4).withValues(alpha: isDark ? 0.15 : 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF4648D4).withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.schedule, size: 14, color: Color(0xFF8083FF)),
                      SizedBox(width: 6),
                      Text(
                        'CURRENT SCHEDULE',
                        style: TextStyle(
                          color: Color(0xFF8083FF),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _currentBlock!.title,
                    style: TextStyle(
                      color: themeProvider?.textPrimary ?? (isDark ? const Color(0xFFDAE2FD) : const Color(0xFF0D1C2E)),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_formatTime12h(_currentBlock!.startTime)} - ${_formatTime12h(_currentBlock!.endTime)}',
                    style: TextStyle(
                      color: themeProvider?.textSecondary ?? (isDark ? const Color(0xFF908FA0) : const Color(0xFF64748B)),
                      fontSize: 11,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // 2. MOBILE HOME SCREEN WIDGET CARD (Keep the mobile widget)
  // -------------------------------------------------------------
  Widget _buildMobileWidgetCard(int pendingTasksCount, int remindersCount) {
    final themeProvider = Provider.of<ThemeProvider?>(context);
    final isDark = themeProvider?.isDarkMode ?? true;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: themeProvider?.surface ?? (isDark ? const Color(0xFF131B2E) : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: isDark ? 0.25 : 0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.widgets, color: Color(0xFF38BDF8), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Phone Home Screen Widget',
                  style: TextStyle(
                    color: themeProvider?.textPrimary ?? (isDark ? Colors.white : const Color(0xFF0D1C2E)),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$pendingTasksCount tasks • $remindersCount reminders synced',
                  style: TextStyle(
                    color: themeProvider?.textSecondary ?? (isDark ? const Color(0xFF908FA0) : const Color(0xFF64748B)),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => HomeScreenWidgetSheet.show(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF38BDF8).withValues(alpha: 0.2),
              foregroundColor: const Color(0xFF38BDF8),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: const BorderSide(color: Color(0xFF38BDF8)),
              ),
            ),
            child: const Text('Add / Pin', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // 3. SECTION FILTER TABS
  // -------------------------------------------------------------
  Widget _buildSectionFilterTabs({
    required int habitsCount,
    required int focusCount,
    required int goalsCount,
    required int challengesCount,
  }) {
    final themeProvider = Provider.of<ThemeProvider?>(context);
    final isDark = themeProvider?.isDarkMode ?? true;

    final filters = [
      {'id': 'all', 'label': 'All'},
      {'id': 'habits', 'label': 'Habits ($habitsCount)'},
      {'id': 'focus', 'label': 'Focus ($focusCount)'},
      {'id': 'goals', 'label': 'Goals ($goalsCount)'},
      if (challengesCount > 0) {'id': 'challenges', 'label': 'Challenges ($challengesCount)'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final isSelected = _activeSectionFilter == f['id'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                f['label']!,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.white : (themeProvider?.textSecondary ?? const Color(0xFF908FA0)),
                ),
              ),
              selected: isSelected,
              showCheckmark: false,
              backgroundColor: themeProvider?.surface ?? (isDark ? const Color(0xFF131B2E) : Colors.white),
              selectedColor: const Color(0xFF4648D4),
              side: BorderSide(
                color: isSelected ? const Color(0xFF8083FF) : (themeProvider?.cardBorder ?? (isDark ? Colors.white10 : Colors.black12)),
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              onSelected: (_) {
                setState(() => _activeSectionFilter = f['id']!);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  // -------------------------------------------------------------
  // 4. CHALLENGE TASKS SECTION
  // -------------------------------------------------------------
  Widget _buildChallengeSection(List<Task> challengeTasks, TaskProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.emoji_events, size: 18, color: Color(0xFFC0C1FF)),
            const SizedBox(width: 8),
            Text(
              'Challenge Tasks',
              style: _outfit(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFFC0C1FF)),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (challengeTasks.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'No pending challenge tasks.',
              style: TextStyle(color: Color(0xFF908FA0), fontSize: 13, fontStyle: FontStyle.italic),
            ),
          )
        else
          ...challengeTasks.map((t) => DashboardTaskCard(
                task: t,
                onToggle: () => _toggleTask(t, provider),
                onDelete: () => provider.deleteTask(t.id),
                onUpdate: (updated) => provider.updateTask(updated),
              )),
      ],
    );
  }

  // -------------------------------------------------------------
  // 5. DAILY HABITS SECTION
  // -------------------------------------------------------------
  Widget _buildDailyHabitsSection(List<Task> dailyTasks, TaskProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.repeat, size: 18, color: Color(0xFFC0C1FF)),
                const SizedBox(width: 8),
                Text(
                  'Daily Habits',
                  style: _outfit(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFFC0C1FF)),
                ),
              ],
            ),
            InkWell(
              onTap: () => setState(() => _showAddHabit = !_showAddHabit),
              child: Row(
                children: [
                  Icon(_showAddHabit ? Icons.close : Icons.add, size: 16, color: const Color(0xFF8083FF)),
                  const SizedBox(width: 4),
                  Text(
                    _showAddHabit ? 'Cancel' : 'Add',
                    style: const TextStyle(color: Color(0xFF8083FF), fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Inline Add Habit Form
        if (_showAddHabit) ...[
          _buildAddHabitForm(),
          const SizedBox(height: 12),
        ],

        if (dailyTasks.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'No daily habits yet.',
              style: TextStyle(color: Color(0xFF908FA0), fontSize: 13, fontStyle: FontStyle.italic),
            ),
          )
        else
          ...dailyTasks.map((t) => DashboardTaskCard(
                task: t,
                onToggle: () => _toggleTask(t, provider),
                onDelete: () => provider.deleteTask(t.id),
                onUpdate: (updated) => provider.updateTask(updated),
              )),
      ],
    );
  }

  Widget _buildAddHabitForm() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF171F33),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          TextField(
            controller: _habitInputController,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'New habit...',
              hintStyle: const TextStyle(color: Color(0xFF908FA0), fontSize: 13),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _habitCategory,
                    dropdownColor: const Color(0xFF171F33),
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                    items: ['Health', 'Wealth', 'Knowledge'].map((c) {
                      return DropdownMenuItem(value: c, child: Text(c));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _habitCategory = val);
                    },
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: _addHabit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4648D4),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Add', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // 6. FOCUS TASKS SECTION (One-Off Tasks)
  // -------------------------------------------------------------
  Widget _buildFocusTasksSection(List<Task> oneOffTasks, List<Task> goalTasks, TaskProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.checklist, size: 18, color: Color(0xFFC0C1FF)),
                const SizedBox(width: 8),
                Text(
                  'Focus Tasks',
                  style: _outfit(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFFC0C1FF)),
                ),
              ],
            ),
            InkWell(
              onTap: () => setState(() => _showAddFocus = !_showAddFocus),
              child: Row(
                children: [
                  Icon(_showAddFocus ? Icons.close : Icons.add, size: 16, color: const Color(0xFF8083FF)),
                  const SizedBox(width: 4),
                  Text(
                    _showAddFocus ? 'Cancel' : 'Add',
                    style: const TextStyle(color: Color(0xFF8083FF), fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Inline Add Focus Task Form
        if (_showAddFocus) ...[
          _buildAddFocusForm(goalTasks),
          const SizedBox(height: 12),
        ],

        if (oneOffTasks.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'No tasks remaining.',
              style: TextStyle(color: Color(0xFF908FA0), fontSize: 13, fontStyle: FontStyle.italic),
            ),
          )
        else
          ...oneOffTasks.map((t) => DashboardTaskCard(
                task: t,
                onToggle: () => _toggleTask(t, provider),
                onDelete: () => provider.deleteTask(t.id),
                onUpdate: (updated) => provider.updateTask(updated),
              )),
      ],
    );
  }

  Widget _buildAddFocusForm(List<Task> goalTasks) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF171F33),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          TextField(
            controller: _focusInputController,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'New focus task...',
              hintStyle: const TextStyle(color: Color(0xFF908FA0), fontSize: 13),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // Category Select
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _focusCategory,
                    dropdownColor: const Color(0xFF171F33),
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                    items: ['Work', 'Personal', 'General', 'Health', 'Wealth', 'Knowledge'].map((c) {
                      return DropdownMenuItem(value: c, child: Text(c));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _focusCategory = val);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Linked Goal Select
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _focusLinkedGoal ?? '',
                      dropdownColor: const Color(0xFF171F33),
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                      items: [
                        const DropdownMenuItem(value: '', child: Text('No Goal', overflow: TextOverflow.ellipsis)),
                        ...goalTasks.map((g) => DropdownMenuItem(
                              value: g.id,
                              child: Text(g.text, overflow: TextOverflow.ellipsis),
                            )),
                      ],
                      onChanged: (val) {
                        setState(() => _focusLinkedGoal = val?.isEmpty == true ? null : val);
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              ElevatedButton(
                onPressed: _addFocusTask,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4648D4),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Add', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // 7. LONG TERM GOALS SECTION
  // -------------------------------------------------------------
  Widget _buildLongTermGoalsSection(List<Task> goalTasks, TaskProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.flag, size: 18, color: Color(0xFFC0C1FF)),
                const SizedBox(width: 8),
                Text(
                  'Long Term Goals',
                  style: _outfit(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFFC0C1FF)),
                ),
              ],
            ),
            InkWell(
              onTap: () => setState(() => _showAddGoal = !_showAddGoal),
              child: Row(
                children: [
                  Icon(_showAddGoal ? Icons.close : Icons.add, size: 16, color: const Color(0xFF8083FF)),
                  const SizedBox(width: 4),
                  Text(
                    _showAddGoal ? 'Cancel' : 'Add',
                    style: const TextStyle(color: Color(0xFF8083FF), fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Inline Add Goal Form
        if (_showAddGoal) ...[
          _buildAddGoalForm(),
          const SizedBox(height: 12),
        ],

        if (goalTasks.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'No goals yet.',
              style: TextStyle(color: Color(0xFF908FA0), fontSize: 13, fontStyle: FontStyle.italic),
            ),
          )
        else
          ...goalTasks.map((t) => DashboardTaskCard(
                task: t,
                onToggle: () => _toggleTask(t, provider),
                onDelete: () => provider.deleteTask(t.id),
                onUpdate: (updated) => provider.updateTask(updated),
              )),
      ],
    );
  }

  Widget _buildAddGoalForm() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF171F33),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          TextField(
            controller: _goalInputController,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'New goal...',
              hintStyle: const TextStyle(color: Color(0xFF908FA0), fontSize: 13),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _goalCategory,
                    dropdownColor: const Color(0xFF171F33),
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                    items: ['Personal', 'Work', 'Health', 'Wealth', 'Knowledge'].map((c) {
                      return DropdownMenuItem(value: c, child: Text(c));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _goalCategory = val);
                    },
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: _addGoal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4648D4),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Add', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _toggleTask(Task task, TaskProvider provider) {
    final updated = Task(
      id: task.id,
      text: task.text,
      category: task.category,
      priority: task.priority,
      isRegular: task.isRegular,
      isGoal: task.isGoal,
      completed: !task.completed,
      completedAt: !task.completed ? DateTime.now().toIso8601String() : null,
      linkedGoalId: task.linkedGoalId,
      challengeId: task.challengeId,
      challengeName: task.challengeName,
      subtasks: task.subtasks,
      order: task.order,
    );
    provider.updateTask(updated);
  }

  // -------------------------------------------------------------
  // DRAWER
  // -------------------------------------------------------------
  Widget _buildDrawer(dynamic user, AuthProvider authProvider) {
    final themeProvider = Provider.of<ThemeProvider?>(context);
    final isDark = themeProvider?.isDarkMode ?? true;
    final textColor = themeProvider?.textPrimary ?? (isDark ? Colors.white : const Color(0xFF0D1C2E));
    final subtextColor = themeProvider?.textSecondary ?? (isDark ? Colors.white54 : const Color(0xFF64748B));
    final dividerColor = themeProvider?.divider ?? (isDark ? Colors.white12 : Colors.black12);

    return Drawer(
      backgroundColor: themeProvider?.surface ?? (isDark ? const Color(0xFF0B1326) : Colors.white),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark ? const [Color(0xFF4648D4), Color(0xFF171F33)] : const [Color(0xFF4648D4), Color(0xFF6063EE)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(Icons.account_circle, size: 54, color: Colors.white),
                const SizedBox(height: 10),
                Text(
                  user?.name ?? 'User',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  user?.email ?? '',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard, color: Color(0xFF8083FF)),
            title: Text('Dashboard', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
            onTap: () {
              Navigator.pop(context);
              setState(() => _currentIndex = 0);
            },
          ),
          ListTile(
            leading: const Icon(Icons.widgets_outlined, color: Color(0xFF38BDF8)),
            title: Text('Home Screen Widget', style: TextStyle(color: textColor)),
            subtitle: Text('Add tasks & reminders to phone', style: TextStyle(color: subtextColor, fontSize: 11)),
            onTap: () {
              Navigator.pop(context);
              HomeScreenWidgetSheet.show(context);
            },
          ),
          Divider(color: dividerColor),
          ListTile(
            leading: const Icon(Icons.auto_awesome, color: Colors.purpleAccent),
            title: Text('Hawk AI Chat', style: TextStyle(color: textColor)),
            onTap: () {
              Navigator.pop(context);
              setState(() => _currentIndex = 1);
            },
          ),
          ListTile(
            leading: const Icon(Icons.schedule, color: Colors.orangeAccent),
            title: Text('Schedules', style: TextStyle(color: textColor)),
            onTap: () {
              Navigator.pop(context);
              setState(() => _currentIndex = 2);
            },
          ),
          ListTile(
            leading: const Icon(Icons.book, color: Colors.tealAccent),
            title: Text('Journal', style: TextStyle(color: textColor)),
            onTap: () {
              Navigator.pop(context);
              setState(() => _currentIndex = 3);
            },
          ),
          ListTile(
            leading: const Icon(Icons.link, color: Colors.blueAccent),
            title: Text('Links', style: TextStyle(color: textColor)),
            onTap: () {
              Navigator.pop(context);
              setState(() => _currentIndex = 4);
            },
          ),
          ListTile(
            leading: const Icon(Icons.analytics, color: Colors.amberAccent),
            title: Text('Analytics', style: TextStyle(color: textColor)),
            onTap: () {
              Navigator.pop(context);
              setState(() => _currentIndex = 5);
            },
          ),
          ListTile(
            leading: const Icon(Icons.emoji_events, color: Colors.yellowAccent),
            title: Text('Challenges', style: TextStyle(color: textColor)),
            onTap: () {
              Navigator.pop(context);
              setState(() => _currentIndex = 6);
            },
          ),
          ListTile(
            leading: const Icon(Icons.people, color: Colors.lightGreenAccent),
            title: Text('Community', style: TextStyle(color: textColor)),
            onTap: () {
              Navigator.pop(context);
              setState(() => _currentIndex = 7);
            },
          ),
          ListTile(
            leading: const Icon(Icons.person, color: Colors.cyanAccent),
            title: Text('Profile', style: TextStyle(color: textColor)),
            onTap: () {
              Navigator.pop(context);
              setState(() => _currentIndex = 8);
            },
          ),
          ListTile(
            leading: const Icon(Icons.attach_money, color: Colors.greenAccent),
            title: Text('Expenses', style: TextStyle(color: textColor)),
            onTap: () {
              Navigator.pop(context);
              setState(() => _currentIndex = 9);
            },
          ),
          ListTile(
            leading: const Icon(Icons.center_focus_strong, color: Colors.redAccent),
            title: Text('Focus', style: TextStyle(color: textColor)),
            onTap: () {
              Navigator.pop(context);
              setState(() => _currentIndex = 10);
            },
          ),
          Divider(color: dividerColor),
          Builder(
            builder: (context) {
              final themeProvider = Provider.of<ThemeProvider?>(context);
              final isDark = themeProvider?.isDarkMode ?? true;
              return ListTile(
                leading: Icon(
                  isDark ? Icons.light_mode : Icons.dark_mode,
                  color: const Color(0xFF8083FF),
                ),
                title: Text(
                  isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                  style: TextStyle(color: textColor),
                ),
                onTap: () {
                  themeProvider?.toggleTheme();
                },
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('Logout', style: TextStyle(color: Colors.redAccent)),
            onTap: () async {
              await authProvider.logout();
              if (!mounted) return;
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // BOTTOM NAVIGATION (Matching website BottomNav.jsx)
  // -------------------------------------------------------------
  Widget _buildBottomNav() {
    final themeProvider = Provider.of<ThemeProvider?>(context);
    final isDark = themeProvider?.isDarkMode ?? true;
    final activeColor = themeProvider?.primary ?? (isDark ? const Color(0xFF8083FF) : const Color(0xFF4648D4));
    final inactiveColor = themeProvider?.textSecondary ?? (isDark ? const Color(0xFF908FA0) : const Color(0xFF64748B));

    final navItems = [
      {'icon': Icons.home, 'label': 'Home'},
      {'icon': Icons.auto_awesome, 'label': 'AI'},
      {'icon': Icons.event, 'label': 'Plan'},
      {'icon': Icons.list_alt, 'label': 'Log'},
      {'icon': Icons.link, 'label': 'Links'},
      {'icon': Icons.insights, 'label': 'Data'},
      {'icon': Icons.flag, 'label': 'Vs'},
      {'icon': Icons.person, 'label': 'Profile'},
    ];

    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: themeProvider?.surface ?? (isDark ? const Color(0xFF131B2E) : Colors.white),
        border: Border(top: BorderSide(color: themeProvider?.border ?? (isDark ? Colors.white10 : Colors.black12))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          ...List.generate(navItems.length, (index) {
            final item = navItems[index];
            final isActive = _currentIndex == index;
            return InkWell(
              onTap: () => setState(() => _currentIndex = index),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    item['icon'] as IconData,
                    size: 20,
                    color: isActive ? activeColor : inactiveColor,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item['label'] as String,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                      color: isActive ? activeColor : inactiveColor,
                    ),
                  ),
                ],
              ),
            );
          }),
          // Global Theme Toggler in Bottom Navbar
          Builder(
            builder: (context) {
              final themeProvider = Provider.of<ThemeProvider?>(context);
              final isDark = themeProvider?.isDarkMode ?? true;
              return InkWell(
                onTap: () => themeProvider?.toggleTheme(),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isDark ? Icons.light_mode : Icons.dark_mode,
                      size: 20,
                      color: activeColor,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isDark ? 'Light' : 'Dark',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: activeColor,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
