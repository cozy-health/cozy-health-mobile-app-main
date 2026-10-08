import 'package:flutter/services.dart';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';
import 'local_db_service.dart';

class ConnectionSound {
  static const asset = 'assets/sounds/connection_restored.mp3';
  Future<void> play() async {
    AudioPlayer? player;
    AudioSession? session;
    AudioSessionConfiguration? previous;
    try {
      if ((await LocalDbService().settingsBox()).get(
            'connection_sound_muted',
            defaultValue: false,
          ) ==
          true) {
        return;
      }
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      if (!manifest.listAssets().contains(asset)) return;
      session = await AudioSession.instance;
      previous = session.configuration;
      // Never interrupt journal playback/recording. Ambient obeys the iOS mute
      // switch; notification usage uses Android's notification volume policy.
      if (previous != null &&
          previous.avAudioSessionCategory != AVAudioSessionCategory.ambient) {
        return;
      }
      await session.configure(
        const AudioSessionConfiguration(
          avAudioSessionCategory: AVAudioSessionCategory.ambient,
          androidAudioAttributes: AndroidAudioAttributes(
            usage: AndroidAudioUsage.notification,
            contentType: AndroidAudioContentType.sonification,
          ),
          androidAudioFocusGainType:
              AndroidAudioFocusGainType.gainTransientMayDuck,
        ),
      );
      player = AudioPlayer();
      final duration = await player.setAsset(asset);
      if (duration == null || duration > const Duration(seconds: 2)) return;
      await player.play();
    } catch (_) {
      // The optional sound or audio platform may be unavailable.
    } finally {
      try {
        await player?.dispose();
        if (session != null && previous != null) {
          await session.configure(previous);
        }
      } catch (_) {
        // Audio teardown is optional too.
      }
    }
  }
}
