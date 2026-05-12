import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter/cupertino.dart';
import 'package:striv/pages/entrepreneur/pitch_upload2/pitch_step3_track.dart';
import 'package:striv/services/pitch_form_controller.dart';
import 'package:striv/utils/app_palette.dart';

class MarketOpportunityForm extends StatefulWidget {
  final Map<String, dynamic> step1Data;

  const MarketOpportunityForm({super.key, required this.step1Data});

  @override
  State<MarketOpportunityForm> createState() => _MarketOpportunityFormState();
}

class _MarketOpportunityFormState extends State<MarketOpportunityForm> {
  final _formKey = GlobalKey<FormState>();

  // Multi-select fields
  List<String> _selectedIndustries = [];
  List<String> _selectedGeographies = [];
  List<String> _selectedRevenueStreams = [];
  List<String> _selectedChannels = [];

  final TextEditingController _keyDifferentiatorController = TextEditingController();
  final TextEditingController _tamController = TextEditingController();
  final TextEditingController _samController = TextEditingController();
  final TextEditingController _somController = TextEditingController();
  final TextEditingController _marketGrowthController = TextEditingController();
  final TextEditingController _pricingController = TextEditingController();
  final TextEditingController _goToMarketController = TextEditingController();

  final List<String> _industryTags = ["Tech", "Healthcare", "Finance", "Education"];
  final List<String> _geographyTargets = ["Global", "North America", "Europe", "Asia"];
  final List<String> _revenueStreams = ["Subscription", "Freemium", "One-time Purchase", "Advertising", "Licensing"];
  final List<String> _distributionChannels = ["Online", "Retail", "Partners", "Direct Sales"];

  bool _isSaving = false;

  @override
  void dispose() {
    _keyDifferentiatorController.dispose();
    _tamController.dispose();
    _samController.dispose();
    _somController.dispose();
    _marketGrowthController.dispose();
    _pricingController.dispose();
    _goToMarketController.dispose();
    super.dispose();
  }

