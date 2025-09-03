import 'package:flutter/material.dart';
import 'dart:math' as math;

class StartMountainView extends StatefulWidget {
  const StartMountainView({Key? key}) : super(key: key);

  @override
  State<StartMountainView> createState() => _StartMountainViewState();
}

class _StartMountainViewState extends State<StartMountainView>
    with TickerProviderStateMixin {
  late AnimationController _cloudController;
  late AnimationController _birdController;
  late AnimationController _sunController;

  @override
  void initState() {
    super.initState();

    // Cloud animation - slow drift
    _cloudController = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    )..repeat();

    // Bird animation - faster movement
    _birdController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();

    // Sun glow animation - gentle pulse
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

  void _showFinancialGoalDialog(BuildContext context) {
    final TextEditingController goalController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF87CEEB).withOpacity(0.95),
                  Color(0xFFFFB347).withOpacity(0.95),
                  Color(0xFFFF6B6B).withOpacity(0.95),
                ],
                stops: [0.0, 0.6, 1.0],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
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
                Text(
                  'Set Your Financial Peak',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        offset: Offset(1, 1),
                        blurRadius: 4,
                        color: Colors.black.withOpacity(0.5),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'What financial goal would you like to achieve?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                    shadows: [
                      Shadow(
                        offset: Offset(1, 1),
                        blurRadius: 2,
                        color: Colors.black.withOpacity(0.3),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: goalController,
                  decoration: InputDecoration(
                    hintText: 'e.g., Save \$10,000 for emergency fund',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  maxLines: 3,
                  minLines: 1,
                ),
                SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          shadows: [
                            Shadow(
                              offset: Offset(1, 1),
                              blurRadius: 2,
                              color: Colors.black.withOpacity(0.3),
                            ),
                          ],
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (goalController.text.trim().isNotEmpty) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Goal set: ${goalController.text.trim()}',
                              ),
                              backgroundColor: Color(0xFF4CAF50),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 4,
                      ),
                      child: Text(
                        'Start Climbing',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
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
                  right: 80,
                  top: 120,
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

                // Game title
                Positioned(
                  top: MediaQuery.of(context).size.height * 0.15,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      Text(
                        'Financial Peak',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              offset: Offset(2, 2),
                              blurRadius: 8,
                              color: Colors.black.withOpacity(0.5),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Climb Your Way to Financial Freedom',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white.withOpacity(0.9),
                          shadows: [
                            Shadow(
                              offset: Offset(1, 1),
                              blurRadius: 4,
                              color: Colors.black.withOpacity(0.3),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Start button
                Positioned(
                  bottom: 80,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: ElevatedButton(
                      onPressed: () {
                        _showFinancialGoalDialog(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 8,
                      ),
                      child: Text(
                        'Begin Your Climb',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
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
