import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/schedule_provider.dart';

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

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ScheduleProvider>(context);

    if (provider.isLoading && provider.schedules.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null && provider.schedules.isEmpty) {
      return Center(child: Text(provider.error!));
    }

    final schedules = provider.schedules;

    return RefreshIndicator(
      onRefresh: provider.fetchSchedules,
      child: Container(
        color: const Color(0xFFF8F9FA),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text(
                'My Schedule',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                itemCount: schedules.length,
                itemBuilder: (context, index) {
                  final schedule = schedules[index];
                  final isActive = _isCurrentBlock(schedule.startTime, schedule.endTime);
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: isActive ? Colors.blue.withValues(alpha: 0.1) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: isActive ? Border.all(color: Colors.blueAccent, width: 2) : Border.all(color: Colors.transparent),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
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
                          color: isActive ? Colors.blueAccent : Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.access_time, 
                          color: isActive ? Colors.white : Colors.black54,
                        ),
                      ),
                      title: Text(
                        schedule.title,
                        style: TextStyle(
                          fontSize: 18, 
                          fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                          color: Colors.black87
                        ),
                      ),
                      subtitle: Text(
                        '${schedule.startTime} - ${schedule.endTime}',
                        style: TextStyle(
                          color: isActive ? Colors.blueAccent : Colors.grey,
                          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        onPressed: () => provider.deleteSchedule(schedule.id),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
