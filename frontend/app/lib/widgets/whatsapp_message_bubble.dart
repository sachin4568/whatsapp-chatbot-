import 'package:flutter/material.dart';
import '../theme/whatsapp_theme.dart';

class WhatsAppMessageOption {
  const WhatsAppMessageOption({
    required this.id,
    required this.label,
  });

  final String id;
  final String label;
}

class WhatsAppMessageBubble extends StatelessWidget {
  const WhatsAppMessageBubble({
    super.key,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.options = const [],
    this.onOptionSelected,
  });

  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<WhatsAppMessageOption> options;
  final ValueChanged<WhatsAppMessageOption>? onOptionSelected;

  String _formatTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 600;

    // Responsive horizontal side margin (8-12px on phone, 10-16px on desktop)
    final sideMargin = isDesktop ? 14.0 : 10.0;

    // Maximum bubble width (~75-80% on phone, capped reasonably on desktop)
    final maxBubbleWidth = isDesktop
        ? (screenWidth * 0.65).clamp(320.0, 580.0)
        : screenWidth * 0.78;

    final hasOptions = !isUser && options.isNotEmpty;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          left: isUser ? 40.0 : sideMargin,
          right: isUser ? sideMargin : 40.0,
          top: 3.0,
          bottom: 3.0,
        ),
        constraints: BoxConstraints(maxWidth: maxBubbleWidth),
        decoration: BoxDecoration(
          color: isUser
              ? WhatsAppTheme.outgoingBubble
              : WhatsAppTheme.incomingBubble,
          borderRadius: BorderRadius.only(
            topLeft: isUser ? const Radius.circular(12) : const Radius.circular(2),
            topRight: isUser ? const Radius.circular(2) : const Radius.circular(12),
            bottomLeft: const Radius.circular(12),
            bottomRight: const Radius.circular(12),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: isUser ? const Radius.circular(12) : const Radius.circular(2),
            topRight: isUser ? const Radius.circular(2) : const Radius.circular(12),
            bottomLeft: const Radius.circular(12),
            bottomRight: const Radius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: hasOptions
                ? CrossAxisAlignment.stretch
                : (isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start),
            children: [
              // Message content and timestamp wrapped snugly
              Padding(
                padding: const EdgeInsets.fromLTRB(11, 8, 9, 5),
                child: Wrap(
                  alignment: isUser ? WrapAlignment.end : WrapAlignment.start,
                  crossAxisAlignment: WrapCrossAlignment.end,
                  spacing: 10,
                  runSpacing: 3,
                  children: [
                    Text(
                      text,
                      style: const TextStyle(
                        color: WhatsAppTheme.messageText,
                        fontSize: 15,
                        height: 1.35,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 1),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatTime(timestamp),
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: WhatsAppTheme.timestampText,
                            ),
                          ),
                          if (isUser) ...[
                            const SizedBox(width: 3),
                            const Icon(
                              Icons.done_all,
                              size: 15,
                              color: WhatsAppTheme.blueCheck,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Quick Reply Buttons inside incoming bot bubbles
              if (hasOptions) ...[
                const Divider(
                  height: 1,
                  thickness: 0.8,
                  color: Color(0xFFE9EDEF),
                ),
                ...options.map(
                  (option) => InkWell(
                    onTap: () {
                      if (onOptionSelected != null) {
                        onOptionSelected!(option);
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 11,
                      ),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Color(0xFFE9EDEF),
                            width: 0.8,
                          ),
                        ),
                      ),
                      child: Text(
                        option.label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: WhatsAppTheme.primaryGreen,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
