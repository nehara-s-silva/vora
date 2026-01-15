// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:vora/main.dart';
import 'package:vora/theme/theme_provider.dart';

void main() {
  testWidgets('App load smoke test', (WidgetTester tester) async {
    // Create a mock/dummy ThemeProvider
    final themeProvider = ThemeProvider(true);

    // Build our app and trigger a frame.
    await tester.pumpWidget(VoraApp(themeProvider: themeProvider));

    // Since the app starts with SplashScreen, we can verify some text from it
    expect(find.text('Vora'), findsOneWidget);
  });
}
