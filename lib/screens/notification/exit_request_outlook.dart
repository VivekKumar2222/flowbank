import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flowbank/api/api_service.dart';
import 'dart:convert';


class ExitRequestOutlook extends StatelessWidget {
  final String titleText;
  final String bodyText;
  final String requestId;

  const ExitRequestOutlook({
    super.key,
    required this.titleText,
    required this.bodyText,
    required this.requestId,
  });


  Color get bgColor =>
      const Color(0xFFF5FAFF);

  Color get borderColor =>
      const Color(0xFFD7E8FF);

  Color get textColor =>
      const Color(0xFF2C82FF);

  Color get badgeBgColor =>
      const Color(0xFFD1E9FF);

      Future<void> approveExitRequest({
  required BuildContext context,
  required String requestId,
}) async {
  try {
    final response = await ApiService.post(
      "/api/collab/approve-exit-request",
      {
        "requestId": requestId,
      },
      context,
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Exit request approved"),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      final data = jsonDecode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(data["message"] ?? "Something went wrong"),
          backgroundColor: Colors.red,
        ),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Network error"),
        backgroundColor: Colors.red,
      ),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: borderColor,
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          Column(
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeBgColor,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Text(
                      "exit request",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  ),
                ],
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
          SizedBox(height: 12),
          InkWell(
  borderRadius: BorderRadius.circular(55),
  onTap: () {
  approveExitRequest(
    context: context,
    requestId: requestId,
  );
},

  child: Container(
    padding: const EdgeInsets.symmetric(vertical: 8),
    width: double.infinity,
    decoration: BoxDecoration(
      color: const Color(0xFF2C82FF),
      borderRadius: BorderRadius.circular(55),
    ),
    child: const Center(
      child: Text(
        "Accept Request",
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    ),
  ),
),
        ],
      ),
    );
  }
}
