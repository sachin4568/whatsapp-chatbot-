import 'package:flutter/foundation.dart';

class ApiService {
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: kDebugMode
        ? 'http://127.0.0.1:8000'
        : 'https://whatsapp-chatbot-tvds.onrender.com',
  );
}
