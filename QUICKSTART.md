# Flame Engine Quick Start Guide

## Project Structure

```
flame_game/
├── lib/
│   ├── main.dart                 # Entry point
│   └── game/
│       ├── flame_game.dart       # Main game class
│       ├── config.dart           # Game configuration
│       └── components/
│           ├── player.dart       # Player component
│           └── example_component.dart
├── assets/
│   ├── images/                   # Image assets
│   └── audio/                    # Audio assets
└── pubspec.yaml                  # Dependencies
```

## Next Steps

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Run the Game
```bash
flutter run
```

### 3. Key Concepts

#### FlameGame
Your main game class in `lib/game/flame_game.dart`. This is where you:
- Load assets
- Add components
- Handle game state
- Implement game logic

#### Components
Game objects that extend `PositionComponent`, `SpriteComponent`, etc.
- `onLoad()` - Initialize the component
- `update(dt)` - Called every frame for game logic
- `render(canvas)` - Draw the component

#### Loading Images
```dart
final sprite = await Sprite.load('player.png');
```

#### Loading Audio
```dart
import 'package:flame_audio/flame_audio.dart';

await FlameAudio.play('sound_effect.mp3');
```

### 4. Common Mixins

Add these to your game class for extra functionality:
- `TapDetector` - Handle tap events
- `HasCollisionDetection` - Enable collisions
- `DragCallbacks` - Handle drag events
- `KeyboardEvents` - Handle keyboard input

Example:
```dart
class MyFlameGame extends FlameGame 
    with TapDetector, HasCollisionDetection {
  // ...
}
```

### 5. Adding Components

```dart
@override
Future<void> onLoad() async {
  await super.onLoad();
  
  // Add a sprite component
  final player = Player();
  add(player);
  
  // Add multiple components
  addAll([enemy1, enemy2, enemy3]);
}
```

### 6. Collision Detection

```dart
class Player extends PositionComponent with CollisionCallbacks {
  @override
  Future<void> onLoad() async {
    add(RectangleHitbox());
  }
  
  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    // Handle collision
  }
}
```

## Resources

- [Flame Documentation](https://docs.flame-engine.org/latest/)
- [Flame Examples](https://examples.flame-engine.org/)
- [Flutter Documentation](https://flutter.dev/docs)
- [Awesome Flame](https://github.com/flame-engine/awesome-flame)

## Tips

1. Use `Vector2` for positions and sizes
2. Call `super.onLoad()` and `super.update(dt)` in your component overrides
3. Use `Anchor` to control component positioning
4. Optimize by removing components when not needed: `component.removeFromParent()`
5. Use `CameraComponent` for advanced camera control

Happy game development! 🎮
