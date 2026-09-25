import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'theme/whatsapp_theme.dart';
import 'widgets/whatsapp_chat_background.dart';
import 'widgets/whatsapp_chat_header.dart';
import 'widgets/whatsapp_date_separator.dart';
import 'widgets/whatsapp_message_bubble.dart';
import 'widgets/whatsapp_message_composer.dart';
import 'widgets/whatsapp_typing_indicator.dart';

void main() {
  runApp(const WhatsAppSchoolPrototype());
}

class WhatsAppSchoolPrototype extends StatelessWidget {
  const WhatsAppSchoolPrototype({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'School WhatsApp Prototype',
      theme: WhatsAppTheme.themeData,
      home: const ModeScreen(),
    );
  }
}

class Api {
  static const baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: kDebugMode
        ? 'http://127.0.0.1:8000'
        : 'https://whatsapp-chatbot-tvds.onrender.com',
  );

  static const _timeout = Duration(seconds: 12);
  static Future<List<Organization>> organizations() async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/api/chat/organizations'),
        )
        .timeout(_timeout);

    return (jsonDecode(response.body) as List)
        .map((item) => Organization.fromJson(item))
        .toList();
  }

  static Future<UserProfile> createUser({
    required String name,
    required String contact,
    required String email,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/profiles/users'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'name': name,
            'contact': contact,
            'email': email,
          }),
        )
        .timeout(_timeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Unable to create user profile (${response.statusCode})');
    }

    return UserProfile.fromJson(jsonDecode(response.body));
  }

  static Future<Organization> createBusiness({
    required String name,
    required bool verified,
    required String type,
    required String bio,
    required String contact,
    required String email,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/business/organizations'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'name': name,
            'verified': verified,
            'business_type': type,
            'bio': bio,
            'contact': contact,
            'email': email,
          }),
        )
        .timeout(_timeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Unable to create business (${response.statusCode})');
    }

    return Organization.fromJson(jsonDecode(response.body));
  }

  static Future<void> reset() async {
    await http
        .post(Uri.parse('$baseUrl/api/prototype/reset'))
        .timeout(_timeout);
  }

  static Future<Map<String, dynamic>> sendMessage({
    required String organizationId,
    required String userId,
    required String message,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/chat'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'organization_id': organizationId,
            'session_id': userId,
            'message': message,
          }),
        )
        .timeout(_timeout);

    return jsonDecode(response.body);
  }

  static Future<List<Conversation>> conversations(
    String organizationId, {
    String? state,
  }) async {
    final query = state == null ? '' : '&state=$state';

    final response = await http
        .get(
          Uri.parse(
            '$baseUrl/api/agent/conversations'
            '?organization_id=$organizationId$query',
          ),
        )
        .timeout(_timeout);

    return (jsonDecode(response.body) as List)
        .map((item) => Conversation.fromJson(item))
        .toList();
  }

  static Future<List<ChatMessage>> messages(String conversationId) async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/api/conversations/$conversationId/messages'),
        )
        .timeout(_timeout);

    return (jsonDecode(response.body) as List)
        .map((item) => ChatMessage.fromJson(item))
        .toList();
  }

  static Future<void> intervene(String conversationId) async {
    await http
        .post(
          Uri.parse(
            '$baseUrl/api/agent/conversations/$conversationId/intervene',
          ),
        )
        .timeout(_timeout);
  }

  static Future<void> leave(String conversationId) async {
    await http
        .post(
          Uri.parse(
            '$baseUrl/api/agent/conversations/$conversationId/leave',
          ),
        )
        .timeout(_timeout);
  }
}

class SessionStore {
  static const _userKey = 'saved_user';
  static const _businessKey = 'saved_business';

  static Future<UserProfile?> user() async {
    final preferences = await SharedPreferences.getInstance();
    final value = preferences.getString(_userKey);
    if (value == null) return null;

    return UserProfile.fromJson(jsonDecode(value));
  }

