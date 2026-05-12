import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:striv/services/pitch_form_controller.dart';
import 'package:striv/utils/app_palette.dart';

class Pitch_secure extends StatefulWidget {
  final Map<String, Object?> data;

  const Pitch_secure({super.key, required this.data});

  @override
  State<Pitch_secure> createState() => _PitchUploadScreenState();
}

class _PitchUploadScreenState extends State<Pitch_secure> {
  String _pitchVisibility = "Public";
  bool _canDownloadDeck = true;
  bool _canRequestDataRoom = false;
  bool _isSaving = false;

  Future<void> _saveDraft() async {
    setState(() => _isSaving = true);
    final controller = Provider.of<PitchFormController>(context, listen: false);

    String visibilityEnum;
    switch (_pitchVisibility) {
      case 'Invite-Only':
        visibilityEnum = 'INVITE_ONLY';
        break;
      case 'NDA Required':
        visibilityEnum = 'NDA_REQUIRED';
        break;
      default:
        visibilityEnum = 'PUBLIC';
    }

    final stepData = {
      'pitchVisibility': _pitchVisibility,
      'visibility': visibilityEnum,
      'canDownloadDeck': _canDownloadDeck,
      'canRequestDataRoom': _canRequestDataRoom,
    };

    if (controller.ideaId != null) {
      await controller.saveStep(5, stepData);
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
    setState(() => _isSaving = true);

    String visibilityEnum;
    switch (_pitchVisibility) {
      case 'Invite-Only':
        visibilityEnum = 'INVITE_ONLY';
        break;
      case 'NDA Required':
        visibilityEnum = 'NDA_REQUIRED';
        break;
      default:
        visibilityEnum = 'PUBLIC';
    }

    final stepData = {
      'pitchVisibility': _pitchVisibility,
      'visibility': visibilityEnum,
      'canDownloadDeck': _canDownloadDeck,
      'canRequestDataRoom': _canRequestDataRoom,
    };

    final controller = Provider.of<PitchFormController>(context, listen: false);
    if (controller.ideaId != null) {
      await controller.saveStep(5, stepData);
      final submitted = await controller.submitPitch();
      
      setState(() => _isSaving = false);

      if (submitted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Pitch submitted successfully!'),
            backgroundColor: AppPalette.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(controller.error ?? 'Submission failed'),
            backgroundColor: AppPalette.danger,
          ),
        );
      }
    } else {
      setState(() => _isSaving = false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pitch submitted successfully!'),
            backgroundColor: AppPalette.success,
          ),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.background,
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        backgroundColor: AppPalette.background,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: AppPalette.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          "Pitch Upload",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppPalette.textPrimary,
          ),
        ),
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
                const Text('Step 5 of 5', style: TextStyle(fontSize: 12, color: AppPalette.textSecondary)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: const LinearProgressIndicator(
                    value: 1.0,
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
                  const Text("Security & Privacy Settings", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 20),

                  const Text("Pitch Visibility", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildChoiceChip("Public"),
                      const SizedBox(width: 8),
                      _buildChoiceChip("Invite-Only"),
                      const SizedBox(width: 8),
                      _buildChoiceChip("NDA Required"),
                    ],
                  ),
                  const SizedBox(height: 30),

                  const Text("Investor Access Controls", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),

                  _buildSwitchTile(
                    title: "Can download deck",
                    subtitle: "Investors can save the pitch deck.",
                    value: _canDownloadDeck,
                    onChanged: (val) => setState(() => _canDownloadDeck = val),
                  ),
                  const SizedBox(height: 12),
                  _buildSwitchTile(
                    title: "Can request data room",
                    subtitle: "Investors can request access to more files.",
                    value: _canRequestDataRoom,
                    onChanged: (val) => setState(() => _canRequestDataRoom = val),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Note: All decks are automatically watermarked with investor ID and timestamp.",
                    style: TextStyle(fontSize: 12, color: AppPalette.textSecondary),
                  ),
                  const SizedBox(height: 40),

                  const Text("In-App Features Overview", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 20),

                  _buildInfoCard(
                    title: "Validation Layers",
                    subtitle: "Auto cross-check against government databases.",
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    title: "Standardized Cards",
                    subtitle: "Data is presented in a consistent, easy-to-digest format.",
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    title: "Access Control",
                    subtitle: "You control who can access your pitch and data room.",
                  ),
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
                        : const Text("Submit Pitch", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceChip(String label) {
    final isSelected = _pitchVisibility == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _pitchVisibility = label);
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
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppPalette.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: SwitchListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 13, color: AppPalette.textSecondary)),
        value: value,
        onChanged: onChanged,
        activeColor: AppPalette.primaryAccent,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppPalette.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(fontSize: 13, color: AppPalette.textSecondary)),
        ],
      ),
    );
  }
}
