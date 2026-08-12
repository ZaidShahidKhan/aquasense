import 'package:flutter/material.dart';

import '../theme.dart';

/// Paints one NEMA 5-15R receptacle recessed into the energy bar.
///
/// Built from the same dark glass as the rest of the app rather than from the
/// real unit's orange-and-grey plastic: copying the hardware's paint makes the
/// board read as a toy sitting inside an instrument. What carries the fidelity
/// is the geometry — the tall neutral blade, the shorter hot blade beside it,
/// the D-shaped ground below — and the 2x4 arrangement of the board itself.
///
/// One body, one rim, one set of slots. Every extra layer of trim added to
/// this shape made it look more cartoonish, not more real.
class SocketPainter extends CustomPainter {
  const SocketPainter({required this.energized});

  /// 0.0 dead, 1.0 fully live. Animated, so the socket lights up over time
  /// rather than snapping between two states.
  final double energized;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final radius = Radius.circular(size.width * 0.24);
    final body = RRect.fromRectAndRadius(rect, radius);

    // Recessed body, lit from above so it sits *in* the bar rather than on it.
    canvas.drawRRect(
      body,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(
              AppColors.socketBody,
              AppColors.socketBodyLive,
              energized,
            )!,
            Color.lerp(
              AppColors.socketWell,
              AppColors.socketBodyLive,
              energized * 0.55,
            )!,
          ],
        ).createShader(rect),
    );

    // Hairline rim, picking up the accent as current arrives.
    canvas.drawRRect(
      body.deflate(0.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1 + energized * 0.6
        ..color = Color.lerp(
          Colors.white.withValues(alpha: 0.17),
          AppColors.accent.withValues(alpha: 0.85),
          energized,
        )!,
    );

    _paintSlots(canvas, rect);
  }

  void _paintSlots(Canvas canvas, Rect face) {
    final w = face.width;
    final h = face.height;

    // Contacts read as voids when dead and faintly lit when live.
    final slotPaint = Paint()
      ..color = Color.lerp(
        AppColors.socketSlot,
        AppColors.accentDim,
        energized * 0.75,
      )!;

    // Real NEMA proportions: long narrow blades, noticeably smaller ground.
    final slotWidth = w * 0.068;
    final gap = w * 0.235;
    final centreY = face.top + h * 0.395;
    final neutralHeight = h * 0.30;
    final hotHeight = h * 0.25;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(face.center.dx - gap / 2, centreY),
          width: slotWidth,
          height: neutralHeight,
        ),
        Radius.circular(slotWidth * 0.3),
      ),
      slotPaint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(face.center.dx + gap / 2, centreY),
          width: slotWidth,
          height: hotHeight,
        ),
        Radius.circular(slotWidth * 0.3),
      ),
      slotPaint,
    );

    // Ground: the D-shaped hole below the blades, flat across the top.
    final groundWidth = w * 0.115;
    final groundHeight = h * 0.10;
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromCenter(
          center: Offset(face.center.dx, face.top + h * 0.685),
          width: groundWidth,
          height: groundHeight,
        ),
        topLeft: Radius.circular(groundWidth * 0.12),
        topRight: Radius.circular(groundWidth * 0.12),
        bottomLeft: Radius.circular(groundWidth * 0.5),
        bottomRight: Radius.circular(groundWidth * 0.5),
      ),
      slotPaint,
    );
  }

  @override
  bool shouldRepaint(SocketPainter oldDelegate) =>
      oldDelegate.energized != energized;
}
