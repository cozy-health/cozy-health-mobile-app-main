import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class AudioRecorderService {
  AudioRecorderService()
    : _recorder = AudioRecorder(),
      _player = AudioPlayer();

  final AudioRecorder _recorder;
  final AudioPlayer _player;

  Stream<Amplitude> get amplitudeStream =>
      _recorder.onAmplitudeChanged(const Duration(milliseconds: 120));

  Future<void> start() async {
    final directory = await getTemporaryDirectory();
    final path =
        '${directory.path}/cozy_voice_${DateTime.now().microsecondsSinceEpoch}.m4a';
    await _recorder.start(const RecordConfig(), path: path);
  }

  Future<String?> stop() {
    return _recorder.stop();
  }

  Future<void> cancel() {
    return _recorder.cancel();
  }

  Future<void> play(String path) async {
    await _player.setFilePath(path);
    await _player.play();
  }

  Future<void> stopPlayback() {
    return _player.stop();
  }

  Future<void> dispose() async {
    await _recorder.dispose();
    await _player.dispose();
  }
}
