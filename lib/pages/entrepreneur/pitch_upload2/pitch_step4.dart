import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter/cupertino.dart';
import 'package:striv/pages/entrepreneur/pitch_upload2/pitch_step5.dart';
import 'package:striv/services/pitch_form_controller.dart';
import 'package:striv/utils/app_palette.dart';

class PitchFundScreen extends StatefulWidget {
  final Map<String, dynamic> data;

  const PitchFundScreen({super.key, required this.data});

  @override
  State<PitchFundScreen> createState() => _PitchFundScreenState();
}

class _PitchFundScreenState extends State<PitchFundScreen> {
  final _amountController = TextEditingController();
  final _equityController = TextEditingController();
  final _patentsController = TextEditingController();
  final _trademarksController = TextEditingController();
  final _useOfFundsController = TextEditingController();
  final _milestonesController = TextEditingController();

  String _selectedCurrency = 'USD';
  String _selectedFundingType = 'Seed Round';
  String _selectedLicense = 'FDA Approval';
  int _selectedLegalDeclaration = 0;
  String? _uploadedFileName;
  bool _isSaving = false;

  // Default placeholder values
  final String defaultAmount = '100,000';
  final String defaultEquity = '10';
  final String defaultUseOfFunds = 'Marketing, Product Development, Team Expansion';
  final String defaultMilestones = 'Launch MVP, Secure First 1000 Users, Achieve Profitability';

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx', 'png', 'jpg', 'jpeg'],
      );

      if (result != null) {
        setState(() => _uploadedFileName = result.files.single.name);
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error picking file. Please try again.'), backgroundColor: AppPalette.danger),
      );
    }
  }

  Future<void> _saveDraft() async {
    setState(() => _isSaving = true);
    final controller = Provider.of<PitchFormController>(context, listen: false);
    
    final amount = _amountController.text.trim().isEmpty ? defaultAmount : _amountController.text.trim();
    final equity = _equityController.text.trim().isEmpty ? defaultEquity : _equityController.text.trim();
    final useOfFunds = _useOfFundsController.text.trim().isEmpty ? defaultUseOfFunds : _useOfFundsController.text.trim();
    final milestones = _milestonesController.text.trim().isEmpty ? defaultMilestones : _milestonesController.text.trim();

    final stepData = {
      'fundingAmount': amount,
      'fundingCurrency': _selectedCurrency,
      'fundingType': _selectedFundingType,
      'equityOffered': equity,
      'useOfFunds': useOfFunds,
      'expectedMilestones': milestones,
      'patents': _patentsController.text.trim(),
      'trademarks': _trademarksController.text.trim(),
      'license': _selectedLicense,
      'companyDocs': _uploadedFileName,
      'legalDeclaration': _selectedLegalDeclaration,
    };

    if (controller.ideaId != null) {
      await controller.saveStep(4, stepData);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Draft saved successfully!'),
            backgroundColor: AppPalette.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot save draft without starting a pitch.'), backgroundColor: AppPalette.danger),
        );
      }
    }
    setState(() => _isSaving = false);
  }

  Future<void> _submit() async {
    final amount = _amountController.text.trim().isEmpty ? defaultAmount : _amountController.text.trim();
    final equity = _equityController.text.trim().isEmpty ? defaultEquity : _equityController.text.trim();
    final useOfFunds = _useOfFundsController.text.trim().isEmpty ? defaultUseOfFunds : _useOfFundsController.text.trim();
    final milestones = _milestonesController.text.trim().isEmpty ? defaultMilestones : _milestonesController.text.trim();

    final stepData = {
      'fundingAmount': amount,
      'fundingCurrency': _selectedCurrency,
      'fundingType': _selectedFundingType,
      'equityOffered': equity,
      'useOfFunds': useOfFunds,
      'expectedMilestones': milestones,
      'patents': _patentsController.text.trim(),
      'trademarks': _trademarksController.text.trim(),
      'license': _selectedLicense,
      'companyDocs': _uploadedFileName,
      'legalDeclaration': _selectedLegalDeclaration,
    };

    setState(() => _isSaving = true);
    final controller = Provider.of<PitchFormController>(context, listen: false);
    if (controller.ideaId != null) {
      await controller.saveStep(4, stepData);
    }
    setState(() => _isSaving = false);

    final merged = {
      ...widget.data,
      ...stepData,
    };

    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => Pitch_secure(data: merged)),
      );
    }
  }

  void _showInfoTooltip(String title, String description) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      backgroundColor: AppPalette.surfaceElevated,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Iconsax.info_circle, color: AppPalette.primaryAccent, size: 28),
                const SizedBox(width: 12),
                Expanded(child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
              ],
            ),
            const SizedBox(height: 16),
            Text(description, style: const TextStyle(fontSize: 15, height: 1.5, color: AppPalette.textSecondary)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppPalette.primaryAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Got it', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoIcon(String title, String description) {
    return GestureDetector(
      onTap: () => _showInfoTooltip(title, description),
      child: const Padding(
        padding: EdgeInsets.only(left: 6.0),
        child: Icon(Iconsax.info_circle, size: 16, color: AppPalette.textTerenary),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? hint,
    int maxLines = 1,
    String? tooltipTitle,
    String? tooltipDesc,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
            if (tooltipTitle != null && tooltipDesc != null)
              _buildInfoIcon(tooltipTitle, tooltipDesc),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
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
            filled: true,
            fillColor: AppPalette.surfaceCard,
            contentPadding: const EdgeInsets.all(14),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          decoration: BoxDecoration(
            color: AppPalette.surfaceCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            decoration: const InputDecoration(border: InputBorder.none),
            icon: const Icon(Iconsax.arrow_down_1, size: 18),
            items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 15)))).toList(),
            onChanged: (val) => onChanged(val!),
          ),
        ),
      ],
    );
  }

  Widget _buildRadioOption(int value, String text) {
    return InkWell(
      onTap: () => setState(() => _selectedLegalDeclaration = value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Radio<int>(
                value: value,
                groupValue: _selectedLegalDeclaration,
                onChanged: (val) => setState(() => _selectedLegalDeclaration = val!),
                activeColor: AppPalette.primaryAccent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(text, style: const TextStyle(fontSize: 14, color: AppPalette.textPrimary, height: 1.4)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _equityController.dispose();
    _patentsController.dispose();
    _trademarksController.dispose();
    _useOfFundsController.dispose();
    _milestonesController.dispose();
    super.dispose();
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
        title: const Text('Pitch Deck Upload', style: TextStyle(color: AppPalette.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
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
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Step 4 of 5', style: TextStyle(fontSize: 12, color: AppPalette.textSecondary)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: const LinearProgressIndicator(
                    value: 4 / 5,
                    backgroundColor: Color(0xFFE8E8EE),
                    valueColor: AlwaysStoppedAnimation<Color>(AppPalette.primaryAccent),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Funding Request', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppPalette.textPrimary)),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          label: 'Amount',
                          controller: _amountController,
                          hint: defaultAmount,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDropdown(
                          label: 'Currency',
                          value: _selectedCurrency,
                          items: ['USD', 'EUR', 'GBP', 'INR'],
                          onChanged: (val) => setState(() => _selectedCurrency = val),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildDropdown(
                    label: 'Type of Funding',
                    value: _selectedFundingType,
                    items: ['Seed Round', 'Series A', 'Series B', 'Series C'],
                    onChanged: (val) => setState(() => _selectedFundingType = val),
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    label: 'Equity/Dilution Offered (%)',
                    controller: _equityController,
                    hint: defaultEquity,
                    tooltipTitle: 'Equity Offered',
                    tooltipDesc: 'This is the percentage of your company you are willing to give to the investor in exchange for the requested funding amount. This effectively sets your pre-money valuation.',
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    label: 'Use of Funds',
                    controller: _useOfFundsController,
                    maxLines: 3,
                    hint: defaultUseOfFunds,
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    label: 'Expected Milestones With Funding',
                    controller: _milestonesController,
                    maxLines: 3,
                    hint: defaultMilestones,
                  ),
                  const SizedBox(height: 30),

                  const Text('Legal & IP', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppPalette.textPrimary)),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          label: 'Patents Filed',
                          controller: _patentsController,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
                          label: 'Trademark Registered',
                          controller: _trademarksController,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildDropdown(
                    label: 'Licenses/Certifications',
                    value: _selectedLicense,
                    items: ['FDA Approval', 'ISO Certification', 'CE Marking', 'Other'],
                    onChanged: (val) => setState(() => _selectedLicense = val),
                  ),
                  const SizedBox(height: 20),

                  const Text('Company Incorporation Docs', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _pickFile,
                    child: DottedBorder(
                      color: AppPalette.primaryAccent.withOpacity(0.4),
                      strokeWidth: 1.5,
                      dashPattern: const [6, 4],
                      borderType: BorderType.RRect,
                      radius: const Radius.circular(14),
                      child: Container(
                        height: 120,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppPalette.surfaceElevated,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: _uploadedFileName == null
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.cloud_upload_outlined, size: 32, color: AppPalette.primaryAccent),
                                    const SizedBox(height: 8),
                                    const Text('Upload a file or drag and drop', style: TextStyle(fontSize: 13, color: AppPalette.textPrimary, fontWeight: FontWeight.w500)),
                                    const SizedBox(height: 4),
                                    const Text('PDF, DOCX, PNG, JPG up to 10MB', style: TextStyle(fontSize: 11, color: AppPalette.textSecondary)),
                                  ],
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(_uploadedFileName!, style: const TextStyle(fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 4),
                                    const Text('Tap to change file', style: TextStyle(fontSize: 12, color: AppPalette.primaryAccent)),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  const Text('Founder Legal Declarations', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                  const SizedBox(height: 12),
                  _buildRadioOption(0, 'No pending litigation against the company.'),
                  _buildRadioOption(1, 'All intellectual property rights are fully owned by the company.'),
                  _buildRadioOption(2, 'Founders have no prior legal issues related to business practices.'),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          
          Container(
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
                    child: const Text('Back',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppPalette.textPrimary)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppPalette.primaryAccent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _isSaving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text("Next", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
