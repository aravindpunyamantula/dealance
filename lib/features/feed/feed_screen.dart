import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:iconsax/iconsax.dart';
import '../../services/api_service.dart';
import '../../services/auth_provider.dart';
import '../../utils/app_palette.dart';
import '../../pages/entrepreneur/pitch_upload2/pitch_problem_step1.dart';
import '../../pages/ideas/my_ideas_screen.dart';
import '../../pages/ai/ai_analysis_screen.dart';
import '../../pages/investor/deal_flow_screen.dart';
import '../deals/deals_screen.dart';
import '../chat/chat_list_screen.dart';
import 'create_post_screen.dart';
import 'feed_media_gallery.dart';
import 'post_detail_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final ApiService _api = ApiService();
  List<dynamic> _posts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _api.getFeedPosts().catchError((_) => <dynamic>[]),
      ]);
      if (mounted) {
        setState(() {
          _posts = results[0];
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleLike(int index) async {
    final post = _posts[index] as Map<String, dynamic>;
    final wasLiked = post['isLiked'] == true;
    final currentLikes = post['likeCount'] as int? ?? 0;

    setState(() {
      _posts[index]['isLiked'] = !wasLiked;
      _posts[index]['likeCount'] = wasLiked ? currentLikes - 1 : currentLikes + 1;
    });

    try {
      await _api.toggleLike(post['id']);
    } catch (_) {
      if (mounted) {
        setState(() {
          _posts[index]['isLiked'] = wasLiked;
          _posts[index]['likeCount'] = currentLikes;
        });
      }
    }
  }

  void _showComments(int index) {
    final post = _posts[index] as Map<String, dynamic>;
    final commentController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CommentSheet(
        postId: post['id'], 
        api: _api, 
        controller: commentController,
        onCommentAdded: () {
          setState(() {
            final currentCount = _posts[index]['_count']?['comments'] ?? 0;
            if (_posts[index]['_count'] == null) {
              _posts[index]['_count'] = {'comments': currentCount + 1};
            } else {
              _posts[index]['_count']['comments'] = currentCount + 1;
            }
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final isEntrepreneur = auth.userRole == 'ENTREPRENEUR';

    return Scaffold(
      backgroundColor: AppPalette.background,
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final created = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreatePostScreen()),
          );
          if (created == true) {
            _loadAll();
          }
        },
        backgroundColor: AppPalette.primaryAccent,
        elevation: 4,
        child: const Icon(Iconsax.edit, color: Colors.white),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadAll,
          color: AppPalette.primaryAccent,
          child: CustomScrollView(
            slivers: [
              // ─── Header ───
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hey, ${auth.userName}',
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppPalette.textPrimary),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isEntrepreneur ? 'Entrepreneur Dashboard' : 'Investor Dashboard',
                              style: const TextStyle(fontSize: 13, color: AppPalette.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatListScreen())),
                        child: Container(
                          width: 42, height: 42,
                          decoration: BoxDecoration(
                            color: AppPalette.surfaceCard,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: const Icon(Iconsax.message, size: 20, color: AppPalette.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ─── Stats Cards Removed ───

              // ─── Quick Actions ───
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Quick Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppPalette.textPrimary)),
                      const SizedBox(height: 12),
                      Row(
                        children: isEntrepreneur
                            ? [
                                _buildGlassQuickAction(
                                  icon: Iconsax.add_square,
                                  label: 'New Startup',
                                  color: AppPalette.success,
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProblemSolutionForm())).then((_) => _loadAll()),
                                ),
                                const SizedBox(width: 10),
                                _buildGlassQuickAction(
                                  icon: Iconsax.magic_star,
                                  label: 'AI Analysis',
                                  color: AppPalette.aiGlow,
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AIAnalysisScreen())),
                                ),
                                const SizedBox(width: 10),
                                _buildGlassQuickAction(
                                  icon: Iconsax.folder_open,
                                  label: 'My Startups',
                                  color: AppPalette.warning,
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyIdeasScreen())),
                                ),
                              ]
                            : [
                                _buildGlassQuickAction(
                                  icon: Iconsax.discover,
                                  label: 'Discover',
                                  color: AppPalette.primaryAccent,
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DealFlowScreen())),
                                ),
                                const SizedBox(width: 10),
                                _buildGlassQuickAction(
                                  icon: Iconsax.briefcase,
                                  label: 'My Deals',
                                  color: AppPalette.info,
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DealsScreen())),
                                ),
                                const SizedBox(width: 10),
                                _buildGlassQuickAction(
                                  icon: Iconsax.message,
                                  label: 'Messages',
                                  color: AppPalette.success,
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatListScreen())),
                                ),
                              ],
                      ),
                    ],
                  ),
                ),
              ),
              
              // ─── Compose Box Removed ───

              // ─── Feed Label ───
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 8, 20, 4),
                  child: Text('Community Feed', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppPalette.textPrimary)),
                ),
              ),

              // ─── Posts ───
              if (_isLoading)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator(color: AppPalette.primaryAccent)),
                  ),
                ),

              if (!_isLoading && _posts.isEmpty)
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(color: AppPalette.surfaceCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade100)),
                    child: const Column(
                      children: [
                        Icon(Iconsax.document, size: 48, color: AppPalette.textTerenary),
                        SizedBox(height: 10),
                        Text('No posts yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppPalette.textSecondary)),
                        SizedBox(height: 4),
                        Text('Be the first to share an update!', style: TextStyle(fontSize: 13, color: AppPalette.textTerenary)),
                      ],
                    ),
                  ),
                ),

              if (!_isLoading && _posts.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildPostCard(index),
                      childCount: _posts.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Widgets ───

  Widget _buildGlassQuickAction({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(height: 8),
                  Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppPalette.textPrimary)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPostCard(int index) {
    final post = _posts[index] as Map<String, dynamic>;
    final user = post['user'] as Map<String, dynamic>?;
    final startup = post['startup'] as Map<String, dynamic>?;
    final isLiked = post['isLiked'] == true;
    final likesCount = post['likesCount'] ?? 0;
    final commentsCount = post['_count']?['comments'] ?? 0;
    final createdAt = DateTime.tryParse(post['createdAt'] ?? '');
    
    List<String> mediaUrls = [];
    if (post['mediaUrls'] is List) {
      mediaUrls = (post['mediaUrls'] as List).map((e) => e.toString()).toList();
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => PostDetailScreen(post: post))).then((_) => _loadAll());
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.grey.shade100),
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User row
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppPalette.primaryAccent.withValues(alpha: 0.1),
                child: Text(
                  (user?['name'] ?? 'U').substring(0, 1).toUpperCase(),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppPalette.primaryAccent),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(child: Text(user?['name'] ?? 'Unknown', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: user?['role'] == 'INVESTOR' ? AppPalette.info.withValues(alpha: 0.1) : AppPalette.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            user?['role'] == 'INVESTOR' ? 'Investor' : 'Founder',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: user?['role'] == 'INVESTOR' ? AppPalette.info : AppPalette.success),
                          ),
                        ),
                      ],
                    ),
                    if (createdAt != null)
                      Text(timeago.format(createdAt), style: const TextStyle(fontSize: 11, color: AppPalette.textTerenary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(post['content'] ?? '', style: const TextStyle(fontSize: 15, height: 1.5, color: AppPalette.textPrimary, fontWeight: FontWeight.w400)),

          if (mediaUrls.isNotEmpty)
            FeedMediaGallery(mediaUrls: mediaUrls),

          if (startup != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppPalette.surfaceElevated.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppPalette.surfaceElevated),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(gradient: AppPalette.primaryGradient, borderRadius: BorderRadius.circular(10)),
                    child: Center(child: Text((startup['companyName'] ?? 'S').substring(0, 1), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16))),
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

          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _toggleLike(index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(isLiked ? Iconsax.heart5 : Iconsax.heart, size: 22, color: isLiked ? AppPalette.danger : AppPalette.textSecondary),
                        const SizedBox(width: 8),
                        Text('$likesCount', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isLiked ? AppPalette.danger : AppPalette.textSecondary)),
                      ],
                    ),
                  ),
                ),
              ),
              Container(width: 1, height: 24, color: Colors.grey.shade200),
              Expanded(
                child: GestureDetector(
                  onTap: () => _showComments(index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Iconsax.message, size: 20, color: AppPalette.textSecondary),
                        const SizedBox(width: 8),
                        Text('$commentsCount', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppPalette.textSecondary)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ));
  }
}

