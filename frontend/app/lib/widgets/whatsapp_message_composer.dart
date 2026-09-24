import 'package:flutter/material.dart';
import '../theme/whatsapp_theme.dart';

class WhatsAppMessageComposer extends StatefulWidget {
  const WhatsAppMessageComposer({
    super.key,
    required this.controller,
    required this.onSend,
    this.sending = false,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSend;
  final bool sending;

  @override
  State<WhatsAppMessageComposer> createState() =>
      _WhatsAppMessageComposerState();
}

class _WhatsAppMessageComposerState extends State<WhatsAppMessageComposer> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _hasText = widget.controller.text.trim().isNotEmpty;
    widget.controller.addListener(_handleTextChange);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleTextChange);
    super.dispose();
  }

  void _handleTextChange() {
    final hasContent = widget.controller.text.trim().isNotEmpty;
    if (hasContent != _hasText) {
      setState(() {
        _hasText = hasContent;
      });
    }
  }

  void _submit() {
    final text = widget.controller.text.trim();
    if (text.isNotEmpty && !widget.sending) {
      widget.onSend(text);
    }
  }

  void _showAttachmentSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAttachmentOption(
                  icon: Icons.insert_drive_file_rounded,
                  color: const Color(0xFF7F66FF),
                  label: 'Document',
                ),
                _buildAttachmentOption(
                  icon: Icons.camera_alt_rounded,
                  color: const Color(0xFFD3396D),
                  label: 'Camera',
                ),
                _buildAttachmentOption(
                  icon: Icons.image_rounded,
                  color: const Color(0xFFAC44CF),
                  label: 'Gallery',
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAttachmentOption(
                  icon: Icons.headphones_rounded,
                  color: const Color(0xFFF9653B),
                  label: 'Audio',
                ),
                _buildAttachmentOption(
                  icon: Icons.location_on_rounded,
                  color: const Color(0xFF0F9D58),
                  label: 'Location',
                ),
                _buildAttachmentOption(
                  icon: Icons.person_rounded,
                  color: const Color(0xFF0088CC),
                  label: 'Contact',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required Color color,
    required String label,
  }) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$label attachment (prototype)'),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: color,
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF54656F),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        color: Colors.transparent,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Rounded input box container
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x15000000),
                      blurRadius: 3,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Attachment Paperclip button at the very left inside container
                    IconButton(
                      icon: const Icon(
                        Icons.attach_file_rounded,
                        color: WhatsAppTheme.iconColor,
                        size: 24,
                      ),
                      onPressed: _showAttachmentSheet,
                      tooltip: 'Attach',
                    ),

                    // Emoji button next to attachment icon
                    IconButton(
                      icon: const Icon(
                        Icons.sentiment_satisfied_alt_rounded,
                        color: WhatsAppTheme.iconColor,
                        size: 24,
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Emoji keyboard (prototype)'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      tooltip: 'Emoji',
                    ),

                    // Text Field
                    Expanded(
                      child: TextField(
                        controller: widget.controller,
                        minLines: 1,
                        maxLines: 5,
                        textCapitalization: TextCapitalization.sentences,
                        style: const TextStyle(
                          fontSize: 16,
                          color: WhatsAppTheme.messageText,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Type a message',
                          hintStyle: TextStyle(
                            color: WhatsAppTheme.iconColor,
                            fontSize: 16,
                          ),
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 10,
                          ),
                        ),
                        onSubmitted: (_) => _submit(),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 6),

            // Microphone or Send Button on the Right Side
            Material(
              color: WhatsAppTheme.primaryGreen,
              shape: const CircleBorder(),
              elevation: 1.5,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () {
                  if (_hasText) {
                    _submit();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Voice message (prototype)'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
                child: SizedBox(
                  width: 46,
                  height: 46,
                  child: Center(
                    child: widget.sending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            _hasText ? Icons.send_rounded : Icons.mic_rounded,
                            color: Colors.white,
                            size: _hasText ? 20 : 23,
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
