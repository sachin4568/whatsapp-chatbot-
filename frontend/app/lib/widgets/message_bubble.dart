import 'package:flutter/material.dart';
import '../models/models.dart';
import 'whatsapp_message_bubble.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.onOption,
  });

  final ChatMessage message;
  final ValueChanged<QuickOption> onOption;

  @override
  Widget build(BuildContext context) {
    final isUser = message.sender == 'USER';

    return WhatsAppMessageBubble(
      text: message.text,
      isUser: isUser,
      timestamp: message.at,
      options: message.options
          .map((opt) => WhatsAppMessageOption(id: opt.id, label: opt.label))
          .toList(),
      onOptionSelected: (opt) {
        onOption(QuickOption(opt.id, opt.label));
      },
    );
  }
}