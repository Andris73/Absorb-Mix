import 'package:flutter_test/flutter_test.dart';
import 'package:absorb/services/book_attenuation.dart';

void main() {
  test('sleep fade and chime attenuation compose and restore independently', () {
    final gain = BookAttenuation();
    expect(gain.effective, 1);
    gain.sleepFade = 0.5;
    gain.chime = 0.15;
    expect(gain.effective, closeTo(0.075, 0.0001));
    gain.sleepFade = 0.25;
    gain.chime = 1; // stale chime completion may only restore its own layer
    expect(gain.effective, 0.25);
    gain.sleepFade = 1; // cancelling/snoozing restores fade, not chosen gain
    expect(gain.effective, 1);
  });
}
