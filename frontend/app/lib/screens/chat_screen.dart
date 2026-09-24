import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/chatbot_api.dart';
import '../widgets/whatsapp_chat_background.dart';
import '../widgets/whatsapp_chat_header.dart';
import '../widgets/whatsapp_date_separator.dart';
import '../widgets/whatsapp_message_bubble.dart';
import '../widgets/whatsapp_message_composer.dart';
import '../widgets/whatsapp_typing_indicator.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.organization,
  });

  final Organization organization;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final api = ChatbotApi();
  final input = TextEditingController();
  final scrollController = ScrollController();
  final messages = <ChatMessage>[];
  bool sending = false;
  late final String sessionId;

  @override
  void initState() {
    super.initState();
    sessionId = 'parent_demo_001';
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => send('Hello', showUser: false),
    );
  }

  Future<void> send(String text, {bool showUser = true}) async {
    if (text.trim().isEmpty || sending) return;

    setState(() {
      sending = true;
      if (showUser) {
        messages.add(
          ChatMessage(
            text: text,
            sender: 'USER',
            at: DateTime.now(),
          ),
        );
      }
    });

    _scrollToBottom();
    input.clear();

    try {
      final r = await api.chat(widget.organization.id, sessionId, text);
      setState(() {
        messages.add(
          ChatMessage(
            text: r['message'],
            sender: 'BOT',
            at: DateTime.now(),
            options: (r['options'] as List)
                .map((v) => QuickOption.fromJson(v))
                .toList(),
          ),
        );
      });
      _scrollToBottom();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not reach the local chatbot service.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) return;
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    input.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: WhatsAppChatHeader(
        organizationName: widget.organization.name,
        verified: widget.organization.verified,
        statusText: 'online',
      ),
      body: Column(
        children: [
          Expanded(
            child: WhatsAppChatBackground(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.only(top: 8, bottom: 8),
                children: [
                  const WhatsAppDateSeparator(text: 'TODAY'),
                  ...messages.map(
                    (message) => WhatsAppMessageBubble(
                      text: message.text,
                      isUser: message.sender == 'USER',
                      timestamp: message.at,
                      options: message.options
                          .map(
                            (opt) => WhatsAppMessageOption(
                              id: opt.id,
                              label: opt.label,
                            ),
                          )
                          .toList(),
                      onOptionSelected: (opt) => send(opt.label),
                    ),
                  ),
                  if (sending) const WhatsAppTypingIndicator(),
                ],
              ),
            ),
          ),
          WhatsAppMessageComposer(
            controller: input,
            onSend: (text) => send(text),
            sending: sending,
          ),
        ],
      ),
    );
  }
}
