import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/journal_provider.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final _textController = TextEditingController();
  late String _todayDateStr;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _todayDateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadJournal();
    });
  }

  void _loadJournal() async {
    final provider = Provider.of<JournalProvider>(context, listen: false);
    await provider.fetchJournal(_todayDateStr);
    if (provider.todayJournal != null) {
      _textController.text = provider.todayJournal!.content;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _save() async {
    final provider = Provider.of<JournalProvider>(context, listen: false);
    final success = await provider.saveJournal(_todayDateStr, _textController.text);
    if (success) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Journal saved successfully')),
      );
      setState(() {
        _isEditing = false;
      });
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Failed to save')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<JournalProvider>(context);

    if (provider.isLoading && !_isEditing && _textController.text.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      color: const Color(0xFFF8F9FA),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Daily Journal',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  Text(
                    DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now()),
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isEditing ? Colors.green : Colors.blueAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                icon: Icon(_isEditing ? Icons.check : Icons.edit, size: 18),
                label: Text(_isEditing ? 'Save' : 'Edit'),
                onPressed: () {
                  if (_isEditing) {
                    _save();
                  } else {
                    setState(() {
                      _isEditing = true;
                    });
                  }
                },
              )
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20.0),
              child: TextField(
                controller: _textController,
                maxLines: null,
                expands: true,
                enabled: _isEditing,
                style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black87),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'What are you grateful for today?\n\nHow are you feeling?',
                  hintStyle: TextStyle(color: Colors.black38),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
