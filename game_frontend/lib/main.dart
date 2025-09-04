import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import './screens/views/view_0.dart'; // Initial view that players see
import './data/user_service.dart';
import './data/local_storage_service.dart';
import './data/tasks_service.dart';

// Conditional import for web platform
import 'web_helper_stub.dart' if (dart.library.html) 'web_helper_web.dart';

void main() async {
  print('main(): Starting Financial Peak app...');
  WidgetsFlutterBinding.ensureInitialized();

  // Check for reset requests from start.py (cross-platform)
  print('main(): About to check for reset requests...');
  await checkForResetRequest();

  // Check for reset parameter in URL (only on web platform)
  if (kIsWeb) {
    await checkForDataReset();
  } else {
    // For non-web platforms (like macOS), clean up old debug tasks
    await cleanupOldData();
  }

  runApp(const FinancialPeakApp());
}

Future<void> checkForResetRequest() async {
  print('checkForResetRequest: Starting reset check...');
  try {
    // Check for reset flag file created by start.py (cross-platform)
    if (!kIsWeb) {
      print(
        'checkForResetRequest: Running on non-web platform, checking for reset flag file...',
      );
      // For non-web platforms, check for the reset flag file
      // First, try to find the project root by looking for start.py
      print('Attempting to find project root by looking for start.py...');

      // For macOS apps, we need to look in the user's home directory and common project locations
      final homeDir = Platform.environment['HOME'] ?? '';
      print('Home directory: $homeDir');

      // Start with basic paths and add more as we find them
      // Only include paths that are likely to be accessible by the Flutter app
      final possiblePaths = <String>[
        'RESET_REQUESTED.flag', // Current directory
        '../RESET_REQUESTED.flag', // Parent directory (if in game_frontend/)
        '../../RESET_REQUESTED.flag', // Project root (if in game_frontend/lib/)
      ];

      // Also check for reset flag directly in home directory (for macOS app)
      try {
        final homeResetFlag = File('$homeDir/RESET_REQUESTED.flag');
        if (await homeResetFlag.exists()) {
          print('Found reset flag file in home directory!');
          possiblePaths.add('$homeDir/RESET_REQUESTED.flag');
        } else {
          print('No reset flag file found in home directory');
        }
      } catch (e) {
        // Skip if we can't access home directory
        if (!e.toString().contains('Operation not permitted')) {
          print('Could not check home directory for reset flag: $e');
        }
      }

      // Check for reset flag in app's Documents directory (accessible by sandboxed apps)
      try {
        final documentsDir = await getApplicationDocumentsDirectory();
        print('App Documents directory: ${documentsDir.path}');
        final documentsResetFlag = File(
          '${documentsDir.path}/RESET_REQUESTED.flag',
        );
        if (await documentsResetFlag.exists()) {
          print('Found reset flag file in app Documents directory!');
          possiblePaths.add('${documentsDir.path}/RESET_REQUESTED.flag');
        } else {
          print('No reset flag file found in app Documents directory');
        }
      } catch (e) {
        print('Could not check app Documents directory for reset flag: $e');
      }

      final projectRootPaths = [
        '.', '..', '../..', // Only check accessible relative paths
        '$homeDir/projects/financial-peak', // Direct path to project
        '$homeDir/Desktop/financial-peak', // Desktop location
        '$homeDir/Documents/financial-peak', // Documents location
        '$homeDir/Development/financial-peak', // Development location
      ];

      String? projectRootPath;

      for (final path in projectRootPaths) {
        try {
          final startPyFile = File('$path/start.py');
          if (await startPyFile.exists()) {
            projectRootPath = path;
            print('Found start.py at: ${startPyFile.absolute.path}');
            print('Project root path: $path');
            break;
          }
        } catch (e) {
          // Skip paths that we can't access due to permissions
          if (!e.toString().contains('Operation not permitted')) {
            print(
              'Skipping inaccessible project path: $path (${e.toString()})',
            );
          }
          continue;
        }
      }

      if (projectRootPath != null) {
        try {
          final resetFlagInProjectRoot = File(
            '$projectRootPath/RESET_REQUESTED.flag',
          );
          print(
            'Checking for reset flag at: ${resetFlagInProjectRoot.absolute.path}',
          );
          if (await resetFlagInProjectRoot.exists()) {
            print('Found reset flag file at project root!');
            possiblePaths.add('$projectRootPath/RESET_REQUESTED.flag');
          } else {
            print('No reset flag file found at project root');
          }
        } catch (e) {
          // Skip if we can't access the project root
          if (!e.toString().contains('Operation not permitted')) {
            print('Could not check project root for reset flag: $e');
          }
        }
      } else {
        print('Could not find project root (start.py not found)');
      }

      print('Checking for reset flag file in possible paths:');
      print('Current working directory: ${Directory.current.path}');
      for (final path in possiblePaths) {
        try {
          final file = File(path);
          print('   - ${file.absolute.path}');
        } catch (e) {
          // Skip paths that we can't access
          if (!e.toString().contains('Operation not permitted')) {
            print('   - $path (inaccessible: ${e.toString()})');
          }
        }
      }

      File? resetFlagFile;
      for (final path in possiblePaths) {
        try {
          final file = File(path);
          if (await file.exists()) {
            resetFlagFile = file;
            print('Found reset flag file at: ${file.absolute.path}');
            break;
          }
        } catch (e) {
          // Skip paths that we can't access due to permissions
          print('Skipping inaccessible path: $path (${e.toString()})');
          continue;
        }
      }

      if (resetFlagFile != null) {
        // Read the flag file content to verify it's a valid reset request
        try {
          final content = await resetFlagFile.readAsString();
          print('Reset flag content: $content');

          // Check if the content looks like a valid reset request
          if (content.contains('RESET_REQUESTED_AT_')) {
            print(
              'Valid reset flag file detected, performing complete reset...',
            );

            // Perform complete reset
            await UserService.forceCompleteReset();

            // Delete the reset flag file
            try {
              await resetFlagFile.delete();
              print('Reset flag file deleted');
            } catch (e) {
              print('Could not delete reset flag file: $e');
            }

            print('Complete reset performed from flag file');
          } else {
            print(
              'Reset flag file found but content is invalid, treating as leftover file',
            );
            // Delete the invalid flag file
            try {
              await resetFlagFile.delete();
              print('Invalid reset flag file deleted');
            } catch (e) {
              print('Could not delete invalid reset flag file: $e');
            }
            // Clean up any other leftover files
            await _cleanupLeftoverResetFiles();
          }
        } catch (e) {
          // Only log if it's not a permission error
          if (!e.toString().contains('Operation not permitted')) {
            print(
              'Error reading reset flag file: $e, treating as leftover file',
            );
          }
          // Delete the unreadable flag file
          try {
            await resetFlagFile.delete();
            print('Unreadable reset flag file deleted');
          } catch (deleteError) {
            // Only log if it's not a permission error
            if (!deleteError.toString().contains('Operation not permitted')) {
              print(
                'Could not delete unreadable reset flag file: $deleteError',
              );
            }
          }
          // Clean up any other leftover files
          await _cleanupLeftoverResetFiles();
        }
      } else {
        print('No reset flag file found in any of the checked paths');
        // No reset flag, clean up any leftover reset files
        await _cleanupLeftoverResetFiles();
      }
    } else {
      // For web platforms, check localStorage for reset flag
      final localStorage = await LocalStorageService.getInstance();
      final resetRequested = await localStorage.getString(
        '_reset_requested_by_start_py',
      );

      if (resetRequested != null) {
        if (kDebugMode) {
          print(
            'Reset flag detected in localStorage, performing complete reset...',
          );
        }

        // Perform complete reset
        await UserService.forceCompleteReset();

        // Clear the reset flag
        await localStorage.removeKey('_reset_requested_by_start_py');

        if (kDebugMode) {
          print('Complete reset performed from localStorage flag');
        }
      } else {
        // No reset flag, clean up any leftover reset files
        await _cleanupLeftoverResetFiles();
      }
    }
  } catch (e) {
    print('Error checking for reset request: $e');
  }
  print('checkForResetRequest: Reset check completed');
}

