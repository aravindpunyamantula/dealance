import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../utils/app_palette.dart';
import '../../features/chat/chat_list_screen.dart';
import '../../features/chat/chat_room_screen.dart';

class DiscoverInvestorsScreen extends StatefulWidget {
  const DiscoverInvestorsScreen({super.key});

  @override
  State<DiscoverInvestorsScreen> createState() => _DiscoverInvestorsScreenState();
}

class _DiscoverInvestorsScreenState extends State<DiscoverInvestorsScreen> {
  final ApiService _api = ApiService();
  final _searchController = TextEditingController();

  List<dynamic> _investors = [];
  bool _isLoading = true;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await _api.searchInvestors();
      if (mounted) {
        setState(() {
          _investors = results;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _search(String query) async {
    setState(() => _isSearching = true);
    try {
      final results = await _api.searchInvestors(search: query.isEmpty ? null : query);
      if (mounted) setState(() { _investors = results; _isSearching = false; });
    } catch (_) {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _startChat(Map<String, dynamic> investor) async {
    try {
      final room = await _api.getOrCreateDMRoom(investor['id']);
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatRoomScreen(
              roomId: room['id'],
              otherUserName: investor['name'] ?? 'Investor',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start chat: $e'), backgroundColor: AppPalette.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Discover Investors 💎',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Revalia',
                            color: AppPalette.textPrimary,
                          ),
                        ),
                        Text(
                          'Find the right partner for your startup',
                          style: TextStyle(fontSize: 13, color: AppPalette.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatListScreen())),
                    child: Container(
                      width: 42, height: 42,
                      decoration: BoxDecoration(
                        color: AppPalette.surfaceCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: const Icon(Icons.chat_bubble_outline, size: 20, color: AppPalette.textPrimary),
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => _search(val),
                decoration: InputDecoration(
                  hintText: 'Search by name, bio, or industry...',
                  hintStyle: const TextStyle(color: AppPalette.textTerenary, fontSize: 14),
                  prefixIcon: const Icon(Icons.search, color: AppPalette.textSecondary, size: 20),
                  suffixIcon: _isSearching
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppPalette.primaryAccent)),
                        )
                      : null,
                  filled: true,
                  fillColor: AppPalette.surfaceCard,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade100),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade100),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Investor list
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadData,
                color: AppPalette.primaryAccent,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppPalette.primaryAccent))
                    : _investors.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.person_search_outlined, size: 64, color: AppPalette.textTerenary),
                                SizedBox(height: 16),
                                Text('No investors found', style: TextStyle(fontSize: 16, color: AppPalette.textSecondary, fontWeight: FontWeight.w500)),
                                Text('Try a different search term', style: TextStyle(fontSize: 13, color: AppPalette.textTerenary)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
                            itemCount: _investors.length,
                            itemBuilder: (context, index) => _buildInvestorCard(_investors[index]),
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvestorCard(Map<String, dynamic> investor) {
    final name = investor['name'] ?? 'Anonymous Investor';
    final bio = investor['bio'] ?? 'No bio provided.';
    final industryFocus = investor['industryFocus'] ?? 'Generalist';
    final avatar = investor['avatar'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppPalette.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _startChat(investor),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppPalette.info.withOpacity(0.1),
                        backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                        child: avatar == null
                            ? Text(name.substring(0, 1).toUpperCase(), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppPalette.info))
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppPalette.textPrimary)),
                                const SizedBox(width: 6),
                                const Icon(Icons.verified, size: 16, color: AppPalette.info),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppPalette.info.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                industryFocus,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppPalette.info),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _startChat(investor),
                        icon: const Icon(Icons.chat_bubble_outline, color: AppPalette.primaryAccent),
                        style: IconButton.styleFrom(
                          backgroundColor: AppPalette.primaryAccent.withOpacity(0.05),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    bio,
                    style: const TextStyle(fontSize: 14, color: AppPalette.textSecondary, height: 1.5),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildStatChip(Icons.trending_up, 'High Activity'),
                      const SizedBox(width: 8),
                      _buildStatChip(Icons.location_on_outlined, 'Remote / Global'),
                      const Spacer(),
                      const Text(
                        'View Profile',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppPalette.primaryAccent),
                      ),
                      const Icon(Icons.chevron_right, size: 18, color: AppPalette.primaryAccent),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppPalette.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppPalette.textSecondary),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppPalette.textSecondary)),
        ],
      ),
    );
  }
}
