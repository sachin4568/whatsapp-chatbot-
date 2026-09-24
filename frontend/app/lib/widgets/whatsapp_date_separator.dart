import 'package:flutter/material.dart';
import '../theme/whatsapp_theme.dart';

class WhatsAppDateSeparator extends StatelessWidget {
  const WhatsAppDateSeparator({
    super.key,
    this.text = 'TODAY',
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: WhatsAppTheme.dateSeparatorBg,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 3,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Text(
          text.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: WhatsAppTheme.dateSeparatorText,
            letterSpacing: 0.6,
          ),
        ),
      ),
    );
  }
}
