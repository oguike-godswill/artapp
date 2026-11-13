import 'dart:async';
import 'audio_service.dart';

SolisAudioService createAudioService() => _StubAudioService();

class _StubAudioService implements SolisAudioService {
  final _posCtrl = StreamController<Duration>.broadcast();
  final _stateCtrl = StreamController<bool>.broadcast();
  bool _playing = false;

  @override
  bool get isPlaying => _playing;

  @override
  Duration get position => Duration.zero;

  @override
  Duration get duration => const Duration(seconds: 35);

  @override
  Stream<Duration> get onPositionChanged => _posCtrl.stream;

  @override
  Stream<bool> get onPlayerStateChanged => _stateCtrl.stream;

  @override
  Future<void> play(String url) async {
    _playing = true;
    _stateCtrl.add(true);
  }

  @override
  Future<void> pause() async {
    _playing = false;
    _stateCtrl.add(false);
  }

  @override
  Future<void> seek(double fraction) async {}

  @override
  void dispose() {
    _posCtrl.close();
    _stateCtrl.close();
  }
}
