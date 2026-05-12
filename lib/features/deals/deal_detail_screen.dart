import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../utils/app_palette.dart';
import '../../services/auth_provider.dart';
import '../../pages/investor/idea_investor_view.dart';
import '../../pages/ideas/idea_detail_screen.dart';
import '../chat/chat_room_screen.dart';

class DealDetailScreen extends StatefulWidget {
  final Map<String, dynamic> deal;

  const DealDetailScreen({super.key, required this.deal});

  @override
  State<DealDetailScreen> createState() => _DealDetailScreenState();
}

class _DealDetailScreenState extends State<DealDetailScreen> {
  final ApiService _api = ApiService();
  late Map<String, dynamic> _deal;

  @override
  void initState() {
    super.initState();
    _deal = widget.deal;
  }

  Future<void> _acceptDeal() async {
    try {
      await _api.acceptDeal(_deal['id']);
      if (mounted) {
        setState(() {
          _deal['status'] = 'ACCEPTED';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Deal accepted'), backgroundColor: AppPalette.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppPalette.danger),
        );
      }
    }
  }

  Future<void> _rejectDeal() async {
    try {
      await _api.rejectDeal(_deal['id']);
      if (mounted) {
        setState(() {
          _deal['status'] = 'REJECTED';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Deal rejected'), backgroundColor: AppPalette.danger),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppPalette.danger),
        );
      }
    }
  }

  Future<void> _startChat(Map<String, dynamic>? otherUser) async {
    if (otherUser == null || otherUser['id'] == null) return;
    try {
      String? roomId = _deal['chatRoomId'];
      
      if (roomId == null) {
        final room = await _api.getOrCreateDMRoom(otherUser['id']);
        roomId = room['id'];
      }

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatRoomScreen(
              roomId: roomId!,
              otherUserName: otherUser['name'] ?? 'User',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppPalette.danger),
        );
      }
    }
  }

  void _viewStartup() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final startupId = _deal['startup']?['id'] ?? _deal['startupId'];
    if (startupId == null) return;

    if (auth.userRole == 'INVESTOR') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => IdeaInvestorView(ideaId: startupId)));
    } else {
      // Assuming entrepreneur wants to see their own idea detail
      // We might need to fetch the full idea, but IdeaDetailScreen takes an idea object
      Navigator.push(context, MaterialPageRoute(builder: (_) => IdeaDetailScreen(idea: _deal['startup'] ?? {'id': startupId})));
    }
  }

  @override
  Widget build(BuildContext context) {
    final startup = _deal['startup'] as Map<String, dynamic>?;
    final investor = _deal['investor'] as Map<String, dynamic>?;
    final entrepreneur = _deal['entrepreneur'] as Map<String, dynamic>?;
    final status = _deal['status'] ?? 'PROPOSED';

    Color statusColor;
    IconData statusIcon;
    switch (status) {
      case 'ACCEPTED': statusColor = AppPalette.success; statusIcon = Iconsax.tick_circle; break;
      case 'REJECTED': statusColor = AppPalette.danger; statusIcon = Iconsax.close_circle; break;
      case 'NEGOTIATING': statusColor = AppPalette.warning; statusIcon = Iconsax.convert; break;
      case 'CLOSED': statusColor = AppPalette.textSecondary; statusIcon = Iconsax.lock; break;
      default: statusColor = AppPalette.info; statusIcon = Iconsax.timer_1;
    }

    final auth = Provider.of<AuthProvider>(context);
    final isEntrepreneur = auth.userRole == 'ENTREPRENEUR';
    final otherUser = isEntrepreneur ? investor : entrepreneur;
    final isPendingAction = status == 'PROPOSED' && isEntrepreneur; // Usually entrepreneur accepts/rejects

    return Scaffold(
      backgroundColor: AppPalette.background,
      appBar: AppBar(
        title: const Text('Deal Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        backgroundColor: AppPalette.background,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: statusColor.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(statusIcon, color: statusColor, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Status: $status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: statusColor)),
                        const SizedBox(height: 4),
                        Text('Last updated: ${_deal['updatedAt'] != null ? DateTime.parse(_deal['updatedAt']).toString().substring(0, 10) : 'N/A'}', style: TextStyle(fontSize: 12, color: statusColor.withValues(alpha: 0.8))),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Startup Info
            const Text('Startup', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppPalette.textPrimary)),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _viewStartup,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppPalette.surfaceCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(gradient: AppPalette.primaryGradient, borderRadius: BorderRadius.circular(12)),
                      child: Center(child: Text((startup?['companyName'] ?? 'S').substring(0, 1).toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700))),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(startup?['companyName'] ?? 'Unknown Startup', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppPalette.textPrimary)),
                          if (startup?['industry'] != null)
                            Text(startup?['industry'], style: const TextStyle(fontSize: 13, color: AppPalette.textSecondary)),
                        ],
                      ),
                    ),
                    const Icon(Iconsax.arrow_right_3, size: 20, color: AppPalette.textSecondary),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Terms
            const Text('Deal Terms', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppPalette.textPrimary)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppPalette.surfaceCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _buildTermRow(Iconsax.money, 'Investment Amount', _deal['investmentAmount'] != null ? '\$${_deal['investmentAmount']}' : 'N/A'),
                  const Divider(height: 24),
                  _buildTermRow(Icons.pie_chart_outline, 'Equity Offered', _deal['equityOffered'] != null ? '${_deal['equityOffered']}%' : 'N/A'),
                  if (_deal['valuation'] != null) ...[
                    const Divider(height: 24),
                    _buildTermRow(Iconsax.graph, 'Valuation', '\$${_deal['valuation']}'),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Notes
            if (_deal['notes'] != null && _deal['notes'].toString().isNotEmpty) ...[
              const Text('Notes / Terms', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppPalette.textPrimary)),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppPalette.surfaceElevated,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(_deal['notes'], style: const TextStyle(fontSize: 14, color: AppPalette.textSecondary, height: 1.5)),
              ),
              const SizedBox(height: 24),
            ],

            // Other Party
            Text(isEntrepreneur ? 'Investor' : 'Entrepreneur', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppPalette.textPrimary)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppPalette.surfaceCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppPalette.primaryAccent.withValues(alpha: 0.1),
                    child: Text((otherUser?['name'] ?? 'U').substring(0, 1).toUpperCase(), style: const TextStyle(color: AppPalette.primaryAccent, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(otherUser?['name'] ?? 'Unknown', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _startChat(otherUser),
                    icon: const Icon(Iconsax.message, size: 16),
                    label: const Text('Message'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppPalette.primaryAccent,
                      side: const BorderSide(color: AppPalette.primaryAccent),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomNavigationBar: isPendingAction ? SafeArea(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppPalette.surfaceCard,
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))],
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _rejectDeal,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppPalette.danger,
                    side: const BorderSide(color: AppPalette.danger),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Reject Deal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _acceptDeal,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppPalette.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: const Text('Accept Deal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ) : null,
    );
  }

  Widget _buildTermRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppPalette.textSecondary),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(fontSize: 14, color: AppPalette.textSecondary)),
        const Spacer(),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppPalette.textPrimary)),
      ],
    );
  }
}