Future<void> _cleanupLeftoverResetFiles() async {
  try {
    print('Cleaning up any leftover reset files...');

    // Clean up any leftover reset files that might exist
    // Only check paths that are likely to be accessible by the Flutter app
    final homeDir = Platform.environment['HOME'] ?? '';
    final possibleResetPaths = [
      'RESET_REQUESTED.flag',
      '../RESET_REQUESTED.flag',
      '../../RESET_REQUESTED.flag',
      '$homeDir/RESET_REQUESTED.flag', // Home directory
    ];

    // Add app Documents directory to cleanup paths
    try {
      final documentsDir = await getApplicationDocumentsDirectory();
      possibleResetPaths.add('${documentsDir.path}/RESET_REQUESTED.flag');
    } catch (e) {
      print('Could not get app Documents directory for cleanup: $e');
    }

    final resetFiles = [
      ...possibleResetPaths.map((path) => File(path)),
      File('web_reset_flag.html'),
    ];

    int cleanedCount = 0;
    for (final file in resetFiles) {
      try {
        if (await file.exists()) {
          try {
            // Check if it's a valid reset flag before deleting
            final content = await file.readAsString();
            if (content.contains('RESET_REQUESTED_AT_')) {
              // This is a valid reset flag, but we're cleaning up, so delete it
              await file.delete();
              print('Cleaned up valid reset flag: ${file.absolute.path}');
              cleanedCount++;
            } else {
              // This is an invalid/leftover file, delete it
              await file.delete();
              print('Cleaned up invalid reset flag: ${file.absolute.path}');
              cleanedCount++;
            }
          } catch (e) {
            // If we can't read it, just try to delete it
            try {
              await file.delete();
              print('Cleaned up unreadable reset flag: ${file.absolute.path}');
              cleanedCount++;
            } catch (deleteError) {
              // Only log if it's not a permission error
              if (!deleteError.toString().contains('Operation not permitted')) {
                print('Could not clean up ${file.absolute.path}: $deleteError');
              }
            }
          }
        }
      } catch (e) {
        // Skip files we can't access due to permissions
        if (!e.toString().contains('Operation not permitted')) {
          print(
            'Skipping inaccessible file: ${file.absolute.path} (${e.toString()})',
          );
        }
        continue;
      }
    }

    if (cleanedCount > 0) {
      print('Cleaned up $cleanedCount leftover reset files');
    } else {
      print('No leftover reset files found');
    }
  } catch (e) {
    print('Error cleaning up leftover reset files: $e');
  }
}

