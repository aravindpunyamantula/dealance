import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../../services/api_service.dart';
import '../../utils/app_palette.dart';

class ChatRoomScreen extends StatefulWidget {
  final String roomId;
  final String otherUserName;
  const ChatRoomScreen({super.key, required this.roomId, required this.otherUserName});

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final ApiService _api = ApiService();
  final _msgController = TextEditingController();
  final _scrollController = ScrollController();
  List<dynamic> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _otherTyping = false;
  io.Socket? _socket;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _connectSocket();
  }

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    _socket?.emit('chat:leave', widget.roomId);
    _socket?.disconnect();
    super.dispose();
  }

  Future<void> _connectSocket() async {
    final token = await _api.getAccessToken();
    if (token == null) return;

    final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000/api';
    final socketUrl = baseUrl.replaceAll('/api', '');

    _socket = io.io(socketUrl, io.OptionBuilder()
      .setTransports(['websocket'])
      .setAuth({'token': token})
      .disableAutoConnect()
      .build());

    _socket!.connect();

    _socket!.onConnect((_) {
      _socket!.emit('chat:join', widget.roomId);
    });

    _socket!.on('chat:message', (data) {
      if (mounted) {
        setState(() {
          _messages.insert(0, data);
          _otherTyping = false;
        });
      }
    });

    _socket!.on('chat:typing', (data) {
      if (data['roomId'] == widget.roomId && mounted) {
        setState(() => _otherTyping = true);
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) setState(() => _otherTyping = false);
        });
      }
    });
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    try {
      final msgs = await _api.getChatMessages(widget.roomId);
      if (mounted) setState(() { _messages = msgs; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;
    setState(() => _isSending = true);
    _msgController.clear();
    try {
      await _api.sendChatMessage(widget.roomId, text);
      // The socket will push the message back — no need to manually add
    } catch (_) {}
    if (mounted) setState(() => _isSending = false);
  }

  void _onTyping() {
    _socket?.emit('chat:typing', {'roomId': widget.roomId});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.background,
      appBar: AppBar(
        backgroundColor: AppPalette.surfaceCard,
        foregroundColor: AppPalette.textPrimary,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.otherUserName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            if (_otherTyping)
              const Text('typing...', style: TextStyle(fontSize: 11, color: AppPalette.success, fontWeight: FontWeight.w400)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppPalette.primaryAccent))
                : _messages.isEmpty
                    ? const Center(child: Text('Start a conversation!', style: TextStyle(color: AppPalette.textSecondary)))
                    : ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _messages.length,
                        itemBuilder: (_, i) => _buildBubble(_messages[i]),
                      ),
          ),

          // Input
          Container(
            padding: EdgeInsets.only(left: 16, right: 8, top: 8, bottom: MediaQuery.of(context).viewInsets.bottom + 8),
            decoration: BoxDecoration(
              color: AppPalette.surfaceCard,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    onChanged: (_) => _onTyping(),
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: const TextStyle(color: AppPalette.textTerenary, fontSize: 14),
                      filled: true,
                      fillColor: AppPalette.background,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: _isSending ? null : _sendMessage,
                  child: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(gradient: AppPalette.primaryGradient, shape: BoxShape.circle),
                    child: _isSending
                        ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send, color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(Map<String, dynamic> msg) {
    final sender = msg['sender'] as Map<String, dynamic>?;
    // Compare sender ID with auth state to determine if it's "mine"
    // For now, use a simple name-based check since we don't have userId in widget
    final isMine = sender?['name'] != widget.otherUserName;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMine ? AppPalette.primaryAccent : AppPalette.surfaceCard,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMine ? 16 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 16),
          ),
          border: isMine ? null : Border.all(color: Colors.grey.shade200),
        ),
        child: Text(
          msg['content'] ?? '',
          style: TextStyle(fontSize: 14, color: isMine ? Colors.white : AppPalette.textPrimary, height: 1.3),
        ),
      ),
    );
  }
}
