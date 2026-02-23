// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flame_engine/main.dart';

void main() {
  testWidgets('Dungeon game loads successfully', (WidgetTester tester) async {
    // Build our game and trigger a frame.
    await tester.pumpWidget(const MaterialApp(home: GameNavigator()));
    await tester.pumpAndSettle();

    // Verify the app bar is present
    expect(find.text('Dungeon Crawler'), findsOneWidget);

    // Verify the game widget is present
    expect(find.byType(GameWidget<DungeonGame>), findsOneWidget);

    // Verify control buttons are present
    expect(find.text('Reset'), findsOneWidget);
    expect(find.text('Scan NFC'), findsOneWidget);
  });
}
