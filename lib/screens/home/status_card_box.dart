import 'package:flutter/material.dart';
import 'dart:math';

class InfoCard_Box extends StatelessWidget {
  final String title;
  final int currentValue;
  final int? maxValue;
  final IconData? icon;
  final String themeColor; // NEW PARAMETER

  InfoCard_Box({
    super.key,
    required this.title,
    required this.currentValue,
    this.maxValue,
    this.icon,
    this.themeColor = "red",
  });

  // Select icon
  IconData _getIcon() {
    if (icon != null) return icon!;
    switch (title.toLowerCase()) {
      case 'subscription':
        return Icons.subscriptions;
      case 'likes':
        return Icons.thumb_up;
      case 'followers':
        return Icons.person;
      default:
        return Icons.favorite;
    }
  }

  // 🎨 Color theme map
  final Map<String, Map<String, Color>> theme = {
    "red": {
      "bg": Color(0xFFFEF6FB),
      "border": Color(0xFFF6DBEA),
      "highlight": Color(0xFFC11574),
      "inner": Color(0xFFFCE7F6),
    },
    "purple": {
      "bg": Color(0xFFF9F2FF),
      "border": Color(0xFFF1E1FE),
      "highlight": Color(0xFFB968F6),
      "inner": Color(0xFFECD4FF),
    },
    "blue": {
      "bg": Color(0xFFF5FAFF),
      "border": Color(0xFFD7E8FF),
      "highlight": Color(0xFF217BFF),
      "inner": Color(0xFFD1E9FF),
    },
  };

  @override
  Widget build(BuildContext context) {
    final selected = theme[themeColor] ?? theme["red"]!;
    double progress = 0;
    if (maxValue != null && maxValue! > 0) {
      progress = currentValue / maxValue!;
      if (progress > 1) progress = 1;
    }

    return Container(
      padding: EdgeInsets.all(14),
   constraints: const BoxConstraints(
    minWidth: 170,   // minimum width
    maxWidth: double.infinity, // take all available width
  ),
      height: 152,
      decoration: BoxDecoration(
        color: selected["bg"],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected["border"]!,
          width: 1.2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0),
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(54, 54),
                  painter: CircleProgressPainter(
                    progress: progress,
                    backgroundColor: Colors.white,
                    progressColor: selected["highlight"]!,
                  ),
                ),
                // Inner circle
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: selected["inner"],
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      _getIcon(),
                      color: selected["highlight"],
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 14),
          // Right side text
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 0.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF667085),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      fontFamily: "Manrope",
                    ),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      children: [
                        Text(
                          "$currentValue",
                          style: TextStyle(
                            color: selected["highlight"],
                            fontWeight: FontWeight.w600,
                            fontSize: 25,
                            fontFamily: "Manrope",
                            height: 0,
                          ),
                        ),
                        if (maxValue != null) ...[
                          const Text(
                            "/",
                            style: TextStyle(
                              color: Color(0xFF2A2A2A),
                              fontWeight: FontWeight.w600,
                              fontSize: 25,
                              fontFamily: "Manrope",
                              height: 0,
                            ),
                          ),
                          Text(
                            "$maxValue",
                            style: const TextStyle(
                              color: Color(0xFF2A2A2A),
                              fontWeight: FontWeight.w600,
                              fontSize: 25,
                              fontFamily: "Manrope",
                              height: 0,
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Circular Progress Painter
class CircleProgressPainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color progressColor;

  CircleProgressPainter({
    required this.progress,
    required this.backgroundColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = 4.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, bgPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
