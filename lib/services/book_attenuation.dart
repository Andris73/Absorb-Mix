/// Independent transient envelopes. The native engine multiplies this by the
/// persisted user book gain (or zero when muted), at a single AVPlayer write.
class BookAttenuation {
  double sleepFade = 1;
  double chime = 1;
  double get effective => sleepFade.clamp(0.0, 1.0) * chime.clamp(0.0, 1.0);
}
