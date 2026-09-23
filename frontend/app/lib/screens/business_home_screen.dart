import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/chatbot_api.dart';
import 'business_setup_screen.dart';
import 'business_chat_screen.dart';

class BusinessHomeScreen extends StatefulWidget {
  const BusinessHomeScreen({super.key, required this.organization});
  final Organization organization;

  @override
  State<BusinessHomeScreen> createState() => _BusinessHomeScreenState();
}

class _BusinessHomeScreenState extends State<BusinessHomeScreen> {
  final api = ChatbotApi();
  int waiting = 0;
  List<Conversation> conversations = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);
    try {
      waiting = await api.requests(widget.organization.id);
      conversations = await api.conversations(widget.organization.id);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.organization.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BusinessSetupScreen(
                    organization: widget.organization,
                  ),
                ),
              );
              load();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: load,
        child: ListView(
          children: [
            ListTile(
              leading: const Icon(Icons.support_agent),
              title: Text(waiting == 0 ? 'Agent Requests' : 'Agent Requests ($waiting)'),
              subtitle: const Text('People waiting for human assistance'),
              trailing: waiting > 0 ? Badge(label: Text('$waiting')) : null,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BusinessChatScreen(
                    organization: widget.organization,
                    filter: 'WAITING_FOR_AGENT',
                  ),
                ),
              ).then((_) => load()),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Conversations', style: Theme.of(context).textTheme.titleMedium),
            ),
            if (loading)
              const Center(child: Padding(padding: EdgeInsets.all(30), child: CircularProgressIndicator()))
            else if (conversations.isEmpty)
              const Padding(padding: EdgeInsets.all(24), child: Text('No conversations yet. Start one in User Mode.'))
            else
              ...conversations.map(
                (c) => ListTile(
                  leading: CircleAvatar(child: Text(c.sessionId[0].toUpperCase())),
                  title: Text(c.sessionId),
                  subtitle: Text(c.state.replaceAll('_', ' ')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BusinessChatScreen(
                        organization: widget.organization,
                        conversation: c,
                      ),
                    ),
                  ).then((_) => load()),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
