import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:financial_app/features/profile/data/repositories/profile_repository.dart';
import 'package:financial_app/services/logger_service.dart';

class ProfileController extends ChangeNotifier {
  final ProfileRepository _r;
  ProfileController({required ProfileRepository repository})
    : _r = repository;

  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  Map<String, dynamic> _profile = {};

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic> get profile => _profile;

  Future<void> loadProfile() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _profile = await _r.getProfile();
    } catch (e) {
      LoggerService.error('Error loading profile', error: e);
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveProfile(Map<String, dynamic> data) async {
    _isSaving = true;
    notifyListeners();
    try {
      await _r.updateProfile(data);
      _profile = data;
    } catch (e) {
      LoggerService.error('Error saving profile', error: e);
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
