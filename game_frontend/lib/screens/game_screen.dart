import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'climbing_view.dart';
import 'views/view_1.dart';
import '../models/daily_task.dart';
import '../data/tasks_service.dart';
import '../data/user_service.dart';
import '../data/local_storage_service.dart';
import '../services/api_service.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({Key? key}) : super(key: key);

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  bool _isClimbingMode = false;
  List<DailyTask> _tasks = [];
  TasksService? _tasksService;
  UserService? _userService;
  int _currentLevel = 1;
  bool _isGeneratingTask = false; // Flag to prevent duplicate task generation
  final GlobalKey<ClimbingViewState> _climbingViewKey =
      GlobalKey<ClimbingViewState>();

  @override
  void initState() {
    super.initState();
    _initializeTasks();
  }

  Future<void> _initializeTasks() async {
    _tasksService = await TasksService.getInstance();
    _userService = await UserService.getInstance();

    final tasks = await _tasksService!.getTodaysTasks();
    final currentLevel = await _userService!.getCurrentLevel();

    // Hard-coded rule: Player can only have ONE task at a time
    final limitedTasks = tasks.isNotEmpty ? [tasks.first] : <DailyTask>[];

    setState(() {
      _tasks = limitedTasks;
      _currentLevel = currentLevel;
    });

    // Check if data was just reset and force refresh if needed
    await _checkForResetAndRefresh();

    // If no tasks available and not already generating, automatically generate a new one using OpenAI API
    if (_tasks.isEmpty && !_isGeneratingTask) {
      await _generateNewTaskFromAPI();
    }
  }

  Future<void> _checkForResetAndRefresh() async {
    try {
      final localStorage = await LocalStorageService.getInstance();
      final wasReset = await localStorage.wasDataJustReset();

      if (wasReset) {
        // Data was just reset, refresh everything
        final tasks = await _tasksService!.getTodaysTasks();
        final currentLevel = await _userService!.getCurrentLevel();

        if (mounted) {
          setState(() {
            _tasks = tasks;
            _currentLevel = currentLevel;
          });
        }
      }
    } catch (e) {
      print('Error checking for reset: $e');
    }
  }

  Future<void> _generateNewTaskFromAPI() async {
    if (_isGeneratingTask)
      return; // Already generating, don't create duplicates

    // Hard-coded rule: Only generate if there are exactly 0 tasks
    if (_tasks.isNotEmpty) {
      print(
        'Player already has ${_tasks.length} task(s), not generating new task',
      );
      return;
    }

    _isGeneratingTask = true; // Set flag to prevent duplicates
    print('Generating new task from OpenAI API...');
    try {
      // Double-check tasks from storage to be absolutely sure
      final currentTasks = await _tasksService!.getTodaysTasks();
      if (currentTasks.isNotEmpty) {
        print(
          'Found ${currentTasks.length} existing tasks in storage, aborting task generation',
        );
        return;
      }

      // Get user's financial goal
      final financialGoal = await _userService!.getFinancialGoal();
      if (financialGoal == null) {
        print('No financial goal found, cannot generate task');
        return;
      }

      // Create mock profile
      final profileData = await ApiService.instance.createMockProfile(
        scenario: 'high_spender',
        userId: 'game_player',
      );

      // Generate next task using the goal and profile
      final taskResponse = await ApiService.instance.generateNextTask(
        validatedGoal: financialGoal,
        financialProfile: profileData['financial_profile'],
      );

      // Extract task details from the AI response
      final tasks = taskResponse['tasks'] as List<dynamic>?;
      if (tasks == null || tasks.isEmpty) {
        print('No tasks returned from API');
        return;
      }

      final taskData = tasks[0];
      final taskTitle = taskData['title'] ?? 'Financial Challenge';
      final taskDescription =
          taskData['description'] ?? 'Complete today\'s financial challenge';
      print('Auto-generated new task: $taskTitle - $taskDescription');

      // Create a DailyTask and add it to TasksService
      final newTask = DailyTask(
        id: 'auto_generated_task_${DateTime.now().millisecondsSinceEpoch}',
        title: taskTitle,
        description: taskDescription,
        createdAt: DateTime.now(),
      );

      // Add the task to the daily tasks list
      await _tasksService!.addTask(newTask);

      // Set tasks to exactly one task (hard-coded limit)
      if (mounted) {
        setState(() {
          _tasks = [newTask]; // Only one task allowed
        });
        print('New task generated and added successfully!');
      }
    } catch (e) {
      print('Error auto-generating task: $e');
      // Create fallback task if API fails
      final fallbackTask = DailyTask(
        id: 'fallback_task_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Daily Financial Task',
        description:
            'Review your spending from yesterday and identify one area for improvement',
        createdAt: DateTime.now(),
      );

      await _tasksService!.addTask(fallbackTask);

      // Set tasks to exactly one task (hard-coded limit)
      if (mounted) {
        setState(() {
          _tasks = [fallbackTask]; // Only one task allowed
        });
        print('Fallback task created and added successfully!');
      }
    } finally {
      _isGeneratingTask = false; // Always reset the flag
    }
  }

  void _toggleMode() {
    setState(() {
      _isClimbingMode = !_isClimbingMode;
    });

    // Refresh chisel count when switching to climbing mode
    if (_isClimbingMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (_climbingViewKey.currentState != null) {
          await _climbingViewKey.currentState!.refreshChiselCount();
        }
      });
    }
  }

  /// Callback method to refresh tasks when a new task is generated from climbing view
  Future<void> _refreshTasksFromClimbingView() async {
    print('New task generated from climbing view, refreshing task list...');

    // Refresh the task list from storage
    if (_tasksService != null) {
      final tasks = await _tasksService!.getTodaysTasks();
      final limitedTasks = tasks.isNotEmpty ? [tasks.first] : <DailyTask>[];

      if (mounted) {
        setState(() {
          _tasks = limitedTasks;
        });
        print('Task list refreshed with ${_tasks.length} task(s)');
      }
    }
  }

  void _showTasksDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Daily Tasks',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D4A22),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close),
                      color: Colors.grey[600],
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Container(
                  constraints: BoxConstraints(maxHeight: 400),
                  child: SingleChildScrollView(
                    child: Column(
                      children: _tasks
                          .map((task) => _buildTaskItem(task))
                          .toList(),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Complete tasks to earn chisels and progress up the mountain!',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTaskItem(DailyTask task) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () async {
              // Close dialog immediately for better UX
              Navigator.of(context).pop();

              // Perform all operations in parallel for better performance
              await Future.wait([
                // Complete the task (it will be removed from the list)
                _tasksService!.completeTask(task.id),
                // Add chisel and increment task completion (handles level progression) - batched operation
                _userService!.completeTaskAndAddChisel(),
              ]);

              // Update UI state immediately without reloading all data
              final newLevel = await _userService!.getCurrentLevel();
              setState(() {
                _tasks.removeWhere((t) => t.id == task.id);
                _currentLevel = newLevel;
              });

              // Refresh chisel count in climbing view if it's active (non-blocking)
              if (_isClimbingMode && _climbingViewKey.currentState != null) {
                _climbingViewKey.currentState!.refreshChiselCount();
              }

              // Generate a new task after completing the current one (with delay for API call)
              if (_tasks.isEmpty && !_isGeneratingTask) {
                print('Task completed, generating new task in 2 seconds...');
                Future.delayed(Duration(seconds: 2), () async {
                  if (mounted && _tasks.isEmpty && !_isGeneratingTask) {
                    await _generateNewTaskFromAPI();
                  }
                });
              }
            },
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.transparent,
                border: Border.all(color: Colors.grey[400]!, width: 2),
              ),
              child: Icon(Icons.add, color: Color(0xFF4CAF50), size: 16),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  task.description,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _getCurrentView() {
    switch (_currentLevel) {
      case 1:
        return View0InGameMode();
      case 2:
        return View1();
      default:
        return View0InGameMode();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Main content
          _isClimbingMode
              ? ClimbingView(
                  key: _climbingViewKey,
                  currentView: _currentLevel == 1 ? 'starting' : 'view_1',
                  currentLevel: _currentLevel,
                  onTaskGenerated: _refreshTasksFromClimbingView,
                )
              : _getCurrentView(),

          // Mode toggle button (bottom)
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton(
                onPressed: _toggleMode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 8,
                ),
                child: Text(
                  _isClimbingMode ? 'Enjoy View' : 'Climb',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),

          // Tasks button (top right, only in climbing mode)
          if (_isClimbingMode)
            Positioned(
              top: 60,
              right: 20,
              child: FloatingActionButton(
                onPressed: _showTasksDialog,
                backgroundColor: Color(0xFF4CAF50),
                child: Icon(Icons.checklist, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}

// Simplified version of View0 for in-game use (without the goal dialog)
class View0InGameMode extends StatefulWidget {
  const View0InGameMode({Key? key}) : super(key: key);

  @override
  State<View0InGameMode> createState() => _View0InGameModeState();
}

class _View0InGameModeState extends State<View0InGameMode>
    with TickerProviderStateMixin {
  late AnimationController _cloudController;
  late AnimationController _birdController;
  late AnimationController _sunController;

  @override
  void initState() {
    super.initState();

    _cloudController = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    )..repeat();

    _birdController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();

    _sunController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _cloudController.dispose();
    _birdController.dispose();
    _sunController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _cloudController,
        _birdController,
        _sunController,
      ]),
      builder: (context, child) {
        return Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF87CEEB), // Sky blue at top
                Color(0xFFFFB347), // Orange middle
                Color(0xFFFF6B6B), // Pink-red at bottom
              ],
              stops: [0.0, 0.6, 1.0],
            ),
          ),
          child: Stack(
            children: [
              // Sun
              Positioned(
                right: 60,
                bottom: 280,
                child: Container(
                  width: 100 + (_sunController.value * 10),
                  height: 100 + (_sunController.value * 10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Color(0xFFFFF700).withOpacity(0.9),
                        Color(0xFFFFD700).withOpacity(0.7),
                        Color(0xFFFF8C00).withOpacity(0.3),
                      ],
                      stops: [0.0, 0.5, 1.0],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFFFFD700).withOpacity(0.4),
                        blurRadius: 20 + (_sunController.value * 10),
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                ),
              ),

              // Back mountains
              Positioned(
                bottom: 0,
                left: -50,
                right: -50,
                child: CustomPaint(
                  size: Size(MediaQuery.of(context).size.width + 100, 300),
                  painter: MountainPainter(
                    color: Color(0xFF4A5D23).withOpacity(0.6),
                    peaks: [0.3, 0.7, 0.5, 0.9, 0.4],
                  ),
                ),
              ),

              // Middle mountains
              Positioned(
                bottom: 0,
                left: -30,
                right: -30,
                child: CustomPaint(
                  size: Size(MediaQuery.of(context).size.width + 60, 250),
                  painter: MountainPainter(
                    color: Color(0xFF5D6B2A).withOpacity(0.8),
                    peaks: [0.5, 0.4, 0.8, 0.3, 0.7],
                  ),
                ),
              ),

              // Front mountains
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: CustomPaint(
                  size: Size(MediaQuery.of(context).size.width, 200),
                  painter: MountainPainter(
                    color: Color(0xFF2D4A22),
                    peaks: [0.4, 0.9, 0.3, 0.6, 0.8],
                  ),
                ),
              ),

              // Forest trees
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: CustomPaint(
                  size: Size(MediaQuery.of(context).size.width, 150),
                  painter: ForestPainter(),
                ),
              ),

              // Clouds
              ...List.generate(3, (index) {
                final cloudOffset =
                    (_cloudController.value *
                        MediaQuery.of(context).size.width *
                        1.5) -
                    MediaQuery.of(context).size.width * 0.3;
                return Positioned(
                  left:
                      (cloudOffset + (index * 200)) %
                          (MediaQuery.of(context).size.width + 200) -
                      100,
                  top: 80 + (index * 40),
                  child: CustomPaint(
                    size: Size(120, 60),
                    painter: CloudPainter(opacity: 0.7 - (index * 0.1)),
                  ),
                );
              }),

              // Flying birds
              ...List.generate(4, (index) {
                final birdOffset =
                    (_birdController.value *
                        MediaQuery.of(context).size.width *
                        1.2) -
                    MediaQuery.of(context).size.width * 0.2;
                return Positioned(
                  left:
                      (birdOffset + (index * 80)) %
                          (MediaQuery.of(context).size.width + 100) -
                      50,
                  top:
                      160 +
                      (index * 30) +
                      (math.sin(_birdController.value * 2 * math.pi + index) *
                          20),
                  child: CustomPaint(
                    size: Size(20, 10),
                    painter: BirdPainter(
                      wingPhase: _birdController.value * 8 + index,
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

class MountainPainter extends CustomPainter {
  final Color color;
  final List<double> peaks;

  MountainPainter({required this.color, required this.peaks});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height);

    for (int i = 0; i < peaks.length; i++) {
      final x = (size.width / (peaks.length - 1)) * i;
      final y = size.height - (size.height * peaks[i]);
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ForestPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Color(0xFF1B3B1B)
      ..style = PaintingStyle.fill;

    // Draw various tree silhouettes
    for (int i = 0; i < 20; i++) {
      final x = (size.width / 20) * i;
      final treeHeight = 60 + (math.sin(i * 0.5) * 30);
      final treeWidth = 20 + (math.cos(i * 0.3) * 10);

      // Tree trunk
      canvas.drawRect(Rect.fromLTWH(x - 3, size.height - 20, 6, 20), paint);

      // Tree crown
      final treePath = Path();
      treePath.moveTo(x, size.height - treeHeight);
      treePath.lineTo(x - treeWidth / 2, size.height - 20);
      treePath.lineTo(x + treeWidth / 2, size.height - 20);
      treePath.close();

      canvas.drawPath(treePath, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CloudPainter extends CustomPainter {
  final double opacity;

  CloudPainter({required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(opacity)
      ..style = PaintingStyle.fill;

    // Draw cloud shape with multiple circles
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.6), 20, paint);
    canvas.drawCircle(Offset(size.width * 0.4, size.height * 0.4), 25, paint);
    canvas.drawCircle(Offset(size.width * 0.6, size.height * 0.5), 22, paint);
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.7), 18, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) =>
      oldDelegate is CloudPainter && oldDelegate.opacity != opacity;
}

class BirdPainter extends CustomPainter {
  final double wingPhase;

  BirdPainter({required this.wingPhase});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.fill
      ..strokeWidth = 2;

    final wingFlap = math.sin(wingPhase) * 0.3;

    // Simple bird "V" shape
    final path = Path();
    path.moveTo(size.width * 0.5, size.height * 0.5);
    path.lineTo(size.width * 0.2, size.height * (0.3 + wingFlap));
    path.moveTo(size.width * 0.5, size.height * 0.5);
    path.lineTo(size.width * 0.8, size.height * (0.3 + wingFlap));

    paint.style = PaintingStyle.stroke;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) =>
      oldDelegate is BirdPainter && oldDelegate.wingPhase != wingPhase;
}
