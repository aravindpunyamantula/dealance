import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../utils/app_palette.dart';
import '../../widgets/state_widgets.dart';
import '../entrepreneur/pitch_upload2/pitch_problem_step1.dart';
import '../ai/ai_analysis_screen.dart';
import 'idea_detail_screen.dart';
import '../../features/chat/chat_list_screen.dart';

class MyIdeasScreen extends StatefulWidget {
  const MyIdeasScreen({super.key});

  @override
  State<MyIdeasScreen> createState() => _MyIdeasScreenState();
}

class _MyIdeasScreenState extends State<MyIdeasScreen> {
  final ApiService _api = ApiService();
  List<dynamic> _ideas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadIdeas();
  }

  Future<void> _loadIdeas() async {
    try {
      final ideas = await _api.getMyIdeas();
      if (mounted) setState(() { _ideas = ideas; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const ProblemSolutionForm()));
          _loadIdeas();
        },
        backgroundColor: AppPalette.primaryAccent,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Startup', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadIdeas,
          color: AppPalette.primaryAccent,
          child: CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppPalette.primaryAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.lightbulb, color: AppPalette.primaryAccent, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'My Startups',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: AppPalette.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${_ideas.length} total',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppPalette.textSecondary,
                          fontWeight: FontWeight.w500,
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
                          child: const Icon(Icons.chat_bubble_outline, size: 20, color: AppPalette.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Quick action: Create if empty
              if (!_isLoading && _ideas.isEmpty)
                SliverToBoxAdapter(
                  child: GestureDetector(
                    onTap: () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (_) => const ProblemSolutionForm()));
                      _loadIdeas();
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: AppPalette.primaryGradient,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.rocket_launch, size: 48, color: Colors.white),
                          SizedBox(height: 12),
                          Text('Pitch Your First Startup', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                          SizedBox(height: 6),
                          Text('Submit your startup idea and get AI-powered analysis', style: TextStyle(fontSize: 13, color: Colors.white70), textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  ),
                ),

              // Ideas list
              if (_isLoading)
                const SliverFillRemaining(
                  child: ShimmerList(count: 3, cardHeight: 140),
                )
              else if (_ideas.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildIdeaCard(_ideas[index]),
                      childCount: _ideas.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIdeaCard(Map<String, dynamic> idea) {
    final status = idea['status'] ?? 'DRAFT';
    final hasReport = idea['aiReports'] != null && (idea['aiReports'] as List).isNotEmpty;
    final score = hasReport ? idea['aiReports'][0]['viabilityScore'] : null;

    return Dismissible(
      key: Key(idea['id'] ?? ''),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppPalette.danger,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Delete Idea?'),
            content: const Text('This cannot be undone.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: AppPalette.danger))),
            ],
          ),
        );
      },
      onDismissed: (_) async {
        try {
          await _api.deleteIdea(idea['id']);
          _loadIdeas();
        } catch (_) {}
      },
      child: GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => IdeaDetailScreen(idea: idea)),
        );
        if (result == true) _loadIdeas();
      },
      child: Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppPalette.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row
            Row(
              children: [
                // Company initial
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: AppPalette.primaryGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      (idea['companyName'] ?? idea['oneLiner'] ?? '?')[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        idea['companyName'] ?? 'Untitled Idea',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        idea['tagline'] ?? idea['oneLiner'] ?? 'No description',
                        style: const TextStyle(fontSize: 12, color: AppPalette.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(status),
              ],
            ),
            const SizedBox(height: 14),

            // Info chips
            Row(
              children: [
                _buildInfoChip(Icons.category_outlined, idea['businessType'] ?? 'STARTUP'),
                const SizedBox(width: 8),
                _buildInfoChip(Icons.stairs_outlined, 'Step ${idea['currentStep'] ?? 1}/5'),
                const Spacer(),
                if (score != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      gradient: AppPalette.aiGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.auto_awesome, color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '$score/100',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // Action buttons
            Row(
              children: [
                if (status == 'DRAFT')
                  _buildActionButton('Continue Editing', Icons.edit_outlined, AppPalette.primaryAccent, onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProblemSolutionForm()),
                    );
                  }),
                if (status == 'DRAFT') const SizedBox(width: 8),
                if (status == 'DRAFT')
                  _buildActionButton('Submit', Icons.send_outlined, AppPalette.success, onTap: () async {
                    try {
                      await _api.submitIdea(idea['id']);
                      _loadIdeas();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Idea submitted successfully!'),
                            backgroundColor: AppPalette.success,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                      }
                    } catch (_) {}
                  }),
                if (status != 'DRAFT' && !hasReport)
                  _buildActionButton('AI Analyze', Icons.auto_awesome, AppPalette.aiGlow, onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AIAnalysisScreen()));
                  }),
                if (hasReport)
                  _buildActionButton('View Report', Icons.assessment_outlined, AppPalette.primaryAccent, onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AIAnalysisScreen()));
                  }),
              ],
            ),
          ],
        ),
      ),
    ), // Container
    ), // GestureDetector
    ); // Dismissible
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'SUBMITTED':
        color = AppPalette.info;
        break;
      case 'UNDER_REVIEW':
        color = AppPalette.warning;
        break;
      case 'APPROVED':
        color = AppPalette.success;
        break;
      case 'REJECTED':
        color = AppPalette.danger;
        break;
      default:
        color = AppPalette.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.replaceAll('_', ' '),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppPalette.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppPalette.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppPalette.textSecondary, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, {VoidCallback? onTap}) {
    return Expanded(
      child: InkWell(
        onTap: onTap ?? () {},
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
