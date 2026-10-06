"""Source integration guards; iOS runtime/device testing remains necessary."""
import pathlib
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]

class NativeCompanionContract(unittest.TestCase):
    def test_widget_versions_follow_generated_flutter_version(self):
        import re
        project = (ROOT / 'ios/Runner.xcodeproj/project.pbxproj').read_text()
        for suffix in ('1', '2', '3'):
            pattern = r'AB10080000000000000E000' + suffix + r' /\*.*?\*/ = \{(.*?)\n\t\t\};'
            match = re.search(pattern, project, re.S)
            assert match is not None
            config = match.group(1)
            self.assertIn('baseConfigurationReference = 9740EEB31CF90195004384FC', config)
            self.assertIn('CURRENT_PROJECT_VERSION = "$(FLUTTER_BUILD_NUMBER)";', config)
            self.assertIn('MARKETING_VERSION = "$(FLUTTER_BUILD_NAME)";', config)
        workflow = (ROOT / '.github/workflows/build.yml').read_text()
        self.assertIn("assert ext['CFBundleVersion']==info['CFBundleVersion']", workflow)
        self.assertIn("assert ext['CFBundleShortVersionString']==info['CFBundleShortVersionString']", workflow)

    def test_app_deployment_matches_advertised_ios_17_minimum(self):
        import json, re
        project = (ROOT / 'ios/Runner.xcodeproj/project.pbxproj').read_text()
        targets = set(re.findall(r'IPHONEOS_DEPLOYMENT_TARGET = ([0-9.]+);', project))
        self.assertEqual(targets, {'17.0'})
        metadata = json.loads((ROOT / 'altstore/absorb-mix.json').read_text())
        self.assertEqual(metadata['minOSVersion'], '17.0')

    def test_simulator_launch_is_debug_and_distribution_archive_is_release(self):
        import xml.etree.ElementTree as ET
        scheme = ET.parse(ROOT / 'ios/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme').getroot()
        launch = scheme.find('LaunchAction')
        archive = scheme.find('ArchiveAction')
        assert launch is not None and archive is not None
        self.assertEqual(launch.get('buildConfiguration'), 'Debug')
        self.assertEqual(archive.get('buildConfiguration'), 'Release')

    def test_all_native_activation_paths_use_persisted_policy(self):
        paths = ['ios/Runner/AppDelegate.swift', 'ios/Runner/AbsorbPlayerCore.swift',
                 'ios/Runner/IOSQueueAdvancer.swift', 'ios/Runner/Audio/AbsorbAudioEngine.swift']
        for path in paths:
            with self.subTest(path=path):
                source = (ROOT / path).read_text()
                self.assertIn('configureAbsorbAudioSession(', source)
                self.assertNotIn('.setCategory(', source)
        self.assertNotIn('session.setActive(true)', (ROOT / 'ios/Runner/AppDelegate.swift').read_text())
        policy = (ROOT / 'ios/AbsorbPlayerCore/Sources/AbsorbPlayerCore/Intents.swift').read_text()
        self.assertIn('companion_mix_enabled', policy)
        self.assertIn('.mixWithOthers', policy)
        self.assertIn('policy: enabled ? .default : .longFormAudio', policy)
        self.assertNotIn('.duckOthers', policy)
        self.assertNotIn('.interruptSpokenAudioAndMixWithOthers', policy)
        self.assertIn('configureAbsorbAudioSession(activate: true)', policy)

    def test_book_gain_is_native_persistent_and_not_replaced_by_source_volume(self):
        engine = (ROOT / 'ios/Runner/Audio/AbsorbAudioEngine.swift').read_text()
        bridge = (ROOT / 'ios/Runner/Audio/AbsorbAudioBridge.swift').read_text()
        self.assertIn('companion_book_gain', engine)
        self.assertIn('companion_book_muted', engine)
        self.assertIn('self.applyComposedVolume()', engine)
        self.assertNotIn('self.volume = volume', engine)
        self.assertNotIn('self.player.volume = newVolume', engine)
        self.assertIn('case "getCompanionSettings":', bridge)
        self.assertIn('case "setCompanionSettings":', bridge)
        self.assertIn('AbsorbAudioEngine.shared.refreshBookGain()', bridge)
        self.assertIn('configureAbsorbAudioSession(', bridge)

    def test_dart_activation_and_chime_do_not_replace_native_opt_in(self):
        service = (ROOT / 'lib/services/audio_player_service.dart').read_text()
        sleep = (ROOT / 'lib/services/sleep_timer_service.dart').read_text()
        self.assertIn('CompanionController.configureSession()', service)
        self.assertIn('CompanionController.activateSession()', service)
        self.assertNotIn('(await AudioSession.instance).setActive(true)', service)
        self.assertNotIn('session.configure(AudioSessionConfiguration(', service)
        self.assertIn('handleAudioSessionActivation: false', sleep)
        self.assertIn('handleInterruptions: false', sleep)

    def test_sleep_restores_only_its_own_envelope(self):
        sleep = (ROOT / 'lib/services/sleep_timer_service.dart').read_text()
        service = (ROOT / 'lib/services/audio_player_service.dart').read_text()
        self.assertNotIn('_fadeStartVolume', sleep)
        self.assertNotIn('player.setVolume(', sleep)
        self.assertIn('_player.setSleepFade(1)', sleep)
        self.assertIn('_player.setSleepFade(fraction)', sleep)
        self.assertIn('player.setChimeAttenuation(0.15)', sleep)
        self.assertIn('player.setChimeAttenuation(1)', sleep)
        self.assertIn('BookAttenuation()', service)
        self.assertIn('_attenuation.effective', service)

    def test_auxiliary_players_cannot_dispose_singleton_book_engine(self):
        for path in ['lib/services/bookmark_preview_player.dart',
                     'lib/services/clip_editor_controller.dart',
                     'lib/screens/chapter_editor_screen.dart']:
            with self.subTest(path=path):
                source = (ROOT / path).read_text()
                self.assertIn("import 'package:just_audio/just_audio.dart';", source)
                self.assertNotIn("import '_audio_player.dart'", source)
                self.assertNotIn("import '../services/_audio_player.dart'", source)

    def test_companion_reachable_from_settings_player_and_before_login(self):
        for path in ['lib/screens/settings_screen.dart', 'lib/widgets/expanded_card.dart',
                     'lib/screens/login_screen.dart']:
            with self.subTest(path=path):
                self.assertIn('openCompanionScreen(context)', (ROOT / path).read_text())

    def test_widget_takeover_keeps_single_engine(self):
        core = (ROOT / 'ios/Runner/AbsorbPlayerCore.swift').read_text()
        delegate = (ROOT / 'ios/Runner/AppDelegate.swift').read_text()
        self.assertNotIn('AVPlayer()', core)
        self.assertIn('AbsorbAudioEngine.shared', core)
        self.assertIn('yieldToForegroundOwner()', delegate)
        self.assertIn('absorbAudioOwnerPid() == myPid', delegate)

if __name__ == '__main__':
    unittest.main()
