import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:matrix/matrix.dart';
import '../utils/responsive_extension.dart';
import 'invite_user_dialog.dart'; // Import the invite user dialog

class ChatScreen extends StatefulWidget {
  final Room room;

  const ChatScreen({super.key, required this.room});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timeline? _timeline;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initTimeline();
  }

  Future<void> _initTimeline() async {
    // Initialize the timeline with the v12 onUpdate callback
    _timeline = await widget.room.getTimeline(
      onUpdate: () {
        if (mounted) setState(() {});
      },
    );

    // Listen to live room update stream so the open chat window updates instantly
    widget.room.onUpdate.stream.listen((_) {
      if (mounted) {
        setState(() {});
      }
    });

    // Fallback sync stream listener
    widget.room.client.onSync.stream.listen((_) {
      if (mounted) setState(() {});
    });

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _timeline?.cancelSubscriptions();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    
    // Force immediate frame redraw to show the local echo optimistically
    if (mounted) setState(() {});

    try {
      await widget.room.sendTextEvent(text);
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Failed to send message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    }
  }

  Future<void> _showInviteDialog() async {
    final invited = await showDialog<bool>(
      context: context,
      builder: (context) => InviteUserDialog(room: widget.room),
    );

    if (invited == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invitation sent successfully!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool tvMode = context.isTv;

    // Filter strictly for actual message events to avoid showing state events like m.room.create, m.room.member, etc.
    final events = _timeline?.events
            .where((e) => 
                e.type == 'm.room.message' && 
                (e.messageType == MessageTypes.Text || e.messageType == MessageTypes.Notice) && 
                e.body.isNotEmpty)
            .toList() ??
        [];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.room.getLocalizedDisplayname(),
          style: TextStyle(fontSize: tvMode ? 24 : 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: 'Invite User to Room',
            onPressed: _showInviteDialog,
          ),
          SizedBox(width: tvMode ? 16 : 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: events.isEmpty
                      ? Center(
                          child: Text(
                            'No messages in this room yet. Say hello!',
                            style: TextStyle(color: Colors.grey, fontSize: context.bodyTextSize),
                          ),
                        )
                      : Focus(
                          autofocus: true,
                          onKeyEvent: (node, event) {
                            if (event is KeyDownEvent || event is KeyRepeatEvent) {
                              if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                                final target = (_scrollController.offset + 80).clamp(
                                  _scrollController.position.minScrollExtent,
                                  _scrollController.position.maxScrollExtent,
                                );
                                _scrollController.animateTo(
                                  target,
                                  duration: const Duration(milliseconds: 50),
                                  curve: Curves.easeOut,
                                );
                                return KeyEventResult.handled;
                              } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                                final target = (_scrollController.offset - 80).clamp(
                                  _scrollController.position.minScrollExtent,
                                  _scrollController.position.maxScrollExtent,
                                );
                                _scrollController.animateTo(
                                  target,
                                  duration: const Duration(milliseconds: 50),
                                  curve: Curves.easeOut,
                                );
                                return KeyEventResult.handled;
                              }
                            }
                            return KeyEventResult.ignored;
                          },
                          child: Scrollbar(
                            controller: _scrollController,
                            thumbVisibility: true,
                            thickness: tvMode ? 10.0 : 8.0,
                            radius: const Radius.circular(4),
                            child: ListView.builder(
                              reverse: true,
                              controller: _scrollController,
                              padding: EdgeInsets.symmetric(
                                horizontal: context.defaultPadding,
                                vertical: tvMode ? 16.0 : 12.0,
                              ),
                              itemCount: events.length,
                              itemBuilder: (context, index) {
                                final event = events[events.length - 1 - index];
                                final isMe = event.senderId == widget.room.client.userID;

                                return Align(
                                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                                  child: Container(
                                    constraints: BoxConstraints(
                                      maxWidth: MediaQuery.of(context).size.width * (tvMode ? 0.60 : 0.70),
                                    ),
                                    margin: EdgeInsets.symmetric(vertical: tvMode ? 6.0 : 4.0),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: tvMode ? 18.0 : 14.0,
                                      vertical: tvMode ? 14.0 : 10.0,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isMe ? Colors.teal.shade700 : Colors.grey.shade800,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (!isMe) ...[
                                          Text(
                                            event.senderFromMemoryOrFallback.calcDisplayname(),
                                            style: TextStyle(
                                              fontSize: tvMode ? 13 : 11,
                                              color: Colors.tealAccent,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(height: tvMode ? 4 : 2),
                                        ],
                                        Text(
                                          event.body,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: context.bodyTextSize,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: EdgeInsets.all(context.defaultPadding),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          autofocus: false,
                          style: TextStyle(color: Colors.white, fontSize: context.bodyTextSize),
                          decoration: InputDecoration(
                            hintText: 'Type a message...',
                            hintStyle: const TextStyle(color: Colors.white54),
                            border: const OutlineInputBorder(),
                            filled: true,
                            fillColor: const Color(0xFF1E1E1E),
                            contentPadding: EdgeInsets.all(tvMode ? 16.0 : 12.0),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      SizedBox(width: tvMode ? 16 : 8),
                      IconButton.filled(
                        onPressed: _sendMessage,
                        iconSize: tvMode ? 28 : 24,
                        padding: EdgeInsets.all(tvMode ? 16 : 12),
                        icon: const Icon(Icons.send),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
