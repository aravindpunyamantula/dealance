import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter/cupertino.dart';
import 'package:striv/pages/entrepreneur/pitch_upload2/pitch_step4.dart';
import 'package:striv/services/pitch_form_controller.dart';
import 'package:striv/utils/app_palette.dart';

class TractionKPIsForm extends StatefulWidget {
  final Map<String, dynamic>? previousData;

  const TractionKPIsForm({
    super.key,
    this.previousData,
    required Map<String, dynamic> data,
  });

  @override
  State<TractionKPIsForm> createState() => _TractionKPIsFormState();
}

class _TractionKPIsFormState extends State<TractionKPIsForm> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _customersController = TextEditingController();
  final TextEditingController _revenueController = TextEditingController();
  final TextEditingController _metricValueController = TextEditingController();
  final TextEditingController _milestoneDescController = TextEditingController();
  final TextEditingController _valuationController = TextEditingController();
  final TextEditingController _revenueHistoryController = TextEditingController();
  final TextEditingController _expensesController = TextEditingController();
  final TextEditingController _runwayController = TextEditingController();
  final TextEditingController _prevAmountController = TextEditingController();
  final TextEditingController _prevInvestorsController = TextEditingController();
  final TextEditingController _prevTypeController = TextEditingController();

  final List<String> _growthMetrics = [
    'MAU',
    'CAC',
    'Retention',
    'DAU',
    'LTV',
    'Churn',
  ];
  final Set<String> _selectedMetrics = {};

  DateTime? _milestoneDate;

  String? _tractionFileName;
  String? _financialFileName;
  bool _isSaving = false;

  @override
  void dispose() {
    _customersController.dispose();
    _revenueController.dispose();
    _metricValueController.dispose();
    _milestoneDescController.dispose();
    _valuationController.dispose();
    _revenueHistoryController.dispose();
    _expensesController.dispose();
    _runwayController.dispose();
    _prevAmountController.dispose();
    _prevInvestorsController.dispose();
    _prevTypeController.dispose();
    super.dispose();
  }

  Future<void> _pickFile({required bool isTraction}) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx', 'pptx', 'xlsx'],
      );

      if (result != null && result.files.isNotEmpty) {
        final name = result.files.first.name;
        setState(() {
          if (isTraction) {
            _tractionFileName = name;
          } else {
            _financialFileName = name;
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to pick file: $e')));
    }
  }

  Future<void> _pickMilestoneDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _milestoneDate ?? now,
      firstDate: DateTime(now.year - 15),
      lastDate: DateTime(now.year + 5),
    );

    if (picked != null) {
      setState(() {
        _milestoneDate = picked;
      });
    }
  }

  String _formatDate(DateTime d) {
    return '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}/${d.year}';
  }

  void _toggleMetric(String metric) {
    setState(() {
      if (_selectedMetrics.contains(metric)) {
        _selectedMetrics.remove(metric);
      } else {
        _selectedMetrics.add(metric);
      }
    });
  }

  Future<void> _saveDraft() async {
    setState(() => _isSaving = true);
    final controller = Provider.of<PitchFormController>(context, listen: false);
    
    final stepData = {
      'currentCustomers': _customersController.text.trim(),
      'revenue': _revenueController.text.trim(),
      'selectedMetrics': _selectedMetrics.toList().join(', '),
      'metricsValue': _metricValueController.text.trim(),
      'milestoneDescription': _milestoneDescController.text.trim(),
      'milestoneDate': _milestoneDate != null ? _formatDate(_milestoneDate!) : null,
      'tractionFile': _tractionFileName,
      'currentValuation': _valuationController.text.trim(),
      'revenueHistory': _revenueHistoryController.text.trim(),
      'expenses': _expensesController.text.trim(),
      'runway': _runwayController.text.trim(),
      'previousFundingAmount': _prevAmountController.text.trim(),
      'previousInvestors': _prevInvestorsController.text.trim(),
      'previousFundingType': _prevTypeController.text.trim(),
      'financialDocs': _financialFileName,
    };

    if (controller.ideaId != null) {
      await controller.saveStep(3, stepData);
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
    if (_formKey.currentState!.validate()) {
      final stepData = {
        'currentCustomers': _customersController.text.trim(),
        'revenue': _revenueController.text.trim(),
        'selectedMetrics': _selectedMetrics.toList().join(', '),
        'metricsValue': _metricValueController.text.trim(),
        'milestoneDescription': _milestoneDescController.text.trim(),
        'milestoneDate': _milestoneDate != null ? _formatDate(_milestoneDate!) : null,
        'tractionFile': _tractionFileName,
        'currentValuation': _valuationController.text.trim(),
        'revenueHistory': _revenueHistoryController.text.trim(),
        'expenses': _expensesController.text.trim(),
        'runway': _runwayController.text.trim(),
        'previousFundingAmount': _prevAmountController.text.trim(),
        'previousInvestors': _prevInvestorsController.text.trim(),
        'previousFundingType': _prevTypeController.text.trim(),
        'financialDocs': _financialFileName,
      };

      setState(() => _isSaving = true);
      final controller = Provider.of<PitchFormController>(context, listen: false);
      if (controller.ideaId != null) {
        await controller.saveStep(3, stepData);
      }
      setState(() => _isSaving = false);

      final merged = {
        ...?widget.previousData,
        ...stepData,
      };

      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => PitchFundScreen(data: merged)),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill required fields'), backgroundColor: AppPalette.danger),
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
    required TextEditingController controller,
    String? label,
    required String hint,
    int maxLines = 1,
    String? tooltipTitle,
    String? tooltipDesc,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Row(
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
              if (tooltipTitle != null && tooltipDesc != null)
                _buildInfoIcon(tooltipTitle, tooltipDesc),
            ],
          ),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: controller,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: (val) => val == null || val.trim().isEmpty ? "Required" : null,
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
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _sectionTitle(String text, {String? tooltipTitle, String? tooltipDesc}) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 12),
      child: Row(
        children: [
          Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppPalette.textPrimary)),
          if (tooltipTitle != null && tooltipDesc != null)
            _buildInfoIcon(tooltipTitle, tooltipDesc),
        ],
      ),
    );
  }

  Widget _dashedUploadBox({
    required String label,
    required String subLabel,
    required VoidCallback onTap,
    String? fileName,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: DottedBorder(
        color: AppPalette.primaryAccent.withOpacity(0.4),
        strokeWidth: 1.5,
        dashPattern: const [6, 4],
        borderType: BorderType.RRect,
        radius: const Radius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 22),
          decoration: BoxDecoration(
            color: AppPalette.surfaceElevated,
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_upload_outlined,
                size: 28,
                color: AppPalette.primaryAccent,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppPalette.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subLabel,
                style: const TextStyle(fontSize: 12, color: AppPalette.textSecondary),
              ),
              if (fileName != null) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle, color: AppPalette.success, size: 20),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        fileName,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
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
        title: const Text('Pitch Deck', style: TextStyle(color: AppPalette.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
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
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Step 3 of 5', style: TextStyle(color: AppPalette.textSecondary, fontSize: 12)),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: const LinearProgressIndicator(
                    value: 3 / 5,
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                _sectionTitle('Traction & KPIs'),
                _buildTextField(
                  label: 'Current Customers',
                  controller: _customersController,
                  hint: 'Current Customers/Users',
                ),
                _buildTextField(
                  label: 'Revenue (MRR/ARR)',
                  controller: _revenueController,
                  hint: '\$10k MRR',
                  tooltipTitle: 'Monthly / Annual Recurring Revenue',
                  tooltipDesc: 'MRR is the predictable total revenue generated by your business from all the active subscriptions in a particular month. ARR is simply the MRR multiplied by 12.',
                ),

                _sectionTitle('Growth Metrics', 
                  tooltipTitle: 'Growth Metrics Glossary', 
                  tooltipDesc: '• MAU/DAU: Monthly/Daily Active Users\n• CAC: Customer Acquisition Cost - How much it costs to acquire a new customer.\n• LTV: Lifetime Value - Total revenue expected from a single customer.\n• Churn: The rate at which customers stop doing business with you.'
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _growthMetrics.map((m) {
                    final selected = _selectedMetrics.contains(m);
                    return FilterChip(
                      label: Text(m),
                      selected: selected,
                      onSelected: (_) => _toggleMetric(m),
                      selectedColor: AppPalette.primaryAccent.withOpacity(0.1),
                      checkmarkColor: AppPalette.primaryAccent,
                      backgroundColor: AppPalette.surfaceElevated,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                        side: BorderSide(color: selected ? AppPalette.primaryAccent : Colors.transparent),
                      ),
                      labelStyle: TextStyle(
                        color: selected ? AppPalette.primaryAccent : AppPalette.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: _metricValueController,
                  hint: 'e.g. CAC = \$50, LTV = \$500',
                  maxLines: 2,
                ),

                _sectionTitle('Milestones Achieved'),
                _buildTextField(
                  controller: _milestoneDescController,
                  maxLines: 3,
                  hint: 'Describe key milestones (e.g., launched MVP, hit 10k users)',
                ),

                const Text('Milestone Date', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _pickMilestoneDate,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppPalette.surfaceCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _milestoneDate == null ? 'mm/dd/yyyy' : _formatDate(_milestoneDate!),
                            style: TextStyle(
                              color: _milestoneDate == null ? AppPalette.textSecondary : AppPalette.textPrimary,
                            ),
                          ),
                        ),
                        const Icon(Iconsax.calendar_1, color: AppPalette.textSecondary, size: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                _dashedUploadBox(
                  label: 'Tap to upload Traction Data',
                  subLabel: 'PDF, DOCX, or PPTX (Max 10MB)',
                  onTap: () => _pickFile(isTraction: true),
                  fileName: _tractionFileName,
                ),
                const SizedBox(height: 24),

                _sectionTitle('Financials'),
                _buildTextField(
                  label: 'Current Valuation',
                  controller: _valuationController,
                  hint: '\$5M Post-Money',
                ),
                _buildTextField(
                  label: 'Revenue History (last 12 months)',
                  controller: _revenueHistoryController,
                  hint: '\$100k generated',
                ),
                _buildTextField(
                  label: 'Expenses / Burn Rate',
                  controller: _expensesController,
                  hint: '\$10k/month',
                  tooltipTitle: 'Burn Rate',
                  tooltipDesc: 'Burn rate is the pace at which a new company runs through its cash reserves before it starts generating positive cash flow. Usually expressed as cash spent per month.',
                ),
                _buildTextField(
                  label: 'Runway Left',
                  controller: _runwayController,
                  hint: '18 months',
                  tooltipTitle: 'Runway',
                  tooltipDesc: 'Runway is how long your company can survive if your income and expenses stay constant. Calculated by dividing your cash reserves by your monthly burn rate.',
                ),

                _sectionTitle('Previous Funding Rounds'),
                _buildTextField(
                  label: 'Amount Raised',
                  controller: _prevAmountController,
                  hint: '\$500k',
                ),
                _buildTextField(
                  label: 'Investor Names',
                  controller: _prevInvestorsController,
                  hint: 'Sequoia, Y Combinator',
                ),
                _buildTextField(
                  label: 'Type of Round',
                  controller: _prevTypeController,
                  hint: 'Pre-Seed, Seed',
                ),
                const SizedBox(height: 12),

                _dashedUploadBox(
                  label: 'Tap to upload Financial Docs',
                  subLabel: 'Balance sheets, P&L, etc.',
                  onTap: () => _pickFile(isTraction: false),
                  fileName: _financialFileName,
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
    );
  }
}