// ─── Comment Sheet ───
class _CommentSheet extends StatefulWidget {
  final String postId;
  final ApiService api;
  final TextEditingController controller;
  final VoidCallback onCommentAdded;
  const _CommentSheet({required this.postId, required this.api, required this.controller, required this.onCommentAdded});

  @override
  State<_CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends State<_CommentSheet> {
  List<dynamic> _comments = [];
  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final comments = await widget.api.getComments(widget.postId);
      if (mounted) setState(() { _comments = comments; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _send() async {
    final text = widget.controller.text.trim();
    if (text.isEmpty) return;
    setState(() => _isSending = true);
    try {
      await widget.api.addComment(widget.postId, text);
      widget.controller.clear();
      widget.onCommentAdded();
      await _load();
    } catch (_) {}
    if (mounted) setState(() => _isSending = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 12),
          const Text('Comments', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const Divider(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppPalette.primaryAccent))
                : _comments.isEmpty
                    ? const Center(child: Text('No comments yet', style: TextStyle(color: AppPalette.textSecondary)))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _comments.length,
                        itemBuilder: (_, i) {
                          final c = _comments[i] as Map<String, dynamic>;
                          final u = c['user'] as Map<String, dynamic>?;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(radius: 14, backgroundColor: AppPalette.surfaceElevated, child: Text((u?['name'] ?? 'U').substring(0, 1), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700))),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(u?['name'] ?? 'Unknown', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 2),
                                      Text(c['content'] ?? '', style: const TextStyle(fontSize: 13, height: 1.4)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
          Container(
            padding: EdgeInsets.only(left: 16, right: 8, top: 8, bottom: MediaQuery.of(context).viewInsets.bottom + 8),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey.shade200))),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    decoration: const InputDecoration(hintText: 'Add a comment...', border: InputBorder.none, isDense: true),
                  ),
                ),
                IconButton(
                  onPressed: _isSending ? null : _send,
                  icon: _isSending ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send, color: AppPalette.primaryAccent),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
