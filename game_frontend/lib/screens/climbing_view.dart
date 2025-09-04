import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'views/view_config.dart';
import '../data/user_service.dart';
import '../data/tasks_service.dart';
import '../models/daily_task.dart';
import '../services/api_service.dart';

class ClimbingView extends StatefulWidget {
  final String currentView;
  final int currentLevel;
  final VoidCallback?
  onTaskGenerated; // Callback to notify parent when task is generated

  const ClimbingView({
    Key? key,
    this.currentView = 'starting',
    this.currentLevel = 1,
    this.onTaskGenerated,
  }) : super(key: key);

  @override
  State<ClimbingView> createState() => ClimbingViewState();
}

class ClimbingViewState extends State<ClimbingView>
    with TickerProviderStateMixin {
  late AnimationController _stairController;
  late AnimationController _playerMoveController;
  late AnimationController _fadeController;
  late AnimationController _wallScaleController;
  late ViewLighting _lighting;

  bool _showingStairs = false;
  bool _playerMoving = false;
  bool _wallScaling = false;
  int _chiselCount = 0;
  List<Offset> _stairPositions = [];
  UserService? _userService;
  TasksService? _tasksService;

  @override
  void initState() {
    super.initState();

    _lighting = ViewConfigs.getLightingForView(widget.currentView);

    _stairController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _playerMoveController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _wallScaleController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _generateStairPositions();
    _initializeUserService();
  }

  Future<void> _initializeUserService() async {
    _userService = await UserService.getInstance();
    _tasksService = await TasksService.getInstance();
    await _refreshChiselCount();
    await _updateLightingForProgress();
  }

  Future<void> _refreshChiselCount() async {
    if (_userService != null) {
      final chiselCount = await _userService!.getChiselCount();
      if (mounted) {
        setState(() {
          _chiselCount = chiselCount;
        });
      }
    }
  }

  Future<void> _updateLightingForProgress() async {
    if (_userService != null) {
      final currentLevel = await _userService!.getCurrentLevel();
      final levelProgress = await _userService!.getLevelProgress();

      ViewLighting newLighting;

      if (currentLevel == 1) {
        // Level 1: Interpolating from starting to view_1 based on task progress
        final baseLighting = ViewConfigs.getLightingForView('starting');
        final targetLighting = ViewConfigs.getLightingForView('view_1');
        newLighting = ViewConfigs.interpolateLighting(
          baseLighting,
          targetLighting,
          levelProgress,
        );
      } else if (currentLevel >= 2) {
        // Level 2+: Show the view_1 aurora lighting fully
        newLighting = ViewConfigs.getLightingForView('view_1');
      } else {
        // Default to starting view
        newLighting = ViewConfigs.getLightingForView('starting');
      }

      if (mounted) {
        setState(() {
          _lighting = newLighting;
        });
      }
    }
  }

  @override
  void dispose() {
    _stairController.dispose();
    _playerMoveController.dispose();
    _fadeController.dispose();
    _wallScaleController.dispose();
    super.dispose();
  }

  void _generateStairPositions() {
    _stairPositions.clear();
    for (int i = 0; i < widget.currentLevel + 2; i++) {
      _stairPositions.add(
        Offset(
          0.3 + (i * 0.15), // X position (percentage of screen width)
          0.8 - (i * 0.12), // Y position (percentage of screen height)
        ),
      );
    }
  }

  Future<void> _useChisel() async {
    if (_chiselCount <= 0 || _showingStairs || _playerMoving || _wallScaling)
      return;

    // Use a chisel
    await _userService!.useChisel();
    final newChiselCount = await _userService!.getChiselCount();
    setState(() {
      _chiselCount = newChiselCount;
      _showingStairs = true;
    });

    // Generate a new task after chisel use
    try {
      await _generateNewTask();
    } catch (e) {
      print('Failed to generate new task: $e');
      // Continue with the game even if task generation fails
    }

    // Start carving animation
    await _stairController.forward();

    // Start player movement
    setState(() {
      _playerMoving = true;
    });

    await _playerMoveController.forward();

    // Start wall scaling animation (wall appears to grow bigger)
    setState(() {
      _wallScaling = true;
    });

    await _wallScaleController.forward();

    // Quick fade to black and back
    await _fadeController.forward();
    await Future.delayed(const Duration(milliseconds: 200));

    // Reset for next level
    _resetForNextLevel();

    // Update lighting after using chisel (advancing to next level)
    await _updateLightingForProgress();

    // Fade back in with new wall
    await _fadeController.reverse();
  }

  void _resetForNextLevel() {
    setState(() {
      _showingStairs = false;
      _playerMoving = false;
      _wallScaling = false;
    });

    _stairController.reset();
    _playerMoveController.reset();
    _wallScaleController.reset();

    // Generate new stair positions for next level
    _generateStairPositions();
  }

  // Public method to refresh chisel count from parent widget
  Future<void> refreshChiselCount() async {
    await _refreshChiselCount();
    // Don't update lighting here - only update when chisel is used
  }

  Future<void> _generateNewTask() async {
    if (_userService == null || _tasksService == null) return;

    try {
      // Get user's financial goal and mock profile
      final financialGoal = await _userService!.getFinancialGoal();
      if (financialGoal == null) {
        print('No financial goal found');
        return;
      }

      // Create mock profile (should ideally be stored after initial creation)
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
        throw Exception('No tasks returned from API');
      }

      final taskData = tasks[0];
      final taskTitle = taskData['title'] ?? 'Financial Challenge';
      final taskDescription =
          taskData['description'] ?? 'Complete today\'s financial challenge';
      print('New task generated: $taskTitle - $taskDescription');

      // Create a DailyTask and add it to TasksService
      final newTask = DailyTask(
        id: 'generated_task_${DateTime.now().millisecondsSinceEpoch}',
        title: taskTitle,
        description: taskDescription,
        createdAt: DateTime.now(),
      );

      // Add the task to the daily tasks list
      await _tasksService!.addTask(newTask);

      // Notify parent widget that a new task was generated
      if (widget.onTaskGenerated != null) {
        widget.onTaskGenerated!();
      }

      // Show dialog to let user know new task was added
      _showNewTaskDialog(taskDescription);
    } catch (e) {
      print('Error generating task: $e');

      // Create fallback task
      final fallbackTask = DailyTask(
        id: 'fallback_task_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Financial Task',
        description:
            'Track your spending today and identify one area to optimize',
        createdAt: DateTime.now(),
      );

      // Add fallback task to the daily tasks list
      await _tasksService!.addTask(fallbackTask);

      // Notify parent widget that a new task was generated
      if (widget.onTaskGenerated != null) {
        widget.onTaskGenerated!();
      }

      // Show fallback task dialog
      _showNewTaskDialog(
        'Track your spending today and identify one area to optimize',
      );
    }
  }

  void _showNewTaskDialog(String taskDescription) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('New Financial Challenge!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(taskDescription),
              SizedBox(height: 16),
              Text(
                'This task has been added to your Daily Tasks list. Click the checklist button to view all tasks.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Got it!'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _stairController,
          _playerMoveController,
          _fadeController,
          _wallScaleController,
        ]),
        builder: (context, child) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(gradient: _lighting.backgroundGradient),
            child: Stack(
              children: [
                // Light source (sun/moon)
                Positioned(
                  right: 60,
                  bottom: 280,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          _lighting.sunColor.withOpacity(
                            _lighting.sunIntensity,
                          ),
                          _lighting.sunColor.withOpacity(
                            _lighting.sunIntensity * 0.7,
                          ),
                          _lighting.sunColor.withOpacity(
                            _lighting.sunIntensity * 0.3,
                          ),
                        ],
                        stops: [0.0, 0.5, 1.0],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _lighting.sunColor.withOpacity(
                            _lighting.sunIntensity * 0.4,
                          ),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                  ),
                ),

                // Flat floor
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 100,
                  child: CustomPaint(
                    painter: FloorPainter(lighting: _lighting),
                  ),
                ),

                // Rock wall with scaling animation
                Positioned(
                  bottom: 100,
                  left: 0,
                  right: 0,
                  top: MediaQuery.of(context).size.height * 0.3,
                  child: Transform.scale(
                    scale: _wallScaling
                        ? 1.0 + (_wallScaleController.value * 1.5)
                        : 1.0,
                    alignment: Alignment.center,
                    child: Transform.translate(
                      offset: _wallScaling
                          ? Offset(0, _wallScaleController.value * 50)
                          : Offset.zero,
                      child: CustomPaint(
                        painter: RockWallPainter(
                          lighting: _lighting,
                          stairProgress: _showingStairs
                              ? _stairController.value
                              : 0.0,
                          stairPositions: _stairPositions,
                        ),
                      ),
                    ),
                  ),
                ),

                // Chisel button (bottom left)
                Positioned(
                  bottom: 120,
                  left: 20,
                  child: Stack(
                    children: [
                      // Main chisel button
                      FloatingActionButton(
                        onPressed: _chiselCount > 0 ? _useChisel : null,
                        backgroundColor: _chiselCount > 0
                            ? Color(0xFF8B4513)
                            : Colors.grey,
                        child: CustomPaint(
                          size: Size(24, 32),
                          painter: ChiselIconPainter(),
                        ),
                      ),
                      // Chisel count indicator (completely hidden during any animation activity)
                      if (_chiselCount > 0 &&
                          !_showingStairs &&
                          !_playerMoving &&
                          !_wallScaling &&
                          _fadeController.value == 0 &&
                          _stairController.value == 0 &&
                          _playerMoveController.value == 0 &&
                          _wallScaleController.value == 0)
                        Positioned(
                          top: -5,
                          right: -5,
                          child: Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: BoxConstraints(
                              minWidth: 20,
                              minHeight: 20,
                            ),
                            child: Text(
                              '$_chiselCount',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Fade overlay for transitions
                if (_fadeController.value > 0)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withOpacity(_fadeController.value),
                    ),
                  ),

                // Level indicator
                Positioned(
                  top: 60,
                  left: 20,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Level ${widget.currentLevel}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class FloorPainter extends CustomPainter {
  final ViewLighting lighting;

  FloorPainter({required this.lighting});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF8B7355).withOpacity(0.9), // Brown stone
          Color(0xFF654321).withOpacity(0.8), // Darker brown
          Color(0xFF4A4A4A).withOpacity(0.7), // Dark gray
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    // Add lighting effect based on light direction
    final lightEffect = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          lighting.ambientColor.withOpacity(lighting.ambientIntensity * 0.3),
          Colors.transparent,
          Colors.black.withOpacity(0.2),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), lightEffect);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class RockWallPainter extends CustomPainter {
  final ViewLighting lighting;
  final double stairProgress;
  final List<Offset> stairPositions;

  RockWallPainter({
    required this.lighting,
    required this.stairProgress,
    required this.stairPositions,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Rock wall base
    final wallPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF696969), // Dim gray
          Color(0xFF2F4F4F), // Dark slate gray
          Color(0xFF1C1C1C), // Very dark gray
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), wallPaint);

    // Add rock texture
    final random = math.Random(42);
    final texturePaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 50; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final path = Path();
      path.addOval(
        Rect.fromCenter(
          center: Offset(x, y),
          width: random.nextDouble() * 30 + 10,
          height: random.nextDouble() * 20 + 10,
        ),
      );
      canvas.drawPath(path, texturePaint);
    }

    // Draw carved stairs if they're being created
    if (stairProgress > 0) {
      // Create a carved effect by removing rock and adding stair geometry
      for (int i = 0; i < stairPositions.length; i++) {
        final progress = ((stairProgress * stairPositions.length) - i).clamp(
          0.0,
          1.0,
        );
        if (progress <= 0) continue;

        final position = stairPositions[i];
        final stairWidth = 80.0 * progress;
        final stairHeight = 20.0 * progress;
        final stairDepth = 15.0 * progress;

        final stairX = position.dx * size.width - stairWidth / 2;
        final stairY = position.dy * size.height;

        // Create the carved step effect
        final carvedPath = Path();
        carvedPath.moveTo(stairX, stairY);
        carvedPath.lineTo(stairX + stairWidth, stairY);
        carvedPath.lineTo(stairX + stairWidth, stairY + stairHeight);
        carvedPath.lineTo(
          stairX + stairWidth - stairDepth,
          stairY + stairHeight,
        );
        carvedPath.lineTo(stairX - stairDepth, stairY + stairHeight);
        carvedPath.lineTo(stairX, stairY);
        carvedPath.close();

        // Paint the carved step in a slightly lighter rock color to show it's carved
        final carvedStairPaint = Paint()
          ..color =
              Color(0xFF505050) // Lighter than the wall
          ..style = PaintingStyle.fill;

        canvas.drawPath(carvedPath, carvedStairPaint);

        // Add shadow for depth
        final shadowPath = Path();
        shadowPath.moveTo(
          stairX + stairWidth - stairDepth,
          stairY + stairHeight,
        );
        shadowPath.lineTo(stairX + stairWidth, stairY + stairHeight);
        shadowPath.lineTo(stairX + stairWidth, stairY + stairHeight + 3);
        shadowPath.lineTo(
          stairX + stairWidth - stairDepth,
          stairY + stairHeight + 3,
        );
        shadowPath.close();

        final shadowPaint = Paint()
          ..color = Colors.black.withOpacity(0.6)
          ..style = PaintingStyle.fill;

        canvas.drawPath(shadowPath, shadowPaint);

        // Add step edge highlight
        final edgePaint = Paint()
          ..color = Color(0xFF707070)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;

        canvas.drawLine(
          Offset(stairX, stairY),
          Offset(stairX + stairWidth, stairY),
          edgePaint,
        );
      }
    }

    // Apply lighting effects
    final lightEffect = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          lighting.ambientColor.withOpacity(lighting.ambientIntensity * 0.2),
          Colors.transparent,
          Colors.black.withOpacity(0.4),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), lightEffect);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is RockWallPainter &&
        oldDelegate.stairProgress != stairProgress;
  }
}

class ChiselIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final handlePaint = Paint()
      ..color =
          Color(0xFF8B4513) // Brown handle
      ..style = PaintingStyle.fill;

    final metalPaint = Paint()
      ..color =
          Color(0xFFC0C0C0) // Silver metal
      ..style = PaintingStyle.fill;

    // Handle (rectangular)
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.3, 0, size.width * 0.4, size.height * 0.7),
      handlePaint,
    );

    // Metal chisel tip (triangular)
    final path = Path();
    path.moveTo(size.width * 0.4, size.height * 0.7);
    path.lineTo(size.width * 0.6, size.height * 0.7);
    path.lineTo(size.width * 0.5, size.height);
    path.close();

    canvas.drawPath(path, metalPaint);

    // Add handle grip lines
    final gripPaint = Paint()
      ..color = Color(0xFF654321)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (int i = 1; i < 4; i++) {
      final y = size.height * 0.15 * i;
      canvas.drawLine(
        Offset(size.width * 0.32, y),
        Offset(size.width * 0.68, y),
        gripPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
