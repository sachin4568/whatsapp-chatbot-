import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/whatsapp_theme.dart';

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
    final hasOptions = message.options.isNotEmpty;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        constraints: const BoxConstraints(maxWidth: 340),
        decoration: BoxDecoration(
          color: isUser ? waOutgoing : Colors.white,
          borderRadius: BorderRadius.circular(9),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 9, 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      message.text,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.3,
                        color: Color(0xFF202C33),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${message.at.hour.toString().padLeft(2, '0')}:'
                    '${message.at.minute.toString().padLeft(2, '0')}'
                    '${isUser ? '  ✓✓' : ''}',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

            // WhatsApp-style template reply rows: text only, no option icons.
            if (hasOptions) ...[
              const Divider(height: 1, thickness: 0.6),
              ...message.options.map(
                (option) => InkWell(
                  onTap: () => onOption(option),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 15,
                    ),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Color(0xFFE9EDEF),
                          width: 0.6,
                        ),
                      ),
                    ),
                    child: Text(
                      option.label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF00A884),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}