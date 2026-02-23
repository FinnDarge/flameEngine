import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Example game component
/// Use this as a template for creating your own game objects
class ExampleComponent extends PositionComponent {
  final Color color;
  late Paint _paint;

  ExampleComponent({
    required Vector2 position,
    required Vector2 size,
    this.color = Colors.green,
  }) : super(
          position: position,
          size: size,
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    _paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    // Draw a circle
    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      size.x / 2,
      _paint,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    // Add your update logic here
    // This runs every frame
  }
}
