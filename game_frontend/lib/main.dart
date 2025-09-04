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
      
      // Use the force complete reset method
      await UserService.forceCompleteReset();
      
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
    
    // Check if there are debug tasks or unusually high levels that indicate corrupted data
    final tasks = await tasksService.getTodaysTasks();
    final currentLevel = await userService.getCurrentLevel();
    print('🔍 cleanupOldData: Found ${tasks.length} tasks, current level: $currentLevel');
    
    // Only reset if we detect debug tasks or unusually high levels (indicating old test data)
    bool hasDebugTasks = tasks.any((task) => 
      task.title.toLowerCase().contains('debug') || 
      task.description.toLowerCase().contains('debug') ||
      task.title == 'Task for Debugging'
    );
    
    bool hasOldData = hasDebugTasks || currentLevel >= 10; // Only reset for very high levels
    print('🔍 cleanupOldData: Has debug tasks: $hasDebugTasks, High level: ${currentLevel >= 10}, Reset needed: $hasOldData');
    
    if (hasOldData) {
      if (kDebugMode) {
        print('🔄 Detected problematic data (debug tasks or very high level), performing reset...');
      }
      
      // Use the force complete reset method only for serious corruption
      await UserService.forceCompleteReset();
      
      if (kDebugMode) {
        print('✅ Completed cleanup of corrupted data');
      }
    } else {
      // No problematic data detected, just gentle cleanup
      await UserService.cleanupDebugData();
      
      if (kDebugMode) {
        print('🧹 No problematic data found, preserving user progress');
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
