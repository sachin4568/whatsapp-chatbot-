class Organization {
  Organization({required this.id, required this.name, required this.description, required this.verified, required this.color});
  final String id, name, description, color; final bool verified;
  factory Organization.fromJson(Map<String, dynamic> json) => Organization(id: json['id'], name: json['name'], description: json['description'], verified: json['verified'] ?? false, color: json['profile_color'] ?? '#128C7E');
}
class ChatMessage {
  ChatMessage({required this.text, required this.sender, required this.at, this.options = const []});
  final String text, sender; final DateTime at; final List<QuickOption> options;
}
class QuickOption { QuickOption(this.id, this.label); final String id, label; factory QuickOption.fromJson(Map<String,dynamic> j) => QuickOption(j['id'], j['label']); }
class Conversation { Conversation({required this.id, required this.sessionId, required this.state, required this.updatedAt}); final String id, sessionId, state, updatedAt; factory Conversation.fromJson(Map<String,dynamic> j) => Conversation(id:j['id'],sessionId:j['session_id'],state:j['state'],updatedAt:j['updated_at']); }
