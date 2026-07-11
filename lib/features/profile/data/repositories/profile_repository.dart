import 'package:financial_app/core/di/service_locator.dart';
import 'package:financial_app/services/api_service.dart';
import 'package:financial_app/features/profile/domain/repositories/profile_repository_interface.dart';

class ProfileRepository implements ProfileRepositoryInterface {
  final ApiService _api;
  ProfileRepository({ApiService? api}) : _api = api ?? getIt<ApiService>();
  @override Future<Map<String, dynamic>> getProfile() => _api.getUserProfile();
  @override Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) => _api.updateProfile(data);
}
