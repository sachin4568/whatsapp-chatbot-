import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/chatbot_api.dart';
import 'chat_screen.dart';

class OrganizationSearchScreen extends StatefulWidget {
  const OrganizationSearchScreen({super.key});

  @override
  State<OrganizationSearchScreen> createState() => _OrganizationSearchScreenState();
}

class _OrganizationSearchScreenState extends State<OrganizationSearchScreen> {
  final api = ChatbotApi();
  List<Organization> items = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load([String query = '']) async {
    setState(() => loading = true);
    try {
      items = await api.organizations(query);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New chat')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: load,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search organizations',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (_, i) {
                      final o = items[i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Color(int.parse('ff${o.color.substring(1)}', radix: 16)),
                          child: Text(o.name[0], style: const TextStyle(color: Colors.white)),
                        ),
                        title: Row(
                          children: [
                            Flexible(child: Text(o.name)),
                            if (o.verified)
                              const Padding(
                                padding: EdgeInsets.only(left: 4),
                                child: Icon(Icons.verified, color: Colors.teal, size: 18),
                              ),
                          ],
                        ),
                        subtitle: Text(o.description),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ChatScreen(organization: o)),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

