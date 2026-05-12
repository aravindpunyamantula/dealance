import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:striv/pages/entrepreneur/pitch_upload2/pitch_step2_upload.dart';
import 'package:striv/services/pitch_form_controller.dart';
import 'package:striv/utils/app_palette.dart';

class ProblemSolutionForm extends StatefulWidget {
  const ProblemSolutionForm({super.key});

  @override
  State<ProblemSolutionForm> createState() => _ProblemSolutionFormState();
}

class _ProblemSolutionFormState extends State<ProblemSolutionForm> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _oneLinerController = TextEditingController();
  final TextEditingController _detailedProblemController = TextEditingController();
  final TextEditingController _productDescriptionController = TextEditingController();
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _companyTaglineController = TextEditingController();

  String? _evidenceFile;
  String? _pitchDeckFile;
  String? _logo;
  String? _card;
  String? _videoPitchFile;
  String? _selectedRole;
  bool _isSaving = false;

  // Picked file paths for upload
  String? _evidencePath;
  String? _pitchDeckPath;
  String? _logoPath;
  String? _cardPath;
  String? _videoPitchPath;

  @override
  void dispose() {
    _oneLinerController.dispose();
    _detailedProblemController.dispose();
    _productDescriptionController.dispose();
    _companyNameController.dispose();
    _companyTaglineController.dispose();
    super.dispose();
  }

  Future<void> _pickFile(String type) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: type == "logo" || type == "card"
            ? ['png', 'jpg', 'jpeg', 'webp']
            : type == "videoPitch"
                ? ['mp4', 'mov', 'avi']
                : ['pdf', 'pptx', 'docx', 'xlsx'],
      );

      if (result != null && result.files.isNotEmpty) {
        final name = result.files.first.name;
        final path = result.files.first.path;
        setState(() {
          switch (type) {
            case "evidence":
              _evidenceFile = name;
              _evidencePath = path;
              break;
            case "pitchDeck":
              _pitchDeckFile = name;
              _pitchDeckPath = path;
              break;
            case "videoPitch":
              _videoPitchFile = name;
              _videoPitchPath = path;
              break;
            case "logo":
              _logo = name;
              _logoPath = path;
              break;
            case "card":
              _card = name;
              _cardPath = path;
              break;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick file: $e')),
        );
      }
    }
  }

  Future<void> _saveDraft() async {
    if (_companyNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a company name to save draft')),
      );
      return;
    }

    setState(() => _isSaving = true);
    final controller = Provider.of<PitchFormController>(context, listen: false);

    final success = await controller.createDraft(
      businessType: PitchFormController.roleToBusinessType(_selectedRole),
      companyName: _companyNameController.text.trim(),
      tagline: _companyTaglineController.text.trim(),
      oneLiner: _oneLinerController.text.trim(),
    );

    if (success && mounted) {
      // Also save step 1 details
      await controller.saveStep(1, {
        'detailedProblem': _detailedProblemController.text.trim(),
        'productDescription': _productDescriptionController.text.trim(),
        'solution': _productDescriptionController.text.trim(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Draft saved successfully!'),
          backgroundColor: AppPalette.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(controller.error ?? 'Failed to save draft'),
          backgroundColor: AppPalette.danger,
        ),
      );
    }

    setState(() => _isSaving = false);
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your business type')),
      );
      return;
    }

    setState(() => _isSaving = true);
    final controller = Provider.of<PitchFormController>(context, listen: false);

    // Create draft first
    final created = await controller.createDraft(
      businessType: PitchFormController.roleToBusinessType(_selectedRole),
      companyName: _companyNameController.text.trim(),
      tagline: _companyTaglineController.text.trim(),
      oneLiner: _oneLinerController.text.trim(),
    );

    if (!created || !mounted) {
      setState(() => _isSaving = false);
      return;
    }

    // Upload files if selected
    final Map<String, dynamic> fileUrls = {};

    if (_evidencePath != null) {
      final url = await controller.uploadFile(File(_evidencePath!), folder: 'evidence');
      if (url != null) fileUrls['evidenceUrl'] = url;
    }
    if (_pitchDeckPath != null) {
      final url = await controller.uploadFile(File(_pitchDeckPath!), folder: 'pitchdecks');
      if (url != null) fileUrls['pitchDeckUrl'] = url;
    }
    if (_videoPitchPath != null) {
      final url = await controller.uploadFile(File(_videoPitchPath!), folder: 'videopitches');
      if (url != null) fileUrls['videoPitchUrl'] = url;
    }
    if (_logoPath != null) {
      final url = await controller.uploadFile(File(_logoPath!), folder: 'logos');
      if (url != null) fileUrls['logoUrl'] = url;
    }
    if (_cardPath != null) {
      final url = await controller.uploadFile(File(_cardPath!), folder: 'cards');
      if (url != null) fileUrls['cardUrl'] = url;
    }

    // Save step 1 data
    await controller.saveStep(1, {
      'detailedProblem': _detailedProblemController.text.trim(),
      'productDescription': _productDescriptionController.text.trim(),
      'solution': _productDescriptionController.text.trim(),
      ...fileUrls,
    });

    setState(() => _isSaving = false);

    if (mounted) {
      final step1Data = {
        "ideaId": controller.ideaId,
        "oneLiner": _oneLinerController.text.trim(),
        "detailedProblem": _detailedProblemController.text.trim(),
        "evidence": _evidenceFile ?? "No evidence uploaded",
        "productDescription": _productDescriptionController.text.trim(),
        "pitchDeck": _pitchDeckFile ?? "No pitch deck uploaded",
        "Logo": _logo ?? "No logo uploaded",
        "card": _card ?? "No card uploaded",
        "videoPitch": _videoPitchFile ?? "No video pitch uploaded",
      };

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MarketOpportunityForm(step1Data: step1Data),
        ),
      );
    }
  }

  Widget _uploadBox({
    required String label,
    required String hint,
    required IconData icon,
    required VoidCallback onTap,
    String? fileName,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
            const SizedBox(width: 4),
            const Icon(Icons.info_outline, size: 16, color: AppPalette.textTerenary),
          ],
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: onTap,
          child: DottedBorder(
            color: AppPalette.primaryAccent.withOpacity(0.4),
            strokeWidth: 1.5,
            dashPattern: const [6, 4],
            borderType: BorderType.RRect,
            radius: const Radius.circular(14),
            child: Container(
              height: 110,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppPalette.surfaceElevated,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: fileName == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(icon, size: 28, color: AppPalette.primaryAccent),
                          const SizedBox(height: 8),
                          Text(
                            hint,
                            style: const TextStyle(color: AppPalette.textSecondary, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle, color: AppPalette.success, size: 20),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              fileName,
                              style: const TextStyle(color: AppPalette.textPrimary, fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (val) => val == null || val.isEmpty ? "Required" : null,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(14),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppPalette.primaryAccent, width: 1.5),
          borderRadius: BorderRadius.circular(14),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppPalette.danger),
          borderRadius: BorderRadius.circular(14),
        ),
        filled: true,
        fillColor: AppPalette.surfaceCard,
        contentPadding: const EdgeInsets.all(14),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.background,
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: AppPalette.background,
        elevation: 0,
        leading: InkWell(
          onTap: () => Navigator.pop(context),
          child: const Icon(CupertinoIcons.back, color: AppPalette.textPrimary),
        ),
        title: const Text("Problem & Solution", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
            )
          else
            TextButton(
              onPressed: _saveDraft,
              child: const Text('Save Draft', style: TextStyle(color: AppPalette.primaryAccent, fontWeight: FontWeight.w600)),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Step 1 of 5", style: TextStyle(fontSize: 12, color: AppPalette.textSecondary)),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: const LinearProgressIndicator(
                    value: 1 / 5,
                    minHeight: 4,
                    backgroundColor: Color(0xFFE8E8EE),
                    valueColor: AlwaysStoppedAnimation<Color>(AppPalette.primaryAccent),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Role Selection
                const Text("What type of business?",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                _buildRoleChips(),
                const SizedBox(height: 20),

                // Company Name
                const Text("Company Name", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                const SizedBox(height: 8),
                _buildTextFormField(controller: _companyNameController, hint: "Your company name"),
                const SizedBox(height: 16),

                // Company Tagline
                const Text("Company Tagline", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                const SizedBox(height: 8),
                _buildTextFormField(controller: _companyTaglineController, hint: "A catchy tagline"),
                const SizedBox(height: 16),

                // One-liner
                const Text("1-Liner Problem Statement", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                const SizedBox(height: 8),
                _buildTextFormField(controller: _oneLinerController, hint: "Briefly describe the problem"),
                const SizedBox(height: 16),

                // Detailed Problem
                const Text("Detailed Problem", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                const SizedBox(height: 8),
                _buildTextFormField(
                  controller: _detailedProblemController,
                  hint: "Provide a comprehensive description of the problem",
                  maxLines: 5,
                ),
                const SizedBox(height: 16),

                // Product Description
                const Text("Product Description / Solution",
                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                const SizedBox(height: 8),
                _buildTextFormField(
                  controller: _productDescriptionController,
                  hint: "Describe your product or solution",
                  maxLines: 4,
                ),
                const SizedBox(height: 20),

                // File uploads
                _uploadBox(
                  label: "Evidence of Problem",
                  hint: "Upload market research, user feedback, etc.",
                  icon: Icons.cloud_upload_outlined,
                  fileName: _evidenceFile,
                  onTap: () => _pickFile("evidence"),
                ),
                _uploadBox(
                  label: "Pitch Deck (PDF/PPT)",
                  hint: "Tap to upload your Pitch Deck",
                  icon: Icons.insert_drive_file_outlined,
                  fileName: _pitchDeckFile,
                  onTap: () => _pickFile("pitchDeck"),
                ),
                _uploadBox(
                  label: "Video Pitch (MP4)",
                  hint: "Tap to upload your Video Pitch",
                  icon: Icons.play_circle_outline,
                  fileName: _videoPitchFile,
                  onTap: () => _pickFile("videoPitch"),
                ),
                _uploadBox(
                  label: "Company Logo (PNG/JPG)",
                  hint: "Tap to upload your Logo",
                  icon: Icons.image_outlined,
                  fileName: _logo,
                  onTap: () => _pickFile("logo"),
                ),
                _uploadBox(
                  label: "Company Visit Card",
                  hint: "Tap to upload your Card",
                  icon: Icons.contact_mail_outlined,
                  fileName: _card,
                  onTap: () => _pickFile("card"),
                ),

                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppPalette.surfaceCard,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4)),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                child: const Text('Cancel',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppPalette.textPrimary)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _isSaving ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppPalette.primaryAccent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text("Next", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleChips() {
    final roles = [
      {'code': 'PP', 'label': 'Patentable Product'},
      {'code': 'ST', 'label': 'Startup'},
      {'code': 'RB', 'label': 'Regular Business'},
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: roles.map((role) {
        final isSelected = _selectedRole == role['code'];
        return ChoiceChip(
          label: Text(role['label']!),
          selected: isSelected,
          onSelected: (selected) {
            setState(() => _selectedRole = selected ? role['code'] : null);
          },
          selectedColor: AppPalette.primaryAccent,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : AppPalette.textPrimary,
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
          backgroundColor: AppPalette.surfaceElevated,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          side: BorderSide(color: isSelected ? AppPalette.primaryAccent : Colors.grey.shade200),
        );
      }).toList(),
    );
  }
}
