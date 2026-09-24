import 'package:flutter/material.dart';
import '../theme/whatsapp_theme.dart';

class WhatsAppChatBackground extends StatelessWidget {
  const WhatsAppChatBackground({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: WhatsAppTheme.wallpaperBase,
        image: DecorationImage(
          image: AssetImage('assets/images/whatsapp_background.png'),
          repeat: ImageRepeat.repeat,
          opacity: 0.35,
        ),
      ),
      child: child,
    );
  }
}
