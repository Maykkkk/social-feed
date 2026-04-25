import 'package:flutter_test/flutter_test.dart';

import 'package:social_feed/src/app.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const App());

    // Verify that our app loads without crashing
    expect(find.text('Update supabase_config.dart with your keys and restart the app'), findsOneWidget);
  });
}
