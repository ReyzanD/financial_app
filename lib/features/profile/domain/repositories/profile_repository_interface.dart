abstract class ProfileRepositoryInterface {
  Future<Map<String, dynamic>> getProfile();
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data);
}
