import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/theme_provider.dart';
import '../widgets/hawk_header.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _users = [];
  bool _isLoading = true;
  String? _error;
  String _activeTab = 'friends';
  String _searchQuery = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _fetchUsers([String search = '']) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final query = search.isNotEmpty ? '?search=${Uri.encodeComponent(search)}' : '';
      final response = await _apiService.get('/users$query');
      
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _users = json.decode(response.body);
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _error = 'Failed to fetch users';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _fetchUsers(_searchQuery);
    });
  }

  Future<void> _handleFriendAction(String friendId, Map<String, dynamic> user) async {
    // Optimistic update
    setState(() {
      final index = _users.indexWhere((u) => u['_id'] == friendId);
      if (index != -1) {
        var u = Map<String, dynamic>.from(_users[index]);
        if (u['isFriend'] == true) {
          u['isFriend'] = false;
          u['hasRequested'] = false;
          u['isRequesting'] = false;
        } else if (u['isRequesting'] == true) {
          u['isFriend'] = true;
          u['isRequesting'] = false;
          u['hasRequested'] = false;
        } else if (u['hasRequested'] == true) {
          u['hasRequested'] = false;
        } else {
          u['hasRequested'] = true;
        }
        _users[index] = u;
      }
    });

    try {
      final response = await _apiService.post('/users/friend', {'friendId': friendId});
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            final index = _users.indexWhere((u) => u['_id'] == friendId);
            if (index != -1) {
               var u = Map<String, dynamic>.from(_users[index]);
               u['isFriend'] = data['isFriend'];
               u['hasRequested'] = data['hasRequested'] ?? false;
               _users[index] = u;
            }
          });
        }
      } else {
        throw Exception('Failed to process friend action');
      }
    } catch (e) {
      debugPrint(e.toString());
      _fetchUsers(_searchQuery);
    }
  }
  
  void _showChallengeModal(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => ChallengeModal(
        user: user,
        apiService: _apiService,
      ),
    );
  }

  Widget _buildButton(Map<String, dynamic> user) {
    if (user['isFriend'] == true) {
      return OutlinedButton.icon(
        onPressed: () => _handleFriendAction(user['_id'], user),
        icon: const Icon(Icons.person_remove, size: 20),
        label: const Text('Remove'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red,
          side: BorderSide(color: Colors.red.withOpacity(0.5)),
          backgroundColor: Colors.red.withOpacity(0.1),
        ),
      );
    }
    if (user['isRequesting'] == true) {
      return ElevatedButton.icon(
        onPressed: () => _handleFriendAction(user['_id'], user),
        icon: const Icon(Icons.person_add, size: 20),
        label: const Text('Accept Request'),
      );
    }
    if (user['hasRequested'] == true) {
      return OutlinedButton.icon(
        onPressed: () => _handleFriendAction(user['_id'], user),
        icon: const Icon(Icons.pending, size: 20),
        label: const Text('Requested'),
      );
    }
    return ElevatedButton.icon(
      onPressed: () => _handleFriendAction(user['_id'], user),
      icon: const Icon(Icons.person_add, size: 20),
      label: const Text('Add Friend'),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final themeProvider = Provider.of<ThemeProvider?>(context);
    final isDark = themeProvider?.isDarkMode ?? true;

    final name = user['name'] ?? 'Unknown';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final pts = user['hawkPoints'] ?? 0;
    final int points = pts < 0 ? 0 : (pts as num).toInt();
    final isFriend = user['isFriend'] == true;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: themeProvider?.surface ?? (isDark ? const Color(0xFF131B2E) : Colors.white),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: themeProvider?.cardBorder ?? (isDark ? Colors.white10 : Colors.black12)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFF4648D4).withValues(alpha: isDark ? 0.25 : 0.1),
                  foregroundColor: const Color(0xFF8083FF),
                  child: Text(initial, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: themeProvider?.textPrimary ?? (isDark ? const Color(0xFFDAE2FD) : Colors.black87),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.stars, size: 16, color: Colors.orange),
                          const SizedBox(width: 4),
                          Text('$points pts', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ],
                  ),
                ),
                if (isFriend)
                  IconButton(
                    icon: const Icon(Icons.person_remove),
                    color: Colors.red,
                    onPressed: () => _handleFriendAction(user['_id'], user),
                    tooltip: 'Remove Friend',
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (isFriend)
              ElevatedButton.icon(
                onPressed: () => _showChallengeModal(user),
                icon: const Icon(Icons.flag, size: 20),
                label: const Text('Give Challenge'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  foregroundColor: Theme.of(context).colorScheme.onSecondary,
                ),
              )
            else
              _buildButton(user),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider?>(context);
    final isDark = themeProvider?.isDarkMode ?? true;

    final bg = themeProvider?.bg ?? (isDark ? const Color(0xFF0B1326) : const Color(0xFFF8F9FF));
    final textPrimary = themeProvider?.textPrimary ?? (isDark ? const Color(0xFFDAE2FD) : Colors.black87);
    final textSecondary = themeProvider?.textSecondary ?? (isDark ? const Color(0xFF908FA0) : Colors.grey);

    final friendsList = _users.where((u) => u['isFriend'] == true).toList();
    final discoverList = _users.where((u) => u['isFriend'] != true).toList();
    final displayList = _activeTab == 'friends' ? friendsList : discoverList;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // 1. HawkHeader
            const HawkHeader(
              title: 'Community',
              subtitle: 'Platform Users & Friends',
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Platform Users', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textPrimary)),
                  const SizedBox(height: 4),
                  Text('Connect with others and assign challenges.', style: TextStyle(color: textSecondary)),
                  const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _activeTab = 'friends'),
                        child: Container(
                          padding: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: _activeTab == 'friends' ? Theme.of(context).primaryColor : Colors.transparent,
                                width: 2,
                              ),
                            ),
                          ),
                          child: Text(
                            'My Friends (${friendsList.length})',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _activeTab == 'friends' ? Theme.of(context).primaryColor : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _activeTab = 'discover'),
                        child: Container(
                          padding: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: _activeTab == 'discover' ? Theme.of(context).primaryColor : Colors.transparent,
                                width: 2,
                              ),
                            ),
                          ),
                          child: Text(
                            'Discover',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _activeTab == 'discover' ? Theme.of(context).primaryColor : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_activeTab == 'discover') ...[
                  const SizedBox(height: 16),
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search users by name or email...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                    onChanged: _onSearchChanged,
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
                    : displayList.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.group_off, size: 48, color: Colors.grey),
                                  const SizedBox(height: 16),
                                  Text(
                                    _activeTab == 'discover' && _searchQuery.isEmpty ? 'Search for people' : 'No users found',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _activeTab == 'friends'
                                        ? "You haven't added any friends yet. Check the Discover tab to find people!"
                                        : _searchQuery.isEmpty
                                            ? "Type a name or email in the search bar above to discover new friends."
                                            : "No users matched your search query.",
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: displayList.length,
                            itemBuilder: (context, index) {
                              final user = displayList[index];
                              return _buildUserCard(user);
                            },
                          ),
          ),
        ],
      ),
    ),
  );
  }
}

