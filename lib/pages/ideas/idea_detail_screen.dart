import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../utils/app_palette.dart';
import '../../utils/app_palette.dart';
import 'package:iconsax/iconsax.dart';
class IdeaDetailScreen extends StatefulWidget {
  final Map<String, dynamic> idea;
  const IdeaDetailScreen({super.key, required this.idea});

  @override
  State<IdeaDetailScreen> createState() => _IdeaDetailScreenState();
}

class _IdeaDetailScreenState extends State<IdeaDetailScreen> {
  final ApiService _api = ApiService();
  late Map<String, dynamic> _idea;

  @override
  void initState() {
    super.initState();
    _idea = widget.idea;
    _loadFull();
  }

  Future<void> _loadFull() async {
    try {
      final full = await _api.getIdea(_idea['id']);
      if (mounted) setState(() => _idea = full);
    } catch (_) {}
  }

  Future<void> _deleteIdea() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Idea?'),
        content: const Text('This action cannot be undone. All data for this idea will be permanently deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppPalette.danger)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await _api.deleteIdea(_idea['id']);
        if (mounted) Navigator.pop(context, true); // true = was deleted
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete: $e'), backgroundColor: AppPalette.danger),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _idea['status'] ?? 'DRAFT';
    final hasReport = _idea['aiReports'] != null && (_idea['aiReports'] as List).isNotEmpty;
    final score = hasReport ? _idea['aiReports'][0]['viabilityScore'] : null;

    return Scaffold(
      backgroundColor: AppPalette.background,
      body: CustomScrollView(
        slivers: [
          // App bar
          SliverAppBar(
            backgroundColor: AppPalette.background,
            elevation: 0,
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, size: 20, color: AppPalette.textPrimary),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(_idea['companyName'] ?? 'Idea Details'),
            centerTitle: true,
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(Iconsax.more, color: AppPalette.textPrimary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onSelected: (val) {
                  if (val == 'delete') _deleteIdea();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'delete', child: Row(
                    children: [
                      Icon(Iconsax.trash, color: AppPalette.danger, size: 20),
                      SizedBox(width: 8),
                      Text('Delete Idea', style: TextStyle(color: AppPalette.danger)),
                    ],
                  )),
                ],
              ),
            ],
          ),

          // Header card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppPalette.surfaceCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade100),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 56, height: 56,
                          decoration: BoxDecoration(
                            gradient: AppPalette.primaryGradient,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(child: Text(
                            (_idea['companyName'] ?? '?')[0].toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700),
                          )),
                        ),
                        const SizedBox(width: 16),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_idea['companyName'] ?? 'Untitled', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                            if (_idea['tagline'] != null)
                              Text(_idea['tagline'], style: const TextStyle(fontSize: 13, color: AppPalette.textSecondary)),
                          ],
                        )),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildChip(_statusLabel(status), _statusColor(status)),
                        const SizedBox(width: 8),
                        _buildChip(_idea['businessType'] ?? 'STARTUP', AppPalette.textSecondary),
                        const SizedBox(width: 8),
                        _buildChip('Step ${_idea['currentStep'] ?? 1}/5', AppPalette.primaryAccent),
                      ],
                    ),
                    if (score != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: AppPalette.aiGradient,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(children: [
                          const Icon(Iconsax.magic_star, color: Colors.white, size: 20),
                          const SizedBox(width: 10),
                          Text('AI Viability Score: $score/100',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
                        ]),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // One-liner
          if (_idea['oneLiner'] != null)
            SliverToBoxAdapter(child: _buildSection('Problem Statement', _idea['oneLiner'])),

          // Detailed problem
          if (_idea['detailedProblem'] != null)
            SliverToBoxAdapter(child: _buildSection('Detailed Problem', _idea['detailedProblem'])),

          // Solution
          if (_idea['solution'] != null || _idea['productDescription'] != null)
            SliverToBoxAdapter(child: _buildSection('Solution', _idea['solution'] ?? _idea['productDescription'])),

          // Market info
          if (_idea['industry'] != null)
            SliverToBoxAdapter(child: _buildSection('Industry', _idea['industry'])),
          if (_idea['targetGeography'] != null)
            SliverToBoxAdapter(child: _buildSection('Target Geography', _idea['targetGeography'])),
          if (_idea['businessModel'] != null)
            SliverToBoxAdapter(child: _buildSection('Business Model', _idea['businessModel'])),

          // Traction
          if (_idea['stage'] != null)
            SliverToBoxAdapter(child: _buildSection('Stage', _idea['stage'])),
          if (_idea['currentCustomers'] != null)
            SliverToBoxAdapter(child: _buildSection('Current Customers', _idea['currentCustomers'])),
          if (_idea['revenue'] != null)
            SliverToBoxAdapter(child: _buildSection('Revenue', _idea['revenue'])),

          // Financial
          if (_idea['currentValuation'] != null)
            SliverToBoxAdapter(child: _buildSection('Valuation', _idea['currentValuation'])),
          if (_idea['fundingAmount'] != null)
            SliverToBoxAdapter(child: _buildSection('Funding Ask', _idea['fundingAmount'])),
          if (_idea['useOfFunds'] != null)
            SliverToBoxAdapter(child: _buildSection('Use of Funds', _idea['useOfFunds'])),

          // Timestamps
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                'Created: ${_formatDate(_idea['createdAt'])}  •  Updated: ${_formatDate(_idea['updatedAt'])}',
                style: const TextStyle(fontSize: 11, color: AppPalette.textTerenary),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),

      // Bottom action bar
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppPalette.surfaceCard,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))],
        ),
        child: Row(children: [
          if (status == 'DRAFT')
            Expanded(child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              child: const Text('Edit', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppPalette.textSecondary)),
            )),
          if (status == 'DRAFT') const SizedBox(width: 12),
          Expanded(
            flex: status == 'DRAFT' ? 2 : 1,
            child: ElevatedButton(
              onPressed: () async {
                if (status == 'DRAFT') {
                  try {
                    await _api.submitIdea(_idea['id']);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: const Text('Idea submitted!'), backgroundColor: AppPalette.success,
                          behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      );
                      Navigator.pop(context, true);
                    }
                  } catch (e) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed: $e'), backgroundColor: AppPalette.danger),
                    );
                  }
                } else {
                  // Navigate to AI tab
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: status == 'DRAFT' ? AppPalette.success : AppPalette.primaryAccent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(status == 'DRAFT' ? Iconsax.send_1 : Iconsax.magic_star, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(status == 'DRAFT' ? 'Submit Pitch' : 'View AI Report',
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppPalette.surfaceCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppPalette.textSecondary, letterSpacing: 0.5)),
            const SizedBox(height: 6),
            Text(content, style: const TextStyle(fontSize: 14, color: AppPalette.textPrimary, height: 1.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label.replaceAll('_', ' '), style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'SUBMITTED': return AppPalette.info;
      case 'UNDER_REVIEW': return AppPalette.warning;
      case 'APPROVED': return AppPalette.success;
      case 'REJECTED': return AppPalette.danger;
      default: return AppPalette.textSecondary;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'DRAFT': return 'Draft';
      case 'SUBMITTED': return 'Submitted';
      case 'UNDER_REVIEW': return 'Under Review';
      case 'APPROVED': return 'Approved';
      case 'REJECTED': return 'Rejected';
      default: return status;
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      final d = DateTime.parse(date.toString());
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return 'N/A';
    }
  }
}
