import 'package:flutter/material.dart';
import '../theme/whatsapp_theme.dart';

class WhatsAppChatHeader extends StatelessWidget implements PreferredSizeWidget {
  const WhatsAppChatHeader({
    super.key,
    required this.organizationName,
    this.statusText = 'online',
    this.profileImageUrl = '',
    this.verified = false,
    this.onBackPressed,
    this.onSearchPressed,
    this.onMenuOptionSelected,
  });

  final String organizationName;
  final String statusText;
  final String profileImageUrl;
  final bool verified;
  final VoidCallback? onBackPressed;
  final VoidCallback? onSearchPressed;
  final ValueChanged<String>? onMenuOptionSelected;

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: WhatsAppTheme.headerGreen,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              // Back Button
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
                tooltip: 'Back',
              ),

              // Profile Avatar
              CircleAvatar(
                radius: 19,
                backgroundColor: WhatsAppTheme.darkTeal,
                backgroundImage: profileImageUrl.isNotEmpty
                    ? NetworkImage(profileImageUrl)
                    : null,
                child: profileImageUrl.isEmpty
                    ? Text(
                        organizationName.isNotEmpty
                            ? organizationName.substring(0, 1).toUpperCase()
                            : 'S',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),

              const SizedBox(width: 10),

              // Organization Name + Status Subtitle
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            organizationName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16.5,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                        if (verified) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.verified,
                            color: Color(0xFF25D366),
                            size: 16,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 1),
                    Text(
                      statusText,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),

              // Action Icons: Search & Three-dot menu
              IconButton(
                icon: const Icon(Icons.search, color: Colors.white),
                onPressed: onSearchPressed ??
                    () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Search in conversation (prototype)'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                tooltip: 'Search',
              ),

              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                tooltip: 'More options',
                onSelected: (value) {
                  if (onMenuOptionSelected != null) {
                    onMenuOptionSelected!(value);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$value selected'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'Contact info',
                    child: Text('Contact info'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'Search',
                    child: Text('Search'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'Mute notifications',
                    child: Text('Mute notifications'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'Clear chat',
                    child: Text('Clear chat'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
