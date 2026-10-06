import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/companion_controller.dart';

void openCompanionScreen(BuildContext context) {
  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const CompanionScreen()));
}

/// Experimental OS-combined audio. Spotify remains entirely in Spotify's app.
class CompanionScreen extends StatefulWidget {
  const CompanionScreen({super.key, this.controller, this.openSpotify});
  final CompanionController? controller;
  final Future<bool> Function()? openSpotify;
  @override
  State<CompanionScreen> createState() => _CompanionScreenState();
}

class _CompanionScreenState extends State<CompanionScreen> with WidgetsBindingObserver {
  late final CompanionController controller;
  bool _ready = false;
  bool _busy = false;
  double? _draftGain;
  String? _error;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    controller = widget.controller ?? CompanionController.instance;
    _load();
  }
  Future<void> _load() async {
    try {
      await controller.load();
      if (mounted) setState(() { _ready = true; _error = null; });
    } catch (e) {
      if (mounted) setState(() { _ready = false; _error = 'Could not read native audio settings. $e'; });
    }
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  Future<void> _change(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try { await action(); } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Audio setting could not be applied: $e')));
    } finally { if (mounted) setState(() => _busy = false); }
  }
  Future<void> _openSpotify() async {
    try {
      final opened = await (widget.openSpotify?.call() ?? launchUrl(Uri.parse('spotify:'), mode: LaunchMode.externalApplication));
      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Install or open the Spotify app, then select music there.')));
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open Spotify. Open it manually and select music there.')));
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Spotify companion')),
      body: ListenableBuilder(listenable: controller, builder: (context, _) {
        final canEdit = controller.supported && _ready && !_busy;
        return ListView(padding: const EdgeInsets.all(20), children: [
          const Text('EXPERIMENTAL • EXTERNAL AUDIO', style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          const Text('Your audiobook + your Spotify app', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          const Text('iOS combines the two apps at the output. This is not an app-owned mixer; Spotify audio is never extracted, captured or imported.'),
          if (!controller.supported) const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('Android overlap is not implemented in this experiment. Existing audiobook playback is unchanged.')),
          if (_error != null) ...[
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            TextButton(onPressed: _load, child: const Text('Retry reading settings')),
          ],
          SwitchListTile(
            key: const Key('companionEnabled'), contentPadding: EdgeInsets.zero,
            title: const Text('Mix with other apps (iOS)'),
            subtitle: Text(controller.enabled ? 'On • Spotify can keep playing with the book' : 'Off by default • standard audiobook audio session'),
            value: controller.enabled,
            onChanged: canEdit ? (value) => _change(() => controller.setEnabled(value)) : null,
          ),
          const Divider(height: 32),
          const Text('Audiobook • book-only gain', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('Use the existing player to choose and play your book. These controls change only the native audiobook player, including after switching books.'),
          Slider(
            key: const Key('bookGain'),
            value: _draftGain ?? controller.bookGain,
            label: '${((_draftGain ?? controller.bookGain) * 100).round()}%',
            divisions: 100,
            onChanged: canEdit ? (value) => setState(() => _draftGain = value) : null,
            onChangeEnd: canEdit ? (value) async {
              await _change(() => controller.setBookGain(value));
              if (mounted) setState(() => _draftGain = null);
            } : null,
          ),
          SwitchListTile(key: const Key('bookMuted'), contentPadding: EdgeInsets.zero,
            title: const Text('Mute book only'), value: controller.bookMuted,
            onChanged: canEdit ? (value) => _change(() => controller.setBookMuted(value)) : null),
          const Divider(height: 32),
          const Text('Spotify • external / manual', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('Log in with your existing Spotify app. Select music and use play/pause in Spotify, then return here. No in-app Spotify OAuth is configured: no developer client ID is available.'),
          const SizedBox(height: 12),
          FilledButton.icon(onPressed: _openSpotify, icon: const Icon(Icons.open_in_new), label: const Text('Open Spotify')),
          const SizedBox(height: 12),
          const Text('Spotify gain • unavailable (not a live level)'),
          const Slider(key: Key('spotifyGain'), value: 0.5, onChanged: null),
          const Text('Independent Spotify gain is unavailable. Adjust Spotify manually where supported; this disabled slider is not a music-volume control.'),
          const Divider(height: 32),
          const Text('Know the limits', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('• Sleep timer controls the book only; Spotify may continue.\n• Hardware volume affects both apps.\n• Other apps may interrupt playback; overlap depends on iOS, Spotify and the audio route.\n• Lock-screen / headset controls may target Spotify instead of the book.\n• Book gain applies to local iOS playback, not Chromecast.'),
          const SizedBox(height: 24),
        ]);
      }),
    );
  }
}