  Future<void> _saveDraft() async {
    setState(() => _isSaving = true);
    final controller = Provider.of<PitchFormController>(context, listen: false);
    
    final stepData = {
      'industry': _selectedIndustries.join(', '),
      'targetGeography': _selectedGeographies.join(', '),
      'keyDifferentiator': _keyDifferentiatorController.text.trim(),
      'tam': _tamController.text.trim(),
      'sam': _samController.text.trim(),
      'som': _somController.text.trim(),
      'marketGrowthRate': _marketGrowthController.text.trim(),
      'revenueStreams': _selectedRevenueStreams.join(', '),
      'pricingExample': _pricingController.text.trim(),
      'distributionChannels': _selectedChannels.join(', '),
      'goToMarketStrategy': _goToMarketController.text.trim(),
    };

    if (controller.ideaId != null) {
      await controller.saveStep(2, stepData);
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

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final stepData = {
        'industry': _selectedIndustries.join(', '),
        'targetGeography': _selectedGeographies.join(', '),
        'keyDifferentiator': _keyDifferentiatorController.text.trim(),
        'tam': _tamController.text.trim(),
        'sam': _samController.text.trim(),
        'som': _somController.text.trim(),
        'marketGrowthRate': _marketGrowthController.text.trim(),
        'revenueStreams': _selectedRevenueStreams.join(', '),
        'pricingExample': _pricingController.text.trim(),
        'distributionChannels': _selectedChannels.join(', '),
        'goToMarketStrategy': _goToMarketController.text.trim(),
      };

      // Save to API
      setState(() => _isSaving = true);
      final controller = Provider.of<PitchFormController>(context, listen: false);
      if (controller.ideaId != null) {
        await controller.saveStep(2, stepData);
      }
      setState(() => _isSaving = false);

      final allData = {
        ...widget.step1Data,
        ...stepData,
      };

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TractionKPIsForm(data: allData),
          ),
        );
      }
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
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildMultiSelect({
    required String label,
    required List<String> items,
    required List<String> selectedList,
    required Function(List<String>) onSelectionChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final List<String>? results = await showDialog(
              context: context,
              builder: (context) {
                List<String> tempSelected = List.from(selectedList);
                return StatefulBuilder(
                  builder: (context, setStateDialog) {
                    return AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      title: Text("Select $label", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                      content: SingleChildScrollView(
                        child: Column(
                          children: items.map((item) {
                            return CheckboxListTile(
                              activeColor: AppPalette.primaryAccent,
                              value: tempSelected.contains(item),
                              title: Text(item),
                              onChanged: (val) {
                                setStateDialog(() {
                                  if (val == true) {
                                    tempSelected.add(item);
                                  } else {
                                    tempSelected.remove(item);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, null),
                          child: const Text("Cancel", style: TextStyle(color: AppPalette.textSecondary)),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, tempSelected),
                          style: ElevatedButton.styleFrom(backgroundColor: AppPalette.primaryAccent),
                          child: const Text("Done", style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    );
                  },
                );
              },
            );

            if (results != null) {
              setState(() => onSelectionChanged(results));
            }
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(14),
              color: AppPalette.surfaceCard,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    selectedList.isEmpty ? "Select $label" : selectedList.join(", "),
                    style: TextStyle(color: selectedList.isEmpty ? AppPalette.textSecondary : AppPalette.textPrimary),
                  ),
                ),
                const Icon(Iconsax.arrow_down_1, size: 18, color: AppPalette.textSecondary),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (selectedList.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: selectedList.map((item) {
              return Chip(
                label: Text(item, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                backgroundColor: AppPalette.primaryAccent.withOpacity(0.1),
                side: BorderSide.none,
                deleteIcon: const Icon(Icons.close, size: 14),
                onDeleted: () {
                  setState(() => selectedList.remove(item));
                },
              );
            }).toList(),
          ),
        const SizedBox(height: 16),
      ],
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
        title: const Text("Market Opportunity", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
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
                const Text("Step 2 of 5", style: TextStyle(fontSize: 12, color: AppPalette.textSecondary)),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: const LinearProgressIndicator(
                    value: 2 / 5,
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
          child: ListView(
            children: [
              _buildMultiSelect(
                label: "Industry / Sector Tags",
                items: _industryTags,
                selectedList: _selectedIndustries,
                onSelectionChanged: (list) => _selectedIndustries = list,
              ),
              _buildMultiSelect(
                label: "Geography Target",
                items: _geographyTargets,
                selectedList: _selectedGeographies,
                onSelectionChanged: (list) => _selectedGeographies = list,
              ),
              _buildTextField(
                label: "Key Differentiator",
                controller: _keyDifferentiatorController,
                hint: "e.g., Proprietary AI algorithm",
              ),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      label: "TAM",
                      controller: _tamController,
                      hint: "\$1B",
                      tooltipTitle: "Total Addressable Market (TAM)",
                      tooltipDesc: "TAM refers to the total market demand for a product or service. It's the maximum amount of revenue a business could possibly generate if it captured 100% of its market.",
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      label: "SAM",
                      controller: _samController,
                      hint: "\$100M",
                      tooltipTitle: "Serviceable Available Market (SAM)",
                      tooltipDesc: "SAM is the segment of the TAM targeted by your products and services which is within your geographical reach. It's the realistic portion of the market you can actually serve.",
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      label: "SOM",
                      controller: _somController,
                      hint: "\$10M",
                      tooltipTitle: "Serviceable Obtainable Market (SOM)",
                      tooltipDesc: "SOM is the portion of the SAM that you can capture in the short term (usually 1-3 years). It takes into account your current resources, competition, and go-to-market strategy.",
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      label: "Market Growth Rate",
                      controller: _marketGrowthController,
                      hint: "15% CAGR",
                      tooltipTitle: "Compound Annual Growth Rate (CAGR)",
                      tooltipDesc: "CAGR represents the smoothed annualized rate of growth of your market over a specified period of time. Investors use this to understand if the market is expanding or shrinking.",
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                "Business Model",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              _buildMultiSelect(
                label: "Revenue Streams",
                items: _revenueStreams,
                selectedList: _selectedRevenueStreams,
                onSelectionChanged: (list) => _selectedRevenueStreams = list,
              ),
              _buildTextField(
                label: "Current Pricing Example",
                controller: _pricingController,
                hint: "e.g., \$99/month Pro Plan",
              ),
              _buildMultiSelect(
                label: "Distribution Channels",
                items: _distributionChannels,
                selectedList: _selectedChannels,
                onSelectionChanged: (list) => _selectedChannels = list,
              ),
              _buildTextField(
                label: "Go-To-Market Strategy",
                controller: _goToMarketController,
                hint: "Describe your strategy",
                maxLines: 4,
              ),
              const SizedBox(height: 80),
            ],
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
                onPressed: _isSaving ? null : _submitForm,
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
