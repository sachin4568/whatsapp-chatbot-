import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/models.dart';
import 'api_service.dart';

class ChatbotApi {
  static const String baseUrl = ApiService.baseUrl;

  Future<List<Organization>> organizations([String query = '']) async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/api/chat/organizations'
        '?q=${Uri.encodeQueryComponent(query)}',
      ),
    );

    if (response.statusCode >= 400) {
      throw Exception('Unable to load organizations');
    }

    return (jsonDecode(response.body) as List)
        .map((item) => Organization.fromJson(item))
        .toList();
  }

  Future<Map<String, dynamic>> chat(
    String organizationId,
    String sessionId,
    String text,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/chat'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'organization_id': organizationId,
        'session_id': sessionId,
        'message': text,
      }),
    );

    if (response.statusCode >= 400) {
      throw Exception('Unable to send message');
    }

    return jsonDecode(response.body);
  }

  Future<List<Conversation>> conversations(
    String organizationId, {
    String? state,
  }) async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/api/agent/conversations'
        '?organization_id=$organizationId'
        '${state == null ? '' : '&state=$state'}',
      ),
    );

    return (jsonDecode(response.body) as List)
        .map((item) => Conversation.fromJson(item))
        .toList();
  }

  Future<int> requests(String organizationId) async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/api/agent/requests?organization_id=$organizationId',
      ),
    );

    return jsonDecode(response.body)['count'];
  }

  Future<void> intervene(String conversationId) async {
    await http.post(
      Uri.parse(
        '$baseUrl/api/agent/conversations/$conversationId/intervene',
      ),
    );
  }

  Future<void> leave(String conversationId) async {
    await http.post(
      Uri.parse(
        '$baseUrl/api/agent/conversations/$conversationId/leave',
      ),
    );
  }

  Future<List<Map<String, dynamic>>> messages(String conversationId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/conversations/$conversationId/messages'),
    );

    return (jsonDecode(response.body) as List).cast<Map<String, dynamic>>();
  }

  Future<void> updateProfile(
    String organizationId,
    String name,
    bool verified,
  ) async {
    await http.put(
      Uri.parse('$baseUrl/api/business/organizations/$organizationId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'verified': verified,
      }),
    );
  }

  Future<Organization> createBusiness(String name) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/business/organizations'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'verified': false,
      }),
    );

    if (response.statusCode >= 400) {
      throw Exception('Unable to create business');
    }

    return Organization.fromJson(jsonDecode(response.body));
  }

  Future<void> resetPrototype() async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/prototype/reset'),
    );

    if (response.statusCode >= 400) {
      throw Exception('Unable to reset prototype');
    }
  }
}
