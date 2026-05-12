import 'dart:io';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

/// Controller that manages pitch form state across all 5 steps,
/// persisting drafts to the backend and handling final submission.
class PitchFormController extends ChangeNotifier {
  final ApiService _api = ApiService();

  String? _ideaId;
  int _currentStep = 1;
  bool _isSaving = false;
  bool _isSubmitting = false;
  String? _error;
  Map<String, dynamic> _formData = {};

  String? get ideaId => _ideaId;
  int get currentStep => _currentStep;
  bool get isSaving => _isSaving;
  bool get isSubmitting => _isSubmitting;
  String? get error => _error;
  Map<String, dynamic> get formData => _formData;

  /// Create a new idea draft on the backend (called in Step 1)
  Future<bool> createDraft({
    required String businessType,
    required String companyName,
    required String tagline,
    required String oneLiner,
  }) async {
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _api.createIdea({
        'businessType': businessType,
        'companyName': companyName,
        'tagline': tagline,
        'oneLiner': oneLiner,
      });

      _ideaId = result['id'];
      _currentStep = 1;
      _formData = result;
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to save draft: $e';
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  /// Save step data to the backend
  Future<bool> saveStep(int stepNumber, Map<String, dynamic> stepData) async {
    if (_ideaId == null) {
      _error = 'No idea ID — please start from Step 1';
      notifyListeners();
      return false;
    }

    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _api.updateIdeaStep(_ideaId!, stepNumber, stepData);
      _currentStep = stepNumber;
      _formData = {..._formData, ...result};
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to save step $stepNumber: $e';
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  /// Upload a file and return the URL
  Future<String?> uploadFile(File file, {String folder = 'ideas'}) async {
    try {
      final result = await _api.uploadFile(file, folder: folder);
      return result['url'];
    } catch (e) {
      _error = 'File upload failed: $e';
      notifyListeners();
      return null;
    }
  }

  /// Final submit
  Future<bool> submitPitch() async {
    if (_ideaId == null) return false;

    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      await _api.submitIdea(_ideaId!);
      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Submission failed: $e';
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  /// Load an existing draft to continue editing
  Future<bool> loadDraft(String ideaId) async {
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _api.getIdea(ideaId);
      _ideaId = ideaId;
      _formData = result;
      _currentStep = result['currentStep'] ?? 1;
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to load draft: $e';
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  /// Convert radio value to API business type
  static String roleToBusinessType(String? roleCode) {
    switch (roleCode) {
      case 'PP':
        return 'PATENTABLE';
      case 'ST':
        return 'STARTUP';
      case 'RB':
        return 'REGULAR_BUSINESS';
      default:
        return 'STARTUP';
    }
  }

  /// Reset controller for new pitch
  void reset() {
    _ideaId = null;
    _currentStep = 1;
    _isSaving = false;
    _isSubmitting = false;
    _error = null;
    _formData = {};
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
