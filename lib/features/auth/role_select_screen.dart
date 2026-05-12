import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../services/api_service.dart';
import '../../utils/app_palette.dart';
import '../../pages/navigation.dart';
import '../../pages/investor/investor_navigation.dart';

class RoleSelectScreen extends StatefulWidget {
  const RoleSelectScreen({super.key});

  @override
  State<RoleSelectScreen> createState() => _RoleSelectScreenState();
}

class _RoleSelectScreenState extends State<RoleSelectScreen> {
  String? _selectedRole;
  final _nameController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    _nameController.text = auth.userName;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (_selectedRole == null || _nameController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);

    try {
      final result = await ApiService().completeSignup(
        name: _nameController.text.trim(),
        role: _selectedRole!,
      );

      if (mounted) {
        final auth = Provider.of<AuthProvider>(context, listen: false);
        auth.updateUserData(result);

        final destination = _selectedRole == 'INVESTOR'
            ? const InvestorNavigation()
            : const Navigation();
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => destination), (_) => false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppPalette.danger, behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              const Text('Welcome to Dealance', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, fontFamily: 'Revalia', color: AppPalette.primaryDark)),
              const SizedBox(height: 8),
              const Text('Tell us about yourself to get started', style: TextStyle(fontSize: 15, color: AppPalette.textSecondary)),
              const SizedBox(height: 32),

              // Name
              const Text('Your Name', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'Full name',
                  filled: true,
                  fillColor: AppPalette.surfaceCard,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppPalette.surfaceElevated)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppPalette.primaryAccent, width: 1.5)),
                ),
              ),

              const SizedBox(height: 24),
              const Text('I am a...', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),

              // Entrepreneur card
              _buildRoleCard(
                role: 'ENTREPRENEUR',
                title: 'Entrepreneur 🚀',
                subtitle: 'I have a startup and want to find investors, get AI analysis, and grow my business.',
                icon: Icons.rocket_launch,
                color: AppPalette.success,
              ),

              const SizedBox(height: 12),

              // Investor card
              _buildRoleCard(
                role: 'INVESTOR',
                title: 'Investor 💰',
                subtitle: 'I want to discover startups, analyze deals, and invest in the next big thing.',
                icon: Icons.account_balance,
                color: AppPalette.info,
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading || _selectedRole == null || _nameController.text.trim().isEmpty ? null : _continue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppPalette.primaryAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                    disabledBackgroundColor: AppPalette.surfaceElevated,
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Get Started', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({required String role, required String title, required String subtitle, required IconData icon, required Color color}) {
    final isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.05) : AppPalette.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? color : Colors.grey.shade200, width: isSelected ? 2 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: isSelected ? color : AppPalette.textPrimary)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: AppPalette.textSecondary, height: 1.3)),
                ],
              ),
            ),
            if (isSelected) Icon(Icons.check_circle, color: color, size: 24),
          ],
        ),
      ),
    );
  }
}
