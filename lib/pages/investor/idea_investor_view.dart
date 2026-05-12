import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_service.dart';
import '../../utils/app_palette.dart';
import '../../features/chat/chat_room_screen.dart';
import 'package:iconsax/iconsax.dart';

class IdeaInvestorView extends StatefulWidget {
  final String ideaId;
  const IdeaInvestorView({super.key, required this.ideaId});

  @override
  State<IdeaInvestorView> createState() => _IdeaInvestorViewState();
}

class _IdeaInvestorViewState extends State<IdeaInvestorView> {
  final ApiService _api = ApiService();
  Map<String, dynamic>? _idea;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadIdea();
  }

  Future<void> _loadIdea() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final idea = await _api.getIdeaForInvestor(widget.ideaId);
      if (mounted) setState(() { _idea = idea; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _launchUrl(String url) async {
    if (!url.startsWith('http')) url = 'https://$url';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.background,
      appBar: AppBar(
        title: Text(_idea?['companyName'] ?? 'Loading...'),
        backgroundColor: AppPalette.background,
        foregroundColor: AppPalette.textPrimary,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppPalette.primaryAccent))
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : _idea == null
                  ? const Center(child: Text('Idea not found'))
                  : _buildContent(),
    );
  }

  Widget _buildContent() {
    final idea = _idea!;
    final user = idea['user'] as Map<String, dynamic>?;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Company header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppPalette.primaryGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  idea['companyName'] ?? 'Untitled',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white),
                ),
                if (idea['tagline'] != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    idea['tagline'],
                    style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.9)),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildHeaderChip(idea['industry'] ?? 'Unknown', Icons.business),
                    const SizedBox(width: 8),
                    _buildHeaderChip(idea['stage'] ?? 'Early', Icons.trending_up),
                    if (idea['businessModel'] != null) ...[
                      const SizedBox(width: 8),
                      _buildHeaderChip(idea['businessModel'], Icons.monetization_on),
                    ],
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Problem & Solution
          if (idea['detailedProblem'] != null)
            _buildSection('The Problem', Icons.warning_amber_outlined, idea['detailedProblem']),
          if (idea['solution'] != null)
            _buildSection('The Solution', Icons.lightbulb_outline, idea['solution']),
          if (idea['productDescription'] != null)
            _buildSection('Product', Icons.devices, idea['productDescription']),

          // Traction
          if (idea['currentCustomers'] != null || idea['revenue'] != null)
            _buildMetricsCard(idea),

          // Financials
          if (idea['fundingAmount'] != null)
            _buildFinancialCard(idea),

          // Team
          if (idea['founderName'] != null)
            _buildTeamCard(idea),

          // Founder contact & social links
          if (user != null) _buildFounderCard(user),

          // ─── CTA Buttons ───
          const SizedBox(height: 8),
          
          // AI Review Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () => _showAIReviewSheet(idea),
              icon: const Icon(Iconsax.magic_star, size: 18),
              label: const Text('AI Review & Analysis', style: TextStyle(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppPalette.surfaceCard,
                foregroundColor: AppPalette.primaryAccent,
                side: BorderSide(color: AppPalette.primaryAccent.withValues(alpha: 0.3)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () => _showMakeOfferSheet(idea),
                    icon: const Icon(Icons.handshake_outlined, size: 18),
                    label: const Text('Make Offer', style: TextStyle(fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppPalette.primaryAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: () => _startChat(user),
                    icon: const Icon(Iconsax.message, size: 18),
                    label: const Text('Message', style: TextStyle(fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppPalette.primaryAccent,
                      side: const BorderSide(color: AppPalette.primaryAccent, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
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
              Text('Make an Offer to ${idea['companyName']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
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
                          const SnackBar(content: Text('✅ Offer sent!'), backgroundColor: AppPalette.success, behavior: SnackBarBehavior.floating),
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
                  child: const Text('Submit Offer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _startChat(Map<String, dynamic>? user) async {
    if (user == null || user['id'] == null) return;
    try {
      final room = await _api.getOrCreateDMRoom(user['id']);
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatRoomScreen(
              roomId: room['id'],
              otherUserName: user['name'] ?? 'Founder',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppPalette.danger, behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  Widget _buildHeaderChip(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPalette.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 18, color: AppPalette.primaryAccent),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppPalette.textPrimary)),
          ]),
          const SizedBox(height: 10),
          Text(content, style: const TextStyle(fontSize: 13, height: 1.6, color: AppPalette.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildMetricsCard(Map<String, dynamic> idea) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPalette.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Iconsax.chart, size: 18, color: AppPalette.primaryAccent),
            const SizedBox(width: 8),
            const Text('Traction', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppPalette.textPrimary)),
          ]),
          const SizedBox(height: 12),
          Row(
            children: [
              if (idea['currentCustomers'] != null) _buildMetric('Customers', idea['currentCustomers']),
              if (idea['revenue'] != null) _buildMetric('Revenue', idea['revenue']),
              if (idea['growthRate'] != null) _buildMetric('Growth', idea['growthRate']),
              if (idea['dailyActiveUsers'] != null) _buildMetric('DAU', idea['dailyActiveUsers'].toString()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppPalette.primaryAccent)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: AppPalette.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildFinancialCard(Map<String, dynamic> idea) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPalette.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Iconsax.bank, size: 18, color: AppPalette.success),
            const SizedBox(width: 8),
            const Text('Financials', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppPalette.textPrimary)),
          ]),
          const SizedBox(height: 12),
          if (idea['fundingAmount'] != null) _buildInfoRow('Funding Ask', idea['fundingAmount']),
          if (idea['currentValuation'] != null) _buildInfoRow('Valuation', idea['currentValuation']),
          if (idea['fundingType'] != null) _buildInfoRow('Type', idea['fundingType']),
          if (idea['equityOffered'] != null) _buildInfoRow('Equity', idea['equityOffered']),
        ],
      ),
    );
  }

  Widget _buildTeamCard(Map<String, dynamic> idea) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPalette.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Iconsax.people, size: 18, color: AppPalette.primaryAccent),
            const SizedBox(width: 8),
            const Text('Team', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppPalette.textPrimary)),
          ]),
          const SizedBox(height: 12),
          if (idea['founderName'] != null) _buildInfoRow('Founder', idea['founderName']),
          if (idea['founderEmail'] != null) _buildInfoRow('Email', idea['founderEmail']),
        ],
      ),
    );
  }

  Widget _buildFounderCard(Map<String, dynamic> user) {
    final hasAnySocial = user['linkedIn'] != null ||
        user['twitter'] != null ||
        user['instagram'] != null ||
        user['website'] != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPalette.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppPalette.primaryAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Iconsax.sms, size: 18, color: AppPalette.primaryAccent),
            const SizedBox(width: 8),
            const Text('Contact Founder', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppPalette.textPrimary)),
          ]),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppPalette.primaryAccent.withValues(alpha: 0.1),
                child: Text(
                  (user['name'] ?? 'U').substring(0, 1).toUpperCase(),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppPalette.primaryAccent),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user['name'] ?? 'Unknown', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  if (user['email'] != null)
                    Text(user['email'], style: const TextStyle(fontSize: 12, color: AppPalette.textSecondary)),
                ],
              ),
            ],
          ),

          // Social links
          if (hasAnySocial) ...[
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 14),
            Row(
              children: [
                if (user['linkedIn'] != null)
                  _buildSocialButton('LinkedIn', Icons.link, user['linkedIn'], const Color(0xFF0A66C2)),
                if (user['twitter'] != null)
                  _buildSocialButton('Twitter', Icons.alternate_email, user['twitter'], const Color(0xFF1DA1F2)),
                if (user['instagram'] != null)
                  _buildSocialButton('Instagram', Icons.camera_alt_outlined, user['instagram'], const Color(0xFFE1306C)),
                if (user['website'] != null)
                  _buildSocialButton('Website', Icons.language, user['website'], AppPalette.primaryAccent),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSocialButton(String label, IconData icon, String url, Color color) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _launchUrl(url),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(label, style: const TextStyle(fontSize: 12, color: AppPalette.textSecondary, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppPalette.textPrimary)),
          ),
        ],
      ),
    );
  }
}

