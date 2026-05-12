import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../utils/app_palette.dart';

class InviteInvestorScreen extends StatefulWidget {
  final String ideaId;
  final String ideaName;
  const InviteInvestorScreen({super.key, required this.ideaId, required this.ideaName});

  @override
  State<InviteInvestorScreen> createState() => _InviteInvestorScreenState();
}

class _InviteInvestorScreenState extends State<InviteInvestorScreen> {
  final ApiService _api = ApiService();
  final _searchController = TextEditingController();

  List<dynamic> _investors = [];
  List<dynamic> _invitedInvestors = [];
  bool _isLoading = true;
  bool _isSearching = false;
  Set<String> _invitingIds = {};

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
      final results = await Future.wait([
        _api.searchInvestors(),
        _api.getInvitedInvestors(widget.ideaId),
      ]);
      if (mounted) {
        setState(() {
          _investors = results[0];
          _invitedInvestors = results[1];
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

  Future<void> _inviteInvestor(String investorId) async {
    setState(() => _invitingIds.add(investorId));
    try {
      await _api.inviteInvestor(ideaId: widget.ideaId, investorId: investorId);
      // Refresh invited list
      final invited = await _api.getInvitedInvestors(widget.ideaId);
      if (mounted) {
        setState(() {
          _invitedInvestors = invited;
          _invitingIds.remove(investorId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Investor invited!'),
            backgroundColor: AppPalette.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _invitingIds.remove(investorId));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: AppPalette.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  bool _isAlreadyInvited(String investorId) {
    return _invitedInvestors.any((inv) => inv['investorId'] == investorId || inv['investor']?['id'] == investorId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.background,
      appBar: AppBar(
        title: const Text('Invite Investors'),
        backgroundColor: AppPalette.background,
        foregroundColor: AppPalette.textPrimary,
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Idea name
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'For: ${widget.ideaName}',
              style: const TextStyle(fontSize: 13, color: AppPalette.textSecondary),
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => _search(val),
              decoration: InputDecoration(
                hintText: 'Search investors by name...',
                hintStyle: const TextStyle(color: AppPalette.textTerenary, fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: AppPalette.textSecondary),
                suffixIcon: _isSearching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    : null,
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

          const SizedBox(height: 12),

          // Invited count
          if (_invitedInvestors.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '${_invitedInvestors.length} investor(s) already invited',
                style: const TextStyle(fontSize: 12, color: AppPalette.success, fontWeight: FontWeight.w600),
              ),
            ),

          const SizedBox(height: 8),

          // Investor list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppPalette.primaryAccent))
                : _investors.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_search, size: 48, color: AppPalette.textTerenary),
                            SizedBox(height: 8),
                            Text('No investors found', style: TextStyle(color: AppPalette.textSecondary)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _investors.length,
                        itemBuilder: (context, index) => _buildInvestorTile(_investors[index]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvestorTile(Map<String, dynamic> investor) {
    final id = investor['id'] as String;
    final name = investor['name'] ?? 'Unknown';
    final email = investor['email'] ?? '';
    final bio = investor['bio'];
    final isInvited = _isAlreadyInvited(id);
    final isInviting = _invitingIds.contains(id);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppPalette.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isInvited ? AppPalette.success.withValues(alpha: 0.3) : Colors.grey.shade100),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppPalette.primaryAccent.withValues(alpha: 0.1),
            child: Text(
              name.substring(0, 1).toUpperCase(),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppPalette.primaryAccent),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppPalette.textPrimary)),
                Text(email, style: const TextStyle(fontSize: 12, color: AppPalette.textSecondary)),
                if (bio != null && bio.isNotEmpty)
                  Text(bio, style: const TextStyle(fontSize: 11, color: AppPalette.textTerenary), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isInvited)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppPalette.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('Invited', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppPalette.success)),
            )
          else
            SizedBox(
              height: 34,
              child: ElevatedButton(
                onPressed: isInviting ? null : () => _inviteInvestor(id),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppPalette.primaryAccent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                ),
                child: isInviting
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Invite', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ),
        ],
      ),
    );
  }
}
