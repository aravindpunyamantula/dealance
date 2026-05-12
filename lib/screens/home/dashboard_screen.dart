import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../services/auth_provider.dart';
import '../../utils/app_palette.dart';
import '../../widgets/state_widgets.dart';
import '../profile/profile_screen.dart';
import '../../pages/entrepreneur/pitch_upload2/pitch_problem_step1.dart';
import '../../pages/ideas/idea_detail_screen.dart';
import '../../pages/ai/ai_analysis_screen.dart';
import '../../pages/community/knowledge_hub.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  int _ideaCount = 0;
  int _aiReportCount = 0;
  List<dynamic> _recentIdeas = [];

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() => _isLoading = true);
    try {
      final ideas = await _api.getMyIdeas();
      int aiCount = 0;
      for (final idea in ideas) {
        if (idea['aiReports'] != null && (idea['aiReports'] as List).isNotEmpty) {
          aiCount++;
        }
      }
      if (mounted) {
        setState(() {
          _ideaCount = ideas.length;
          _aiReportCount = aiCount;
          _recentIdeas = ideas.take(3).toList();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppPalette.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadDashboard,
          color: AppPalette.primaryAccent,
          child: CustomScrollView(
            slivers: [
              // App bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hello, ${auth.userName.split(' ').first} 👋',
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: AppPalette.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Ready to pitch something great?',
                              style: TextStyle(fontSize: 14, color: AppPalette.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ProfileScreen()),
                        ),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: AppPalette.primaryGradient,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Text(
                              auth.userName.isNotEmpty ? auth.userName[0].toUpperCase() : 'U',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Stats cards
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: _isLoading
                      ? const ShimmerCard(height: 100)
                      : Row(
                          children: [
                            Expanded(child: _buildStatCard('My Ideas', '$_ideaCount', Icons.lightbulb_outline, AppPalette.primaryAccent)),
                            const SizedBox(width: 12),
                            Expanded(child: _buildStatCard('AI Reports', '$_aiReportCount', Icons.auto_awesome, AppPalette.aiGlow)),
                          ],
                        ),
                ),
              ),

              // Quick actions
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Quick Actions',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppPalette.textPrimary),
                      ),
                      const SizedBox(height: 12),
                      _buildActionCard(
                        'Submit New Idea',
                        'Pitch your startup idea in 5 easy steps',
                        Icons.add_circle_outline,
                        AppPalette.primaryGradient,
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ProblemSolutionForm()),
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      _buildActionCard(
                        'AI Deep Research',
                        'Analyze your idea with AI-powered insights',
                        Icons.auto_awesome,
                        AppPalette.aiGradient,
                        () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const AIAnalysisScreen()));
                        },
                      ),
                      const SizedBox(height: 10),
                      _buildActionCard(
                        'Learning Hub',
                        'Articles, guides, and videos for entrepreneurs',
                        Icons.school_outlined,
                        const LinearGradient(colors: [Color(0xFF00D4AA), Color(0xFF00B4D8)]),
                        () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const KnowledgeHubScreen()));
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Recent ideas
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                  child: const Text(
                    'Recent Ideas',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppPalette.textPrimary),
                  ),
                ),
              ),

              if (_isLoading)
                const SliverToBoxAdapter(child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: ShimmerCard(height: 80),
                ))
              else if (_recentIdeas.isEmpty)
                const SliverToBoxAdapter(
                  child: EmptyStateWidget(
                    icon: Icons.rocket_launch_outlined,
                    title: 'No ideas yet',
                    subtitle: 'Submit your first idea to get started!',
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => _buildRecentIdeaCard(_recentIdeas[i]),
                      childCount: _recentIdeas.length,
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppPalette.surfaceCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: color)),
              Text(label, style: const TextStyle(fontSize: 12, color: AppPalette.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(String title, String subtitle, IconData icon, Gradient gradient, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.white.withOpacity(0.5), size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentIdeaCard(Map<String, dynamic> idea) {
    final status = idea['status'] ?? 'DRAFT';
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => IdeaDetailScreen(idea: idea)),
        );
        if (result == true) _loadDashboard(); // Refresh if idea was modified/deleted
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppPalette.surfaceCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: AppPalette.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  (idea['companyName']?.toString().isNotEmpty == true ? idea['companyName'] : '?')[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    idea['companyName'] ?? 'Untitled',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Step ${idea['currentStep'] ?? 1}/5 • $status',
                    style: const TextStyle(fontSize: 11, color: AppPalette.textSecondary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppPalette.textTerenary, size: 20),
          ],
        ),
      ),
    );
  }

}
