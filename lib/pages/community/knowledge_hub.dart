import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../services/api_service.dart';
import '../../utils/app_palette.dart';

class KnowledgeHubScreen extends StatefulWidget {
  const KnowledgeHubScreen({super.key});

  @override
  State<KnowledgeHubScreen> createState() => _KnowledgeHubScreenState();
}

class _KnowledgeHubScreenState extends State<KnowledgeHubScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final ApiService _api = ApiService();
  late TabController _tabController;

  List<dynamic> _articles = [];
  bool _isLoading = true;
  String _selectedCategory = 'All';

  final categories = ["All", "Article", "Video", "Guide", "Case Study"];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: categories.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadArticles();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    setState(() {
      _selectedCategory = categories[_tabController.index];
    });
    _loadArticles();
  }

  Future<void> _loadArticles() async {
    setState(() => _isLoading = true);
    try {
      final articles = await _api.getArticles(
        type: _selectedCategory == 'All' ? null : _selectedCategory.toUpperCase().replaceAll(' ', '_'),
        search: _searchController.text.isEmpty ? null : _searchController.text,
      );
      if (mounted) {
        setState(() {
          _articles = articles;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppPalette.primaryAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.book, color: AppPalette.primaryAccent, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      "Knowledge Hub",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppPalette.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Search
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => _loadArticles(),
                decoration: InputDecoration(
                  hintText: "Search articles, guides, and videos...",
                  prefixIcon: const Icon(Icons.search, color: AppPalette.primaryAccent),
                  filled: true,
                  fillColor: AppPalette.surfaceCard,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),

            // Tab bar
            Container(
              margin: const EdgeInsets.only(top: 8),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: AppPalette.primaryAccent,
                unselectedLabelColor: AppPalette.textSecondary,
                indicatorColor: AppPalette.primaryAccent,
                indicatorSize: TabBarIndicatorSize.label,
                labelStyle: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 13),
                unselectedLabelStyle: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w400, fontSize: 13),
                tabs: categories.map((c) => Tab(text: c)).toList(),
              ),
            ),

            // Content
            Expanded(
              child: _isLoading
                  ? _buildShimmerList()
                  : _articles.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _loadArticles,
                          color: AppPalette.primaryAccent,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _articles.length,
                            itemBuilder: (context, index) => _buildArticleCard(_articles[index]),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArticleCard(Map<String, dynamic> article) {
    final type = article['type'] ?? 'ARTICLE';
    final isVideo = type == 'VIDEO';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppPalette.surfaceCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail
          if (article['thumbnailUrl'] != null)
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                  child: CachedNetworkImage(
                    imageUrl: article['thumbnailUrl'],
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Shimmer.fromColors(
                      baseColor: Colors.grey.shade200,
                      highlightColor: Colors.grey.shade100,
                      child: Container(height: 160, color: Colors.white),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      height: 160,
                      color: AppPalette.surfaceElevated,
                      child: const Center(child: Icon(Icons.image_not_supported, size: 40, color: AppPalette.textTerenary)),
                    ),
                  ),
                ),
                if (isVideo)
                  Positioned.fill(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.play_arrow, color: Colors.white, size: 32),
                      ),
                    ),
                  ),
                // Type badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getTypeColor(type),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      type.replaceAll('_', ' '),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  article['title'] ?? 'Untitled',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: AppPalette.textPrimary,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  article['description'] ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppPalette.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      isVideo ? Icons.play_circle_outline : Icons.schedule,
                      size: 16,
                      color: AppPalette.textTerenary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      article['duration'] ?? '',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppPalette.textTerenary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (article['author'] != null) ...[
                      const SizedBox(width: 12),
                      const Icon(Icons.person_outline, size: 16, color: AppPalette.textTerenary),
                      const SizedBox(width: 4),
                      Text(
                        article['author'],
                        style: const TextStyle(fontSize: 12, color: AppPalette.textTerenary),
                      ),
                    ],
                    const Spacer(),
                    InkWell(
                      onTap: () {},
                      child: const Icon(Icons.bookmark_border, color: AppPalette.primaryAccent, size: 20),
                    ),
                    const SizedBox(width: 12),
                    InkWell(
                      onTap: () {},
                      child: const Icon(Icons.share_outlined, color: AppPalette.primaryAccent, size: 20),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: Colors.grey.shade200,
        highlightColor: Colors.grey.shade100,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          height: 260,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.article_outlined, size: 64, color: AppPalette.textTerenary),
          const SizedBox(height: 16),
          const Text(
            'No content found',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppPalette.textSecondary),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try adjusting your search or category filter',
            style: TextStyle(color: AppPalette.textTerenary),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'VIDEO':
        return AppPalette.danger;
      case 'GUIDE':
        return AppPalette.success;
      case 'CASE_STUDY':
        return AppPalette.warning;
      default:
        return AppPalette.primaryAccent;
    }
  }
}
