import 'dart:math';
import '../models/user_profile.dart';
import 'local_storage_service.dart';

class UserService {
  static UserService? _instance;
  LocalStorageService? _localStorage;
  UserProfile? _currentProfile;

  UserService._();

  static Future<UserService> getInstance() async {
    _instance ??= UserService._();
    _instance!._localStorage ??= await LocalStorageService.getInstance();
    return _instance!;
  }

  String _generateUserId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(10000);
    return 'user_${timestamp}_$random';
  }

  Future<UserProfile> getCurrentProfile() async {
    if (_currentProfile != null) return _currentProfile!;
    
    _currentProfile = await _localStorage!.getUserProfile();
    
    if (_currentProfile == null) {
      final userId = _generateUserId();
      _currentProfile = UserProfile(
        id: userId,
        createdAt: DateTime.now(),
      );
      await _localStorage!.saveUserProfile(_currentProfile!);
      await _localStorage!.saveUserId(userId);
    }
    
    return _currentProfile!;
  }

  Future<void> setFinancialGoal(String goal) async {
    final currentProfile = await getCurrentProfile();
    _currentProfile = currentProfile.copyWith(
      financialGoal: goal,
      goalSetAt: DateTime.now(),
    );
    await _localStorage!.saveUserProfile(_currentProfile!);
  }

  Future<void> updateLevel(int newLevel) async {
    final currentProfile = await getCurrentProfile();
    _currentProfile = currentProfile.copyWith(currentLevel: newLevel);
    await _localStorage!.saveUserProfile(_currentProfile!);
  }

  Future<void> incrementTasksCompleted() async {
    final currentProfile = await getCurrentProfile();
    _currentProfile = currentProfile.copyWith(
      totalTasksCompleted: currentProfile.totalTasksCompleted + 1,
    );
    await _localStorage!.saveUserProfile(_currentProfile!);
  }

  Future<bool> hasFinancialGoal() async {
    final profile = await getCurrentProfile();
    return profile.financialGoal != null && profile.financialGoal!.isNotEmpty;
  }

  Future<void> clearUserData() async {
    await _localStorage!.clearUserData();
    _currentProfile = null;
  }

  Future<String?> getFinancialGoal() async {
    final profile = await getCurrentProfile();
    return profile.financialGoal;
  }
}