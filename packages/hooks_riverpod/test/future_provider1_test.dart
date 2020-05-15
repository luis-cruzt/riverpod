import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  testWidgets('FutureProvider into FutureProvider1', (tester) async {
    final futureProvider = FutureProvider((_) async => 42);

    final futureProvider1 = FutureProvider<int>((ref) async {
      final other = ref.dependOn(futureProvider);
      return await other.future * 2;
    });

    await tester.pumpWidget(
      ProviderScope(
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: HookBuilder(builder: (c) {
            return useProvider(futureProvider1).when(
              data: (value) => Text(value.toString()),
              loading: () => const Text('loading'),
              error: (dynamic err, stack) => const Text('error'),
            );
          }),
        ),
      ),
    );

    expect(find.text('loading'), findsOneWidget);

    await tester.pump();

    expect(find.text('84'), findsOneWidget);
  });
  testWidgets('FutureProvider1 works with other providers', (tester) async {
    final futureProvider = Provider((_) => 42);

    final futureProvider1 = FutureProvider<int>((ref) async {
      final other = ref.dependOn(futureProvider);
      return other.value * 2;
    });

    await tester.pumpWidget(
      ProviderScope(
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: HookBuilder(builder: (c) {
            return useProvider(futureProvider1).when(
              data: (value) => Text(value.toString()),
              loading: () => const Text('loading'),
              error: (dynamic err, stack) => const Text('error'),
            );
          }),
        ),
      ),
    );

    expect(find.text('loading'), findsOneWidget);

    await tester.pump();

    expect(find.text('84'), findsOneWidget);
  });
  testWidgets('FutureProvider1 can be used directly', (tester) async {
    final futureProvider = Provider((_) => 42);

    final futureProvider1 = FutureProvider<int>((ref) async {
      final other = ref.dependOn(futureProvider);
      return other.value * 2;
    });

    await tester.pumpWidget(
      ProviderScope(
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: HookBuilder(builder: (c) {
            return useProvider(futureProvider1).when(
              data: (value) => Text(value.toString()),
              loading: () => const Text('loading'),
              error: (dynamic err, stack) => const Text('error'),
            );
          }),
        ),
      ),
    );

    expect(find.text('loading'), findsOneWidget);

    await tester.pump();

    expect(find.text('84'), findsOneWidget);
  });
}
