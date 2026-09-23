import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/chatbot_api.dart';
import '../widgets/message_bubble.dart';

class BusinessChatScreen extends StatefulWidget {
  const BusinessChatScreen({
    super.key,
    required this.organization,
    this.conversation,
    this.filter,
  });

  final Organization organization;
  final Conversation? conversation;
  final String? filter;

  @override
  State<BusinessChatScreen> createState() => _BusinessChatScreenState();
}

class _BusinessChatScreenState extends State<BusinessChatScreen> {
  final api = ChatbotApi();
  List<Conversation> conversationList = [];
  List<ChatMessage> messages = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      if (widget.conversation == null) {
        // Load list of conversations for the organization (optionally filtered)
        conversationList = await api.conversations(widget.organization.id, state: widget.filter);
      } else {
        // Load messages for a specific conversation
        final raw = await api.messages(widget.conversation!.id);
        messages = raw
            .map((x) => ChatMessage(
                  text: x['text'] as String,
                  sender: x['sender_type'] == 'USER' ? 'USER' : 'BOT',
                  at: DateTime.tryParse(x['created_at'] as String) ?? DateTime.now(),
                ))
            .toList();
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // If we are on the conversation list view
    if (widget.conversation == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Agent requests')),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : conversationList.isEmpty
                ? const Center(child: Text('No parents are waiting.'))
                : ListView.builder(
                    itemCount: conversationList.length,
                    itemBuilder: (context, index) {
                      final conv = conversationList[index];
                      return ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.person)),
                        title: Text(conv.sessionId.replaceAll('_', ' ')),
                        subtitle: Text(conv.state.replaceAll('_', ' ')),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () async {
                          // Navigate to the same screen but with a conversation selected
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BusinessChatScreen(
                                organization: widget.organization,
                                conversation: conv,
                              ),
                            ),
                          );
                          // Refresh when returning
                          _load();
                        },
                      );
                    },
                  ),
      );
    }

    // Conversation view
    final conv = widget.conversation!;
    final bool isWaiting = conv.state == 'WAITING_FOR_AGENT';
    final bool isActive = conv.state == 'INTERVENED';

    return Scaffold(
      appBar: AppBar(title: Text(conv.sessionId.replaceAll('_', ' '))),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: isActive ? const Color(0xffd9fdd3) : const Color(0xfffff3cd),
            padding: const EdgeInsets.all(10),
            child: Text(
              isActive
                  ? 'School representative has joined this conversation.'
                  : isWaiting
                      ? 'This parent requested school assistance.'
                      : 'Conversation attended.',
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: messages.length,
                    itemBuilder: (context, i) => MessageBubble(
                      message: messages[i],
                      onOption: (_) {},
                    ),
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: isWaiting
                  ? FilledButton.icon(
                      onPressed: () async {
                        await api.intervene(conv.id);
                        if (mounted) Navigator.pop(context);
                      },
                      icon: const Icon(Icons.support_agent),
                      label: const Text('Intervene'),
                    )
                  : isActive
                      ? FilledButton.tonalIcon(
                          onPressed: () async {
                            await api.leave(conv.id);
                            if (mounted) Navigator.pop(context);
                          },
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Leave and mark attended'),
                        )
                      : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}
