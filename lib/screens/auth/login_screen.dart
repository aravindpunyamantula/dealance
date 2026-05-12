import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../utils/app_palette.dart';
import '../../pages/navigation.dart';
import '../../pages/investor/investor_navigation.dart';
import 'otp_screen.dart';

enum AuthMode { signIn, signUp }
enum UserRole { entrepreneur, investor }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

typedef LoginScreenWidget = LoginScreen;

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  
  // State
  AuthMode _authMode = AuthMode.signIn;
  UserRole _selectedRole = UserRole.entrepreneur;
  bool _isLoading = false;
  bool _isGoogleLoading = false;

  // Controllers
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _linkedInController = TextEditingController();
  final _educationController = TextEditingController();
  final _networthController = TextEditingController();

  late AnimationController _animController;
  late Animation<Offset> _slideUp;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _slideUp = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _fadeIn = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _linkedInController.dispose();
    _educationController.dispose();
    _networthController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final email = _emailController.text.trim();
    final success = await auth.sendOtp(email);
    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => OtpScreen(
          email: email,
          name: _authMode == AuthMode.signUp ? _nameController.text.trim() : null,
          role: _authMode == AuthMode.signUp ? (_selectedRole == UserRole.entrepreneur ? 'ENTREPRENEUR' : 'INVESTOR') : null,
          phone: _authMode == AuthMode.signUp ? _phoneController.text.trim() : null,
          linkedIn: _authMode == AuthMode.signUp ? _linkedInController.text.trim() : null,
          education: _authMode == AuthMode.signUp && _selectedRole == UserRole.entrepreneur ? _educationController.text.trim() : null,
          networth: _authMode == AuthMode.signUp && _selectedRole == UserRole.investor ? _networthController.text.trim() : null,
        ),
      ));
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Failed to send OTP'),
          backgroundColor: AppPalette.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isGoogleLoading = true);

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.signInWithGoogle();

    setState(() => _isGoogleLoading = false);

    if (success && mounted) {
      final destination = auth.userRole == 'INVESTOR'
          ? const InvestorNavigation()
          : const Navigation();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => destination),
        (route) => false,
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Google sign-in failed'),
          backgroundColor: AppPalette.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isMandatory = false,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        validator: validator,
        style: const TextStyle(color: AppPalette.textPrimary, fontSize: 16),
        decoration: InputDecoration(
          label: RichText(
            text: TextSpan(
              text: label,
              style: const TextStyle(color: AppPalette.textSecondary, fontSize: 15),
              children: [
                if (isMandatory)
                  const TextSpan(text: ' *', style: TextStyle(color: AppPalette.danger)),
              ],
            ),
          ),
          prefixIcon: Icon(icon, color: AppPalette.textSecondary),
          filled: true,
          fillColor: AppPalette.surfaceCard,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppPalette.surfaceElevated),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppPalette.surfaceElevated),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppPalette.primary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppPalette.danger),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFDF5EE), Color(0xFFF8F7F6)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
            child: SlideTransition(
              position: _slideUp,
              child: FadeTransition(
                opacity: _fadeIn,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      // Logo
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: AppPalette.primaryGradient,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppPalette.primary.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 28),
                      ),
                      const SizedBox(height: 32),

                      // Title
                      Text(
                        _authMode == AuthMode.signIn ? "Welcome Back" : "Join Dealance",
                        style: const TextStyle(
                          fontSize: 32, fontWeight: FontWeight.w800,
                          fontFamily: 'Revalia',
                          color: AppPalette.textPrimary, height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _authMode == AuthMode.signIn
                            ? "Enter your email to sign in."
                            : "Create an account to start your journey.",
                        style: const TextStyle(fontSize: 16, color: AppPalette.textSecondary, height: 1.5),
                      ),
                      const SizedBox(height: 32),

                      // Auth Mode Toggle (SignIn / SignUp)
                      Container(
                        decoration: BoxDecoration(
                          color: AppPalette.surfaceElevated,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _authMode = AuthMode.signIn),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: _authMode == AuthMode.signIn ? AppPalette.surfaceCard : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: _authMode == AuthMode.signIn ? [
                                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
                                    ] : [],
                                  ),
                                  child: Center(
                                    child: Text(
                                      "Sign In",
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: _authMode == AuthMode.signIn ? FontWeight.w700 : FontWeight.w500,
                                        color: _authMode == AuthMode.signIn ? AppPalette.primary : AppPalette.textSecondary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _authMode = AuthMode.signUp),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: _authMode == AuthMode.signUp ? AppPalette.surfaceCard : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: _authMode == AuthMode.signUp ? [
                                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
                                    ] : [],
                                  ),
                                  child: Center(
                                    child: Text(
                                      "Sign Up",
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: _authMode == AuthMode.signUp ? FontWeight.w700 : FontWeight.w500,
                                        color: _authMode == AuthMode.signUp ? AppPalette.primary : AppPalette.textSecondary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Role Toggle (Only for SignUp)
                      if (_authMode == AuthMode.signUp) ...[
                        const Text(
                          "I am an",
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppPalette.textSecondary),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildRoleCard(
                                title: "Entrepreneur",
                                icon: Icons.lightbulb_outline,
                                role: UserRole.entrepreneur,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildRoleCard(
                                title: "Investor",
                                icon: Icons.attach_money,
                                role: UserRole.investor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Email Field (Always visible)
                      _buildTextField(
                        controller: _emailController,
                        label: "Email address",
                        icon: Icons.email_outlined,
                        isMandatory: true,
                        keyboardType: TextInputType.emailAddress,
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Email is required';
                          final regex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
                          if (!regex.hasMatch(val)) return 'Enter a valid email';
                          return null;
                        },
                      ),

                      // Sign Up Fields
                      if (_authMode == AuthMode.signUp) ...[
                        _buildTextField(
                          controller: _nameController,
                          label: "Full Name",
                          icon: Icons.person_outline,
                          isMandatory: true,
                          validator: (val) => val == null || val.isEmpty ? 'Name is required' : null,
                        ),
                        _buildTextField(
                          controller: _phoneController,
                          label: "Phone Number (e.g. 9876543210)",
                          icon: Icons.phone_outlined,
                          isMandatory: true,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          validator: (val) {
                            if (val == null || val.isEmpty) return 'Phone number is required';
                            final regex = RegExp(r'^[6-9]\d{9}$');
                            if (!regex.hasMatch(val)) return 'Enter a valid 10-digit Indian phone number';
                            return null;
                          },
                        ),
                        _buildTextField(
                          controller: _linkedInController,
                          label: "LinkedIn Profile URL",
                          icon: Icons.link_rounded,
                          validator: (val) => val == null || val.isEmpty ? 'LinkedIn profile is required' : null,
                        ),
                        if (_selectedRole == UserRole.entrepreneur)
                          _buildTextField(
                            controller: _educationController,
                            label: "Education Details",
                            icon: Icons.school_outlined,
                            validator: (val) => val == null || val.isEmpty ? 'Education is required' : null,
                          )
                        else
                          _buildTextField(
                            controller: _networthController,
                            label: "Estimated Networth (e.g. \$1M)",
                            icon: Icons.account_balance_wallet_outlined,
                            validator: (val) => val == null || val.isEmpty ? 'Networth is required' : null,
                          ),
                      ],

                      const SizedBox(height: 8),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppPalette.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : Text(
                                  _authMode == AuthMode.signIn ? "Continue with Email" : "Create Account",
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)
                                ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Divider
                      Row(
                        children: [
                          Expanded(child: Divider(color: AppPalette.surfaceElevated, thickness: 1)),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text('or', style: TextStyle(fontSize: 13, color: AppPalette.textTerenary)),
                          ),
                          Expanded(child: Divider(color: AppPalette.surfaceElevated, thickness: 1)),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Google Sign-In button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton(
                          onPressed: _isGoogleLoading ? null : _signInWithGoogle,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: AppPalette.surfaceElevated),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            backgroundColor: AppPalette.surfaceCard,
                          ),
                          child: _isGoogleLoading
                              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.g_mobiledata, size: 28, color: Color(0xFF4285F4)),
                                    SizedBox(width: 8),
                                    Text(
                                      'Continue with Google',
                                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppPalette.textPrimary),
                                    ),
                                  ],
                                ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      const Center(
                        child: Text(
                          "By continuing, you agree to our Terms of Service",
                          style: TextStyle(fontSize: 12, color: AppPalette.textTerenary),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({required String title, required IconData icon, required UserRole role}) {
    final isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppPalette.primary.withOpacity(0.08) : AppPalette.surfaceCard,
          border: Border.all(
            color: isSelected ? AppPalette.primary : AppPalette.surfaceElevated,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? AppPalette.primary : AppPalette.textSecondary,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppPalette.primary : AppPalette.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
