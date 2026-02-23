import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// A simple player component that can be moved around the screen
class Player extends PositionComponent {
  static const double speed = 200.0;
  static const double size = 50.0;

  Vector2? targetPosition;
  late Paint _paint;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Set initial size and position
    this.size = Vector2.all(size);
    position = Vector2(
      (parent as PositionComponent).size.x / 2 - size / 2,
      (parent as PositionComponent).size.y / 2 - size / 2,
    );
    anchor = Anchor.center;

    // Set up paint for rendering
    _paint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      _paint,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Move towards target position if set
    if (targetPosition != null) {
      final direction = targetPosition! - position;
      final distance = direction.length;

      if (distance < speed * dt) {
        // Reached target
        position = targetPosition!;
        targetPosition = null;
      } else {
        // Move towards target
        direction.normalize();
        position += direction * speed * dt;
      }
    }
  }

  /// Set a new target position for the player to move to
  void moveTo(Vector2 newPosition) {
    targetPosition = newPosition.clone();
  }
}
