import 'package:flutter/material.dart';

class WhatsAppTypingIndicator extends StatefulWidget {
  const WhatsAppTypingIndicator({super.key});

  @override
  State<WhatsAppTypingIndicator> createState() =>
      _WhatsAppTypingIndicatorState();
}

class _WhatsAppTypingIndicatorState extends State<WhatsAppTypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final sideMargin = screenWidth > 600 ? 16.0 : 10.0;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          left: sideMargin,
          top: 4,
          bottom: 4,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(2),
            topRight: Radius.circular(12),
            bottomLeft: Radius.circular(12),
            bottomRight: Radius.circular(12),
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            return AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                // Staggered sine wave bounce offset per dot
                final double phase = (_controller.value - (index * 0.18)) % 1.0;
                final double offsetY =
                    -3.5 * (1.0 - (phase - 0.5).abs() * 2).clamp(0.0, 1.0);

                return Transform.translate(
                  offset: Offset(0, offsetY),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2.5),
                    child: Container(
                      width: 6.5,
                      height: 6.5,
                      decoration: const BoxDecoration(
                        color: Color(0xFF667781), // Neutral WhatsApp grey
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                );
              },
            );
          }),
        ),
      ),
    );
  }
}
