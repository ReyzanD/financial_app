import 'package:financial_app/services/local_auth_service.dart';

class ProfileRepository {
  final LocalAuthService _auth;
  ProfileRepository({LocalAuthService? auth})
      : _auth = auth ?? LocalAuthService();
  Future<Map<String, dynamic>> getProfile() async {
    final user = await _auth.getCurrentUser();
    if (user == null) throw Exception('Not authenticated');
    return {'user': user};
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) =>
      _auth.updateProfile(data);
}
