import 'package:audio_session/audio_session.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:absorb/services/companion_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.absorb.audio_engine');
  final calls = <MethodCall>[];
  var stored = <String, dynamic>{};

  setUp(() {
    calls.clear();
    stored = {};
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      if (call.method == 'setCompanionSettings') {
        stored.addAll(Map<String, dynamic>.from(call.arguments as Map));
      }
      return Map<String, dynamic>.from(stored);
    });
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('iOS opt-in mixes without ducking; off and Android retain their baseline', () {
    final on = CompanionController.audioConfiguration(isIOS: true, enabled: true);
    expect(on.avAudioSessionCategoryOptions, AVAudioSessionCategoryOptions.mixWithOthers);
    expect(on.avAudioSessionMode, AVAudioSessionMode.defaultMode);
    expect(on.avAudioSessionRouteSharingPolicy, AVAudioSessionRouteSharingPolicy.defaultPolicy);
    final off = CompanionController.audioConfiguration(isIOS: true, enabled: false);
    expect(off.avAudioSessionCategoryOptions, AVAudioSessionCategoryOptions.none);
    expect(off.avAudioSessionMode, AVAudioSessionMode.spokenAudio);
    expect(off.avAudioSessionRouteSharingPolicy, AVAudioSessionRouteSharingPolicy.longFormAudio);
    final android = CompanionController.audioConfiguration(isIOS: false, enabled: true);
    expect(android.androidAudioFocusGainType, AndroidAudioFocusGainType.gain);
    expect(android.androidAudioAttributes?.contentType, AndroidAudioContentType.speech);
    expect(android.androidWillPauseWhenDucked, isTrue);
  });

  test('book gain and mute survive native read-back without changing each other', () async {
    final controller = CompanionController(supported: true);
    await controller.setBookGain(0.35);
    await controller.setBookMuted(true);
    final restarted = CompanionController(supported: true);
    await restarted.load();
    expect(restarted.bookGain, 0.35);
    expect(restarted.bookMuted, isTrue);
    await restarted.setBookMuted(false);
    expect(restarted.bookGain, 0.35);
    await restarted.setBookGain(2);
    expect(restarted.bookGain, 1);
  });

  test('native failure never reports an opt-in that was not saved', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async {
      throw PlatformException(code: 'companion_session');
    });
    final controller = CompanionController(supported: true);
    await expectLater(controller.setEnabled(true), throwsA(isA<PlatformException>()));
    expect(controller.enabled, isFalse);
  });

  test('unsupported platform leaves overlap off and never touches native engine', () async {
    final controller = CompanionController(supported: false);
    await controller.load();
    await expectLater(controller.setEnabled(true), throwsUnsupportedError);
    expect(controller.enabled, isFalse);
    expect(calls, isEmpty);
  });

  test('mixing defaults off and reads persisted opt-in from native owner', () async {
    final controller = CompanionController(supported: true);
    expect(controller.enabled, isFalse);
    await controller.load();
    expect(controller.enabled, isFalse);
    await controller.setEnabled(true);
    expect(stored['enabled'], isTrue);
    final restarted = CompanionController(supported: true);
    await restarted.load();
    expect(restarted.enabled, isTrue);
    expect(calls.map((c) => c.method), [
      'getCompanionSettings', 'setCompanionSettings', 'getCompanionSettings',
    ]);
  });
}
