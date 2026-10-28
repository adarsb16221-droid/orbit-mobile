import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/journal_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/hawk_header.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final TextEditingController _textController = TextEditingController();
  DateTime _currentDate = DateTime.now();
  Timer? _debounce;
  String _saveStatus = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadJournals();
    });
  }

  void _loadJournals() async {
    final provider = Provider.of<JournalProvider>(context, listen: false);
    await provider.fetchAllJournals();
    _updateTextForCurrentDate();
  }

  void _updateTextForCurrentDate() {
    final provider = Provider.of<JournalProvider>(context, listen: false);
    final dateStr = DateFormat('yyyy-MM-dd').format(_currentDate);
    final text = provider.entries[dateStr] ?? '';
    if (_textController.text != text) {
      _textController.text = text;
    }
  }

  void _changeDate(int offsetDays) {
    setState(() {
      _currentDate = _currentDate.add(Duration(days: offsetDays));
      _saveStatus = '';
    });
    _updateTextForCurrentDate();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _currentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF8083FF),
              surface: Color(0xFF131B2E),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _currentDate) {
      setState(() {
        _currentDate = picked;
        _saveStatus = '';
      });
      _updateTextForCurrentDate();
    }
  }

  void _onTextChanged(String content) {
    setState(() {
      _saveStatus = 'Saving soon...';
    });

    if (_debounce?.isActive ?? false) _debounce!.cancel();

    final dateStr = DateFormat('yyyy-MM-dd').format(_currentDate);

    _debounce = Timer(const Duration(milliseconds: 1000), () async {
      setState(() => _saveStatus = 'Saving...');

      final provider = Provider.of<JournalProvider>(context, listen: false);
      final success = await provider.saveJournal(dateStr, content);

      if (mounted) {
        setState(() {
          _saveStatus = success ? 'Saved' : 'Error saving';
        });

        if (success) {
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted && _saveStatus == 'Saved') {
              setState(() => _saveStatus = '');
            }
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _textController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider?>(context);
    final isDark = themeProvider?.isDarkMode ?? true;
    final dateStr = DateFormat('yyyy-MM-dd').format(_currentDate);
    final isToday = dateStr == DateFormat('yyyy-MM-dd').format(DateTime.now());
    final displayDate = isToday ? 'Today' : DateFormat('EEE, MMM d').format(_currentDate);

    return Scaffold(
      backgroundColor: themeProvider?.bg ?? (isDark ? const Color(0xFF0B1326) : const Color(0xFFF8F9FF)),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Header (Journal & Plan)
            const HawkHeader(
              title: 'Journal',
              subtitle: 'Journal & Plan',
            ),

            // 2. Controls Row (Previous Page, Date Picker, Next Page)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Prev Page Button
                  IconButton(
                    onPressed: () => _changeDate(-1),
                    icon: Icon(
                      Icons.chevron_left,
                      color: themeProvider?.textPrimary ?? (isDark ? const Color(0xFFDAE2FD) : const Color(0xFF0D1C2E)),
                      size: 28,
                    ),
                    tooltip: 'Previous Page',
                  ),

                  // Center: Date Pill + Status
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: themeProvider?.surfaceContainer ?? (isDark ? const Color(0xFF131B2E) : const Color(0xFFEFF4FF)),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: themeProvider?.cardBorder ?? (isDark ? Colors.white10 : Colors.black12)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.calendar_today, size: 14, color: Color(0xFF8083FF)),
                              const SizedBox(width: 6),
                              Text(
                                dateStr,
                                style: TextStyle(
                                  color: themeProvider?.textPrimary ?? (isDark ? const Color(0xFFDAE2FD) : const Color(0xFF0D1C2E)),
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        height: 14,
                        child: _saveStatus.isNotEmpty
                            ? Text(
                                _saveStatus,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: _saveStatus == 'Error saving' ? Colors.redAccent : const Color(0xFF4EDEA3),
                                  fontWeight: FontWeight.w500,
                                ),
                              )
                            : null,
                      ),
                    ],
                  ),

                  // Next Page Button
                  IconButton(
                    onPressed: () => _changeDate(1),
                    icon: Icon(
                      Icons.chevron_right,
                      color: themeProvider?.textPrimary ?? (isDark ? const Color(0xFFDAE2FD) : const Color(0xFF0D1C2E)),
                      size: 28,
                    ),
                    tooltip: 'Next Page',
                  ),
                ],
              ),
            ),

            // 3. Ruled Notebook Book Container (matching PageContent)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: themeProvider?.surface ?? (isDark ? const Color(0xFF131B2E) : Colors.white),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: themeProvider?.cardBorder ?? (isDark ? Colors.white10 : Colors.black12)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Book Spine Shadow
                      Container(
                        width: 8,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
                          color: isDark ? const Color(0xFF1E283F) : const Color(0xFFE2E8F0),
                        ),
                      ),

                      // Journal Page Content
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Page Top Bar
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.menu_book, color: Color(0xFF8083FF), size: 18),
                                      const SizedBox(width: 8),
                                      Text(
                                        dateStr,
                                        style: _outfit(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF8083FF),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    displayDate,
                                    style: _outfit(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: themeProvider?.textPrimary ?? (isDark ? const Color(0xFFDAE2FD) : const Color(0xFF0D1C2E)),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Divider(color: themeProvider?.divider ?? (isDark ? Colors.white10 : Colors.black12), height: 1),

                              // Ruled Notebook Lines & Text Field
                              Expanded(
                                child: Stack(
                                  children: [
                                    // Ruled Horizontal Lines Background
                                    Positioned.fill(
                                      child: CustomPaint(
                                        painter: _RuledLinesPainter(
                                          lineColor: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.08),
                                          lineHeight: 32.0,
                                        ),
                                      ),
                                    ),

                                    // Multiline Text Editor
                                    TextField(
                                      controller: _textController,
                                      maxLines: null,
                                      expands: true,
                                      onChanged: _onTextChanged,
                                      style: TextStyle(
                                        fontSize: 15,
                                        height: 32.0 / 15.0, // Matches exactly 32px line height!
                                        color: themeProvider?.textPrimary ?? (isDark ? const Color(0xFFDAE2FD) : const Color(0xFF0D1C2E)),
                                      ),
                                      cursorColor: const Color(0xFF8083FF),
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        hintText: 'Write your thoughts here...',
                                        hintStyle: TextStyle(
                                          color: themeProvider?.textSecondary ?? (isDark ? const Color(0xFF908FA0) : const Color(0xFF64748B)),
                                          fontSize: 15,
                                          height: 32.0 / 15.0,
                                        ),
                                        contentPadding: const EdgeInsets.only(top: 4),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RuledLinesPainter extends CustomPainter {
  final Color lineColor;
  final double lineHeight;

  _RuledLinesPainter({required this.lineColor, this.lineHeight = 32.0});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.0;

    for (double y = lineHeight; y < size.height; y += lineHeight) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RuledLinesPainter oldDelegate) =>
      oldDelegate.lineColor != lineColor || oldDelegate.lineHeight != lineHeight;
}
