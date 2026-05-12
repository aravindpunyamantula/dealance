import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:iconsax/iconsax.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../services/auth_provider.dart';
import '../../services/api_service.dart';
import '../../utils/app_palette.dart';
import '../auth/login_screen.dart';
import '../../features/chat/chat_list_screen.dart';
import '../../features/feed/post_detail_screen.dart';
import '../../features/deals/deal_detail_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _api = ApiService();
  List<dynamic> _posts = [];
  List<dynamic> _deals = [];
  bool _isLoadingPosts = true;
  bool _isLoadingDeals = true;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final userId = auth.user?['id'];
    if (userId == null) return;

    setState(() {
      _isLoadingPosts = true;
      _isLoadingDeals = true;
    });

    // Refresh profile to ensure we have all fields for editing
    try {
      final profile = await _api.getProfile();
      auth.updateUserData(profile);
    } catch (_) {}

    try {
      final posts = await _api.getMyPosts(userId);
      if (mounted) setState(() { _posts = posts; _isLoadingPosts = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoadingPosts = false);
    }

    try {
      final deals = await _api.getMyDeals();
      if (mounted) setState(() { _deals = deals; _isLoadingDeals = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoadingDeals = false);
    }
  }

  void _showEditProfileDialog(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user ?? {};
    final isEntrepreneur = auth.userRole == 'ENTREPRENEUR';
    
    final nameController = TextEditingController(text: user['name'] ?? '');
    final phoneController = TextEditingController(text: user['phone'] ?? '');
    final linkedInController = TextEditingController(text: user['linkedIn'] ?? '');
    final bioController = TextEditingController(text: user['bio'] ?? '');
    final roleSpecificController = TextEditingController(
      text: isEntrepreneur ? (user['education'] ?? '') : (user['networth'] ?? '')
    );
    
    final api = ApiService();
    bool isLoading = false;
    XFile? selectedAvatar;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateLocal) {
          return Container(
            height: MediaQuery.of(ctx).size.height * 0.85,
            padding: EdgeInsets.only(
              left: 24, right: 24, top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Edit Profile',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppPalette.textPrimary),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        Center(
                          child: GestureDetector(
                            onTap: () async {
                              final picker = ImagePicker();
                              final picked = await picker.pickImage(source: ImageSource.gallery);
                              if (picked != null) {
                                setStateLocal(() {
                                  selectedAvatar = picked;
                                });
                              }
                            },
                            child: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 40,
                                  backgroundColor: AppPalette.surfaceElevated,
                                  backgroundImage: selectedAvatar != null 
                                      ? (kIsWeb ? NetworkImage(selectedAvatar!.path) : FileImage(File(selectedAvatar!.path))) as ImageProvider
                                      : (user['avatar'] != null ? NetworkImage(user['avatar']) : null),
                                  child: (selectedAvatar == null && user['avatar'] == null)
                                      ? Text((user['name']?.toString().isNotEmpty == true ? user['name'] : 'U')[0].toUpperCase(), style: const TextStyle(fontSize: 24, color: AppPalette.primaryAccent, fontWeight: FontWeight.w700))
                                      : null,
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: AppPalette.primaryAccent,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Iconsax.edit, size: 14, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildSettingsField('Display Name', 'Enter your name', nameController),
                        _buildSettingsField('Bio', 'Tell us about yourself', bioController, maxLines: 3),
                        _buildSettingsField('Phone Number', 'Enter your phone number', phoneController, keyboardType: TextInputType.phone),
                        _buildSettingsField('LinkedIn Profile', 'Enter LinkedIn URL', linkedInController, keyboardType: TextInputType.url),
                        if (isEntrepreneur)
                          _buildSettingsField('Education Details', 'Enter your education', roleSpecificController)
                        else
                          _buildSettingsField('Estimated Networth', 'Enter your networth (e.g. \$1M)', roleSpecificController),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : () async {
                      final newName = nameController.text.trim();
                      if (newName.isEmpty) return;
                      
                      setStateLocal(() => isLoading = true);
                      
                      try {
                        String? avatarUrl = user['avatar'];
                        
                        if (selectedAvatar != null) {
                          final uploadRes = await api.uploadXFile(selectedAvatar!, folder: 'avatars');
                          if (uploadRes.containsKey('url')) {
                            avatarUrl = uploadRes['url'];
                          }
                        }

                        final updateData = {
                          'name': newName,
                          'phone': phoneController.text.trim(),
                          'linkedIn': linkedInController.text.trim(),
                          'bio': bioController.text.trim(),
                          if (avatarUrl != null) 'avatar': avatarUrl,
                        };
                        
                        if (isEntrepreneur) {
                          updateData['education'] = roleSpecificController.text.trim();
                        } else {
                          updateData['networth'] = roleSpecificController.text.trim();
                        }
                        
                        final updatedUser = await api.updateProfile(updateData);
                        auth.updateUserData(updatedUser);
                        
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Profile updated!'),
                              backgroundColor: AppPalette.success,
                            ),
                          );
                          setState(() {});
                        }
                      } catch (e) {
                        if (ctx.mounted) {
                          setStateLocal(() => isLoading = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to update: $e'), backgroundColor: AppPalette.danger),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppPalette.primaryAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: isLoading 
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Save Changes', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          );
        }
      ),
    );
  }

  Widget _buildSettingsField(String label, String hint, TextEditingController controller, {TextInputType keyboardType = TextInputType.text, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: const TextStyle(color: AppPalette.textSecondary, fontSize: 14),
          filled: true,
          fillColor: AppPalette.surfaceElevated,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  void _logout(BuildContext context) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    await auth.logout();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Widget _buildTabButton(int index, String title, IconData icon) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppPalette.primaryAccent : AppPalette.surfaceElevated,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: isSelected ? Colors.white : AppPalette.textSecondary),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(
                color: isSelected ? Colors.white : AppPalette.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              )),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user ?? {};

    return Scaffold(
      backgroundColor: AppPalette.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: AppPalette.primaryAccent,
          child: CustomScrollView(
            slivers: [
              // AppBar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Profile',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, fontFamily: 'Revalia', color: AppPalette.textPrimary),
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
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () => _logout(context),
                        child: Container(
                          width: 42, height: 42,
                          decoration: BoxDecoration(
                            color: AppPalette.danger.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Iconsax.logout, size: 20, color: AppPalette.danger),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Profile Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 46,
                        backgroundColor: AppPalette.surfaceElevated,
                        backgroundImage: user['avatar'] != null ? NetworkImage(user['avatar']) : null,
                        child: user['avatar'] == null
                            ? Text((user['name']?.toString().isNotEmpty == true ? user['name'] : 'U')[0].toUpperCase(), style: const TextStyle(fontSize: 32, color: AppPalette.primaryAccent, fontWeight: FontWeight.w700))
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Text(user['name'] ?? 'User', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppPalette.textPrimary)),
                      const SizedBox(height: 4),
                      Text(auth.userRole == 'ENTREPRENEUR' ? 'Entrepreneur' : 'Investor', style: const TextStyle(fontSize: 14, color: AppPalette.primaryAccent, fontWeight: FontWeight.w600)),
                      
                      const SizedBox(height: 16),
                      SizedBox(
                        width: 160,
                        child: OutlinedButton(
                          onPressed: () => _showEditProfileDialog(context),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Edit Profile', style: TextStyle(color: AppPalette.textPrimary, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      _buildTabButton(0, 'My Posts', Iconsax.document),
                      const SizedBox(width: 12),
                      _buildTabButton(1, 'My Deals', Icons.handshake_outlined),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),

              if (_selectedTab == 0) ...[
                if (_isLoadingPosts)
                  const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: AppPalette.primaryAccent)))
                else if (_posts.isEmpty)
                  const SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Iconsax.note_2, size: 48, color: AppPalette.textTerenary),
                          SizedBox(height: 12),
                          Text('No posts yet', style: TextStyle(color: AppPalette.textSecondary)),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => _buildPostCard(_posts[i]),
                        childCount: _posts.length,
                      ),
                    ),
                  ),
              ] else ...[
                if (_isLoadingDeals)
                  const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: AppPalette.primaryAccent)))
                else if (_deals.isEmpty)
                  const SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.handshake_outlined, size: 48, color: AppPalette.textTerenary),
                          SizedBox(height: 12),
                          Text('No deals found', style: TextStyle(color: AppPalette.textSecondary)),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => _buildDealCard(_deals[i]),
                        childCount: _deals.length,
                      ),
                    ),
                  ),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post) {
    final user = post['user'] ?? {};
    final mediaUrls = post['mediaUrls'] as List<dynamic>? ?? [];

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => PostDetailScreen(post: post))).then((_) => _loadData());
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppPalette.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppPalette.primaryAccent.withValues(alpha: 0.1),
                  backgroundImage: user['avatar'] != null ? NetworkImage(user['avatar']) : null,
                  child: user['avatar'] == null
                      ? Text((user['name']?.toString().isNotEmpty == true ? user['name'] : 'U')[0].toUpperCase(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppPalette.primaryAccent))
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user['name'] ?? 'User', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      Text(timeago.format(DateTime.parse(post['createdAt'])), style: const TextStyle(fontSize: 11, color: AppPalette.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(post['content'] ?? '', style: const TextStyle(fontSize: 14, color: AppPalette.textPrimary, height: 1.4)),
            
            if (mediaUrls.isNotEmpty) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(mediaUrls[0], fit: BoxFit.cover, width: double.infinity, height: 180),
              ),
            ],
            
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(post['isLiked'] == true ? Iconsax.heart5 : Iconsax.heart, 
                     size: 20, color: post['isLiked'] == true ? AppPalette.danger : AppPalette.textSecondary),
                const SizedBox(width: 6),
                Text('${post['likeCount'] ?? 0}', style: const TextStyle(color: AppPalette.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(width: 16),
                const Icon(Iconsax.message, size: 20, color: AppPalette.textSecondary),
                const SizedBox(width: 6),
                Text('${post['_count']?['comments'] ?? 0}', style: const TextStyle(color: AppPalette.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDealCard(Map<String, dynamic> deal) {
    final startup = deal['startup'] as Map<String, dynamic>?;
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
        Navigator.push(context, MaterialPageRoute(builder: (_) => DealDetailScreen(deal: deal))).then((_) => _loadData());
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
            Row(
              children: [
                if (deal['investmentAmount'] != null) _buildTermChip(Iconsax.money, '\$${deal['investmentAmount']}'),
                if (deal['equityOffered'] != null) _buildTermChip(Icons.pie_chart_outline, '${deal['equityOffered']}%'),
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
}
