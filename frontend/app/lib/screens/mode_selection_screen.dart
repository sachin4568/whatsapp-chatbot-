import 'package:flutter/material.dart';

import '../services/chatbot_api.dart';
import 'business_home_screen.dart';
import 'organization_search_screen.dart';

class ModeSelectionScreen extends StatefulWidget {
  const ModeSelectionScreen({super.key});

  @override
  State<ModeSelectionScreen> createState() => _ModeSelectionScreenState();
}

class _ModeSelectionScreenState extends State<ModeSelectionScreen> {
  final ChatbotApi _api = ChatbotApi();
  bool _working = false;

  Future<void> _openBusinessMode() async {
    setState(() => _working = true);

    try {
      final organizations = await _api.organizations();

      if (!mounted) return;

      if (organizations.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Create a business before opening Business Mode.'),
          ),
        );
        return;
      }

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BusinessHomeScreen(
            organization: organizations.first,
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not connect to the local chatbot service.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _addBusiness() async {
    final controller = TextEditingController();

    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add new school business'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'School / organization name',
            hintText: 'Example International School',
          ),
          onSubmitted: (value) {
            Navigator.pop(dialogContext, value);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              dialogContext,
              controller.text,
            ),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (name == null || name.trim().isEmpty) return;

    setState(() => _working = true);

    try {
      final organization = await _api.createBusiness(name.trim());

      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BusinessHomeScreen(
            organization: organization,
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not create the business.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _resetPrototype() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reset prototype chats?'),
        content: const Text(
          'This clears all conversation history and agent requests. '
          'Your configured businesses remain available.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade700,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Reset chats'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _working = true);

    try {
      await _api.resetPrototype();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Prototype reset. You can begin a fresh demo.'),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not reset the prototype.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Organization Chat')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.chat,
                  size: 72,
                  color: Color(0xFF25D366),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Choose a view to simulate',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),

                FilledButton(
                  onPressed: _working
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const OrganizationSearchScreen(),
                            ),
                          );
                        },
                  child: const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('Open User Mode'),
                  ),
                ),
                const SizedBox(height: 12),

                OutlinedButton(
                  onPressed: _working ? null : _openBusinessMode,
                  child: const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('Open Business Mode'),
                  ),
                ),
                const SizedBox(height: 12),

                TextButton(
                  onPressed: _working ? null : _addBusiness,
                  child: const Text('+ Add new business'),
                ),
                const SizedBox(height: 18),

                const Divider(),
                const SizedBox(height: 8),

                OutlinedButton(
                  onPressed: _working ? null : _resetPrototype,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                  ),
                  child: _working
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Reset prototype chats'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}