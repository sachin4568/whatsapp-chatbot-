import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/chatbot_api.dart';
import '../theme/whatsapp_theme.dart';
import '../widgets/whatsapp_chat_background.dart';
import '../widgets/whatsapp_chat_header.dart';
import '../widgets/whatsapp_date_separator.dart';
import '../widgets/whatsapp_message_bubble.dart';

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
        conversationList = await api.conversations(
          widget.organization.id,
          state: widget.filter,
        );
      } else {
        final raw = await api.messages(widget.conversation!.id);
        messages = raw
            .map(
              (x) => ChatMessage(
                text: x['text'] as String,
                sender: x['sender_type'] == 'USER' ? 'USER' : 'BOT',
                at: DateTime.tryParse(x['created_at'] as String) ??
                    DateTime.now(),
              ),
            )
            .toList();
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.conversation == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: WhatsAppTheme.headerGreen,
          foregroundColor: Colors.white,
          title: const Text('Agent requests'),
        ),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : conversationList.isEmpty
                ? const Center(child: Text('No parents are waiting.'))
                : ListView.builder(
                    itemCount: conversationList.length,
                    itemBuilder: (context, index) {
                      final conv = conversationList[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: WhatsAppTheme.darkTeal,
                          child: const Icon(
                            Icons.person,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(conv.sessionId.replaceAll('_', ' ')),
                        subtitle: Text(conv.state.replaceAll('_', ' ')),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BusinessChatScreen(
                                organization: widget.organization,
                                conversation: conv,
                              ),
                            ),
                          );
                          _load();
                        },
                      );
                    },
                  ),
      );
    }

    final conv = widget.conversation!;
    final bool isWaiting = conv.state == 'WAITING_FOR_AGENT';
    final bool isActive = conv.state == 'INTERVENED';

    return Scaffold(
      appBar: WhatsAppChatHeader(
        organizationName: conv.sessionId.replaceAll('_', ' '),
        statusText: isActive
            ? 'agent connected'
            : isWaiting
                ? 'waiting for agent'
                : 'attended',
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: isActive ? const Color(0xFFD9FDD3) : const Color(0xFFFFF3CD),
            padding: const EdgeInsets.all(10),
            child: Text(
              isActive
                  ? 'School representative has joined this conversation.'
                  : isWaiting
                      ? 'This parent requested school assistance.'
                      : 'Conversation attended.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF111B21),
              ),
            ),
          ),
          Expanded(
            child: WhatsAppChatBackground(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.only(top: 8, bottom: 8),
                      children: [
                        const WhatsAppDateSeparator(text: 'TODAY'),
                        ...messages.map(
                          (m) => WhatsAppMessageBubble(
                            text: m.text,
                            isUser: m.sender == 'USER',
                            timestamp: m.at,
                          ),
                        ),
                      ],
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
                      style: FilledButton.styleFrom(
                        backgroundColor: WhatsAppTheme.primaryGreen,
                        minimumSize: const Size.fromHeight(46),
                      ),
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
