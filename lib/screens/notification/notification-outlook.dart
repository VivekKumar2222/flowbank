import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationOutlook extends StatelessWidget {
  final String titleText;
  final String badgeText;
  final String bodyText;

  const NotificationOutlook({
    super.key,
    required this.titleText,
    required this.badgeText,
    required this.bodyText,
  });

  bool get isPenalty => badgeText.toLowerCase() == "penalty";

  Color get bgColor =>
      isPenalty ? const Color(0xFFFFD1D1) : const Color(0xFFF5FAFF);

  Color get borderColor => isPenalty
      ? const Color.fromARGB(127, 255, 51, 51)
      : const Color(0xFFD7E8FF);

  Color get textColor =>
      isPenalty ? const Color(0xFFFF2121) : const Color(0xFF2C82FF);

  Color get badgeBgColor => isPenalty
      ? const Color.fromARGB(255, 255, 227, 227)
      : const Color(0xFFD1E9FF);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    const maxFontSize = 20.0;
                    const minFontSize = 14.0;

                    double fontSize = maxFontSize;

                    final textPainter = TextPainter(
                      text: TextSpan(
                        text: titleText,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: maxFontSize,
                          color: textColor,
                        ),
                      ),
                      maxLines: 1,
                      textDirection: TextDirection.ltr,
                    );

                    textPainter.layout(maxWidth: constraints.maxWidth);

                    if (textPainter.didExceedMaxLines) {
                      fontSize = minFontSize;
                    }

                    return Text(
                      titleText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: badgeBgColor,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            bodyText,
            style: TextStyle(
              fontSize: 12,
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
