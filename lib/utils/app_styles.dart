import 'dart:math' as math;

import 'package:flutter/material.dart';

// Tasarımda kullanılan ana renkler
const Color kLightBlue = Color(0xFFC7EBFD);
const Color kLightOrange = Color(0xFFFFE6B5);
const Color kInputFillColor = Color(0xFFFFF2D0);
const Color kPrimaryBlue = Color(0xFF0D47A1); // Koyu Mavi (Yazılar için)
const Color kOrangeButton = Color(0xFFF1B746); // Sign Up Buton Rengi
const Color kLightestBlue = Color(0xFFE0F7FA); // Login input rengi

// Yeniden Kullanılabilir Text Field Widget'ı
class CustomTextField extends StatelessWidget {
  final String hintText;
  final bool isPassword;

  const CustomTextField(
      {super.key, required this.hintText, this.isPassword = false});

  @override
  Widget build(BuildContext context) {
    return TextField(
      obscureText: isPassword,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.black87),
        filled: true,
        fillColor: kInputFillColor,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none),
      ),
    );
  }
}

class GoogleAuthButton extends StatelessWidget {
  final String text;
  final bool isLoading;
  final VoidCallback? onPressed;

  const GoogleAuthButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: const BorderSide(color: Color(0xFFE0E0E0), width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Color(0xFF4285F4),
                  strokeWidth: 2.5,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const GoogleLogo(size: 24),
                  const SizedBox(width: 12),
                  Text(
                    text,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class GoogleLogo extends StatelessWidget {
  final double size;
  final Color backgroundColor;

  const GoogleLogo({
    super.key,
    this.size = 24,
    this.backgroundColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _GoogleLogoPainter(backgroundColor: backgroundColor),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  final Color backgroundColor;

  const _GoogleLogoPainter({required this.backgroundColor});

  @override
  void paint(Canvas canvas, Size size) {
    const blue = Color(0xFF4285F4);
    const green = Color(0xFF34A853);
    const yellow = Color(0xFFFBBC05);
    const red = Color(0xFFEA4335);

    final ringThickness = size.width * 0.22;
    final outerRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final innerRect = Rect.fromLTWH(
      ringThickness,
      ringThickness,
      size.width - ringThickness * 2,
      size.height - ringThickness * 2,
    );

    const segmentSweep = math.pi / 2;
    const pad = math.pi / 180;

    void drawSegment(Color color, double startAngle, double sweepAngle) {
      final adjustedSweep = sweepAngle - pad * 2;
      if (adjustedSweep <= 0) return;

      final path = Path()
        ..arcTo(outerRect, startAngle + pad, adjustedSweep, false)
        ..arcTo(innerRect, startAngle + pad + adjustedSweep, -adjustedSweep,
            false)
        ..close();
      canvas.drawPath(path, Paint()..color = color);
    }

    // Segment order: red (top), yellow (left), green (bottom), blue (right).
    const redEndTrim = math.pi / 18;
    drawSegment(red, -3 * math.pi / 4, segmentSweep - redEndTrim);
    drawSegment(yellow, 3 * math.pi / 4, segmentSweep);
    drawSegment(green, math.pi / 4, segmentSweep);

    // Split blue to create the "G" gap on the right.
    const gap = math.pi / 6;
    const blueTopTrim = math.pi / 6;
    final blueStart = -math.pi / 4 + blueTopTrim;
    final blueEnd = math.pi / 4;
    final firstBlueSweep = (-gap / 2) - blueStart;
    final secondBlueSweep = blueEnd - (gap / 2);
    drawSegment(blue, blueStart, firstBlueSweep);
    drawSegment(blue, gap / 2, secondBlueSweep);

    // Draw the blue bar inside the ring.
    final center = Offset(size.width / 2, size.height / 2);
    final barHeight = ringThickness * 0.9;
    final barRight = outerRect.right - ringThickness * 0.1;
    final barRect = Rect.fromLTWH(
      center.dx,
      center.dy - barHeight / 2,
      barRight - center.dx,
      barHeight,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(barRect, Radius.circular(barHeight / 2)),
      Paint()..color = blue,
    );
  }

  @override
  bool shouldRepaint(covariant _GoogleLogoPainter oldDelegate) => false;
}