  static Future<Organization?> business() async {
    final preferences = await SharedPreferences.getInstance();
    final value = preferences.getString(_businessKey);
    if (value == null) return null;

    return Organization.fromJson(jsonDecode(value));
  }

  static Future<void> saveUser(UserProfile user) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_userKey, jsonEncode(user.toJson()));
  }

  static Future<void> saveBusiness(Organization business) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _businessKey,
      jsonEncode(business.toJson()),
    );
  }

  static Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_userKey);
    await preferences.remove(_businessKey);
  }
}

class Organization {
  const Organization({
    required this.id,
    required this.name,
    required this.description,
    required this.verified,
    required this.profileImageUrl,
  });

  final String id;
  final String name;
  final String description;
  final bool verified;
  final String profileImageUrl;

  factory Organization.fromJson(Map<String, dynamic> json) {
    return Organization(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      verified: json['verified'] ?? false,
      profileImageUrl: json['profile_image_url'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'verified': verified,
        'profile_image_url': profileImageUrl,
      };
}

class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      name: json['name'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
      };
}

class Conversation {
  const Conversation({
    required this.id,
    required this.userName,
    required this.lastMessage,
    required this.state,
  });

  final String id;
  final String userName;
  final String lastMessage;
  final String state;

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'],
      userName: json['user_name'] ?? 'Parent',
      lastMessage: json['last_message'] ?? 'No messages yet',
      state: json['state'],
    );
  }
}

class ChatMessage {
  const ChatMessage({
    required this.text,
    required this.sender,
    required this.time,
    this.options = const [],
  });

  final String text;
  final String sender;
  final DateTime time;
  final List<ReplyOption> options;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final metadata = json['metadata'] ?? {};
    final values = metadata['options'] ?? [];

    return ChatMessage(
      text: json['text'],
      sender: json['sender_type'],
      time: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      options:
          (values as List).map((item) => ReplyOption.fromJson(item)).toList(),
    );
  }
}

class ReplyOption {
  const ReplyOption({
    required this.id,
    required this.label,
  });

  final String id;
  final String label;

  factory ReplyOption.fromJson(Map<String, dynamic> json) {
    return ReplyOption(
      id: json['id'],
      label: json['label'],
    );
  }
}

class ModeScreen extends StatefulWidget {
  const ModeScreen({super.key});

  @override
  State<ModeScreen> createState() => _ModeScreenState();
}

class _ModeScreenState extends State<ModeScreen> {
  bool loading = true;
  UserProfile? savedUser;
  Organization? savedBusiness;

  @override
  void initState() {
    super.initState();
    restoreSession();
  }

  Future<void> restoreSession() async {
    final user = await SessionStore.user();
    final business = await SessionStore.business();

    if (!mounted) return;

    setState(() {
      savedUser = user;
      savedBusiness = business;
      loading = false;
    });
  }

