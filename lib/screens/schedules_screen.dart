import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/schedule.dart';
import '../providers/schedule_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/hawk_header.dart';

class SchedulesScreen extends StatefulWidget {
  const SchedulesScreen({super.key});

  @override
  State<SchedulesScreen> createState() => _SchedulesScreenState();
}

class _SchedulesScreenState extends State<SchedulesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ScheduleProvider>(context, listen: false).fetchSchedules();
    });
  }

  bool _isCurrentBlock(String start, String end) {
    final now = DateTime.now();
    final h = now.hour.toString().padLeft(2, '0');
    final m = now.minute.toString().padLeft(2, '0');
    final currentTime = '$h:$m';
    return currentTime.compareTo(start) >= 0 && currentTime.compareTo(end) <= 0;
  }
  
  String _formatTimeStr(String time24) {
    if (time24.isEmpty) return '';
    final parts = time24.split(':');
    if (parts.length != 2) return time24;
    int h = int.tryParse(parts[0]) ?? 0;
    final String m = parts[1];
    final ampm = h >= 12 ? 'PM' : 'AM';
    h = h % 12;
    if (h == 0) h = 12;
    return '$h:$m $ampm';
  }

  void _showScheduleDialog({Schedule? existing}) {
    final titleController = TextEditingController(text: existing?.title ?? '');
    TimeOfDay? startTime = existing != null 
        ? TimeOfDay(hour: int.parse(existing.startTime.split(':')[0]), minute: int.parse(existing.startTime.split(':')[1])) 
        : const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay? endTime = existing != null 
        ? TimeOfDay(hour: int.parse(existing.endTime.split(':')[0]), minute: int.parse(existing.endTime.split(':')[1])) 
        : const TimeOfDay(hour: 10, minute: 0);
        
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> selectTime(bool isStart) async {
              final initial = isStart ? startTime! : endTime!;
              final picked = await showTimePicker(context: context, initialTime: initial);
              if (picked != null) {
                setModalState(() {
                  if (isStart) startTime = picked;
                  else endTime = picked;
                });
              }
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(ctx).viewInsets.bottom + 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(existing == null ? 'Add Schedule Block' : 'Edit Schedule Block', 
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Title / Activity Name', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          const Text('Start Time', style: TextStyle(color: Colors.grey)),
                          TextButton(
                            onPressed: () => selectTime(true),
                            child: Text(startTime!.format(context), style: const TextStyle(fontSize: 16)),
                          )
                        ],
                      ),
                      const Text('to'),
                      Column(
                        children: [
                          const Text('End Time', style: TextStyle(color: Colors.grey)),
                          TextButton(
                            onPressed: () => selectTime(false),
                            child: Text(endTime!.format(context), style: const TextStyle(fontSize: 16)),
                          )
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        if (titleController.text.trim().isEmpty) return;
                        
                        final sTimeStr = '${startTime!.hour.toString().padLeft(2, '0')}:${startTime!.minute.toString().padLeft(2, '0')}';
                        final eTimeStr = '${endTime!.hour.toString().padLeft(2, '0')}:${endTime!.minute.toString().padLeft(2, '0')}';
                        
                        final provider = Provider.of<ScheduleProvider>(context, listen: false);
                        
                        final scheduleObj = Schedule(
                          id: existing?.id ?? '',
                          title: titleController.text.trim(),
                          startTime: sTimeStr,
                          endTime: eTimeStr,
                          color: existing?.color ?? 'primary',
                        );
                        
                        bool success;
                        if (existing == null) {
                          success = await provider.addSchedule(scheduleObj);
                        } else {
                          success = await provider.updateSchedule(scheduleObj);
                        }
                        
                        if (success) {
                          if (mounted) Navigator.pop(ctx);
                        } else {
                          if (mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(provider.error ?? 'Failed to save schedule')));
                          }
                        }
                      },
                      child: const Text('Save Schedule', style: TextStyle(fontSize: 16)),
                    ),
                  )
                ],
              ),
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ScheduleProvider>(context);
    final themeProvider = Provider.of<ThemeProvider?>(context);
    final isDark = themeProvider?.isDarkMode ?? true;

    final bg = themeProvider?.bg ?? (isDark ? const Color(0xFF0B1326) : const Color(0xFFF8F9FF));
    final surface = themeProvider?.surface ?? (isDark ? const Color(0xFF131B2E) : Colors.white);
    final textPrimary = themeProvider?.textPrimary ?? (isDark ? const Color(0xFFDAE2FD) : Colors.black87);
    final textSecondary = themeProvider?.textSecondary ?? (isDark ? const Color(0xFF908FA0) : Colors.grey);

    if (provider.isLoading && provider.schedules.isEmpty) {
      return Scaffold(
        backgroundColor: bg,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (provider.error != null && provider.schedules.isEmpty) {
      return Scaffold(
        backgroundColor: bg,
        body: Center(child: Text(provider.error ?? '', style: TextStyle(color: textPrimary))),
      );
    }

    final schedules = provider.schedules;
    
    // Sort schedules
    schedules.sort((a, b) => a.startTime.compareTo(b.startTime));

    return Scaffold(
      backgroundColor: bg,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showScheduleDialog(),
        backgroundColor: const Color(0xFF4648D4),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Unified HawkHeader
            HawkHeader(
              title: 'Schedules',
              subtitle: 'Daily Routines & Time Blocks',
              actions: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: themeProvider?.circleBtnBg ?? (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
                    border: Border.all(color: themeProvider?.circleBtnBorder ?? (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1))),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.add, size: 20, color: isDark ? const Color(0xFFC0C1FF) : const Color(0xFF4648D4)),
                    tooltip: 'Add Schedule',
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    padding: EdgeInsets.zero,
                    onPressed: () => _showScheduleDialog(),
                  ),
                ),
              ],
            ),

            // 2. Schedule List
            Expanded(
              child: RefreshIndicator(
                onRefresh: provider.fetchSchedules,
                color: const Color(0xFF8083FF),
                backgroundColor: surface,
                child: schedules.isEmpty 
                    ? Center(
                        child: Text(
                          'No schedule blocks found. Tap + to add one!',
                          style: TextStyle(color: textSecondary),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 80.0),
                        itemCount: schedules.length,
                        itemBuilder: (context, index) {
                          final schedule = schedules[index];
                          final isActive = _isCurrentBlock(schedule.startTime, schedule.endTime);
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? (isDark ? const Color(0xFF4648D4).withValues(alpha: 0.25) : const Color(0xFF4648D4).withValues(alpha: 0.12))
                                  : surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isActive
                                    ? const Color(0xFF8083FF)
                                    : (themeProvider?.cardBorder ?? (isDark ? Colors.white10 : Colors.black12)),
                                width: isActive ? 1.5 : 1.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isActive ? const Color(0xFF4648D4) : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.05)),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.access_time, 
                                  color: isActive ? Colors.white : (isDark ? const Color(0xFF8083FF) : const Color(0xFF4648D4)),
                                ),
                              ),
                              title: Text(
                                schedule.title,
                                style: TextStyle(
                                  fontSize: 17, 
                                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                                  color: textPrimary,
                                ),
                              ),
                              subtitle: Text(
                                '${_formatTimeStr(schedule.startTime)} - ${_formatTimeStr(schedule.endTime)}',
                                style: TextStyle(
                                  color: isActive ? const Color(0xFF8083FF) : textSecondary,
                                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                              trailing: PopupMenuButton<String>(
                                iconColor: textSecondary,
                                onSelected: (val) {
                                  if (val == 'edit') {
                                    _showScheduleDialog(existing: schedule);
                                  } else if (val == 'delete') {
                                    provider.deleteSchedule(schedule.id);
                                  }
                                },
                                itemBuilder: (ctx) => [
                                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                  const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