Future<void> checkForDataReset() async {
  try {
    // Check URL parameters for reset_data=true (only on web)
    final shouldReset = shouldResetData();
    if (kDebugMode) {
      print('Web reset check: shouldResetData() = $shouldReset');
    }

    if (shouldReset) {
      if (kDebugMode) {
        print('Data reset requested via URL parameter');
      }

      // Use the force complete reset method
      await UserService.forceCompleteReset();

      // Clear web localStorage if available
      clearWebStorage();

      if (kDebugMode) {
        print('All game data has been reset to defaults via URL parameter');
      }

      // Clean up URL if possible
      cleanUpUrl();
    } else {
      if (kDebugMode) {
        print(
          'No URL parameter reset requested, proceeding with normal startup',
        );
      }
    }
  } catch (e) {
    if (kDebugMode) {
      print('Error during data reset: $e');
    }
  }
}

Future<void> cleanupOldData() async {
  try {
    // Check for manual reset request first (for testing/debugging)
    final localStorage = await LocalStorageService.getInstance();
    final manualResetRequested =
        await localStorage.getString('_manual_reset_requested') == 'true';

    if (manualResetRequested) {
      if (kDebugMode) {
        print('Manual reset requested for macOS build');
      }

      // Clear the manual reset flag first
      await localStorage.removeKey('_manual_reset_requested');

      // Perform complete reset
      await UserService.forceCompleteReset();

      if (kDebugMode) {
        print('Manual reset completed for macOS build');
      }
      return;
    }

    // Initialize services and clean up old debug tasks
    final tasksService = await TasksService.getInstance();
    final userService = await UserService.getInstance();

    // Check if there are debug tasks or unusually high levels that indicate corrupted data
    final tasks = await tasksService.getTodaysTasks();
    final currentLevel = await userService.getCurrentLevel();
    print(
      'cleanupOldData: Found ${tasks.length} tasks, current level: $currentLevel',
    );

    // Only reset if we detect debug tasks or unusually high levels (indicating old test data)
    bool hasDebugTasks = tasks.any(
      (task) =>
          task.title.toLowerCase().contains('debug') ||
          task.description.toLowerCase().contains('debug') ||
          task.title == 'Task for Debugging',
    );

    bool hasOldData =
        hasDebugTasks || currentLevel >= 10; // Only reset for very high levels
    print(
      'cleanupOldData: Has debug tasks: $hasDebugTasks, High level: ${currentLevel >= 10}, Reset needed: $hasOldData',
    );

    if (hasOldData) {
      if (kDebugMode) {
        print(
          'Detected problematic data (debug tasks or very high level), performing reset...',
        );
      }

      // Use the force complete reset method only for serious corruption
      await UserService.forceCompleteReset();

      if (kDebugMode) {
        print('Completed cleanup of corrupted data');
      }
    } else {
      // No problematic data detected, just gentle cleanup
      await UserService.cleanupDebugData();

      if (kDebugMode) {
        print('No problematic data found, preserving user progress');
      }
    }
  } catch (e) {
    if (kDebugMode) {
      print('Error during data cleanup: $e');
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
