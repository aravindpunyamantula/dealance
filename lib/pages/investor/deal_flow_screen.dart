import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../utils/app_palette.dart';
import 'idea_investor_view.dart';
import 'nda_sign_screen.dart';
import '../../features/chat/chat_list_screen.dart';
import 'package:iconsax/iconsax.dart';

class DealFlowScreen extends StatefulWidget {
  const DealFlowScreen({super.key});

  @override
  State<DealFlowScreen> createState() => _DealFlowScreenState();
}

class _DealFlowScreenState extends State<DealFlowScreen> {
  final ApiService _api = ApiService();
  List<dynamic> _ideas = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  Future<void> _loadFeed() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final feed = await _api.getDealFlowFeed();
      if (mounted) setState(() { _ideas = feed; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadFeed,
          color: AppPalette.primaryAccent,
          child: CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Deal Flow',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Revalia',
                                color: AppPalette.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_ideas.length} opportunities available',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppPalette.textSecondary,
                              ),
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
                          child: const Icon(Iconsax.message, size: 20, color: AppPalette.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Loading
              if (_isLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: AppPalette.primaryAccent)),
                ),

              // Error
              if (_error != null && !_isLoading)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: AppPalette.danger),
                        const SizedBox(height: 12),
                        Text('Failed to load feed', style: TextStyle(color: AppPalette.textSecondary)),
                        const SizedBox(height: 12),
                        ElevatedButton(onPressed: _loadFeed, child: const Text('Retry')),
                      ],
                    ),
                  ),
                ),

              // Empty
              if (!_isLoading && _error == null && _ideas.isEmpty)
                const SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_outlined, size: 64, color: AppPalette.textTerenary),
                        SizedBox(height: 12),
                        Text(
                          'No deals available yet',
                          style: TextStyle(fontSize: 16, color: AppPalette.textSecondary),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Pull down to refresh',
                          style: TextStyle(fontSize: 13, color: AppPalette.textTerenary),
                        ),
                      ],
                    ),
                  ),
                ),

              // Feed cards
              if (!_isLoading && _error == null && _ideas.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildDealCard(_ideas[index]),
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

  Widget _buildDealCard(Map<String, dynamic> idea) {
    final visibility = idea['visibility'] ?? 'PUBLIC';
    final isNdaLocked = visibility == 'NDA_REQUIRED' && idea['ndaSigned'] != true;
    final aiScore = idea['aiScore'];
    final companyName = idea['companyName'] ?? 'Untitled Startup';
    final industry = idea['industry'] ?? 'Unknown';
    final stage = idea['stage'] ?? 'Early';
    final tagline = idea['tagline'] ?? '';
    final fundingAmount = idea['fundingAmount'];

    return GestureDetector(
      onTap: () async {
        if (isNdaLocked) {
          // Navigate to NDA signing
          final signed = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => NDASignScreen(ideaId: idea['id'], companyName: companyName)),
          );
          if (signed == true) _loadFeed();
        } else {
          // Navigate to full detail
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => IdeaInvestorView(ideaId: idea['id'])),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppPalette.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: name + score
            Row(
              children: [
                // Company avatar
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: AppPalette.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      companyName.isNotEmpty ? companyName[0].toUpperCase() : 'S',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        companyName,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppPalette.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$industry · $stage',
                        style: const TextStyle(fontSize: 12, color: AppPalette.textSecondary),
                      ),
                    ],
                  ),
                ),
                if (aiScore != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _scoreColor(aiScore).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$aiScore/100',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _scoreColor(aiScore),
                      ),
                    ),
                  ),
              ],
            ),

            if (tagline.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                isNdaLocked ? 'NDA required to view details' : tagline,
                style: TextStyle(
                  fontSize: 13,
                  color: isNdaLocked ? AppPalette.warning : AppPalette.textSecondary,
                  fontStyle: isNdaLocked ? FontStyle.italic : FontStyle.normal,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            const SizedBox(height: 12),

            // Bottom row: funding ask + visibility badge
            Row(
              children: [
                if (fundingAmount != null) ...[
                  Icon(Icons.attach_money, size: 14, color: AppPalette.success),
                  const SizedBox(width: 2),
                  Text(
                    fundingAmount.toString(),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppPalette.success),
                  ),
                  const Spacer(),
                ] else
                  const Spacer(),

                _buildVisibilityBadge(visibility, isNdaLocked),
              ],
            ),

            if (!isNdaLocked) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: () => _showMakeOfferSheet(idea),
                        icon: const Icon(Icons.handshake, size: 16),
                        label: const Text('Make Deal', style: TextStyle(fontWeight: FontWeight.w600)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppPalette.primaryAccent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: OutlinedButton.icon(
                        onPressed: () => _showAIReviewSheet(idea),
                        icon: const Icon(Icons.auto_awesome, size: 16),
                        label: const Text('AI Report', style: TextStyle(fontWeight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppPalette.primaryAccent,
                          side: const BorderSide(color: AppPalette.primaryAccent),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVisibilityBadge(String visibility, bool isLocked) {
    Color color;
    String label;
    IconData icon;

    switch (visibility) {
      case 'NDA_REQUIRED':
        color = isLocked ? AppPalette.warning : AppPalette.success;
        label = isLocked ? 'NDA Required' : 'NDA Signed';
        icon = isLocked ? Iconsax.lock : Iconsax.unlock;
        break;
      case 'INVITE_ONLY':
        color = AppPalette.primaryAccent;
        label = 'Invited';
        icon = Iconsax.sms;
        break;
      default:
        color = AppPalette.success;
        label = 'Public';
        icon = Iconsax.global;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Color _scoreColor(int score) {
    if (score >= 75) return AppPalette.success;
    if (score >= 50) return AppPalette.warning;
    return AppPalette.danger;
  }

  void _showAIReviewSheet(Map<String, dynamic> idea) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AIReviewSheet(ideaId: idea['id'], companyName: idea['companyName'] ?? 'Startup'),
    );
  }

  void _showMakeOfferSheet(Map<String, dynamic> idea) {
    final amountController = TextEditingController();
    final equityController = TextEditingController();
    final notesController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Text('Make a Deal with ${idea['companyName'] ?? 'Startup'}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Investment Amount (\$)',
                  filled: true, fillColor: AppPalette.surfaceElevated,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: equityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Equity Offered (%)',
                  filled: true, fillColor: AppPalette.surfaceElevated,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Notes / Terms',
                  filled: true, fillColor: AppPalette.surfaceElevated,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () async {
                    if (amountController.text.isEmpty) return;
                    try {
                      await _api.createDeal({
                        'startupId': idea['id'],
                        'entrepreneurId': idea['userId'],
                        'investmentAmount': amountController.text.trim(),
                        'equityOffered': equityController.text.trim(),
                        'notes': notesController.text.trim(),
                      });
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('✅ Deal request sent!'), backgroundColor: AppPalette.success, behavior: SnackBarBehavior.floating),
                        );
                      }
                    } catch (e) {
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e'), backgroundColor: AppPalette.danger, behavior: SnackBarBehavior.floating),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppPalette.primaryAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: const Text('Submit Deal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
