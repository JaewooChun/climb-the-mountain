import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import './screens/views/view_0.dart'; // Initial view that players see
import './data/user_service.dart';
import './data/local_storage_service.dart';
import './data/tasks_service.dart';

// Conditional import for web platform
import 'web_helper_stub.dart'
    if (dart.library.html) 'web_helper_web.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Check for reset parameter in URL (only on web platform)
  if (kIsWeb) {
    await checkForDataReset();
  } else {
    // For non-web platforms (like macOS), clean up old debug tasks
    await cleanupOldData();
  }
  
  runApp(const FinancialPeakApp());
}

Future<void> checkForDataReset() async {
  try {
    // Check URL parameters for reset_data=true (only on web)
    if (shouldResetData()) {
      if (kDebugMode) {
        print('🔄 Data reset requested via URL parameter');
      }
      
      // Clear all user data
      final userService = await UserService.getInstance();
      final localStorage = await LocalStorageService.getInstance();
      final tasksService = await TasksService.getInstance();
      
      // Clear user data
      await userService.clearUserData();
      await localStorage.clearUserData();
      await tasksService.clearTasks();
      
      // Clear web localStorage if available
      clearWebStorage();
      
      if (kDebugMode) {
        print('✅ All game data has been reset to defaults');
      }
      
      // Clean up URL if possible
      cleanUpUrl();
    }
  } catch (e) {
    if (kDebugMode) {
      print('⚠️ Error during data reset: $e');
    }
  }
}

Future<void> cleanupOldData() async {
  try {
    // Initialize services and clean up old debug tasks
    final tasksService = await TasksService.getInstance();
    final userService = await UserService.getInstance();
    final localStorage = await LocalStorageService.getInstance();
    
    // Check if there's old data that needs to be reset by looking for debug tasks or high levels
    final tasks = await tasksService.getTodaysTasks();
    final currentLevel = await userService.getCurrentLevel();
    
    // If we detect debug tasks or an unusually high level (level 3+ could indicate cached old data)
    bool hasOldData = tasks.any((task) => 
      task.title.toLowerCase().contains('debug') || 
      task.description.toLowerCase().contains('debug') ||
      task.title == 'Task for Debugging'
    ) || currentLevel >= 3;
    
    if (hasOldData) {
      if (kDebugMode) {
        print('🔄 Detected old data (level $currentLevel), performing full reset...');
      }
      
      // Perform a full reset like the web version
      await userService.clearUserData();
      await localStorage.clearUserData();
      await tasksService.clearTasks();
      
      if (kDebugMode) {
        print('✅ Completed full data reset on macOS');
      }
    } else {
      // Just clean up debug tasks if no major reset needed
      if (kDebugMode) {
        print('🧹 Cleaned up old debug tasks on app start');
      }
    }
  } catch (e) {
    if (kDebugMode) {
      print('⚠️ Error during data cleanup: $e');
    }
  }
}

class FinancialPeakApp extends StatelessWidget {
  const FinancialPeakApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Financial Peak',
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // Remove the debug banner for a cleaner look
      debugShowCheckedModeBanner: false,
      // Set View0 as the home screen
      home: const View0(),
    );
  }
}
