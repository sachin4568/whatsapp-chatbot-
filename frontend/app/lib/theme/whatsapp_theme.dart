import 'package:flutter/material.dart';

class WhatsAppTheme {
  // WhatsApp Colors
  static const Color headerGreen = Color(0xFF075E54);
  static const Color darkTeal = Color(0xFF128C7E);
  static const Color primaryGreen = Color(0xFF00A884);
  static const Color accentGreen = Color(0xFF25D366);
  static const Color wallpaperBase = Color(0xFFEFEAE2);

  // Message Bubbles
  static const Color outgoingBubble = Color(0xFFD9FDD3);
  static const Color incomingBubble = Color(0xFFFFFFFF);
  static const Color messageText = Color(0xFF111B21);
  static const Color timestampText = Color(0xFF667781);
  static const Color blueCheck = Color(0xFF53BDEB);

  // Components
  static const Color dateSeparatorBg = Color(0xE6FFFFFF);
  static const Color dateSeparatorText = Color(0xFF54656F);
  static const Color composerBg = Color(0xFFF0F2F5);
  static const Color iconColor = Color(0xFF8696A0);

  static ThemeData get themeData {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: wallpaperBase,
      appBarTheme: const AppBarTheme(
        backgroundColor: headerGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen,
        primary: primaryGreen,
        surface: wallpaperBase,
      ),
    );
  }
}
