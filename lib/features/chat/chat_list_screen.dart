import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../services/api_service.dart';
import '../../utils/app_palette.dart';
import 'chat_room_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ApiService _api = ApiService();
  List<dynamic> _rooms = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final rooms = await _api.getChatRooms();
      if (mounted) setState(() { _rooms = rooms; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Text('Messages 💬', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, fontFamily: 'Revalia', color: AppPalette.textPrimary)),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppPalette.primaryAccent))
                    : _rooms.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.chat_bubble_outline, size: 56, color: AppPalette.textTerenary),
                                SizedBox(height: 12),
                                Text('No conversations yet', style: TextStyle(fontSize: 16, color: AppPalette.textSecondary)),
                                SizedBox(height: 4),
                                Text('Start a chat from a startup page', style: TextStyle(fontSize: 13, color: AppPalette.textTerenary)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _rooms.length,
                            itemBuilder: (_, i) => _buildRoomTile(_rooms[i]),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoomTile(Map<String, dynamic> room) {
    final otherUser = room['otherUser'] as Map<String, dynamic>?;
    final lastMsg = room['lastMessage'] as Map<String, dynamic>?;
    final name = otherUser?['name'] ?? 'Unknown';
    final role = otherUser?['role'] ?? '';
    final lastContent = lastMsg?['content'] ?? 'No messages yet';
    final lastTime = DateTime.tryParse(lastMsg?['createdAt'] ?? '');

    return ListTile(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ChatRoomScreen(
            roomId: room['id'],
            otherUserName: name,
          )),
        );
        _load(); // Refresh on return
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: role == 'INVESTOR' ? AppPalette.info.withValues(alpha: 0.1) : AppPalette.primaryAccent.withValues(alpha: 0.1),
        child: Text(name.substring(0, 1).toUpperCase(), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: role == 'INVESTOR' ? AppPalette.info : AppPalette.primaryAccent)),
      ),
      title: Row(
        children: [
          Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: role == 'INVESTOR' ? AppPalette.info.withValues(alpha: 0.1) : AppPalette.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(role == 'INVESTOR' ? '💰' : '🚀', style: const TextStyle(fontSize: 10)),
          ),
        ],
      ),
      subtitle: Text(lastContent, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: AppPalette.textSecondary)),
      trailing: lastTime != null ? Text(timeago.format(lastTime, locale: 'en_short'), style: const TextStyle(fontSize: 11, color: AppPalette.textTerenary)) : null,
    );
  }
}
