# Manual acceptance checklist — experimental iOS companion

Install Absorb Mix alongside Absorb; confirm both icons and independent login/settings/data. Do not delete original Absorb.

1. Sign in to Audiobookshelf. Open Settings → external music companion and enable coexistence.
2. Open Spotify, sign in there if needed, start a track, return to Absorb Mix and play a book. Record whether both remain audible.
3. Change only the audiobook gain from 100% to 25%. Verify Spotify loudness does not change. Mute/unmute the book; verify its chosen gain is restored.
4. Try both startup orders: music→book and book→music. Record any Spotify-side interruption; our app cannot override Spotify's audio-session policy.
5. Pause/resume and seek the book, change chapters, and exercise downloaded/offline and streaming books. Spotify should not be controlled by these book actions.
6. Lock the phone for 5 minutes, then resume the app. Test foreground/background transitions and widget play/pause after terminating the app.
7. Exercise the audiobook sleep timer with fade and warning chime. Music may continue: this prototype does not own Spotify transport. Cancel during fade and verify the book gain returns to the selected value, not 100%.
8. Test headphones/Bluetooth disconnect, reconnect and phone-call interruption; never auto-resume on speakers unexpectedly. Test AirPlay if used.
9. Disable coexistence and verify ordinary exclusive audiobook playback returns. Preferences should survive force-quit/relaunch.
10. Report device/iOS version, output route, startup order, exact symptom, and whether streaming or downloaded playback was used. No Spotify passwords or tokens in reports.

No independent Spotify-volume slider, in-app Spotify OAuth, PCM mixer or Android coexistence is claimed in this release. The hardware volume controls the shared device output.
