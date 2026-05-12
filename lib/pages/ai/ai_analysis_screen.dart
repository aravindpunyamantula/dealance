import 'dart:async';
import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../../services/api_service.dart';
import '../../utils/app_palette.dart';
import '../../widgets/state_widgets.dart';

class AIAnalysisScreen extends StatefulWidget {
  const AIAnalysisScreen({super.key});

  @override
  State<AIAnalysisScreen> createState() => _AIAnalysisScreenState();
}

class _AIAnalysisScreenState extends State<AIAnalysisScreen>
    with TickerProviderStateMixin {
  final ApiService _api = ApiService();
  List<dynamic> _ideas = [];
  bool _isLoading = true;
  Map<String, dynamic>? _selectedReport;
  String? _selectedIdeaId;
  String? _analysisStatus;
  String? _errorMessage;
  Timer? _pollTimer;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _loadIdeas();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadIdeas() async {
    try {
      final ideas = await _api.getMyIdeas();
      if (mounted) {
        setState(() {
          _ideas = ideas;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _parseError(dynamic e) {
    final raw = e.toString();
    if (raw.contains('429') || raw.contains('RESOURCE_EXHAUSTED') || raw.contains('quota')) {
      return 'AI quota exceeded. The free tier has limited requests.\n\nPlease wait 1-2 minutes and try again, or upgrade your Gemini API key at ai.google.dev';
    }
    if (raw.contains('timed out') || raw.contains('timeout')) {
      return 'AI analysis timed out. Please try again.';
    }
    if (raw.contains('SocketException') || raw.contains('Connection refused')) {
      return 'Cannot reach the server. Please check your connection.';
    }
    // Try to extract a clean error message
    final match = RegExp(r'"error":\s*"([^"]+)"').firstMatch(raw);
    if (match != null) return match.group(1)!;
    final msgMatch = RegExp(r'"message":\s*"([^"]{1,100})').firstMatch(raw);
    if (msgMatch != null) return msgMatch.group(1)!;
    return 'Analysis failed. Please try again later.';
  }

  Future<void> _triggerAnalysis(String ideaId) async {
    setState(() {
      _selectedIdeaId = ideaId;
      _analysisStatus = 'PROCESSING';
      _selectedReport = null;
      _errorMessage = null;
    });

    try {
      await _api.triggerAIAnalysis(ideaId);
      _startPolling(ideaId);
    } catch (e) {
      setState(() {
        _analysisStatus = 'FAILED';
        _errorMessage = _parseError(e);
      });
    }
  }

  void _startPolling(String ideaId) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      try {
        final report = await _api.getAIReport(ideaId);
        if (report['status'] == 'COMPLETE') {
          _pollTimer?.cancel();
          setState(() {
            _analysisStatus = 'COMPLETE';
            _selectedReport = report['parsedReport'];
          });
          // Reload ideas list to update badges
          _loadIdeas();
        } else if (report['status'] == 'FAILED') {
          _pollTimer?.cancel();
          setState(() {
            _analysisStatus = 'FAILED';
            _errorMessage = report['errorMessage'] ?? 'Analysis failed. Please try again.';
          });
        }
      } catch (_) {}
    });
  }

  Future<void> _loadExistingReport(String ideaId) async {
    setState(() {
      _selectedIdeaId = ideaId;
      _analysisStatus = 'LOADING';
      _errorMessage = null;
    });

    try {
      final report = await _api.getAIReport(ideaId);
      setState(() {
        _analysisStatus = report['status'];
        if (report['parsedReport'] != null) {
          _selectedReport = report['parsedReport'];
        }
        if (report['status'] == 'FAILED') {
          _errorMessage = report['errorMessage'] ?? 'Analysis failed.';
        }
      });
    } catch (_) {
      setState(() => _analysisStatus = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.background,
      appBar: (_selectedReport != null || _analysisStatus == 'PROCESSING' || _analysisStatus == 'FAILED')
          ? null // These views build their own headers/appbars
          : AppBar(
              backgroundColor: AppPalette.background,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: AppPalette.textPrimary),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text('AI Analysis', style: TextStyle(color: AppPalette.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
            ),
      body: SafeArea(
        child: _isLoading
            ? const ShimmerList(count: 3, cardHeight: 80)
            : _selectedReport != null
                ? _buildReportView()
                : _analysisStatus == 'PROCESSING'
                    ? _buildProcessingView()
                    : _analysisStatus == 'FAILED'
                        ? _buildFailedView()
                        : _buildIdeasList(),
      ),
    );
  }

  Widget _buildFailedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppPalette.danger.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline, color: AppPalette.danger, size: 48),
            ),
            const SizedBox(height: 24),
            const Text(
              'Analysis Failed',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppPalette.textPrimary),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Something went wrong. Please try again.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppPalette.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: () => setState(() {
                    _analysisStatus = null;
                    _errorMessage = null;
                  }),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  child: const Text('Go Back', style: TextStyle(color: AppPalette.textSecondary)),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    if (_selectedIdeaId != null) _triggerAnalysis(_selectedIdeaId!);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppPalette.primaryAccent,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Retry', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIdeasList() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: AppPalette.aiGradient,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.auto_awesome, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI Deep Research',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: AppPalette.textPrimary,
                            ),
                          ),
                          Text(
                            'Analyze your ideas with AI',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppPalette.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Info card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: AppPalette.aiGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.lightbulb_outline, color: Colors.white, size: 24),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Our AI analyzes your idea against competitors, market trends, and success patterns to give you actionable insights.',
                          style: TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                const Text(
                  'Select an idea to analyze',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppPalette.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_ideas.isEmpty)
          const SliverFillRemaining(
            child: EmptyStateWidget(
              icon: Icons.lightbulb_outline,
              title: 'No ideas yet',
              subtitle: 'Create an idea first, then come back to analyze it with AI.',
            ),
          ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildIdeaCard(_ideas[index]),
              childCount: _ideas.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIdeaCard(Map<String, dynamic> idea) {
    final hasReport = idea['aiReports'] != null &&
        (idea['aiReports'] as List).isNotEmpty;
    final reportStatus = hasReport ? idea['aiReports'][0]['status'] : null;
    final score = hasReport ? idea['aiReports'][0]['viabilityScore'] : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppPalette.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (reportStatus == 'COMPLETE') {
              _loadExistingReport(idea['id']);
            } else {
              _triggerAnalysis(idea['id']);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppPalette.primaryAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      (idea['companyName'] ?? idea['oneLiner'] ?? '?')[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppPalette.primaryAccent,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        idea['companyName'] ?? idea['oneLiner'] ?? 'Untitled Idea',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppPalette.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        idea['businessType'] ?? 'STARTUP',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppPalette.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status
                if (reportStatus == 'COMPLETE' && score != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getScoreColor(score).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$score/100',
                      style: TextStyle(
                        color: _getScoreColor(score),
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: AppPalette.aiGradient,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Analyze',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProcessingView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated scanning effect
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppPalette.aiGradient,
                    boxShadow: [
                      BoxShadow(
                        color: AppPalette.aiGlow.withOpacity(0.3 * _pulseController.value),
                        blurRadius: 30 + (20 * _pulseController.value),
                        spreadRadius: 5 * _pulseController.value,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.auto_awesome, color: Colors.white, size: 48),
                );
              },
            ),
            const SizedBox(height: 32),
            const Text(
              'Analyzing Your Idea...',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppPalette.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Our AI is deep-searching the market,\nanalyzing competitors, and calculating\nyour viability score.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppPalette.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            const SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                backgroundColor: Color(0xFFE8E8EE),
                valueColor: AlwaysStoppedAnimation<Color>(AppPalette.primaryAccent),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportView() {
    final report = _selectedReport!;
    final score = report['viabilityScore'] ?? 50;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: AppPalette.surfaceCard,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 20),
            onPressed: () => setState(() {
              _selectedReport = null;
              _selectedIdeaId = null;
              _analysisStatus = null;
            }),
          ),
          title: const Text('AI Analysis Report'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, size: 22, color: AppPalette.primaryAccent),
              onPressed: () {
                if (_selectedIdeaId != null) {
                  _triggerAnalysis(_selectedIdeaId!);
                }
              },
              tooltip: 'Recalculate Score',
            ),
            const SizedBox(width: 8),
          ],
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Score Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: AppPalette.aiGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      CircularPercentIndicator(
                        radius: 45,
                        lineWidth: 8,
                        percent: score / 100,
                        center: Text(
                          '$score',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        progressColor: Colors.white,
                        backgroundColor: Colors.white24,
                        circularStrokeCap: CircularStrokeCap.round,
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Viability Score',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _getScoreLabel(score),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              report['investmentReadiness'] ?? '',
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Executive Summary
                _buildSection(
                  'Executive Summary',
                  Icons.description_outlined,
                  child: Text(
                    report['executiveSummary']?.toString() ?? 'No summary available.',
                    style: const TextStyle(fontSize: 14, height: 1.6, color: AppPalette.textPrimary),
                  ),
                ),

                // Competitors
                if (report['existingCompetitors'] != null)
                  _buildSection(
                    'Competitors Found',
                    Icons.groups_outlined,
                    child: Column(
                      children: (report['existingCompetitors'] as List)
                          .map<Widget>((c) => _buildCompetitorCard(c))
                          .toList(),
                    ),
                  ),

                // Market Analysis
                if (report['marketAnalysis'] != null)
                  _buildSection(
                    'Market Analysis',
                    Icons.trending_up,
                    child: _buildMarketAnalysis(report['marketAnalysis']),
                  ),

                // Strengths & Weaknesses
                if (report['strengthsAndWeaknesses'] != null) ...[
                  _buildSection(
                    'Strengths',
                    Icons.thumb_up_outlined,
                    child: _buildChipList(
                      report['strengthsAndWeaknesses']?['strengths'],
                      AppPalette.success,
                    ),
                  ),
                  _buildSection(
                    'Weaknesses',
                    Icons.thumb_down_outlined,
                    child: _buildChipList(
                      report['strengthsAndWeaknesses']?['weaknesses'],
                      AppPalette.warning,
                    ),
                  ),
                ],

                // Risks
                if (report['risks'] != null)
                  _buildSection(
                    'Risks',
                    Icons.warning_amber_outlined,
                    child: _buildChipList(
                      report['risks'],
                      AppPalette.danger,
                    ),
                  ),

                // Recommendations
                if (report['recommendations'] != null)
                  _buildSection(
                    'Recommendations',
                    Icons.tips_and_updates_outlined,
                    child: Column(
                      children: (report['recommendations'] is List
                              ? report['recommendations'] as List
                              : [report['recommendations']])
                          .asMap()
                          .entries
                          .map<Widget>((entry) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 24,
                                      margin: const EdgeInsets.only(right: 10, top: 2),
                                      decoration: BoxDecoration(
                                        color: AppPalette.primaryAccent.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${entry.key + 1}',
                                          style: const TextStyle(
                                            color: AppPalette.primaryAccent,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        entry.value.toString(),
                                        style: const TextStyle(fontSize: 13, height: 1.5),
                                      ),
                                    ),
                                  ],
                                ),
                              ))
                          .toList(),
                    ),
                  ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSection(String title, IconData icon, {required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPalette.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppPalette.primaryAccent),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppPalette.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildCompetitorCard(Map<String, dynamic> competitor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppPalette.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Similarity badge
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _getScoreColor(competitor['similarity'] ?? 50).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '${competitor['similarity'] ?? '?'}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _getScoreColor(competitor['similarity'] ?? 50),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  competitor['name']?.toString() ?? 'Unknown',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                if (competitor['description'] != null)
                  Text(
                    competitor['description'].toString(),
                    style: const TextStyle(fontSize: 12, color: AppPalette.textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketAnalysis(Map<String, dynamic> market) {
    return Column(
      children: [
        _buildMarketRow('Market Size', market['marketSize']),
        _buildMarketRow('Growth Rate', market['growthRate']),
        _buildMarketRow('Target', market['targetDemographic']),
        if (market['marketTrends'] != null)
          _buildMarketRow('Trends', market['marketTrends']),
      ],
    );
  }

  Widget _buildMarketRow(String label, dynamic rawValue) {
    String value = 'N/A';
    if (rawValue != null) {
      if (rawValue is List) {
        value = rawValue.map((e) => e.toString()).join(', ');
      } else {
        value = rawValue.toString();
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppPalette.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, color: AppPalette.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChipList(dynamic rawItems, Color color) {
    List<String> items = [];
    if (rawItems is List) {
      items = rawItems.map((e) => e.toString()).toList();
    } else if (rawItems != null) {
      items = [rawItems.toString()];
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items
          .map((item) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  item,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ))
          .toList(),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 70) return AppPalette.success;
    if (score >= 40) return AppPalette.warning;
    return AppPalette.danger;
  }

  String _getScoreLabel(int score) {
    if (score >= 80) return 'Excellent Potential';
    if (score >= 60) return 'Good Potential';
    if (score >= 40) return 'Moderate Potential';
    return 'Needs Work';
  }
}
