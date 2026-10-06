import 'dart:io';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Settings for an external/manual companion, not a Spotify player or mixer.
/// Native app-group preferences are authoritative even before Flutter starts.
class CompanionController extends ChangeNotifier {
  CompanionController({bool? supported}) : supported = supported ?? Platform.isIOS;
  static final instance = CompanionController();
  static const channel = MethodChannel('com.absorb.audio_engine');
  final bool supported;
  bool enabled = false;
  double bookGain = 1;
  bool bookMuted = false;

  void _adopt(Map<String, dynamic>? raw) {
    if (raw == null) throw StateError('Native companion settings unavailable');
    enabled = raw['enabled'] as bool? ?? false;
    final gain = (raw['bookGain'] as num?)?.toDouble() ?? 1;
    bookGain = gain.isFinite ? gain.clamp(0.0, 1.0) : 1;
    bookMuted = raw['bookMuted'] as bool? ?? false;
    notifyListeners();
  }

  Future<void> load() async {
    if (!supported) return;
    _adopt(await channel.invokeMapMethod<String, dynamic>('getCompanionSettings'));
  }

  Future<void> _save(Map<String, dynamic> change) async {
    if (!supported) throw UnsupportedError('External overlap is iOS-only');
    _adopt(await channel.invokeMapMethod<String, dynamic>('setCompanionSettings', change));
  }

  static AudioSessionConfiguration audioConfiguration({required bool isIOS, required bool enabled}) {
    return AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playback,
      avAudioSessionMode: isIOS && enabled ? AVAudioSessionMode.defaultMode : AVAudioSessionMode.spokenAudio,
      avAudioSessionRouteSharingPolicy: AVAudioSessionRouteSharingPolicy.longFormAudio,
      avAudioSessionCategoryOptions: isIOS
          ? (enabled ? AVAudioSessionCategoryOptions.mixWithOthers : AVAudioSessionCategoryOptions.none)
          : AVAudioSessionCategoryOptions.duckOthers,
      androidAudioAttributes: const AndroidAudioAttributes(
        contentType: AndroidAudioContentType.speech, usage: AndroidAudioUsage.media,
      ),
      androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
      androidWillPauseWhenDucked: true,
    );
  }

  /// Read native policy on every iOS activation, including foreground adoption.
  /// audio_session caches its configuration, so native-only changes are not enough.
  static Future<void> configureSession() async {
    var mixing = false;
    if (Platform.isIOS) {
      final raw = await channel.invokeMapMethod<String, dynamic>('getCompanionSettings');
      mixing = raw?['enabled'] as bool? ?? false;
    }
    await (await AudioSession.instance).configure(audioConfiguration(isIOS: Platform.isIOS, enabled: mixing));
  }

  static Future<bool> activateSession() async {
    if (Platform.isIOS) await configureSession();
    return (await AudioSession.instance).setActive(true);
  }

  Future<void> setEnabled(bool value) async {
    await _save({'enabled': value});
    if (Platform.isIOS) await configureSession();
  }
  Future<void> setBookGain(double value) {
    if (!value.isFinite) throw ArgumentError.value(value);
    return _save({'bookGain': value.clamp(0.0, 1.0)});
  }
  Future<void> setBookMuted(bool value) => _save({'bookMuted': value});
}
