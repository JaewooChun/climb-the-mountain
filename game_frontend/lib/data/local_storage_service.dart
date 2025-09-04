import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';

class LocalStorageService {
  static const String _userProfileKey = 'user_profile';
  static const String _userIdKey = 'user_id';
  
  static LocalStorageService? _instance;
  SharedPreferences? _prefs;
  
  LocalStorageService._();
  
  static Future<LocalStorageService> getInstance() async {
    _instance ??= LocalStorageService._();
    _instance!._prefs ??= await SharedPreferences.getInstance();
    return _instance!;
  }

  Future<void> saveUserProfile(UserProfile profile) async {
    final profileJson = json.encode(profile.toJson());
    await _prefs!.setString(_userProfileKey, profileJson);
  }

  Future<UserProfile?> getUserProfile() async {
    print('🔍 LocalStorageService: getUserProfile called');
    print('🔍 LocalStorageService: Has profile key: ${_prefs!.containsKey(_userProfileKey)}');
    
    final profileJson = _prefs!.getString(_userProfileKey);
    print('🔍 LocalStorageService: Profile JSON: $profileJson');
    
    if (profileJson == null) {
      print('🔍 LocalStorageService: No profile JSON found, returning null');
      return null;
    }
    
    try {
      final profileMap = json.decode(profileJson) as Map<String, dynamic>;
      print('🔍 LocalStorageService: Successfully decoded profile map: $profileMap');
      final profile = UserProfile.fromJson(profileMap);
      print('🔍 LocalStorageService: Created profile with goal: "${profile.financialGoal}"');
      return profile;
    } catch (e) {
      print('🔍 LocalStorageService: Error decoding profile: $e');
      return null;
    }
  }

  Future<String?> getUserId() async {
    return _prefs!.getString(_userIdKey);
  }

  Future<void> saveUserId(String userId) async {
    await _prefs!.setString(_userIdKey, userId);
  }

  Future<void> clearUserData() async {
    print('🧹 LocalStorageService: Clearing user data...');
    print('🧹 LocalStorageService: Before clear - has profile: ${_prefs!.containsKey(_userProfileKey)}');
    print('🧹 LocalStorageService: Before clear - has user ID: ${_prefs!.containsKey(_userIdKey)}');
    
    // Get all keys for debugging
    final allKeys = _prefs!.getKeys();
    print('🧹 LocalStorageService: All keys before clear: $allKeys');
    
    // Clear the specific keys
    final profileRemoved = await _prefs!.remove(_userProfileKey);
    final userIdRemoved = await _prefs!.remove(_userIdKey);
    
    print('🧹 LocalStorageService: Profile removal success: $profileRemoved');
    print('🧹 LocalStorageService: User ID removal success: $userIdRemoved');
    
    // Also clear any tasks
    final tasksRemoved = await _prefs!.remove('daily_tasks');
    print('🧹 LocalStorageService: Tasks removal success: $tasksRemoved');
    
    // Force reload preferences to ensure changes are applied
    await _prefs!.reload();
    
    print('🧹 LocalStorageService: After reload - has profile: ${_prefs!.containsKey(_userProfileKey)}');
    print('🧹 LocalStorageService: After reload - has user ID: ${_prefs!.containsKey(_userIdKey)}');
    
    // Get all keys after clear
    final allKeysAfter = _prefs!.getKeys();
    print('🧹 LocalStorageService: All keys after clear: $allKeysAfter');
    
    // Set a flag to indicate data was just reset
    await _prefs!.setBool('_data_was_reset', true);
    print('🧹 LocalStorageService: Set reset flag');
  }
  
  Future<bool> wasDataJustReset() async {
    final wasReset = _prefs!.getBool('_data_was_reset') ?? false;
    if (wasReset) {
      // Clear the flag after checking
      await _prefs!.remove('_data_was_reset');
      return true;
    }
    return false;
  }

  Future<bool> hasUserProfile() async {
    return _prefs!.containsKey(_userProfileKey);
  }

  Future<String?> getString(String key) async {
    return _prefs!.getString(key);
  }

  Future<void> setString(String key, String value) async {
    await _prefs!.setString(key, value);
  }

  Future<void> removeKey(String key) async {
    await _prefs!.remove(key);
  }

  /// Resets all singleton instances - call this after data reset
  static void resetInstances() {
    print('🔄 LocalStorageService: Resetting singleton instance');
    _instance = null;
  }

  /// Nuclear option - clear ALL preferences data (for debugging)
  static Future<void> clearAllData() async {
    print('💥 LocalStorageService: Nuclear clear - removing ALL SharedPreferences data');
    final prefs = await SharedPreferences.getInstance();
    
    // Get all keys for logging
    final allKeys = prefs.getKeys();
    print('💥 LocalStorageService: Clearing keys: $allKeys');
    
    // Set the reset flag BEFORE clearing everything
    await prefs.setBool('_data_was_reset', true);
    print('💥 LocalStorageService: Set reset flag BEFORE clearing');
    
    // Clear everything EXCEPT the reset flag
    for (final key in allKeys) {
      if (key != '_data_was_reset') {
        await prefs.remove(key);
      }
    }
    
    print('💥 LocalStorageService: Cleared all data except reset flag');
    
    // Reload to ensure changes are applied
    await prefs.reload();
    
    final remainingKeys = prefs.getKeys();
    print('💥 LocalStorageService: Remaining keys after clear: $remainingKeys');
    
    // Reset singleton to force fresh instance
    _instance = null;
  }
}