  Future<void> openUserForm() async {
    if (savedUser != null) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OrganizationListScreen(user: savedUser!),
        ),
      );
      return;
    }

    final user = await Navigator.push<UserProfile>(
      context,
      MaterialPageRoute(builder: (_) => const UserProfileForm()),
    );

    if (user == null || !mounted) return;

    await SessionStore.saveUser(user);
    savedUser = user;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrganizationListScreen(user: user),
      ),
    );
  }

  Future<void> openBusinessForm() async {
    if (savedBusiness != null) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BusinessHomeScreen(
            organization: savedBusiness!,
          ),
        ),
      );
      return;
    }

    final business = await Navigator.push<Organization>(
      context,
      MaterialPageRoute(builder: (_) => const BusinessProfileForm()),
    );

    if (business == null || !mounted) return;

    await SessionStore.saveBusiness(business);
    savedBusiness = business;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BusinessHomeScreen(organization: business),
      ),
    );
  }

  Future<void> openExistingBusinesses() async {
    setState(() => loading = true);

    try {
      final businesses = await Api.organizations();

      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ExistingBusinessesScreen(
            businesses: businesses,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> resetPrototype() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reset prototype?'),
        content: const Text(
          'This clears user profiles, chat history, and agent requests. '
          'Business profiles remain available.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade700,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => loading = true);

    try {
      await Api.reset();
      await SessionStore.clear();

      if (mounted) {
        setState(() {
          savedUser = null;
          savedBusiness = null;
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Prototype reset successfully.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F8),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.chat,
                  color: Color(0xFF00A884),
                  size: 72,
                ),
                const SizedBox(height: 20),
                const Text(
                  'School WhatsApp Prototype',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF202C33),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: loading ? null : openUserForm,
                  child: const Padding(
                    padding: EdgeInsets.all(14),
                    child: Text('Start User Mode'),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: loading ? null : openBusinessForm,
                  child: const Padding(
                    padding: EdgeInsets.all(14),
                    child: Text('Add New Business'),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: loading ? null : openExistingBusinesses,
                  child: const Padding(
                    padding: EdgeInsets.all(14),
                    child: Text('Open Business Mode'),
                  ),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: loading ? null : resetPrototype,
                  child: const Text(
                    'Reset Prototype Chats',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class UserProfileForm extends StatefulWidget {
  const UserProfileForm({super.key});

  @override
  State<UserProfileForm> createState() => _UserProfileFormState();
}

class _UserProfileFormState extends State<UserProfileForm> {
  final name = TextEditingController();
  final contact = TextEditingController();
  final email = TextEditingController();
  bool loading = false;

  Future<void> submit() async {
    if (name.text.trim().isEmpty ||
        contact.text.trim().isEmpty ||
        email.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Complete all profile fields to continue.')),
      );
      return;
    }

    setState(() => loading = true);

    try {
      final user = await Api.createUser(
        name: name.text.trim(),
        contact: contact.text.trim(),
        email: email.text.trim(),
      );

      if (mounted) Navigator.pop(context, user);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not create your profile: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ProfileFormScaffold(
      title: 'Your profile',
      children: [
        TextField(
          controller: name,
          decoration: const InputDecoration(labelText: 'Your name'),
        ),
        TextField(
          controller: contact,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: 'Contact number'),
        ),
        TextField(
          controller: email,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Email address'),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: loading ? null : submit,
          child: Text(loading ? 'Creating...' : 'Continue to schools'),
        ),
      ],
    );
  }
}

class BusinessProfileForm extends StatefulWidget {
  const BusinessProfileForm({super.key});

  @override
  State<BusinessProfileForm> createState() => _BusinessProfileFormState();
}

class _BusinessProfileFormState extends State<BusinessProfileForm> {
  final name = TextEditingController();
  final type = TextEditingController(text: 'School');
  final bio = TextEditingController();
  final contact = TextEditingController();
  final email = TextEditingController();

  bool verified = false;
  bool loading = false;

  Future<void> submit() async {
    if (name.text.trim().isEmpty || type.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Enter a business name and type to continue.')),
      );
      return;
    }

    setState(() => loading = true);

    try {
      final business = await Api.createBusiness(
        name: name.text.trim(),
        verified: verified,
        type: type.text.trim(),
        bio: bio.text.trim(),
        contact: contact.text.trim(),
        email: email.text.trim(),
      );

      if (mounted) Navigator.pop(context, business);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not create the business: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ProfileFormScaffold(
      title: 'Business profile',
      children: [
        TextField(
          controller: name,
          decoration: const InputDecoration(labelText: 'Business name'),
        ),
        TextField(
          controller: type,
          decoration: const InputDecoration(labelText: 'Business type'),
        ),
        TextField(
          controller: bio,
          maxLines: 2,
          decoration: const InputDecoration(labelText: 'Business bio'),
        ),
        TextField(
          controller: contact,
          decoration: const InputDecoration(labelText: 'Business contact'),
        ),
        TextField(
          controller: email,
          decoration: const InputDecoration(labelText: 'Business email'),
        ),
        SwitchListTile(
          value: verified,
          onChanged: (value) => setState(() => verified = value),
          title: const Text('Show green verification tick'),
          subtitle: const Text('Prototype visual indicator only'),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: loading ? null : submit,
          child: Text(loading ? 'Creating...' : 'Create business'),
        ),
      ],
    );
  }
}

class ProfileFormScaffold extends StatelessWidget {
  const ProfileFormScaffold({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: children
            .map(
              (child) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: child,
              ),
            )
            .toList(),
      ),
    );
  }
}

class ExistingBusinessesScreen extends StatelessWidget {
  const ExistingBusinessesScreen({
    super.key,
    required this.businesses,
  });

  final List<Organization> businesses;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose Business')),
      body: ListView.builder(
        itemCount: businesses.length,
        itemBuilder: (_, index) {
          final business = businesses[index];

          return ListTile(
            leading: CircleAvatar(
              radius: 22,
              backgroundColor: const Color(0xFF128C7E),
              backgroundImage: business.profileImageUrl.isNotEmpty
                  ? NetworkImage(business.profileImageUrl)
                  : null,
              child: business.profileImageUrl.isEmpty
                  ? Text(
                      business.name.substring(0, 1).toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    )
                  : null,
            ),
            title: Row(
              children: [
                Flexible(child: Text(business.name)),
                if (business.verified)
                  const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Icon(
                      Icons.verified,
                      color: Color(0xFF00A884),
                      size: 18,
                    ),
                  ),
              ],
            ),
            subtitle: Text(business.description),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BusinessHomeScreen(
                    organization: business,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class OrganizationListScreen extends StatefulWidget {
  const OrganizationListScreen({
    super.key,
    required this.user,
  });

  final UserProfile user;

  @override
  State<OrganizationListScreen> createState() => _OrganizationListScreenState();
}

class _OrganizationListScreenState extends State<OrganizationListScreen> {
  late Future<List<Organization>> businesses;

  @override
  void initState() {
    super.initState();
    businesses = Api.organizations();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Hello, ${widget.user.name}')),
      body: FutureBuilder<List<Organization>>(
        future: businesses,
        builder: (_, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            children: snapshot.data!
                .map(
                  (business) => ListTile(
                    leading: CircleAvatar(
                      radius: 22,
                      backgroundColor: const Color(0xFF128C7E),
                      backgroundImage: business.profileImageUrl.isNotEmpty
                          ? NetworkImage(business.profileImageUrl)
                          : null,
                      child: business.profileImageUrl.isEmpty
                          ? Text(
                              business.name.substring(0, 1).toUpperCase(),
                              style: const TextStyle(color: Colors.white),
                            )
                          : null,
                    ),
                    title: Row(
                      children: [
                        Flexible(child: Text(business.name)),
                        if (business.verified)
                          const Icon(
                            Icons.verified,
                            color: Color(0xFF00A884),
                            size: 18,
                          ),
                      ],
                    ),
                    subtitle: Text(business.description),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UserChatScreen(
                            organization: business,
                            user: widget.user,
                          ),
                        ),
                      );
                    },
                  ),
                )
                .toList(),
          );
        },
      ),
    );
  }
}

class UserChatScreen extends StatefulWidget {
  const UserChatScreen({
    super.key,
    required this.organization,
    required this.user,
  });

  final Organization organization;
  final UserProfile user;

  @override
  State<UserChatScreen> createState() => _UserChatScreenState();
}

class _UserChatScreenState extends State<UserChatScreen> {
  final input = TextEditingController();
  final scrollController = ScrollController();
  final messages = <ChatMessage>[];
  bool sending = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback(
      (_) => send('hello', showUserMessage: false),
    );
  }

  Future<void> send(
    String message, {
    bool showUserMessage = true,
  }) async {
    if (message.trim().isEmpty || sending) return;

    setState(() {
      sending = true;

      if (showUserMessage) {
        messages.add(
          ChatMessage(
            text: message,
            sender: 'USER',
            time: DateTime.now(),
          ),
        );
      }
    });
    scrollToBottom();

    input.clear();

    try {
      final responseFuture = Api.sendMessage(
        organizationId: widget.organization.id,
        userId: widget.user.id,
        message: message,
      );
      final response = await responseFuture;

      setState(() {
        messages.add(
          ChatMessage(
            text: response['message'],
            sender: 'BOT',
            time: DateTime.now(),
            options: (response['options'] as List)
                .map((item) => ReplyOption.fromJson(item))
                .toList(),
          ),
        );
      });
      scrollToBottom();
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) return;

      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    input.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: WhatsAppChatHeader(
        organizationName: widget.organization.name,
        profileImageUrl: widget.organization.profileImageUrl,
        verified: widget.organization.verified,
        statusText: 'online',
      ),
      body: Column(
        children: [
          Expanded(
            child: WhatsAppChatBackground(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.only(top: 8, bottom: 8),
                children: [
                  const WhatsAppDateSeparator(text: 'TODAY'),
                  ...messages.map(
                    (message) => TemplateMessageBubble(
                      message: message,
                      onOption: (option) => send(option.label),
                    ),
                  ),
                  if (sending) const TypingIndicator(),
                ],
              ),
            ),
          ),
          WhatsAppMessageComposer(
            controller: input,
            onSend: send,
            sending: sending,
          ),
        ],
      ),
    );
  }
}

class BusinessHomeScreen extends StatefulWidget {
  const BusinessHomeScreen({
    super.key,
    required this.organization,
  });

  final Organization organization;

  @override
  State<BusinessHomeScreen> createState() => _BusinessHomeScreenState();
}

class _BusinessHomeScreenState extends State<BusinessHomeScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F9F8),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF7F9F8),
          title: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFF128C7E),
                backgroundImage: widget.organization.profileImageUrl.isNotEmpty
                    ? NetworkImage(widget.organization.profileImageUrl)
                    : null,
                child: widget.organization.profileImageUrl.isEmpty
                    ? Text(
                        widget.organization.name.substring(0, 1).toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(child: Text(widget.organization.name)),
                        if (widget.organization.verified)
                          const Icon(
                            Icons.verified,
                            color: Color(0xFF38BDF8),
                            size: 18,
                          ),
                      ],
                    ),
                    const Text(
                      'Business Mode',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF00A884),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          bottom: const TabBar(
            indicatorColor: Color(0xFF00A884),
            labelColor: Color(0xFF00A884),
            unselectedLabelColor: Color(0xFF95A5AF),
            tabs: [
              Tab(text: 'All'),
              Tab(text: 'Requests'),
              Tab(text: 'Active'),
              Tab(text: 'Attended'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            BusinessConversationList(
              organizationId: widget.organization.id,
            ),
            BusinessConversationList(
              organizationId: widget.organization.id,
              state: 'WAITING_FOR_AGENT',
            ),
            BusinessConversationList(
              organizationId: widget.organization.id,
              state: 'INTERVENED',
            ),
            BusinessConversationList(
              organizationId: widget.organization.id,
              state: 'ATTENDED',
            ),
          ],
        ),
      ),
    );
  }
}

