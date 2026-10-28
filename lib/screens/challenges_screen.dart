import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/hawk_header.dart';

class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({super.key});

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen> {
  final ApiService _apiService = ApiService();
  bool _loading = true;
  List<dynamic> _challenges = [];
  final Map<String, bool> _expandedChallenges = {};

  final List<Map<String, dynamic>> _challengeTemplates = [
    {
      'id': 'get_in_shape',
      'title': 'Get in Shape',
      'icon': Icons.fitness_center,
      'desc': 'Daily exercise challenge',
      'durationDays': 30,
      'tasks': [
        {'title': 'Exercise for 45 minutes', 'isDaily': true}
      ]
    },
    {
      'id': 'read_book',
      'title': 'Read a Book',
      'icon': Icons.menu_book,
      'desc': 'Buy a book and read it daily',
      'durationDays': 14,
      'tasks': [
        {'title': 'Buy the book', 'isDaily': false},
        {'title': 'Read 10 pages', 'isDaily': true}
      ]
    },
    {
      'id': '75_hard',
      'title': '75 Hard',
      'icon': Icons.local_fire_department,
      'desc': 'The ultimate mental toughness program',
      'durationDays': 75,
      'tasks': [
        {'title': 'Two 45-min workouts (one outside)', 'isDaily': true},
        {'title': 'Drink 1 gallon of water', 'isDaily': true},
        {'title': 'Read 10 pages of nonfiction', 'isDaily': true},
        {'title': 'Stick to a diet', 'isDaily': true},
        {'title': 'No cheat meals or alcohol', 'isDaily': true},
        {'title': 'Take a progress picture', 'isDaily': true}
      ]
    }
  ];

  @override
  void initState() {
    super.initState();
    _fetchChallenges();
  }

  Future<void> _fetchChallenges() async {
    try {
      final res = await _apiService.get('/challenges');
      if (res.statusCode == 200) {
        if (mounted) {
          setState(() {
            _challenges = List<dynamic>.from(json.decode(res.body));
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching challenges: $e');
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _toggleTask(String challengeId, String taskId, bool completed) async {
    final userId = Provider.of<AuthProvider>(context, listen: false).user?.id;
    final todayStr = DateTime.now().toIso8601String().split('T')[0];

    // Optimistic Update
    setState(() {
      for (var c in _challenges) {
        if (c['_id'] == challengeId) {
          List<dynamic> newTasks = [];
          for (var t in c['tasks']) {
            if (t['_id'] == taskId) {
              final isCreator = c['creator']?['_id'] == userId;
              final isSelf = c['creator']?['_id'] == c['recipient']?['_id'];
              final isMutual = c['type'] == 'mutual';

              Map<String, dynamic> newTask = Map<String, dynamic>.from(t);
              
              if (t['isDaily'] == true) {
                if (isSelf || !isCreator) {
                  List<dynamic> newHistory = List<dynamic>.from(t['recipientHistory'] ?? []);
                  if (completed && !newHistory.contains(todayStr)) {
                    newHistory.add(todayStr);
                  } else if (!completed) {
                    newHistory.remove(todayStr);
                  }
                  newTask['recipientHistory'] = newHistory;
                }
                if (isCreator && isMutual) {
                  List<dynamic> newHistory = List<dynamic>.from(t['creatorHistory'] ?? []);
                  if (completed && !newHistory.contains(todayStr)) {
                    newHistory.add(todayStr);
                  } else if (!completed) {
                    newHistory.remove(todayStr);
                  }
                  newTask['creatorHistory'] = newHistory;
                }
              } else {
                if (isSelf || !isCreator) {
                  newTask['recipientCompleted'] = completed;
                }
                if (isCreator && isMutual) {
                  newTask['creatorCompleted'] = completed;
                }
              }
              newTasks.add(newTask);
            } else {
              newTasks.add(t);
            }
          }
          c['tasks'] = newTasks;
        }
      }
    });

    try {
      final res = await _apiService.patch('/challenges/$challengeId', {
        'taskId': taskId,
        'completed': completed,
      });
      if (res.statusCode != 200) {
        _fetchChallenges();
      }
    } catch (e) {
      _fetchChallenges();
    }
  }

  Future<void> _handleChallengeAction(String challengeId, String action) async {
    setState(() {
      for (var c in _challenges) {
        if (c['_id'] == challengeId) {
          c['status'] = action == 'accept' ? 'accepted' : 'rejected';
        }
      }
    });

    try {
      final res = await _apiService.post('/challenges/$challengeId', {
        'action': action,
      });
      if (res.statusCode != 200) {
        _fetchChallenges();
      }
    } catch (e) {
      _fetchChallenges();
    }
  }

  Future<void> _openTemplateModal(Map<String, dynamic> template) async {
    final userId = Provider.of<AuthProvider>(context, listen: false).user?.id;
    List<dynamic> friends = [];
    
    // Fetch friends
    try {
      final res = await _apiService.get('/users');
      if (res.statusCode == 200) {
        final users = List<dynamic>.from(json.decode(res.body));
        friends = users.where((u) => u['isFriend'] == true).toList();
      }
    } catch (e) {
      debugPrint('Error fetching friends: $e');
    }

    if (!mounted) return;

    String? selectedFriend;
    String challengeType = 'mutual';
    bool isSubmitting = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(template['icon'] as IconData, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text(
                            'Start ${template['title']}',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      )
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Assign To', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                    value: selectedFriend,
                    hint: const Text('Choose someone...'),
                    items: [
                      if (userId != null)
                        DropdownMenuItem(
                          value: userId,
                          child: const Text('Myself (Personal Challenge)'),
                        ),
                      ...friends.map((f) {
                        return DropdownMenuItem<String>(
                          value: f['_id'],
                          child: Text(f['name'] ?? 'Unknown'),
                        );
                      }),
                    ],
                    onChanged: (val) {
                      setModalState(() {
                        selectedFriend = val;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  if (selectedFriend != null && selectedFriend != userId) ...[
                    const Text('Challenge Mode', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                      value: challengeType,
                      items: const [
                        DropdownMenuItem(value: 'mutual', child: Text('Mutual (Both of you do it)')),
                        DropdownMenuItem(value: 'challenge', child: Text('Solo Challenge (Only they do it)')),
                      ],
                      onChanged: (val) {
                        setModalState(() {
                          challengeType = val!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Challenge Details', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('Duration: ${template['durationDays']} Days', style: TextStyle(color: Colors.grey.shade700)),
                        const SizedBox(height: 8),
                        ...List.generate((template['tasks'] as List).length, (index) {
                          final t = template['tasks'][index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.circle, size: 6, color: Colors.grey),
                                const SizedBox(width: 8),
                                Expanded(child: Text(t['title'])),
                                if (t['isDaily'] == true)
                                  Container(
                                    margin: const EdgeInsets.only(left: 8),
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade100,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text('DAILY', style: TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold)),
                                  )
                              ],
                            ),
                          );
                        })
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: isSubmitting || selectedFriend == null
                          ? null
                          : () async {
                              setModalState(() => isSubmitting = true);
                              final startDate = DateTime.now();
                              final endDate = startDate.add(Duration(days: template['durationDays']));
                              final isSelf = selectedFriend == userId;
                              
                              try {
                                final res = await _apiService.post('/challenges', {
                                  'recipientId': selectedFriend,
                                  'type': isSelf ? 'challenge' : challengeType,
                                  'startDate': startDate.toIso8601String().split('T')[0],
                                  'endDate': endDate.toIso8601String().split('T')[0],
                                  'tasks': template['tasks'],
                                });
                                if (res.statusCode == 200 || res.statusCode == 201) {
                                  if (mounted) {
                                    Navigator.pop(ctx);
                                    _fetchChallenges();
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Challenge started successfully!')));
                                  }
                                } else {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to start challenge')));
                                  }
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error starting challenge')));
                                }
                              } finally {
                                if (mounted) {
                                  setModalState(() => isSubmitting = false);
                                }
                              }
                            },
                      child: Text(isSubmitting ? 'Starting...' : 'Start Challenge', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = Provider.of<AuthProvider>(context).user?.id;
    final themeProvider = Provider.of<ThemeProvider?>(context);
    final isDark = themeProvider?.isDarkMode ?? true;

    final bg = themeProvider?.bg ?? (isDark ? const Color(0xFF0B1326) : const Color(0xFFF8F9FF));
    final surface = themeProvider?.surface ?? (isDark ? const Color(0xFF131B2E) : Colors.white);
    final textPrimary = themeProvider?.textPrimary ?? (isDark ? const Color(0xFFDAE2FD) : Colors.black87);
    final textSecondary = themeProvider?.textSecondary ?? (isDark ? const Color(0xFF908FA0) : Colors.grey);
    final cardBorder = themeProvider?.cardBorder ?? (isDark ? Colors.white10 : Colors.black12);

    final todayStr = DateTime.now().toIso8601String().split('T')[0];
    final activeChallenges = _challenges.where((c) => c['status'] != 'completed' && c['status'] != 'rejected').toList();

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // 1. HawkHeader
            const HawkHeader(
              title: 'Challenges',
              subtitle: 'Compete & Win Together',
            ),

            // 2. Content
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Challenge Templates', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textPrimary)),
                          const SizedBox(height: 4),
                          Text('Start a standard challenge with your friends.', style: TextStyle(color: textSecondary)),
                          const SizedBox(height: 16),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 0.85,
                            ),
                            itemCount: _challengeTemplates.length,
                            itemBuilder: (ctx, index) {
                              final template = _challengeTemplates[index];
                              return GestureDetector(
                                onTap: () => _openTemplateModal(template),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: surface,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: cardBorder),
                                    boxShadow: [
                                      BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04), blurRadius: 10, offset: const Offset(0, 4))
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF4648D4).withValues(alpha: isDark ? 0.2 : 0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(template['icon'] as IconData, color: const Color(0xFF8083FF), size: 28),
                                      ),
                                      const Spacer(),
                                      Text(template['title'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textPrimary)),
                                      const SizedBox(height: 4),
                                      Text(template['desc'], style: TextStyle(fontSize: 12, color: textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 8),
                                      Text('${template['durationDays']} Days • ${(template['tasks'] as List).length} Tasks', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF8083FF))),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 32),
                          Text('Active Challenges', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textPrimary)),
                  const SizedBox(height: 16),
                  if (activeChallenges.isEmpty)
                    Center(
                      child: Column(
                        children: [
                          const SizedBox(height: 32),
                          Icon(Icons.flag, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          const Text('No Active Challenges', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text('You don\'t have any ongoing challenges right now.', style: TextStyle(color: Colors.grey.shade600)),
                        ],
                      ),
                    )
                  else
                    ...activeChallenges.map((c) {
                      final isCreator = c['creator']?['_id'] == userId;
                      final isSelf = c['creator']?['_id'] == c['recipient']?['_id'];
                      final otherUser = isSelf ? c['creator'] : (isCreator ? c['recipient'] : c['creator']);
                      final isMutual = c['type'] == 'mutual';

                      final totalTasks = (c['tasks'] as List).length;
                      int completedTasks = 0;
                      for (var t in c['tasks']) {
                        if (isMutual && !isSelf) {
                          if (isCreator && (t['isDaily'] == true ? (t['creatorHistory'] as List?)?.contains(todayStr) == true : t['creatorCompleted'] == true)) completedTasks++;
                          if (!isCreator && (t['isDaily'] == true ? (t['recipientHistory'] as List?)?.contains(todayStr) == true : t['recipientCompleted'] == true)) completedTasks++;
                        } else {
                          if (t['isDaily'] == true ? (t['recipientHistory'] as List?)?.contains(todayStr) == true : t['recipientCompleted'] == true) completedTasks++;
                        }
                      }
                      
                      final progressPercent = totalTasks == 0 ? 0.0 : (completedTasks / totalTasks);
                      final isExpanded = _expandedChallenges[c['_id']] == true || !isCreator || isSelf;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: cardBorder),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04), blurRadius: 10, offset: const Offset(0, 4))
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: Colors.blue.shade200),
                                  ),
                                  child: Text(
                                    isSelf ? 'PERSONAL CHALLENGE' : (isMutual ? 'MUTUAL CHALLENGE' : 'SOLO CHALLENGE'),
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: c['status'] == 'pending' ? Colors.grey.shade100 : (c['status'] == 'completed' ? Colors.green.shade50 : Colors.purple.shade50),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: c['status'] == 'pending' ? Colors.transparent : (c['status'] == 'completed' ? Colors.green.shade200 : Colors.transparent)),
                                  ),
                                  child: Text(
                                    (c['status'] ?? '').toString().toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10, 
                                      fontWeight: FontWeight.bold, 
                                      color: c['status'] == 'pending' ? Colors.grey.shade700 : (c['status'] == 'completed' ? Colors.green : Colors.purple)
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              isSelf ? 'My Challenge' : (isCreator ? 'Sent to ${otherUser?['name']}' : 'Received from ${otherUser?['name']}'),
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${c['startDate']?.split('T')[0] ?? ''} - ${c['endDate']?.split('T')[0] ?? ''}',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                            ),
                            if (c['note'] != null && c['note'].toString().isNotEmpty)
                              Container(
                                margin: const EdgeInsets.only(top: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.purple.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.purple.shade100),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('"${c['note']}"', style: const TextStyle(fontStyle: FontStyle.italic)),
                                    const SizedBox(height: 4),
                                    Text('— ${c['creator']?['name']}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.purple)),
                                  ],
                                ),
                              ),
                            if (isCreator)
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _expandedChallenges[c['_id']] = !isExpanded;
                                  });
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(top: 16),
                                  padding: const EdgeInsets.only(top: 16),
                                  decoration: BoxDecoration(
                                    border: Border(top: BorderSide(color: Colors.grey.shade200)),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                const Text('Today\'s Progress', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                                                Text('$completedTasks / $totalTasks Tasks', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 14)),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            LinearProgressIndicator(
                                              value: progressPercent,
                                              backgroundColor: Colors.grey.shade200,
                                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                                              minHeight: 8,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Icon(isExpanded ? Icons.expand_less : Icons.expand_more, color: Colors.grey),
                                    ],
                                  ),
                                ),
                              ),
                            if (isExpanded)
                              Container(
                                margin: EdgeInsets.only(top: isCreator ? 16 : 16),
                                padding: EdgeInsets.only(top: isCreator ? 0 : 16),
                                decoration: BoxDecoration(
                                  border: isCreator ? null : Border(top: BorderSide(color: Colors.grey.shade200)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (!isCreator)
                                      const Padding(
                                        padding: EdgeInsets.only(bottom: 12),
                                        child: Text('Tasks', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      ),
                                    ...c['tasks'].map<Widget>((t) {
                                      final iCanEdit = c['status'] == 'accepted' && (isMutual || !isCreator || isSelf);
                                      
                                      bool mainChecked = false;
                                      bool partnerChecked = false;

                                      if (isMutual && !isSelf) {
                                        if (t['isDaily'] == true) {
                                          mainChecked = isCreator ? (t['creatorHistory'] as List?)?.contains(todayStr) == true : (t['recipientHistory'] as List?)?.contains(todayStr) == true;
                                          partnerChecked = isCreator ? (t['recipientHistory'] as List?)?.contains(todayStr) == true : (t['creatorHistory'] as List?)?.contains(todayStr) == true;
                                        } else {
                                          mainChecked = isCreator ? t['creatorCompleted'] == true : t['recipientCompleted'] == true;
                                          partnerChecked = isCreator ? t['recipientCompleted'] == true : t['creatorCompleted'] == true;
                                        }
                                      } else {
                                        if (t['isDaily'] == true) {
                                          mainChecked = (t['recipientHistory'] as List?)?.contains(todayStr) == true;
                                        } else {
                                          mainChecked = t['recipientCompleted'] == true;
                                        }
                                      }

                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 8),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade50,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: Colors.grey.shade200),
                                        ),
                                        child: Row(
                                          children: [
                                            if (iCanEdit)
                                              Checkbox(
                                                value: mainChecked,
                                                onChanged: (val) {
                                                  if (val != null) _toggleTask(c['_id'], t['_id'], val);
                                                },
                                                activeColor: Colors.blue,
                                              )
                                            else
                                              Container(
                                                margin: const EdgeInsets.symmetric(horizontal: 12),
                                                width: 20,
                                                height: 20,
                                                decoration: BoxDecoration(
                                                  color: mainChecked ? Colors.blue : Colors.grey.shade100,
                                                  borderRadius: BorderRadius.circular(4),
                                                  border: Border.all(color: mainChecked ? Colors.blue : Colors.grey.shade400),
                                                ),
                                                child: mainChecked ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                                              ),
                                            Expanded(
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      t['title'],
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.w500,
                                                        decoration: mainChecked ? TextDecoration.lineThrough : null,
                                                        color: mainChecked ? Colors.grey : Colors.black,
                                                      ),
                                                    ),
                                                  ),
                                                  if (t['isDaily'] == true)
                                                    Container(
                                                      margin: const EdgeInsets.only(left: 8),
                                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: Colors.orange.shade50,
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                      child: const Text('DAILY', style: TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold)),
                                                    )
                                                ],
                                              ),
                                            ),
                                            if (isMutual && !isSelf)
                                              Row(
                                                children: [
                                                  Text(
                                                    '${otherUser?['name']?.toString().split(' ')[0] ?? ''}: ',
                                                    style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
                                                  ),
                                                  Icon(
                                                    partnerChecked ? Icons.check_circle : Icons.radio_button_unchecked,
                                                    size: 16,
                                                    color: partnerChecked ? Colors.green : Colors.grey.shade400,
                                                  ),
                                                ],
                                              ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ],
                                ),
                              ),
                            if (!isCreator && c['status'] == 'pending')
                              Container(
                                margin: const EdgeInsets.only(top: 16),
                                padding: const EdgeInsets.only(top: 16),
                                decoration: BoxDecoration(
                                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                        onPressed: () => _handleChallengeAction(c['_id'], 'accept'),
                                        child: const Text('Accept', style: TextStyle(fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextButton(
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.red,
                                          backgroundColor: Colors.red.shade50,
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                        onPressed: () => _handleChallengeAction(c['_id'], 'reject'),
                                        child: const Text('Decline', style: TextStyle(fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
}
