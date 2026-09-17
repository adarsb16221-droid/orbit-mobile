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

    if (provider.isLoading && !_isEditing) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Journal - $_todayDateStr',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: Icon(_isEditing ? Icons.save : Icons.edit),
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
          const SizedBox(height: 16),
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _textController,
                  maxLines: null,
                  expands: true,
                  enabled: _isEditing,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'How was your day?',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
