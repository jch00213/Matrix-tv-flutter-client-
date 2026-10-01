import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import '../utils/responsive_extension.dart';
import 'settings_screen.dart';
import 'chat_screen.dart';

class RoomListScreen extends StatefulWidget {
  final Client client;

  const RoomListScreen({super.key, required this.client});

  @override
  State<RoomListScreen> createState() => _RoomListScreenState();
}

class _RoomListScreenState extends State<RoomListScreen> {
  @override
  void initState() {
    super.initState();
    widget.client.onSync.stream.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final rooms = widget.client.rooms;
    final bool tvMode = context.isTv;

    return Scaffold(
      appBar: AppBar(
        title: Text(tvMode ? 'Matrix TV Rooms' : 'Matrix Rooms'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsScreen(client: widget.client),
                ),
              );
            },
          ),
          SizedBox(width: tvMode ? 16 : 8),
        ],
      ),
      body: rooms.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Syncing Matrix rooms...', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(context.defaultPadding),
              itemCount: rooms.length,
              itemBuilder: (context, index) {
                final room = rooms[index];
                
                return _AdaptiveRoomCardItem(
                  room: room,
                  isFirst: index == 0,
                  tvMode: tvMode,
                );
              },
            ),
    );
  }
}

class _AdaptiveRoomCardItem extends StatefulWidget {
  final Room room;
  final bool isFirst;
  final bool tvMode;

  const _AdaptiveRoomCardItem({
    required this.room,
    required this.isFirst,
    required this.tvMode,
  });

  @override
  State<_AdaptiveRoomCardItem> createState() => _AdaptiveRoomCardItemState();
}

class _AdaptiveRoomCardItemState extends State<_AdaptiveRoomCardItem> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final roomName = widget.room.getLocalizedDisplayname();
    final firstLetter = roomName.isNotEmpty ? roomName[0].toUpperCase() : '?';
    final lastMessage = widget.room.lastEvent?.body ?? 'No messages yet';

    return Padding(
      padding: EdgeInsets.symmetric(vertical: widget.tvMode ? 8.0 : 6.0),
      child: Focus(
        onFocusChange: (focused) {
          setState(() {
            _isFocused = focused;
          });
        },
        child: Card(
          elevation: _isFocused ? 8 : 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
            side: BorderSide(
              color: _isFocused ? Colors.greenAccent : Colors.transparent,
              width: widget.tvMode && _isFocused ? 3.0 : 0.0,
            ),
          ),
          color: _isFocused ? Colors.teal.shade900 : null,
          child: InkWell(
            autofocus: widget.isFirst && widget.tvMode,
            borderRadius: BorderRadius.circular(12.0),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(room: widget.room),
                ),
              );
            },
            child: Padding(
              padding: EdgeInsets.all(context.listItemPadding),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: widget.tvMode ? 28 : 20,
                    backgroundColor: Colors.blueGrey,
                    child: Text(
                      firstLetter,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: widget.tvMode ? 20 : 14,
                      ),
                    ),
                  ),
                  SizedBox(width: widget.tvMode ? 24 : 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          roomName,
                          style: TextStyle(
                            fontSize: context.titleTextSize,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: widget.tvMode ? 6 : 4),
                        Text(
                          lastMessage,
                          style: TextStyle(
                            fontSize: context.bodyTextSize,
                            color: Colors.grey[400],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (widget.room.notificationCount > 0)
                    Container(
                      padding: EdgeInsets.all(widget.tvMode ? 12 : 8),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${widget.room.notificationCount}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: widget.tvMode ? 14 : 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
