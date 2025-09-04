import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import 'local_storage_service.dart';
import 'tasks_service.dart';

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
    print('🔍 UserService: getCurrentProfile called');

    // Check if data was just reset by looking at the reset flag
    final wasReset = await _localStorage!.wasDataJustReset();
    if (wasReset) {
      print('🔍 UserService: Data was just reset, clearing cached profile');
      _currentProfile = null;
    }

    if (_currentProfile != null) {
      print(
        '🔍 UserService: Using cached profile with goal: "${_currentProfile!.financialGoal}"',
      );
      return _currentProfile!;
    }

    print('🔍 UserService: Loading profile from localStorage...');
    _currentProfile = await _localStorage!.getUserProfile();

    if (_currentProfile == null) {
      print('🔍 UserService: No profile found, creating new one');
      final userId = _generateUserId();
      _currentProfile = UserProfile(id: userId, createdAt: DateTime.now());
      await _localStorage!.saveUserProfile(_currentProfile!);
      await _localStorage!.saveUserId(userId);
      print('🔍 UserService: Created new profile with ID: $userId');
    } else {
      print(
        '🔍 UserService: Loaded existing profile with goal: "${_currentProfile!.financialGoal}"',
      );
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
    final newTasksInLevel = currentProfile.tasksCompletedInCurrentLevel + 1;

    _currentProfile = currentProfile.copyWith(
      totalTasksCompleted: currentProfile.totalTasksCompleted + 1,
      tasksCompletedInCurrentLevel: newTasksInLevel,
    );

    // Check if player should advance to next level (3 tasks per level)
    if (newTasksInLevel >= 3) {
      _currentProfile = _currentProfile!.copyWith(
        currentLevel: currentProfile.currentLevel + 1,
        tasksCompletedInCurrentLevel: 0, // Reset for new level
      );
    }

    await _localStorage!.saveUserProfile(_currentProfile!);
  }

  Future<bool> hasFinancialGoal() async {
    final profile = await getCurrentProfile();
    final hasGoal =
        profile.financialGoal != null && profile.financialGoal!.isNotEmpty;
    print(
      '🔍 UserService: hasFinancialGoal check - Goal: "${profile.financialGoal}", Result: $hasGoal',
    );
    return hasGoal;
  }

  Future<void> clearUserData() async {
    print('🧹 UserService: Clearing user data...');
    print(
      '🧹 UserService: Current profile before clear: ${_currentProfile?.financialGoal}',
    );
    await _localStorage!.clearUserData();
    _currentProfile = null;
    print('🧹 UserService: Current profile after clear: $_currentProfile');
  }

  Future<String?> getFinancialGoal() async {
    final profile = await getCurrentProfile();
    return profile.financialGoal;
  }

  Future<void> addChisel() async {
    final currentProfile = await getCurrentProfile();
    _currentProfile = currentProfile.copyWith(
      chiselCount: currentProfile.chiselCount + 1,
    );
    await _localStorage!.saveUserProfile(_currentProfile!);
  }

  /// Batch update for task completion - adds chisel and increments task count in one operation
  Future<void> completeTaskAndAddChisel() async {
    final currentProfile = await getCurrentProfile();
    final newTasksInLevel = currentProfile.tasksCompletedInCurrentLevel + 1;

    _currentProfile = currentProfile.copyWith(
      chiselCount: currentProfile.chiselCount + 1,
      totalTasksCompleted: currentProfile.totalTasksCompleted + 1,
      tasksCompletedInCurrentLevel: newTasksInLevel,
    );

    // Check if player should advance to next level (3 tasks per level)
    if (newTasksInLevel >= 3) {
      _currentProfile = _currentProfile!.copyWith(
        currentLevel: _currentProfile!.currentLevel + 1,
        tasksCompletedInCurrentLevel: 0,
      );
    }

    await _localStorage!.saveUserProfile(_currentProfile!);
  }

  Future<void> useChisel() async {
    final currentProfile = await getCurrentProfile();
    if (currentProfile.chiselCount > 0) {
      _currentProfile = currentProfile.copyWith(
        chiselCount: currentProfile.chiselCount - 1,
      );
      await _localStorage!.saveUserProfile(_currentProfile!);
    }
  }

  Future<int> getChiselCount() async {
    final profile = await getCurrentProfile();
    return profile.chiselCount;
  }

  Future<int> getCurrentLevel() async {
    final profile = await getCurrentProfile();
    return profile.currentLevel;
  }

  Future<int> getTasksCompletedInCurrentLevel() async {
    final profile = await getCurrentProfile();
    return profile.tasksCompletedInCurrentLevel;
  }

  Future<double> getLevelProgress() async {
    final tasksCompleted = await getTasksCompletedInCurrentLevel();
    return tasksCompleted / 3.0; // 3 tasks per level
  }

  Future<void> saveTransactionHistory(Map<String, dynamic> transactions) async {
    final currentProfile = await getCurrentProfile();
    _currentProfile = currentProfile.copyWith(transactionHistory: transactions);
    await _localStorage!.saveUserProfile(_currentProfile!);
  }

  Future<Map<String, dynamic>?> getTransactionHistory() async {
    final profile = await getCurrentProfile();
    return profile.transactionHistory;
  }

  /// Resets all singleton instances - call this after data reset
  static void resetInstances() {
    print('🔄 UserService: Resetting singleton instance');
    _instance = null;
  }

  /// Complete reset of all data and services - ONLY for explicit user reset requests
  static Future<void> forceCompleteReset() async {
    print('🔥 UserService: Force complete reset starting...');

    // Clear cached data from current instances before resetting
    if (_instance != null) {
      print('🔥 UserService: Clearing cached profile from current instance');
      _instance!._currentProfile = null;
    }

    // Clear cached tasks data
    TasksService.clearCachedData();

    // Nuclear option: Clear ALL SharedPreferences data
    await LocalStorageService.nuclearClear();

    // Reset all singletons
    UserService.resetInstances();
    LocalStorageService.resetInstances();
    TasksService.resetInstances();

    // Verify reset was successful
    await _verifyResetSuccess();

    print('🔥 UserService: Force complete reset finished');
  }

  /// Verify that the reset was successful by checking for any remaining data
  static Future<void> _verifyResetSuccess() async {
    try {
      // Get fresh instances to verify reset
      final localStorage = await LocalStorageService.getInstance();
      final hasProfile = await localStorage.hasUserProfile();
      final userId = await localStorage.getUserId();
      final tasksJson = await localStorage.getString('daily_tasks');
      final resetFlag = await localStorage.getString('_data_was_reset');

      print(
        '🔍 UserService: Reset verification - hasProfile: $hasProfile, userId: $userId, tasksJson: $tasksJson, resetFlag: $resetFlag',
      );

      // Also check all keys in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();
      print('🔍 UserService: All SharedPreferences keys after reset: $allKeys');

      if (hasProfile || userId != null || tasksJson != null) {
        print(
          '⚠️ UserService: WARNING - Reset may not have been completely successful!',
        );
        print(
          '⚠️ UserService: Remaining data detected - this indicates a problem with the reset process',
        );
      } else {
        print(
          '✅ UserService: Reset verification successful - no user data found',
        );
      }
    } catch (e) {
      print('⚠️ UserService: Error during reset verification: $e');
    }
  }

  /// Gentle cleanup - only removes problematic debug data, preserves user progress
  static Future<void> cleanupDebugData() async {
    print('🧹 UserService: Gentle cleanup of debug data only...');

    try {
      // Get fresh instances
      final tasksService = await TasksService.getInstance();

      // Only remove debug tasks, keep user data
      await tasksService.removeDebugTasks();

      print('🧹 UserService: Debug data cleanup completed');
    } catch (e) {
      print('⚠️ UserService: Error during debug cleanup: $e');
    }
  }

  /// Trigger a manual reset for macOS builds (for testing/debugging)
  static Future<void> triggerManualReset() async {
    print('🔧 UserService: Triggering manual reset for macOS...');

    try {
      final localStorage = await LocalStorageService.getInstance();
      await localStorage.setString('_manual_reset_requested', 'true');

      print(
        '✅ UserService: Manual reset flag set. Restart the app to reset all data.',
      );
    } catch (e) {
      print('⚠️ UserService: Error setting manual reset flag: $e');
    }
  }
}
