import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../utils/app_palette.dart';

class NDASignScreen extends StatefulWidget {
  final String ideaId;
  final String companyName;
  const NDASignScreen({super.key, required this.ideaId, required this.companyName});

  @override
  State<NDASignScreen> createState() => _NDASignScreenState();
}

class _NDASignScreenState extends State<NDASignScreen> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _agreedToTerms = false;
  bool _isSigning = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _signNDA() async {
    if (!_formKey.currentState!.validate() || !_agreedToTerms) return;

    setState(() => _isSigning = true);

    try {
      await ApiService().signNDA(
        ideaId: widget.ideaId,
        signatureText: _nameController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('NDA signed successfully! You now have full access.'),
            backgroundColor: AppPalette.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true); // Return true = signed
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSigning = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to sign NDA: $e'),
            backgroundColor: AppPalette.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.background,
      appBar: AppBar(
        title: const Text('Non-Disclosure Agreement'),
        backgroundColor: AppPalette.background,
        foregroundColor: AppPalette.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // NDA Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2C3E50), Color(0xFF3498DB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.shield_outlined, size: 36, color: Colors.white),
                    const SizedBox(height: 12),
                    const Text(
                      'Confidentiality Agreement',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'For access to: ${widget.companyName}',
                      style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.8)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // NDA Content
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppPalette.surfaceCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TERMS AND CONDITIONS',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppPalette.textSecondary, letterSpacing: 1),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'By signing this Non-Disclosure Agreement ("NDA"), you agree to the following:\n\n'
                      '1. CONFIDENTIALITY: You agree to keep all information about "${widget.companyName}" strictly confidential.\n\n'
                      '2. NON-DISCLOSURE: You will not share, publish, or distribute any confidential information to any third party without prior written consent.\n\n'
                      '3. NON-COMPETE: You agree not to use the confidential information to develop, manufacture, or market competing products or services.\n\n'
                      '4. RETURN OF MATERIALS: Upon request, you will return or destroy all confidential materials.\n\n'
                      '5. TERM: This NDA remains in effect for 2 years from the date of signing.\n\n'
                      '6. REMEDIES: You acknowledge that breach of this NDA may cause irreparable harm and the disclosing party may seek injunctive relief.',
                      style: const TextStyle(fontSize: 13, height: 1.6, color: AppPalette.textSecondary),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Digital Signature
              const Text(
                'Digital Signature',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppPalette.textPrimary),
              ),
              const SizedBox(height: 8),
              const Text(
                'Type your full legal name below to sign this NDA',
                style: TextStyle(fontSize: 13, color: AppPalette.textSecondary),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _nameController,
                style: const TextStyle(
                  fontSize: 18,
                  fontFamily: 'Revalia',
                  color: AppPalette.textPrimary,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Your full name is required';
                  if (val.trim().length < 2) return 'Please enter your full legal name';
                  return null;
                },
                decoration: InputDecoration(
                  hintText: 'Your Full Legal Name',
                  hintStyle: const TextStyle(color: AppPalette.textTerenary, fontFamily: 'Revalia', fontSize: 16),
                  filled: true,
                  fillColor: AppPalette.surfaceCard,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppPalette.surfaceElevated),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppPalette.primaryAccent, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                ),
              ),

              const SizedBox(height: 16),

              // Agreement checkbox
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: _agreedToTerms,
                    onChanged: (val) => setState(() => _agreedToTerms = val ?? false),
                    activeColor: AppPalette.primaryAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _agreedToTerms = !_agreedToTerms),
                      child: const Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: Text(
                          'I have read, understand, and agree to the terms of this Non-Disclosure Agreement',
                          style: TextStyle(fontSize: 13, color: AppPalette.textSecondary, height: 1.4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Sign button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSigning || !_agreedToTerms ? null : _signNDA,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppPalette.primaryAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                    disabledBackgroundColor: AppPalette.surfaceElevated,
                  ),
                  child: _isSigning
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.draw, size: 20),
                            SizedBox(width: 8),
                            Text('Sign NDA', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
