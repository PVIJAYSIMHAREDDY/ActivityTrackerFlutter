import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:activity_tracker/services/issa_library.dart';

void main() {
  testWidgets(
    'Bundled library loads and searches on the target platform',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold()));
      await tester.runAsync(() async {
        final library = await IssaLibrary.load();
        expect(library.books, hasLength(6));
        expect(library.searchablePages, greaterThan(2400));
        expect(library.search('progressive overload'), isNotEmpty);
        expect(identical(await IssaLibrary.load(), library), isTrue);
      });
    },
    skip: kIsWeb,
  ); // Flutter web unit tests do not mock the platform asset channel.
}
