import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/hawk_header.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _loading = true;
  Map<String, dynamic>? _profile;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final response = await _apiService.get('/users/profile');
      if (response.statusCode == 200) {
        setState(() {
          _profile = json.decode(response.body);
        });
      } else {
        print('Failed to load profile: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading profile: $e');
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Widget _buildHeatmap(Map<String, dynamic> activityMap) {
    // Generate simple heatmap mock or real based on activityMap
    // For simplicity, we create a small grid
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_fire_department, color: Colors.purple, size: 20),
              const SizedBox(width: 8),
              const Text('Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              Icon(Icons.local_fire_department, color: Colors.orange[500], size: 16),
              const SizedBox(width: 4),
              Text('${_profile?['streak'] ?? 0} day streak', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 16),
          // Simplified Heatmap placeholder due to complex scroll/grid requirements
          // Web version uses a 52-week grid. We will show a simplified list or text, or a basic grid.
          // To keep it simple, we'll just show total activity and streak.
          const Text('Detailed activity heatmap is available on the web version.', style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider?>(context);
    final isDark = themeProvider?.isDarkMode ?? true;

    final bg = themeProvider?.bg ?? (isDark ? const Color(0xFF0B1326) : const Color(0xFFF8F9FF));
    final surface = themeProvider?.surface ?? (isDark ? const Color(0xFF131B2E) : Colors.white);
    final textPrimary = themeProvider?.textPrimary ?? (isDark ? const Color(0xFFDAE2FD) : Colors.black87);
    final textSecondary = themeProvider?.textSecondary ?? (isDark ? const Color(0xFF908FA0) : Colors.grey);
    final cardBorder = themeProvider?.cardBorder ?? (isDark ? Colors.white10 : Colors.black12);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // 1. HawkHeader
            const HawkHeader(
              title: 'Profile',
              subtitle: 'Account & Settings',
            ),

            // 2. Profile Content
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _profile == null
                      ? Center(child: Text('Failed to load profile.', style: TextStyle(color: textSecondary)))
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Profile Header Card
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: cardBorder),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    color: Colors.purple.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.purple.withOpacity(0.2)),
                                  ),
                                  child: Center(
                                    child: Text(
                                      _profile!['user']['name'].substring(0, 1).toUpperCase(),
                                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.purple),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _profile!['user']['name'],
                                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        _profile!['user']['email'],
                                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                _buildStatCard(
                                  icon: Icons.stars,
                                  iconColor: Colors.blue,
                                  label: 'POINTS',
                                  value: '${_profile!['user']['hawkPoints'] ?? 0}',
                                ),
                                const SizedBox(width: 8),
                                _buildStatCard(
                                  icon: Icons.local_fire_department,
                                  iconColor: Colors.orange,
                                  label: 'STREAK',
                                  value: '${_profile!['streak'] ?? 0}',
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                _buildStatCard(
                                  icon: Icons.group,
                                  iconColor: Colors.green,
                                  label: 'FRIENDS',
                                  value: '${_profile!['friendCount'] ?? 0}',
                                ),
                                const SizedBox(width: 8),
                                _buildStatCard(
                                  icon: Icons.emoji_events,
                                  iconColor: Colors.purple,
                                  label: 'WON',
                                  value: '${_profile!['completedChallengesCount'] ?? 0}',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Activity Heatmap
                      _buildHeatmap(_profile!['activityMap'] ?? {}),
                      const SizedBox(height: 20),

                      // Timeline
                      const Text(
                        'Completed History',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      _buildTimeline(_profile!['timeline'] ?? []),
                    ],
                  ),
                ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({required IconData icon, required Color iconColor, required String label, required String value}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                  Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline(List<dynamic> timeline) {
    if (timeline.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
        ),
        child: Column(
          children: const [
            Icon(Icons.hourglass_empty, size: 44, color: Colors.grey),
            SizedBox(height: 12),
            Text('No history yet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text('Complete tasks, habits, and challenges to earn points!', style: TextStyle(color: Colors.grey, fontSize: 12), textAlign: TextAlign.center),
          ],
        ),
      );
    }

    return Column(
      children: timeline.map((item) {
        IconData iconData = Icons.task_alt;
        Color iconColor = Colors.purple;
        if (item['type'] == 'challenge') {
          iconData = Icons.emoji_events;
          iconColor = Colors.blue;
        } else if (item['type'] == 'habit') {
          iconData = Icons.loop;
          iconColor = Colors.green;
        }

        final dateStr = item['date'] != null ? DateFormat.yMMMd().format(DateTime.parse(item['date'])) : '';

        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 4, right: 12),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.withOpacity(0.2), width: 2),
                ),
                child: Icon(iconData, color: iconColor, size: 20),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.withOpacity(0.2)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      )
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(dateStr, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                            const SizedBox(height: 4),
                            Text(item['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            if (item['type'] == 'challenge' && item['with'] != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Row(
                                  children: [
                                    const Icon(Icons.group, size: 12, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text('With ${item['with']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Text('+${item['points']}', style: const TextStyle(color: Colors.purple, fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(width: 2),
                            const Icon(Icons.stars, color: Colors.purple, size: 14),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