class ChallengeModal extends StatefulWidget {
  final Map<String, dynamic> user;
  final ApiService apiService;

  const ChallengeModal({super.key, required this.user, required this.apiService});

  @override
  State<ChallengeModal> createState() => _ChallengeModalState();
}

class _ChallengeModalState extends State<ChallengeModal> {
  String _challengeType = 'mutual';
  String _challengeNote = '';
  late DateTime _startDate;
  late DateTime _endDate;
  final List<TextEditingController> _taskControllers = [TextEditingController()];
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _startDate = DateTime.now();
    _endDate = DateTime.now().add(const Duration(days: 7));
  }

  @override
  void dispose() {
    for (var controller in _taskControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submitChallenge() async {
    final tasks = _taskControllers.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();
    if (tasks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add at least one task')));
      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      final response = await widget.apiService.post('/challenges', {
        'recipientId': widget.user['_id'],
        'type': _challengeType,
        'startDate': _startDate.toIso8601String().split('T')[0],
        'endDate': _endDate.toIso8601String().split('T')[0],
        'tasks': tasks.map((t) => {'title': t}).toList(),
        'note': _challengeNote,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Challenge sent successfully!')));
        }
      } else {
        throw Exception('Failed to create challenge');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error creating challenge')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final initialDate = isStart ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != initialDate) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.flag, color: Theme.of(context).primaryColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Challenge ${widget.user['name']?.split(' ')[0] ?? 'Friend'}',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),
              const Text('Type', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _challengeType,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 'mutual', child: Text('Mutual (Both complete tasks)')),
                  DropdownMenuItem(value: 'challenge', child: Text('Solo Challenge (Only they)')),
                ],
                onChanged: (val) => setState(() => _challengeType = val!),
              ),
              const SizedBox(height: 16),
              const Text('Note to Friend', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Add an encouraging note...',
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) => _challengeNote = val,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Start Date', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _selectDate(context, true),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                            child: Text(_startDate.toIso8601String().split('T')[0]),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('End Date', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _selectDate(context, false),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                            child: Text(_endDate.toIso8601String().split('T')[0]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Tasks', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...List.generate(_taskControllers.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _taskControllers[index],
                          decoration: InputDecoration(
                            hintText: 'Task ${index + 1}',
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                        ),
                      ),
                      if (_taskControllers.length > 1)
                        IconButton(
                          icon: const Icon(Icons.remove_circle, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              _taskControllers[index].dispose();
                              _taskControllers.removeAt(index);
                            });
                          },
                        ),
                    ],
                  ),
                );
              }),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _taskControllers.add(TextEditingController());
                    });
                  },
                  icon: const Icon(Icons.add_circle),
                  label: const Text('Add Task'),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _submitting ? null : _submitChallenge,
                    child: Text(_submitting ? 'Sending...' : 'Send Challenge'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
