import 'dart:convert';
import '../models/daily_task.dart';
import 'local_storage_service.dart';

class TasksService {
  static TasksService? _instance;
  LocalStorageService? _localStorage;
  List<DailyTask>? _currentTasks;

  static const String _tasksKey = 'daily_tasks';

  TasksService._();

  static Future<TasksService> getInstance() async {
    _instance ??= TasksService._();
    _instance!._localStorage ??= await LocalStorageService.getInstance();
    return _instance!;
  }

  Future<List<DailyTask>> getTodaysTasks() async {
    if (_currentTasks != null) {
      // Remove any old debug tasks that might be cached
      await _removeOldDebugTasks();
      return _currentTasks!;
    }

    final tasksJson = await _getTasksJson();
    if (tasksJson == null) {
      _currentTasks = _getDefaultTasks();
      await _saveTasks();
      return _currentTasks!;
    }

    try {
      final tasksList = json.decode(tasksJson) as List<dynamic>;
      _currentTasks = tasksList
          .map((taskJson) => DailyTask.fromJson(taskJson as Map<String, dynamic>))
          .toList();
      
      // Remove any old debug tasks from loaded data
      await _removeOldDebugTasks();
      
      // Check if we need to add default tasks for new users
      if (_currentTasks!.isEmpty) {
        _currentTasks = _getDefaultTasks();
        await _saveTasks();
      }
      
      return _currentTasks!;
    } catch (e) {
      _currentTasks = _getDefaultTasks();
      await _saveTasks();
      return _currentTasks!;
    }
  }

  List<DailyTask> _getDefaultTasks() {
    return [
      DailyTask(
        id: 'task_1',
        title: 'Commit to the Climb',
        description: 'Take the first step towards your financial goal by committing to this journey.',
        createdAt: DateTime.now(),
      ),
    ];
  }

  Future<void> completeTask(String taskId) async {
    await getTodaysTasks(); // Ensure tasks are loaded
    final taskIndex = _currentTasks!.indexWhere((task) => task.id == taskId);
    
    if (taskIndex != -1) {
      // Remove the completed task from the list instead of marking it complete
      _currentTasks!.removeAt(taskIndex);
      
      await _saveTasks();
    }
  }

  Future<void> _removeOldDebugTasks() async {
    if (_currentTasks == null) return;
    
    // Remove any tasks that contain debug-related text or have debug-related IDs
    final originalLength = _currentTasks!.length;
    _currentTasks!.removeWhere((task) => 
      task.title.toLowerCase().contains('debug') ||
      task.description.toLowerCase().contains('debug') ||
      task.id.toLowerCase().contains('debug') ||
      task.title == 'Task for Debugging'
    );
    
    // If we removed any debug tasks, save the updated list
    if (_currentTasks!.length != originalLength) {
      await _saveTasks();
    }
  }


  Future<void> addTask(DailyTask task) async {
    await getTodaysTasks(); // Ensure tasks are loaded
    _currentTasks!.add(task);
    await _saveTasks();
  }

  Future<String?> _getTasksJson() async {
    return await _localStorage!.getString(_tasksKey);
  }

  Future<void> _saveTasks() async {
    if (_currentTasks != null) {
      final tasksJson = json.encode(
        _currentTasks!.map((task) => task.toJson()).toList(),
      );
      await _localStorage!.setString(_tasksKey, tasksJson);
    }
  }

  Future<int> getCompletedTasksCount() async {
    final tasks = await getTodaysTasks();
    return tasks.where((task) => task.isCompleted).length;
  }

  Future<bool> hasCompletedAllTasks() async {
    final tasks = await getTodaysTasks();
    return tasks.isNotEmpty && tasks.every((task) => task.isCompleted);
  }

  Future<void> clearTasks() async {
    _currentTasks = null;
    await _localStorage!.removeKey(_tasksKey);
  }
}