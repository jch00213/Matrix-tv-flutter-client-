import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'room_list_screen.dart';
import 'settings_screen.dart';
import 'chat_screen.dart';
import '../utils/responsive_extension.dart';

class SpaceListScreen extends StatefulWidget {
  final Client client;

  const SpaceListScreen({super.key, required this.client});

  @override
  State<SpaceListScreen> createState() => _SpaceListScreenState();
}

class _SpaceListScreenState extends State<SpaceListScreen> {
  @override
  void initState() {
    super.initState();
    widget.client.onSync.stream.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool tvMode = context.isTv;
    final allRooms = widget.client.rooms;
    final spaces = allRooms.where((room) => room.isSpace).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Matrix TV - Spaces',
          style: TextStyle(fontSize: tvMode ? 24 : 20),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings, size: tvMode ? 28 : 24),
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
      body: spaces.isEmpty
          ? RoomListScreen(client: widget.client)
          : GridView.builder(
              padding: EdgeInsets.all(context.defaultPadding),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: tvMode ? 3 : 2,
                crossAxisSpacing: tvMode ? 20.0 : 16.0,
                mainAxisSpacing: tvMode ? 20.0 : 16.0,
                childAspectRatio: tvMode ? 1.6 : 1.5,
              ),
              itemCount: spaces.length,
              itemBuilder: (context, index) {
                final space = spaces[index];
                return Card(
                  elevation: 4,
                  child: InkWell(
                    autofocus: index == 0,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SpaceDetailScreen(client: widget.client, space: space),
                        ),
                      );
                    },
                    child: Padding(
                      padding: EdgeInsets.all(tvMode ? 20.0 : 16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.folder_special,
                            size: tvMode ? 48 : 40,
                            color: Colors.blueAccent,
                          ),
                          SizedBox(height: tvMode ? 16 : 12),
                          Text(
                            space.getLocalizedDisplayname(),
                            style: TextStyle(
                              fontSize: context.bodyTextSize + 1,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class SpaceDetailScreen extends StatelessWidget {
  final Client client;
  final Room space;

  const SpaceDetailScreen({super.key, required this.client, required this.space});

  @override
  Widget build(BuildContext context) {
    final bool tvMode = context.isTv;
    final childRooms = space.spaceChildrenRooms;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          space.getLocalizedDisplayname(),
          style: TextStyle(fontSize: tvMode ? 24 : 20),
        ),
      ),
      body: childRooms.isEmpty
          ? Center(
              child: Text(
                'No rooms found in this space.',
                style: TextStyle(color: Colors.grey, fontSize: context.bodyTextSize),
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(context.defaultPadding),
              itemCount: childRooms.length,
              itemBuilder: (context, index) {
                final room = childRooms[index];
                return Card(
                  margin: EdgeInsets.symmetric(vertical: tvMode ? 8.0 : 4.0),
                  child: InkWell(
                    autofocus: index == 0,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(room: room),
                        ),
                      );
                    },
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: tvMode ? 24.0 : 16.0,
                        vertical: tvMode ? 8.0 : 4.0,
                      ),
                      leading: Icon(Icons.chat, size: tvMode ? 32 : 24),
                      title: Text(
                        room.getLocalizedDisplayname(),
                        style: TextStyle(
                          fontSize: context.bodyTextSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        room.lastEvent?.body ?? 'No messages yet',
                        maxLines: 1,
                        style: TextStyle(fontSize: context.bodyTextSize - 2),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