class BusinessConversationList extends StatefulWidget {
  const BusinessConversationList({
    super.key,
    required this.organizationId,
    this.state,
  });

  final String organizationId;
  final String? state;

  @override
  State<BusinessConversationList> createState() =>
      _BusinessConversationListState();
}

class _BusinessConversationListState extends State<BusinessConversationList> {
  late Future<List<Conversation>> conversations;

  @override
  void initState() {
    super.initState();
    conversations = Api.conversations(
      widget.organizationId,
      state: widget.state,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Conversation>>(
      future: conversations,
      builder: (_, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              'No conversations',
              style: TextStyle(color: Color(0xFF667781)),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {
              conversations = Api.conversations(
                widget.organizationId,
                state: widget.state,
              );
            });
          },
          child: ListView(
            children: snapshot.data!
                .map(
                  (conversation) => ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.red.shade700,
                      child: Text(
                        conversation.userName.substring(0, 1).toUpperCase(),
                      ),
                    ),
                    title: Text(
                      conversation.userName,
                      style: const TextStyle(color: Color(0xFF202C33)),
                    ),
                    subtitle: Text(
                      conversation.lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Color(0xFF95A5AF)),
                    ),
                    trailing: conversation.state == 'WAITING_FOR_AGENT'
                        ? const Badge(label: Text('1'))
                        : null,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BusinessChatScreen(
                            conversation: conversation,
                          ),
                        ),
                      );

