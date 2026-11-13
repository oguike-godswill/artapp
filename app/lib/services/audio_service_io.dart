import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'audio_service.dart';

SolisAudioService createAudioService() => SolisAudioServiceIO();

class SolisAudioServiceIO implements SolisAudioService {
  final AudioPlayer _player = AudioPlayer();
  final _posCtrl = StreamController<Duration>.broadcast();
  final _stateCtrl = StreamController<bool>.broadcast();
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = const Duration(seconds: 35);
  StreamSubscription? _posSub;
  StreamSubscription? _durSub;
  StreamSubscription? _stateSub;
  StreamSubscription? _compSub;

  SolisAudioServiceIO() {
    _posSub = _player.onPositionChanged.listen((p) {
      _position = p;
      _posCtrl.add(p);
    });
    _durSub = _player.onDurationChanged.listen((d) {
      if (d > Duration.zero) {
        _duration = d;
      }
    });
    _stateSub = _player.onPlayerStateChanged.listen((s) {
      _isPlaying = s == PlayerState.playing;
      _stateCtrl.add(_isPlaying);
    });
    _compSub = _player.onPlayerComplete.listen((_) {
      _isPlaying = false;
      _position = Duration.zero;
      _posCtrl.add(Duration.zero);
      _stateCtrl.add(false);
    });
  }

  @override
  bool get isPlaying => _isPlaying;

  @override
  Duration get position => _position;

  @override
  Duration get duration => _duration;

  @override
  Stream<Duration> get onPositionChanged => _posCtrl.stream;

  @override
  Stream<bool> get onPlayerStateChanged => _stateCtrl.stream;

  @override
  Future<void> play(String url) async {
    try {
      await _player.play(UrlSource(url));
    } catch (_) {}
  }

  @override
  Future<void> pause() async {
    await _player.pause();
  }

  @override
  Future<void> seek(double fraction) async {
    final targetMs = (fraction * _duration.inMilliseconds).round();
    await _player.seek(Duration(milliseconds: targetMs));
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _durSub?.cancel();
    _stateSub?.cancel();
    _compSub?.cancel();
    _player.dispose();
    _posCtrl.close();
    _stateCtrl.close();
  }
}
