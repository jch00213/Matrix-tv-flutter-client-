import 'package:flutter/material.dart' hide Visibility;
import 'package:matrix/matrix.dart';

class CreateRoomDialog extends StatefulWidget {
  final Client client;

  const CreateRoomDialog({super.key, required this.client});

  @override
  State<CreateRoomDialog> createState() => _CreateRoomDialogState();
}

class _CreateRoomDialogState extends State<CreateRoomDialog> {
  final _nameController = TextEditingController();
  final _topicController = TextEditingController();
  bool _isSpace = false;
  bool _isPublic = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _topicController.dispose();
    super.dispose();
  }

  Future<void> _createRoomOrSpace() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      await widget.client.createRoom(
        name: name,
        topic: _topicController.text.trim().isEmpty ? null : _topicController.text.trim(),
        visibility: _isPublic ? Visibility.public : Visibility.private,
        initialState: _isSpace
            ? [
                Event.fromJson({
                  'type': 'm.room.create',
                  'content': {'type': 'm.space'},
                  'sender': widget.client.userID ?? '',
                }, null)
              ]
            : null,
      );

      if (mounted) {
        Navigator.of(context).pop(true); // Return true to trigger a refresh
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isSpace ? 'Create New Space' : 'Create New Room'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'e.g. Media Hub or General Chat',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _topicController,
              decoration: const InputDecoration(
                labelText: 'Topic (Optional)',
                hintText: 'What is this channel about?',
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Is this a Space?'),
              subtitle: const Text('Spaces group multiple rooms together'),
              value: _isSpace,
              onChanged: (val) => setState(() => _isSpace = val),
            ),
            SwitchListTile(
              title: const Text('Public Access'),
              subtitle: const Text('Anyone on the homeserver can find and join'),
              value: _isPublic,
              onChanged: (val) => setState(() => _isPublic = val),
            ),
            if (_isLoading) ...[
              const SizedBox(height: 24),
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _createRoomOrSpace,
          child: const Text('Create'),
        ),
      ],
    );
  }
}