                      if (mounted) {
                        setState(() {
                          conversations = Api.conversations(
                            widget.organizationId,
                            state: widget.state,
                          );
                        });
                      }
                    },
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }
}

class BusinessChatScreen extends StatefulWidget {
  const BusinessChatScreen({
    super.key,
    required this.conversation,
  });

  final Conversation conversation;

  @override
  State<BusinessChatScreen> createState() => _BusinessChatScreenState();
}

class _BusinessChatScreenState extends State<BusinessChatScreen> {
  late Future<List<ChatMessage>> messages;

  @override
  void initState() {
    super.initState();
    messages = Api.messages(widget.conversation.id);
  }

  Future<void> intervene() async {
    await Api.intervene(widget.conversation.id);

    if (mounted) Navigator.pop(context);
  }

  Future<void> leave() async {
    await Api.leave(widget.conversation.id);

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final waiting = widget.conversation.state == 'WAITING_FOR_AGENT';
    final active = widget.conversation.state == 'INTERVENED';

    return Scaffold(
      appBar: WhatsAppChatHeader(
        organizationName: widget.conversation.userName,
        statusText: active
            ? 'agent connected'
            : waiting
                ? 'waiting for agent'
                : 'attended',
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            color: active ? const Color(0xFFD9FDD3) : const Color(0xFFFFF3CD),
            child: Text(
              active
                  ? 'School representative has joined this conversation.'
                  : waiting
                      ? 'This parent requested school assistance.'
                      : 'Conversation attended.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF111B21),
              ),
            ),
          ),
          Expanded(
            child: WhatsAppChatBackground(
              child: FutureBuilder<List<ChatMessage>>(
                future: messages,
                builder: (_, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  return ListView(
                    padding: const EdgeInsets.only(top: 8, bottom: 8),
                    children: [
                      const WhatsAppDateSeparator(text: 'TODAY'),
                      ...snapshot.data!.map(
                        (message) => TemplateMessageBubble(
                          message: message,
                          onOption: (_) {},
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: waiting
                  ? FilledButton(
                      onPressed: intervene,
                      style: FilledButton.styleFrom(
                        backgroundColor: WhatsAppTheme.primaryGreen,
                        minimumSize: const Size.fromHeight(46),
                      ),
                      child: const Text('Intervene'),
                    )
                  : active
                      ? FilledButton.tonal(
                          onPressed: leave,
                          child: const Text('Leave and mark attended'),
                        )
                      : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}

class TypingIndicator extends StatelessWidget {
  const TypingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const WhatsAppTypingIndicator();
  }
}

class TemplateMessageBubble extends StatelessWidget {
  const TemplateMessageBubble({
    super.key,
    required this.message,
    required this.onOption,
  });

  final ChatMessage message;
  final ValueChanged<ReplyOption> onOption;

  @override
  Widget build(BuildContext context) {
    return WhatsAppMessageBubble(
      text: message.text,
      isUser: message.sender == 'USER',
      timestamp: message.time,
      options: message.options
          .map((opt) => WhatsAppMessageOption(id: opt.id, label: opt.label))
          .toList(),
      onOptionSelected: (opt) {
        onOption(ReplyOption(id: opt.id, label: opt.label));
      },
    );
  }
}
