import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../utils/app_palette.dart';
import '../../pages/navigation.dart';
import '../../pages/investor/investor_navigation.dart';
import '../../features/auth/role_select_screen.dart';

class OtpScreen extends StatefulWidget {
  final String email;
  final String? name;
  final String? role;
  final String? phone;
  final String? linkedIn;
  final String? education;
  final String? networth;

  const OtpScreen({
    super.key,
    required this.email,
    this.name,
    this.role,
    this.phone,
    this.linkedIn,
    this.education,
    this.networth,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isVerifying = false;
  bool _showNameField = false;
  final _nameController = TextEditingController();

  @override
  void dispose() {
    for (final c in _controllers) { c.dispose(); }
    for (final f in _focusNodes) { f.dispose(); }
    _nameController.dispose();
    super.dispose();
  }

  String get _otpCode => _controllers.map((c) => c.text).join();

  Future<void> _verifyOtp() async {
    if (_isVerifying) return;
    final code = _otpCode;
    if (code.length != 6) return;

    setState(() => _isVerifying = true);

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final result = await auth.verifyOtp(
      email: widget.email,
      code: code,
      name: widget.name ?? (_showNameField ? _nameController.text.trim() : null),
      role: widget.role,
      phone: widget.phone,
      linkedIn: widget.linkedIn,
      education: widget.education,
      networth: widget.networth,
    );

    setState(() => _isVerifying = false);
    if (!mounted) return;

    if (result == 'NEW_USER') {
      setState(() => _showNameField = true);
    } else if (result == 'SUCCESS') {
      Widget destination;
      if (auth.isNewUser) {
        destination = const RoleSelectScreen();
      } else {
        destination = auth.userRole == 'INVESTOR'
            ? const InvestorNavigation()
            : const Navigation();
      }
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => destination), (route) => false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'Verification failed'), backgroundColor: AppPalette.danger, behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<void> _resendOtp() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    await auth.sendOtp(widget.email);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('New code sent!'), backgroundColor: AppPalette.success, behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFDF5EE), Color(0xFFF8F7F6)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios, color: AppPalette.textPrimary, size: 20),
                ),
                const Spacer(flex: 1),

                const Text(
                  "Verify your email",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, fontFamily: 'Revalia', color: AppPalette.textPrimary),
                ),
                const SizedBox(height: 8),
                Text(
                  "We sent a 6-digit code to\n${widget.email}",
                  style: const TextStyle(fontSize: 15, color: AppPalette.textSecondary, height: 1.5),
                ),
                const SizedBox(height: 36),

                // OTP boxes
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(6, (i) => _buildOtpBox(i)),
                ),
                const SizedBox(height: 16),

                Center(
                  child: TextButton(
                    onPressed: _resendOtp,
                    child: const Text("Didn't get the code? Resend", style: TextStyle(color: AppPalette.textSecondary, fontSize: 13)),
                  ),
                ),

                // Name field (new users)
                if (_showNameField) ...[
                  const SizedBox(height: 20),
                  const Text("What should we call you?", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppPalette.textPrimary)),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nameController,
                    autofocus: true,
                    style: const TextStyle(color: AppPalette.textPrimary, fontSize: 16),
                    decoration: InputDecoration(
                      hintText: "Your name",
                      hintStyle: const TextStyle(color: AppPalette.textTerenary),
                      prefixIcon: const Icon(Icons.person_outline, color: AppPalette.textSecondary),
                      filled: true,
                      fillColor: AppPalette.surfaceCard,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: AppPalette.surfaceElevated)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    ),
                  ),
                ],
                const SizedBox(height: 28),

                // Verify button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isVerifying ? null : _verifyOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppPalette.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: _isVerifying
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(_showNameField ? "Create Account" : "Verify & Continue",
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOtpBox(int index) {
    return SizedBox(
      width: 48,
      height: 56,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        maxLength: 1,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppPalette.textPrimary),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: AppPalette.surfaceCard,
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppPalette.surfaceElevated)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppPalette.surfaceElevated)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppPalette.primary, width: 2)),
        ),
        onChanged: (val) {
          if (val.isNotEmpty && index < 5) { _focusNodes[index + 1].requestFocus(); }
          else if (val.isEmpty && index > 0) { _focusNodes[index - 1].requestFocus(); }
          if (_otpCode.length == 6 && !_showNameField) { _verifyOtp(); }
        },
      ),
    );
  }
}
