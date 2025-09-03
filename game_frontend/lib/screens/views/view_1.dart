import 'package:flutter/material.dart';
import 'dart:math' as math;

class View1 extends StatefulWidget {
  const View1({Key? key}) : super(key: key);

  @override
  State<View1> createState() => _View1State();
}

class _View1State extends State<View1> with TickerProviderStateMixin {
  late AnimationController _auroraController;
  late AnimationController _snowController;
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();

    // Aurora animation - slow wave motion
    _auroraController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();

    // Snow animation - gentle falling
    _snowController = AnimationController(
      duration: const Duration(seconds: 12),
      vsync: this,
    )..repeat();

    // Lake shimmer animation
    _shimmerController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _auroraController.dispose();
    _snowController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _auroraController,
        _snowController,
        _shimmerController,
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
                Color(0xFF0A0F1C), // Very dark blue at top
                Color(0xFF1A1F3A), // Dark blue-purple
                Color(0xFF2D3561), // Medium blue
                Color(0xFF4A5D7A), // Lighter blue at horizon
              ],
              stops: [0.0, 0.3, 0.6, 1.0],
            ),
          ),
          child: Stack(
            children: [
              // Aurora Borealis
              Positioned(
                top: 50,
                left: 0,
                right: 0,
                height: 400,
                child: CustomPaint(
                  size: Size(MediaQuery.of(context).size.width, 400),
                  painter: AuroraPainter(
                    animationValue: _auroraController.value,
                  ),
                ),
              ),

              // Stars
              ...List.generate(50, (index) {
                final random = math.Random(index);
                return Positioned(
                  left: random.nextDouble() * MediaQuery.of(context).size.width,
                  top: random.nextDouble() * 300,
                  child: Container(
                    width: random.nextDouble() * 3 + 1,
                    height: random.nextDouble() * 3 + 1,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.7 + (random.nextDouble() * 0.3)),
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              }),

              // Frozen lake
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 200,
                child: CustomPaint(
                  size: Size(MediaQuery.of(context).size.width, 200),
                  painter: FrozenLakePainter(
                    shimmerValue: _shimmerController.value,
                  ),
                ),
              ),

              // Snow-covered trees on left
              Positioned(
                bottom: 150,
                left: -20,
                child: CustomPaint(
                  size: Size(200, 300),
                  painter: SnowyTreesPainter(side: 'left'),
                ),
              ),

              // Snow-covered trees on right
              Positioned(
                bottom: 150,
                right: -20,
                child: CustomPaint(
                  size: Size(200, 300),
                  painter: SnowyTreesPainter(side: 'right'),
                ),
              ),

              // Moose on the lake
              Positioned(
                bottom: 180,
                left: MediaQuery.of(context).size.width * 0.4,
                child: CustomPaint(
                  size: Size(120, 100),
                  painter: MoosePainter(),
                ),
              ),

              // Falling snow
              ...List.generate(100, (index) {
                final random = math.Random(index);
                final snowOffset = (_snowController.value * 2.0 - 1.0) * 
                    (MediaQuery.of(context).size.height + 100);
                final xOffset = random.nextDouble() * MediaQuery.of(context).size.width;
                final fallSpeed = 0.5 + (random.nextDouble() * 0.5);
                
                return Positioned(
                  left: xOffset + (math.sin(_snowController.value * 2 * math.pi + index) * 20),
                  top: (snowOffset * fallSpeed + (index * 15)) % 
                      (MediaQuery.of(context).size.height + 100) - 50,
                  child: Container(
                    width: random.nextDouble() * 4 + 2,
                    height: random.nextDouble() * 4 + 2,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              }),

              // Aurora reflection on lake
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 150,
                child: ClipRect(
                  child: Transform.flip(
                    flipY: true,
                    child: Opacity(
                      opacity: 0.3,
                      child: CustomPaint(
                        size: Size(MediaQuery.of(context).size.width, 150),
                        painter: AuroraReflectionPainter(
                          animationValue: _auroraController.value,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class AuroraPainter extends CustomPainter {
  final double animationValue;

  AuroraPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    // Green aurora band
    final greenPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF00FF7F).withOpacity(0.8),
          Color(0xFF32CD32).withOpacity(0.6),
          Color(0xFF00FF7F).withOpacity(0.2),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    // Purple aurora band
    final purplePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF9370DB).withOpacity(0.7),
          Color(0xFF8A2BE2).withOpacity(0.5),
          Color(0xFF9370DB).withOpacity(0.2),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    // Draw green aurora waves
    final greenPath = Path();
    greenPath.moveTo(0, size.height * 0.8);
    
    for (double x = 0; x <= size.width; x += 10) {
      final y = size.height * 0.4 + 
          math.sin((x / size.width) * 4 * math.pi + animationValue * 2 * math.pi) * 60 +
          math.sin((x / size.width) * 2 * math.pi + animationValue * math.pi) * 30;
      greenPath.lineTo(x, y);
    }
    greenPath.lineTo(size.width, size.height * 0.8);
    greenPath.lineTo(0, size.height * 0.8);
    greenPath.close();

    canvas.drawPath(greenPath, greenPaint);

    // Draw purple aurora waves (offset)
    final purplePath = Path();
    purplePath.moveTo(0, size.height * 0.9);
    
    for (double x = 0; x <= size.width; x += 10) {
      final y = size.height * 0.3 + 
          math.sin((x / size.width) * 3 * math.pi + animationValue * 1.5 * math.pi + 1) * 80 +
          math.sin((x / size.width) * 5 * math.pi + animationValue * 2.5 * math.pi) * 40;
      purplePath.lineTo(x, y);
    }
    purplePath.lineTo(size.width, size.height * 0.9);
    purplePath.lineTo(0, size.height * 0.9);
    purplePath.close();

    canvas.drawPath(purplePath, purplePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class AuroraReflectionPainter extends CustomPainter {
  final double animationValue;

  AuroraReflectionPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    // Similar to AuroraPainter but dimmer for reflection
    final greenPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          Color(0xFF00FF7F).withOpacity(0.3),
          Color(0xFF32CD32).withOpacity(0.2),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final greenPath = Path();
    greenPath.moveTo(0, 0);
    
    for (double x = 0; x <= size.width; x += 10) {
      final y = size.height * 0.6 - 
          math.sin((x / size.width) * 4 * math.pi + animationValue * 2 * math.pi) * 30;
      greenPath.lineTo(x, y);
    }
    greenPath.lineTo(size.width, 0);
    greenPath.lineTo(0, 0);
    greenPath.close();

    canvas.drawPath(greenPath, greenPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class FrozenLakePainter extends CustomPainter {
  final double shimmerValue;

  FrozenLakePainter({required this.shimmerValue});

  @override
  void paint(Canvas canvas, Size size) {
    // Ice surface gradient
    final icePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF87CEEB).withOpacity(0.8), // Light blue ice
          Color(0xFF4682B4).withOpacity(0.6), // Medium blue
          Color(0xFF2F4F4F).withOpacity(0.8), // Dark slate gray
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), icePaint);

    // Ice crack patterns
    final crackPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Draw some ice cracks
    for (int i = 0; i < 8; i++) {
      final random = math.Random(i);
      final startX = random.nextDouble() * size.width;
      final startY = random.nextDouble() * size.height;
      final endX = startX + (random.nextDouble() - 0.5) * 200;
      final endY = startY + (random.nextDouble() - 0.5) * 100;
      
      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), crackPaint);
    }

    // Shimmer effect
    final shimmerPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.transparent,
          Colors.white.withOpacity(shimmerValue * 0.2),
          Colors.transparent,
        ],
        stops: [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), shimmerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class SnowyTreesPainter extends CustomPainter {
  final String side;

  SnowyTreesPainter({required this.side});

  @override
  void paint(Canvas canvas, Size size) {
    final treePaint = Paint()
      ..color = Color(0xFF0F2A0F)
      ..style = PaintingStyle.fill;

    final snowPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Draw 3-4 evergreen trees
    for (int i = 0; i < 4; i++) {
      final treeX = (side == 'left') 
          ? i * 40.0 + 20 
          : size.width - (i * 40.0 + 60);
      final treeHeight = 120 + (i * 20);
      final treeWidth = 60 + (i * 10);

      // Tree layers (evergreen style)
      for (int layer = 0; layer < 4; layer++) {
        final layerY = size.height - treeHeight + (layer * 25);
        final layerWidth = treeWidth - (layer * 8);

        // Tree triangle
        final treePath = Path();
        treePath.moveTo(treeX, layerY);
        treePath.lineTo(treeX - layerWidth / 2, layerY + 35);
        treePath.lineTo(treeX + layerWidth / 2, layerY + 35);
        treePath.close();

        canvas.drawPath(treePath, treePaint);

        // Snow on tree branches
        final snowPath = Path();
        snowPath.moveTo(treeX - layerWidth / 2, layerY + 35);
        snowPath.quadraticBezierTo(
          treeX - layerWidth / 4, layerY + 30,
          treeX, layerY + 32,
        );
        snowPath.quadraticBezierTo(
          treeX + layerWidth / 4, layerY + 30,
          treeX + layerWidth / 2, layerY + 35,
        );
        snowPath.lineTo(treeX + layerWidth / 2 - 5, layerY + 37);
        snowPath.lineTo(treeX - layerWidth / 2 + 5, layerY + 37);
        snowPath.close();

        canvas.drawPath(snowPath, snowPaint);
      }

      // Tree trunk - connect to bottom of lowest tree layer
      final lowestLayerY = size.height - treeHeight + (3 * 25) + 35; // Bottom of last layer
      final trunkHeight = size.height - lowestLayerY;
      final trunkRect = Rect.fromLTWH(
        treeX - 8,
        lowestLayerY,
        16,
        trunkHeight,
      );
      canvas.drawRect(trunkRect, Paint()..color = Color(0xFF4A2C2A));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class MoosePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final moosePaint = Paint()
      ..color = Color(0xFF4A2C2A) // Dark brown
      ..style = PaintingStyle.fill;

    final antlerPaint = Paint()
      ..color = Color(0xFF8B7355) // Lighter brown for antlers
      ..style = PaintingStyle.fill;

    // Moose body (ellipse)
    final bodyRect = Rect.fromLTWH(
      size.width * 0.3,
      size.height * 0.4,
      size.width * 0.4,
      size.height * 0.3,
    );
    canvas.drawOval(bodyRect, moosePaint);

    // Moose head
    final headRect = Rect.fromLTWH(
      size.width * 0.1,
      size.height * 0.2,
      size.width * 0.25,
      size.height * 0.25,
    );
    canvas.drawOval(headRect, moosePaint);

    // Moose legs
    for (int i = 0; i < 4; i++) {
      final legX = size.width * (0.35 + i * 0.08);
      final legRect = Rect.fromLTWH(
        legX,
        size.height * 0.65,
        size.width * 0.04,
        size.height * 0.35,
      );
      canvas.drawRect(legRect, moosePaint);
    }

    // Antlers
    final antlerPath = Path();
    
    // Left antler
    antlerPath.moveTo(size.width * 0.15, size.height * 0.1);
    antlerPath.lineTo(size.width * 0.05, size.height * 0.05);
    antlerPath.lineTo(size.width * 0.08, size.height * 0.15);
    antlerPath.lineTo(size.width * 0.12, size.height * 0.08);
    antlerPath.close();

    // Right antler
    antlerPath.moveTo(size.width * 0.28, size.height * 0.1);
    antlerPath.lineTo(size.width * 0.38, size.height * 0.05);
    antlerPath.lineTo(size.width * 0.35, size.height * 0.15);
    antlerPath.lineTo(size.width * 0.31, size.height * 0.08);
    antlerPath.close();

    canvas.drawPath(antlerPath, antlerPaint);

    // Simple eye
    canvas.drawCircle(
      Offset(size.width * 0.2, size.height * 0.3),
      3,
      Paint()..color = Colors.black,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}