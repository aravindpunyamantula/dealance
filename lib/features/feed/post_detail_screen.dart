import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../services/api_service.dart';
import '../../utils/app_palette.dart';
import 'feed_media_gallery.dart';

class PostDetailScreen extends StatefulWidget {
  final Map<String, dynamic> post;

  const PostDetailScreen({super.key, required this.post});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final ApiService _api = ApiService();
  late Map<String, dynamic> _post;
  final TextEditingController _commentController = TextEditingController();
  List<dynamic> _comments = [];
  bool _isLoadingComments = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _post = widget.post;
    _loadComments();
  }

  Future<void> _loadComments() async {
    try {
      final comments = await _api.getComments(_post['id']);
      if (mounted) {
        setState(() {
          _comments = comments;
          _isLoadingComments = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingComments = false);
    }
  }

  Future<void> _toggleLike() async {
    final wasLiked = _post['isLiked'] == true;
    final currentLikes = _post['likeCount'] as int? ?? 0;

    setState(() {
      _post['isLiked'] = !wasLiked;
      _post['likeCount'] = wasLiked ? currentLikes - 1 : currentLikes + 1;
    });

    try {
      await _api.toggleLike(_post['id']);
    } catch (_) {
      if (mounted) {
        setState(() {
          _post['isLiked'] = wasLiked;
          _post['likeCount'] = currentLikes;
        });
      }
    }
  }

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);
    try {
      await _api.addComment(_post['id'], text);
      _commentController.clear();
      
      setState(() {
        final currentCount = _post['_count']?['comments'] ?? 0;
        if (_post['_count'] == null) {
          _post['_count'] = {'comments': currentCount + 1};
        } else {
          _post['_count']['comments'] = currentCount + 1;
        }
      });
      await _loadComments();
    } catch (_) {}
    if (mounted) setState(() => _isSending = false);
  }

  @override
  Widget build(BuildContext context) {
    final user = _post['user'] as Map<String, dynamic>?;
    final startup = _post['startup'] as Map<String, dynamic>?;
    final isLiked = _post['isLiked'] == true;
    final likesCount = _post['likeCount'] ?? 0;
    final commentsCount = _post['_count']?['comments'] ?? 0;
    final createdAt = DateTime.tryParse(_post['createdAt'] ?? '');
    
    List<String> mediaUrls = [];
    if (_post['mediaUrls'] is List) {
      mediaUrls = (_post['mediaUrls'] as List).map((e) => e.toString()).toList();
    }

    return Scaffold(
      backgroundColor: AppPalette.background,
      appBar: AppBar(
        title: const Text('Post', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        backgroundColor: AppPalette.background,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Post Content
                  Container(
                    padding: const EdgeInsets.all(20),
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: AppPalette.primaryAccent.withValues(alpha: 0.1),
                              backgroundImage: user?['avatar'] != null ? NetworkImage(user!['avatar']) : null,
                              child: user?['avatar'] == null
                                  ? Text((user?['name'] ?? 'U').substring(0, 1).toUpperCase(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppPalette.primaryAccent))
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(child: Text(user?['name'] ?? 'Unknown', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: user?['role'] == 'INVESTOR' ? AppPalette.info.withValues(alpha: 0.1) : AppPalette.success.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          user?['role'] == 'INVESTOR' ? 'Investor' : 'Founder',
                                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: user?['role'] == 'INVESTOR' ? AppPalette.info : AppPalette.success),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (createdAt != null)
                                    Text(timeago.format(createdAt), style: const TextStyle(fontSize: 12, color: AppPalette.textTerenary)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(_post['content'] ?? '', style: const TextStyle(fontSize: 16, height: 1.5, color: AppPalette.textPrimary)),

                        if (mediaUrls.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          FeedMediaGallery(mediaUrls: mediaUrls),
                        ],

                        if (startup != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppPalette.surfaceElevated,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40, height: 40,
                                  decoration: BoxDecoration(gradient: AppPalette.primaryGradient, borderRadius: BorderRadius.circular(10)),
                                  child: Center(child: Text((startup['companyName'] ?? 'S').substring(0, 1), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16))),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(startup['companyName'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppPalette.textPrimary)),
                                      const SizedBox(height: 2),
                                      if (startup['industry'] != null)
                                        Text(startup['industry'], style: const TextStyle(fontSize: 12, color: AppPalette.textSecondary)),
                                    ],
                                  ),
                                ),
                                const Icon(Iconsax.arrow_right_3, size: 16, color: AppPalette.textSecondary),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 20),
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: _toggleLike,
                                child: Row(
                                  children: [
                                    Icon(isLiked ? Iconsax.heart5 : Iconsax.heart, size: 24, color: isLiked ? AppPalette.danger : AppPalette.textSecondary),
                                    const SizedBox(width: 8),
                                    Text('$likesCount Likes', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isLiked ? AppPalette.danger : AppPalette.textSecondary)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 24),
                              Row(
                                children: [
                                  const Icon(Iconsax.message, size: 24, color: AppPalette.textSecondary),
                                  const SizedBox(width: 8),
                                  Text('$commentsCount Comments', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppPalette.textSecondary)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                      ],
                    ),
                  ),

                  // Comments Section
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Comments', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppPalette.textPrimary)),
                        const SizedBox(height: 16),
                        if (_isLoadingComments)
                          const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: AppPalette.primaryAccent)))
                        else if (_comments.isEmpty)
                          const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('No comments yet. Be the first to comment!', style: TextStyle(color: AppPalette.textSecondary))))
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _comments.length,
                            itemBuilder: (context, index) {
                              final comment = _comments[index];
                              final commentUser = comment['user'] as Map<String, dynamic>?;
                              final commentTime = DateTime.tryParse(comment['createdAt'] ?? '');
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: AppPalette.surfaceElevated,
                                      backgroundImage: commentUser?['avatar'] != null ? NetworkImage(commentUser!['avatar']) : null,
                                      child: commentUser?['avatar'] == null
                                          ? Text((commentUser?['name'] ?? 'U').substring(0, 1).toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: Colors.grey.shade200),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(commentUser?['name'] ?? 'Unknown', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                                if (commentTime != null)
                                                  Text(timeago.format(commentTime), style: const TextStyle(fontSize: 11, color: AppPalette.textTerenary)),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(comment['content'] ?? '', style: const TextStyle(fontSize: 14, height: 1.4)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Comment Input
          Container(
            padding: EdgeInsets.only(left: 16, right: 16, top: 12, bottom: MediaQuery.of(context).padding.bottom + 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4))],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppPalette.surfaceElevated,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _commentController,
                      decoration: const InputDecoration(
                        hintText: 'Write a comment...',
                        hintStyle: TextStyle(color: AppPalette.textSecondary, fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendComment(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _isSending ? null : _sendComment,
                  child: Container(
                    width: 44, height: 44,
                    decoration: const BoxDecoration(
                      color: AppPalette.primaryAccent,
                      shape: BoxShape.circle,
                    ),
                    child: _isSending 
                        ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
                        : const Icon(Iconsax.send_1, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
