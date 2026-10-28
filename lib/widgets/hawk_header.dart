import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

/// Universal header matching the website Header.jsx and journal_screen / home_screen.
class HawkHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final bool showThemeToggle;
  final bool showMenu;
  final bool? showBack;
  final VoidCallback? onBack;
  final VoidCallback? onMenu;

  const HawkHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.showThemeToggle = true,
    this.showMenu = false,
    this.showBack,
    this.onBack,
    this.onMenu,
  });

  TextStyle _outfit({
    required double fontSize,
    required FontWeight fontWeight,
    required Color color,
    double? letterSpacing,
  }) {
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

    final titleColor = themeProvider?.primary ?? (isDark ? const Color(0xFF8083FF) : const Color(0xFF4648D4));
    final subtitleColor = themeProvider?.textSecondary ?? (isDark ? const Color(0xFF908FA0) : const Color(0xFF64748B));
    final btnBg = themeProvider?.circleBtnBg ?? (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05));
    final btnBorder = themeProvider?.circleBtnBorder ?? (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1));
    final iconColor = isDark ? const Color(0xFFC0C1FF) : const Color(0xFF4648D4);
    final dividerColor = themeProvider?.divider ?? (isDark ? Colors.white10 : Colors.black12);

    final canGoBack = showBack ?? (Navigator.canPop(context) && !showMenu);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left: [Back button] + Title & Subtitle
              Expanded(
                child: Row(
                  children: [
                    if (canGoBack) ...[
                      Container(
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: btnBg,
                          border: Border.all(color: btnBorder),
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.arrow_back,
                            size: 18,
                            color: isDark ? const Color(0xFFDAE2FD) : const Color(0xFF0D1C2E),
                          ),
                          tooltip: 'Back',
                          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                          padding: EdgeInsets.zero,
                          onPressed: onBack ?? () => Navigator.maybePop(context),
                        ),
                      ),
                    ],
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            overflow: TextOverflow.ellipsis,
                            style: _outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: titleColor,
                            ),
                          ),
                          if (subtitle != null && subtitle!.isNotEmpty) ...[
                            const SizedBox(height: 1),
                            Text(
                              subtitle!,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: subtitleColor,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Right: Action buttons + Global Theme Toggler + Menu
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...?actions,
                  if (showThemeToggle) ...[
                    if (actions != null && actions!.isNotEmpty) const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: btnBg,
                        border: Border.all(color: btnBorder),
                      ),
                      child: IconButton(
                        icon: Icon(
                          isDark ? Icons.light_mode : Icons.dark_mode,
                          size: 18,
                          color: iconColor,
                        ),
                        tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                        padding: EdgeInsets.zero,
                        onPressed: () => themeProvider?.toggleTheme(),
                      ),
                    ),
                  ],
                  if (showMenu) ...[
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: btnBg,
                        border: Border.all(color: btnBorder),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.menu,
                          size: 18,
                          color: isDark ? Colors.white70 : const Color(0xFF0D1C2E),
                        ),
                        tooltip: 'Menu',
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                        padding: EdgeInsets.zero,
                        onPressed: onMenu ?? () => Scaffold.maybeOf(context)?.openDrawer(),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        Divider(color: dividerColor, height: 1),
      ],
    );
  }
}
