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
      // Always ensure debug task is available when getting tasks
      await _ensureDebugTaskAvailable();
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
      
      // Check if we need to add default tasks for new users
      if (_currentTasks!.isEmpty) {
        _currentTasks = _getDefaultTasks();
        await _saveTasks();
      }
      
      // Always ensure debug task is available
      await _ensureDebugTaskAvailable();
      
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
      DailyTask(
        id: 'debug_task',
        title: 'Task for Debugging',
        description: 'A debug task to help test the climbing functionality.',
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
      
      // Always ensure debug task is available after completing any task
      await _ensureDebugTaskAvailable();
      
      await _saveTasks();
    }
  }

  Future<void> _ensureDebugTaskAvailable() async {
    if (_currentTasks == null) return;
    
    // Check if debug task exists and is not completed
    final debugTaskExists = _currentTasks!.any(
      (task) => task.title == 'Task for Debugging' && !task.isCompleted,
    );
    
    // If no available debug task, add a new one
    if (!debugTaskExists) {
      final newDebugTask = DailyTask(
        id: 'debug_task_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Task for Debugging',
        description: 'A debug task to help test the climbing functionality.',
        createdAt: DateTime.now(),
      );
      _currentTasks!.add(newDebugTask);
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