class AIReviewSheet extends StatefulWidget {
  final String ideaId;
  final String companyName;

  const AIReviewSheet({super.key, required this.ideaId, required this.companyName});

  @override
  State<AIReviewSheet> createState() => _AIReviewSheetState();
}

class _AIReviewSheetState extends State<AIReviewSheet> {
  final ApiService _api = ApiService();
  String? _report;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchReview();
  }

  Future<void> _fetchReview() async {
    try {
      final report = await _api.getInvestorAIReview(widget.ideaId);
      if (mounted) setState(() { _report = report; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: AppPalette.primaryAccent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'AI Review: ${widget.companyName}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppPalette.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Divider(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: AppPalette.primaryAccent),
                        SizedBox(height: 16),
                        Text('Analyzing startup data...', style: TextStyle(color: AppPalette.textSecondary)),
                      ],
                    ),
                  )
                : _error != null
                    ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('Failed to load review: $_error', textAlign: TextAlign.center, style: const TextStyle(color: AppPalette.danger))))
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        physics: const BouncingScrollPhysics(),
                        child: MarkdownBody(
                          data: _report ?? 'No content',
                          styleSheet: MarkdownStyleSheet(
                            h1: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppPalette.textPrimary),
                            h2: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppPalette.textPrimary, height: 1.5),
                            h3: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppPalette.textPrimary),
                            p: const TextStyle(fontSize: 14, color: AppPalette.textSecondary, height: 1.6),
                            listBullet: const TextStyle(color: AppPalette.primaryAccent),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

