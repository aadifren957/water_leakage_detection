import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:water_watch/app.dart';

void main() {
  testWidgets('WaterWatch app initial render smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: WaterWatchApp(),
      ),
    );

    // Initial pump
    await tester.pumpAndSettle();

    // Verify app brand text is rendered
    expect(find.text('WaterWatch'), findsWidgets);
  });
}
