import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:parrot_downloader/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ParrotDownloaderApp());

    // Verify that our app starts with the correct title.
    expect(find.text('Parrot Downloader'), findsOneWidget);
  });
}

