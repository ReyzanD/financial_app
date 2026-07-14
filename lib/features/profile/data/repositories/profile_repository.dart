import 'package:financial_app/core/di/service_locator.dart';
import 'package:financial_app/services/api_service.dart';

class ProfileRepository {
  final ApiService _api;
  ProfileRepository({ApiService? api}) : _api = api ?? getIt<ApiService>();
  Future<Map<String, dynamic>> getProfile() => _api.getUserProfile();
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) =>
      _api.updateProfile(data);
}
