import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:absorb/services/companion_controller.dart';
import 'package:absorb/screens/companion_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.absorb.audio_engine');
  setUp(() {
    var state = <String, dynamic>{};
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'setCompanionSettings') state.addAll(Map<String, dynamic>.from(call.arguments as Map));
      return state;
    });
  });
  tearDown(() => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null));

  testWidgets('opt-in and book mute are native-backed controls', (tester) async {
    final controller = CompanionController(supported: true);
    await tester.pumpWidget(MaterialApp(home: CompanionScreen(controller: controller)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('companionEnabled')));
    await tester.pumpAndSettle();
    expect(controller.enabled, isTrue);
    await tester.ensureVisible(find.byKey(const Key('bookMuted')));
    await tester.tap(find.byKey(const Key('bookMuted')));
    await tester.pumpAndSettle();
    expect(controller.bookMuted, isTrue);
  });

  testWidgets('Android labels unsupported overlap and disables book controls', (tester) async {
    await tester.pumpWidget(MaterialApp(home: CompanionScreen(controller: CompanionController(supported: false))));
    await tester.pumpAndSettle();
    expect(find.textContaining('Android overlap is not implemented'), findsOneWidget);
    expect(tester.widget<SwitchListTile>(find.byKey(const Key('companionEnabled'))).onChanged, isNull);
    await tester.ensureVisible(find.byKey(const Key('bookGain')));
    expect(tester.widget<Slider>(find.byKey(const Key('bookGain'))).onChanged, isNull);
  });

  testWidgets('book gain drag stays interactive and persists only on release', (tester) async {
    final controller = CompanionController(supported: true);
    await tester.pumpWidget(MaterialApp(home: CompanionScreen(controller: controller)));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('bookGain')));
    var slider = tester.widget<Slider>(find.byKey(const Key('bookGain')));
    slider.onChanged!(0.4);
    await tester.pump();
    slider = tester.widget<Slider>(find.byKey(const Key('bookGain')));
    expect(slider.onChanged, isNotNull);
    expect(slider.value, 0.4);
    expect(controller.bookGain, 1);
    expect(slider.onChangeEnd, isNotNull);
    slider.onChangeEnd!(0.4);
    await tester.pumpAndSettle();
    expect(controller.bookGain, 0.4);
    expect(tester.widget<Slider>(find.byKey(const Key('bookGain'))).value, 0.4);
  });

  testWidgets('Spotify is manual with a disabled slider and all limitations visible', (tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var opened = 0;
    await tester.pumpWidget(MaterialApp(home: CompanionScreen(
      controller: CompanionController(supported: true),
      openSpotify: () async { opened++; return true; },
    )));
    await tester.pumpAndSettle();
    final slider = tester.widget<Slider>(find.byKey(const Key('spotifyGain')));
    expect(slider.onChanged, isNull);
    expect(find.text('Spotify • external / manual'), findsOneWidget);
    expect(find.textContaining('Sleep timer controls the book only'), findsOneWidget);
    expect(find.textContaining('Hardware volume affects both'), findsOneWidget);
    expect(find.textContaining('Independent Spotify gain is unavailable'), findsOneWidget);
    expect(find.textContaining('No in-app Spotify OAuth is configured'), findsOneWidget);
    await tester.ensureVisible(find.text('Open Spotify'));
    await tester.tap(find.text('Open Spotify'));
    await tester.pumpAndSettle();
    expect(opened, 1);
    expect(find.byIcon(Icons.skip_next), findsNothing);
  });
}
