import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:absorb/services/native_ios_audio_player.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('one native wrapper owns channel state across book source changes', () async {
    SharedPreferences.setMockInitialValues({});
    final loads = <Map>[];
    const events = MethodChannel('com.absorb.audio_engine.events');
    const commands = MethodChannel('com.absorb.audio_engine');
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(events, (_) async => null);
    messenger.setMockMethodCallHandler(commands, (call) async {
      if (call.method == 'load') loads.add(call.arguments as Map);
      return call.method == 'load' ? {'durationS': 60.0} : true;
    });
    final first = NativeIosAudioPlayer();
    final adopted = NativeIosAudioPlayer();
    expect(identical(first, adopted), isTrue);
    await first.setVolume(0.25); // transient envelope, not user's persisted gain
    await first.setAudioSource(ja.AudioSource.uri(Uri.parse('file:///book-one.m4b')));
    await adopted.setAudioSource(ja.AudioSource.uri(Uri.parse('file:///book-two.m4b')));
    expect(loads.map((m) => m['volume']), [0.25, 0.25]);
    expect(adopted.volume, 0.25);
    await first.dispose();
    messenger.setMockMethodCallHandler(events, null);
    messenger.setMockMethodCallHandler(commands, null);
  });
}
