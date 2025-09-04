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
    final profileJson = _prefs!.getString(_userProfileKey);
    if (profileJson == null) return null;
    
    try {
      final profileMap = json.decode(profileJson) as Map<String, dynamic>;
      return UserProfile.fromJson(profileMap);
    } catch (e) {
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
    await _prefs!.remove(_userProfileKey);
    await _prefs!.remove(_userIdKey);
    
    // Set a flag to indicate data was just reset
    await _prefs!.setBool('_data_was_reset', true);
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
}