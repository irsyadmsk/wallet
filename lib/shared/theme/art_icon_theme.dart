import 'package:flutter/material.dart';

/// Supported geometric shapes for ART+ adaptive icon system.
enum ArtShape {
  squircle,
  circle,
  hexagon,
  roundedSquare,
  stadium;

  String get label {
    switch (this) {
      case ArtShape.squircle:
        return 'Squircle (iOS)';
      case ArtShape.circle:
        return 'Circle';
      case ArtShape.hexagon:
        return 'Hexagon';
      case ArtShape.roundedSquare:
        return 'Rounded Box';
      case ArtShape.stadium:
        return 'Stadium';
    }
  }

  String get description {
    switch (this) {
      case ArtShape.squircle:
        return 'Sudut melengkung halus dan elegan';
      case ArtShape.circle:
        return 'Bentuk lingkaran simetris klasik';
      case ArtShape.hexagon:
        return 'Geometris futuristik bersudut enam';
      case ArtShape.roundedSquare:
        return 'Bentuk kotak dengan sudut membulat';
      case ArtShape.stadium:
        return 'Kapsul oval dinamis dan modern';
    }
  }

  IconData get previewIcon {
    switch (this) {
      case ArtShape.squircle:
        return Icons.crop_square_rounded;
      case ArtShape.circle:
        return Icons.circle_outlined;
      case ArtShape.hexagon:
        return Icons.hexagon_outlined;
      case ArtShape.roundedSquare:
        return Icons.check_box_outline_blank_rounded;
      case ArtShape.stadium:
        return Icons.stadium_outlined;
    }
  }
}

/// Custom Clipper for pointy-topped hexagon.
class HexagonClipper extends CustomClipper<Path> {
  const HexagonClipper({this.cornerRadius = 3.0});

  final double cornerRadius;

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path();
    path.moveTo(w * 0.5, 0);
    path.lineTo(w, h * 0.25);
    path.lineTo(w, h * 0.75);
    path.lineTo(w * 0.5, h);
    path.lineTo(0, h * 0.75);
    path.lineTo(0, h * 0.25);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant HexagonClipper oldClipper) =>
      oldClipper.cornerRadius != cornerRadius;
}

/// Custom Painter for hexagon border and background
class HexagonPainter extends CustomPainter {
  const HexagonPainter({
    required this.backgroundColor,
    required this.borderColor,
    this.borderWidth = 1.0,
  });

  final Color backgroundColor;
  final Color borderColor;
  final double borderWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final fillPath = Path()
      ..moveTo(w * 0.5, 0)
      ..lineTo(w, h * 0.25)
      ..lineTo(w, h * 0.75)
      ..lineTo(w * 0.5, h)
      ..lineTo(0, h * 0.75)
      ..lineTo(0, h * 0.25)
      ..close();

    final fillPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    if (borderWidth > 0 && borderColor.a > 0) {
      final borderPaint = Paint()
        ..color = borderColor
        ..strokeWidth = borderWidth
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(fillPath, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant HexagonPainter oldDelegate) {
    return oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.borderWidth != borderWidth;
  }
}
