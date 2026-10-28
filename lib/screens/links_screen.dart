import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/link.dart';
import '../providers/link_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/hawk_header.dart';

class LinksScreen extends StatefulWidget {
  const LinksScreen({super.key});

  @override
  State<LinksScreen> createState() => _LinksScreenState();
}

class _LinksScreenState extends State<LinksScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LinkProvider>(context, listen: false).fetchLinks();
    });
  }

  Future<void> _launchUrl(String urlString) async {
    final url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch $urlString')),
      );
    }
  }

  void _showAddLinkDialog(BuildContext context) {
    final nameController = TextEditingController();
    final urlController = TextEditingController();
    final themeProvider = Provider.of<ThemeProvider?>(context, listen: false);
    final isDark = themeProvider?.isDarkMode ?? true;
    final surface = themeProvider?.surface ?? (isDark ? const Color(0xFF131B2E) : Colors.white);
    final textPrimary = themeProvider?.textPrimary ?? (isDark ? const Color(0xFFDAE2FD) : Colors.black87);
    final textSecondary = themeProvider?.textSecondary ?? (isDark ? const Color(0xFF908FA0) : Colors.grey);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: surface,
        title: Text('Add New Link', style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: TextStyle(color: textPrimary),
              decoration: InputDecoration(
                labelText: 'Name',
                labelStyle: TextStyle(color: textSecondary),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlController,
              style: TextStyle(color: textPrimary),
              decoration: InputDecoration(
                labelText: 'URL (e.g. https://example.com)',
                labelStyle: TextStyle(color: textSecondary),
              ),
              keyboardType: TextInputType.url,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              var url = urlController.text.trim();
              if (name.isNotEmpty && url.isNotEmpty) {
                if (!url.startsWith('http://') && !url.startsWith('https://')) {
                  url = 'https://$url';
                }
                Provider.of<LinkProvider>(context, listen: false).addLink(Link(id: '', name: name, url: url));
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<LinkProvider>(context);
    final themeProvider = Provider.of<ThemeProvider?>(context);
    final isDark = themeProvider?.isDarkMode ?? true;

    final bg = themeProvider?.bg ?? (isDark ? const Color(0xFF0B1326) : const Color(0xFFF8F9FF));
    final surface = themeProvider?.surface ?? (isDark ? const Color(0xFF131B2E) : Colors.white);
    final textPrimary = themeProvider?.textPrimary ?? (isDark ? const Color(0xFFDAE2FD) : Colors.black87);
    final textSecondary = themeProvider?.textSecondary ?? (isDark ? const Color(0xFF908FA0) : Colors.grey);

    if (provider.isLoading && provider.links.isEmpty) {
      return Scaffold(
        backgroundColor: bg,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (provider.error != null && provider.links.isEmpty) {
      return Scaffold(
        backgroundColor: bg,
        body: Center(child: Text(provider.error!, style: TextStyle(color: textPrimary))),
      );
    }

    final links = provider.links;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. HawkHeader
            HawkHeader(
              title: 'Links',
              subtitle: 'Saved Bookmarks & Resources',
              actions: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: themeProvider?.circleBtnBg ?? (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
                    border: Border.all(color: themeProvider?.circleBtnBorder ?? (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1))),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.add, size: 20, color: isDark ? const Color(0xFFC0C1FF) : const Color(0xFF4648D4)),
                    tooltip: 'Add Link',
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    padding: EdgeInsets.zero,
                    onPressed: () => _showAddLinkDialog(context),
                  ),
                ),
              ],
            ),

            // 2. Links Grid
            Expanded(
              child: RefreshIndicator(
                onRefresh: provider.fetchLinks,
                color: const Color(0xFF8083FF),
                backgroundColor: surface,
                child: links.isEmpty
                    ? Center(
                        child: Text(
                          'No saved links yet. Tap + to add one!',
                          style: TextStyle(color: textSecondary),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 1.2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: links.length,
                        itemBuilder: (context, index) {
                          final link = links[index];
                          return InkWell(
                            onTap: () => _launchUrl(link.url),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              decoration: BoxDecoration(
                                color: surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: themeProvider?.cardBorder ?? (isDark ? Colors.white10 : Colors.black12),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(16.0),
                              child: Stack(
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF4648D4).withValues(alpha: isDark ? 0.2 : 0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Icon(Icons.public, color: Color(0xFF8083FF), size: 26),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        link.name,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: textPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        link.url.replaceFirst('https://', '').replaceFirst('http://', ''),
                                        style: TextStyle(fontSize: 12, color: textSecondary),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                  Positioned(
                                    top: -8,
                                    right: -8,
                                    child: IconButton(
                                      icon: Icon(Icons.close, size: 16, color: textSecondary),
                                      onPressed: () => provider.deleteLink(link.id),
                                    ),
                                  ),
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
