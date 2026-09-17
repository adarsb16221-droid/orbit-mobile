import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/link_provider.dart';

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

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<LinkProvider>(context);

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null) {
      return Center(child: Text(provider.error!));
    }

    final links = provider.links;

    return RefreshIndicator(
      onRefresh: provider.fetchLinks,
      child: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: links.length,
        itemBuilder: (context, index) {
          final link = links[index];
          return Card(
            child: ListTile(
              leading: const Icon(Icons.link),
              title: Text(link.name),
              subtitle: Text(link.url, style: const TextStyle(color: Colors.blue)),
              onTap: () => _launchUrl(link.url),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  provider.deleteLink(link.id);
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
