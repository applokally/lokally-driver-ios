import 'package:flutter/material.dart';
import 'package:get/get.dart';

class WifiAnimations extends StatefulWidget {
  const WifiAnimations({
    super.key,
    this.size = 100,
    this.color = Colors.grey,
    this.centered = false,
  });

  final double size;
  final bool centered;
  final Color color;

  @override
  WifiAnimationsState createState() => WifiAnimationsState();
}

class WifiAnimationsState extends State<WifiAnimations>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 5000),
      vsync: this,
    )..repeat();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: List.generate(6, (index) {
          return SizedBox.square(
            dimension: widget.size,
            child: Padding(
              padding: EdgeInsets.all(index * (widget.size / 10)),
              child: ShapesState(
                controller: _controller,
                color: widget.color,
                centered: widget.centered,
                index: index,
              ),
            ),
          );
        }),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class ShapesState extends AnimatedWidget {
  const ShapesState({
    super.key,
    required this.index,
    required this.color,
    required this.centered,
    required AnimationController controller,
  }) : super(listenable: controller);

  final int index;
  final bool centered;
  final Color color;

  Animation<double> get controller => listenable as Animation<double>;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: DrawShapes(index, color, centered, controller.value),
    );
  }
}

class DrawShapes extends CustomPainter {
  DrawShapes(this.index, this.color, this.centered, this.controller);

  final Color color;
  final bool centered;
  final int index;
  final double controller;

  @override
  void paint(Canvas canvas, Size size) {
    final Color primaryColor =
        color == Colors.grey ? Theme.of(Get.context!).primaryColor : color;

    Color waveColor = primaryColor.withValues(alpha: 0.10);
    if ((4 - index) == ((controller * 5).toInt())) {
      waveColor = primaryColor;
    }

    final Paint brush = Paint()
      ..color = waveColor
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;

    const double pi = 3.14;
    final double startArc = (225 * pi) / 180;
    final double sweepArc = (90 * pi) / 180;
    final Offset center = Offset(size.width / 2, size.height / 2);

    if (index == 0 && centered) {
      brush.style = PaintingStyle.fill;
      canvas.drawCircle(center, 5, brush);
      return;
    }

    canvas.drawArc(
      Rect.fromCenter(
        center: center,
        height: size.height,
        width: size.width,
      ),
      startArc,
      sweepArc,
      false,
      brush,
    );
  }

  @override
  bool shouldRepaint(covariant DrawShapes oldDelegate) {
    return oldDelegate.index != index ||
        oldDelegate.color != color ||
        oldDelegate.centered != centered ||
        oldDelegate.controller != controller;
  }
}
