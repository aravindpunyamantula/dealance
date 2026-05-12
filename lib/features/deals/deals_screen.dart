import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../utils/app_palette.dart';
import '../chat/chat_list_screen.dart';
import 'deal_detail_screen.dart';
import 'package:iconsax/iconsax.dart';

class DealsScreen extends StatefulWidget {
  const DealsScreen({super.key});

  @override
  State<DealsScreen> createState() => _DealsScreenState();
}

class _DealsScreenState extends State<DealsScreen> with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  List<dynamic> _deals = [];
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final deals = await _api.getMyDeals();
      if (mounted) setState(() { _deals = deals; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeDeals = _deals.where((d) => d['status'] == 'PROPOSED' || d['status'] == 'NEGOTIATING').toList();
    final pastDeals = _deals.where((d) => d['status'] == 'ACCEPTED' || d['status'] == 'REJECTED' || d['status'] == 'CLOSED').toList();

    return Scaffold(
      backgroundColor: AppPalette.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header with Chat Icon
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Deals', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, fontFamily: 'Revalia', color: AppPalette.textPrimary)),
                        const SizedBox(height: 4),
                        Text('${activeDeals.length} active deals', style: const TextStyle(fontSize: 13, color: AppPalette.textSecondary)),
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
            
            // TabBar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: AppPalette.surfaceElevated,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: AppPalette.surfaceCard,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))],
                ),
                labelColor: AppPalette.primary,
                unselectedLabelColor: AppPalette.textSecondary,
                labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                padding: const EdgeInsets.all(4),
                tabs: const [
                  Tab(text: 'Active'),
                  Tab(text: 'Past'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // TabBarView
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppPalette.primaryAccent))
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildDealsList(activeDeals, 'No active deals', 'Active deals will appear here.'),
                        _buildDealsList(pastDeals, 'No past deals', 'Closed, accepted, or rejected deals will appear here.'),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDealsList(List<dynamic> deals, String emptyTitle, String emptySubtitle) {
    if (deals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.handshake_outlined, size: 56, color: AppPalette.textTerenary),
            const SizedBox(height: 12),
            Text(emptyTitle, style: const TextStyle(fontSize: 16, color: AppPalette.textSecondary, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(emptySubtitle, style: const TextStyle(fontSize: 13, color: AppPalette.textTerenary)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: AppPalette.primaryAccent,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: deals.length,
        itemBuilder: (_, i) => _buildDealCard(deals[i]),
      ),
    );
  }

  Widget _buildDealCard(Map<String, dynamic> deal) {
    final startup = deal['startup'] as Map<String, dynamic>?;
    final investor = deal['investor'] as Map<String, dynamic>?;
    final entrepreneur = deal['entrepreneur'] as Map<String, dynamic>?;
    final status = deal['status'] ?? 'PROPOSED';

    Color statusColor;
    IconData statusIcon;
    switch (status) {
      case 'ACCEPTED': statusColor = AppPalette.success; statusIcon = Iconsax.tick_circle; break;
      case 'REJECTED': statusColor = AppPalette.danger; statusIcon = Iconsax.close_circle; break;
      case 'NEGOTIATING': statusColor = AppPalette.warning; statusIcon = Iconsax.convert; break;
      case 'CLOSED': statusColor = AppPalette.textSecondary; statusIcon = Iconsax.lock; break;
      default: statusColor = AppPalette.info; statusIcon = Iconsax.timer_1;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => DealDetailScreen(deal: deal))).then((_) => _load());
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPalette.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(gradient: AppPalette.primaryGradient, borderRadius: BorderRadius.circular(12)),
                child: Center(child: Text((startup?['companyName']?.toString().isNotEmpty == true ? startup!['companyName'] : 'D')[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(startup?['companyName'] ?? 'Startup', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    Text(startup?['industry'] ?? '', style: const TextStyle(fontSize: 12, color: AppPalette.textSecondary)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 14, color: statusColor),
                    const SizedBox(width: 4),
                    Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor)),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Deal terms
          Row(
            children: [
              if (deal['investmentAmount'] != null) _buildTermChip(Iconsax.money, '\$${deal['investmentAmount']}'),
              if (deal['equityOffered'] != null) _buildTermChip(Icons.pie_chart_outline, '${deal['equityOffered']}%'),
              if (deal['valuation'] != null) _buildTermChip(Iconsax.graph, '\$${deal['valuation']}'),
            ],
          ),

          const SizedBox(height: 12),

          // Parties
          Row(
            children: [
              const Icon(Iconsax.user, size: 14, color: AppPalette.textSecondary),
              const SizedBox(width: 6),
              Text('${investor?['name']} → ${entrepreneur?['name']}', style: const TextStyle(fontSize: 12, color: AppPalette.textSecondary)),
              const Spacer(),
              if (status == 'PROPOSED')
                Row(
                  children: [
                    _buildActionButton('Accept', AppPalette.success, () => _acceptDeal(deal['id'])),
                    const SizedBox(width: 6),
                    _buildActionButton('Reject', AppPalette.danger, () => _rejectDeal(deal['id'])),
                  ],
                ),
            ],
          ),
        ],
      ),
    ),
  );
}

  Widget _buildTermChip(IconData icon, String text) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: AppPalette.surfaceElevated, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppPalette.textSecondary),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppPalette.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
        child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
      ),
    );
  }

  Future<void> _acceptDeal(String id) async {
    try { await _api.acceptDeal(id); _load(); } catch (_) {}
  }

  Future<void> _rejectDeal(String id) async {
    try { await _api.rejectDeal(id); _load(); } catch (_) {}
  }
}
