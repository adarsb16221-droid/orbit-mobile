import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/theme_provider.dart';
import '../widgets/hawk_header.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;
  List<dynamic> _transactions = [];
  
  // Date format: YYYY-MM
  String _month = DateTime.now().toIso8601String().substring(0, 7);
  String _filter = 'all';

  final _formKey = GlobalKey<FormState>();
  String _type = 'expense';
  String _title = '';
  String _amount = '';
  String _category = 'Food';
  String _date = DateTime.now().toIso8601String().substring(0, 10);
  String _note = '';
  String? _editingId;

  final List<String> _categories = [
    'Food', 'Transport', 'Shopping', 'Bills', 'Health', 'Entertainment', 'Education', 'Other'
  ];

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await _apiService.get('/expenses?month=$_month');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _transactions = List<dynamic>.from(data);
        });
      } else {
        setState(() {
          _error = 'Failed to load transactions';
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _submitTransaction() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() {
      _isSaving = true;
      _error = null;
    });

    final payload = {
      if (_editingId != null) '_id': _editingId,
      'type': _type,
      'title': _title,
      'amount': double.tryParse(_amount) ?? 0.0,
      'category': _category,
      'date': _date,
      'note': _note,
    };

    try {
      final response = _editingId != null
          ? await _apiService.put('/expenses', payload)
          : await _apiService.post('/expenses', payload);

      if (response.statusCode == 200 || response.statusCode == 201) {
        _resetForm();
        _loadTransactions();
      } else {
        setState(() {
          _error = 'Failed to save transaction';
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _deleteTransaction(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete transaction?'),
        content: const Text('Are you sure you want to delete this transaction?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final response = await _apiService.delete('/expenses?id=$id');
      if (response.statusCode == 200) {
        setState(() {
          _transactions.removeWhere((t) => t['_id'] == id);
        });
      } else {
        setState(() {
          _error = 'Failed to delete transaction';
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    }
  }

  void _startEditing(dynamic item) {
    setState(() {
      _editingId = item['_id'];
      _type = item['type'];
      _title = item['title'];
      _amount = item['amount'].toString();
      _category = item['category'];
      _date = item['date'];
      _note = item['note'] ?? '';
    });
  }

  void _resetForm() {
    setState(() {
      _editingId = null;
      _type = 'expense';
      _title = '';
      _amount = '';
      _category = 'Food';
      _date = DateTime.now().toIso8601String().substring(0, 10);
      _note = '';
    });
    _formKey.currentState?.reset();
  }

  String _formatMoney(num amount) {
    return '₹${amount.toStringAsFixed(2)}'; // Hardcoding INR as per Next.js 'en-IN' format
  }

  @override
  Widget build(BuildContext context) {
    final visibleTransactions = _filter == 'all'
        ? _transactions
        : _transactions.where((t) => t['type'] == _filter).toList();

    double totalIncome = 0;
    double totalExpense = 0;
    Map<String, double> categoryTotals = {};

    for (var t in _transactions) {
      double amt = (t['amount'] as num).toDouble();
      if (t['type'] == 'income') {
        totalIncome += amt;
      } else {
        totalExpense += amt;
        categoryTotals[t['category']] = (categoryTotals[t['category']] ?? 0) + amt;
      }
    }

    String topCategoryName = 'No spending yet';
    double topCategoryAmount = 0;
    if (categoryTotals.isNotEmpty) {
      final sortedEntries = categoryTotals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      topCategoryName = sortedEntries.first.key;
      topCategoryAmount = sortedEntries.first.value;
    }

    final themeProvider = Provider.of<ThemeProvider?>(context);
    final isDark = themeProvider?.isDarkMode ?? true;

    final bg = themeProvider?.bg ?? (isDark ? const Color(0xFF0B1326) : const Color(0xFFF8F9FF));
    final textPrimary = themeProvider?.textPrimary ?? (isDark ? const Color(0xFFDAE2FD) : Colors.black87);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // 1. HawkHeader
            HawkHeader(
              title: 'Expenses',
              subtitle: 'Income & Expense Tracking',
              actions: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: themeProvider?.circleBtnBg ?? (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
                    border: Border.all(color: themeProvider?.circleBtnBorder ?? (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1))),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.add, size: 20, color: isDark ? const Color(0xFFC0C1FF) : const Color(0xFF4648D4)),
                    tooltip: 'Add Transaction',
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    padding: EdgeInsets.zero,
                    onPressed: () => _resetForm(),
                  ),
                ),
              ],
            ),

            // 2. Expenses Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_error != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        color: Colors.red.shade100,
                        child: Text(_error!, style: const TextStyle(color: Colors.red)),
                      ),

                    // Month Picker Area
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Money overview', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textPrimary)),
                        TextButton.icon(
                          icon: const Icon(Icons.calendar_month, color: Color(0xFF8083FF)),
                          label: Text(_month, style: const TextStyle(color: Color(0xFF8083FF), fontWeight: FontWeight.bold)),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.parse('$_month-01'),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setState(() {
                                _month = picked.toIso8601String().substring(0, 7);
                              });
                              _loadTransactions();
                            }
                          },
                        ),
                      ],
                    ),
            const SizedBox(height: 16),

            // Stats Cards
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.5,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              children: [
                _buildStatCard('Income', _formatMoney(totalIncome), Colors.green, Icons.trending_up),
                _buildStatCard('Expenses', _formatMoney(totalExpense), Colors.red, Icons.trending_down),
                _buildStatCard('Balance', _formatMoney(totalIncome - totalExpense), totalIncome - totalExpense >= 0 ? Colors.blue : Colors.red, Icons.account_balance),
                _buildStatCard('Top category', topCategoryAmount > 0 ? '$topCategoryName\n${_formatMoney(topCategoryAmount)}' : topCategoryName, Colors.purple, Icons.category),
              ],
            ),
            const SizedBox(height: 24),

            // Form
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_editingId != null ? 'Edit transaction' : 'Add transaction', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          if (_editingId != null)
                            TextButton(onPressed: _resetForm, child: const Text('Cancel')),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: const Text('Expense'),
                              selected: _type == 'expense',
                              onSelected: (val) => setState(() => _type = 'expense'),
                              selectedColor: Colors.blueAccent,
                              labelStyle: TextStyle(color: _type == 'expense' ? Colors.white : Colors.black),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ChoiceChip(
                              label: const Text('Income'),
                              selected: _type == 'income',
                              onSelected: (val) => setState(() => _type = 'income'),
                              selectedColor: Colors.blueAccent,
                              labelStyle: TextStyle(color: _type == 'income' ? Colors.white : Colors.black),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: _title,
                        decoration: const InputDecoration(labelText: 'What was it for?', border: OutlineInputBorder()),
                        validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                        onSaved: (val) => _title = val ?? '',
                        onChanged: (val) => _title = val,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: _amount,
                              decoration: const InputDecoration(labelText: 'Amount', border: OutlineInputBorder()),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                              onSaved: (val) => _amount = val ?? '',
                              onChanged: (val) => _amount = val,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              key: ValueKey(_date),
                              initialValue: _date,
                              decoration: const InputDecoration(labelText: 'Date', border: OutlineInputBorder()),
                              readOnly: true,
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.parse(_date),
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                );
                                if (picked != null) {
                                  setState(() {
                                    _date = picked.toIso8601String().substring(0, 10);
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _category,
                        decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                        items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: (val) => setState(() => _category = val!),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        initialValue: _note,
                        decoration: const InputDecoration(labelText: 'Note (optional)', border: OutlineInputBorder()),
                        maxLines: 2,
                        onSaved: (val) => _note = val ?? '',
                        onChanged: (val) => _note = val,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _submitTransaction,
                          child: _isSaving
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text(_editingId != null ? 'Update transaction' : 'Add transaction'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Transactions List
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                DropdownButton<String>(
                  value: _filter,
                  items: ['all', 'expense', 'income']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e.toUpperCase())))
                      .toList(),
                  onChanged: (val) => setState(() => _filter = val!),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator()))
            else if (visibleTransactions.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text('No transactions for this month.', style: TextStyle(color: Colors.grey)),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: visibleTransactions.length,
                itemBuilder: (context, index) {
                  final t = visibleTransactions[index];
                  final isIncome = t['type'] == 'income';
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isIncome ? Colors.green.shade100 : Colors.red.shade100,
                        child: Icon(
                          isIncome ? Icons.payments : Icons.shopping_bag,
                          color: isIncome ? Colors.green : Colors.red,
                        ),
                      ),
                      title: Text(t['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${t['category']} · ${t['date']}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${isIncome ? '+' : '-'}${_formatMoney(t['amount'])}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isIncome ? Colors.green : Colors.red,
                              fontSize: 16,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20, color: Colors.grey),
                            onPressed: () => _startEditing(t),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, size: 20, color: Colors.grey),
                            onPressed: () => _deleteTransaction(t['_id']),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    ),
  ],
),
),
);
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    final themeProvider = Provider.of<ThemeProvider?>(context);
    final isDark = themeProvider?.isDarkMode ?? true;

    return Card(
      elevation: 0,
      color: themeProvider?.surface ?? (isDark ? const Color(0xFF131B2E) : Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: themeProvider?.cardBorder ?? (isDark ? Colors.white10 : Colors.black12)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color),
            const Spacer(),
            Text(label, style: TextStyle(fontSize: 12, color: themeProvider?.textSecondary ?? Colors.grey)),
            Text(
              value,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
