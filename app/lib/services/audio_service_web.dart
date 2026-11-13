// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:async';
import 'audio_service.dart';

SolisAudioService createAudioService() => SolisAudioServiceWeb();

class SolisAudioServiceWeb implements SolisAudioService {
  html.AudioElement? _audio;
  final _posCtrl = StreamController<Duration>.broadcast();
  final _stateCtrl = StreamController<bool>.broadcast();
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = const Duration(seconds: 35);
  String? _currentUrl;

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

  void _ensureAudio(String url) {
    if (_audio != null && _currentUrl == url) return;

    _audio?.pause();
    _currentUrl = url;
    _audio = html.AudioElement(url)
      ..preload = 'auto';

    _audio!.onTimeUpdate.listen((_) {
      final curSec = _audio?.currentTime.toDouble() ?? 0.0;
      _position = Duration(milliseconds: (curSec * 1000).round());
      _posCtrl.add(_position);
    });

    _audio!.onDurationChange.listen((_) {
      final durSec = _audio?.duration.toDouble() ?? 0.0;
      if (durSec.isFinite && durSec > 0) {
        _duration = Duration(milliseconds: (durSec * 1000).round());
      }
    });

    _audio!.onPlay.listen((_) {
      _isPlaying = true;
      _stateCtrl.add(true);
    });

    _audio!.onPause.listen((_) {
      _isPlaying = false;
      _stateCtrl.add(false);
    });

    _audio!.onEnded.listen((_) {
      _isPlaying = false;
      _position = Duration.zero;
      _posCtrl.add(Duration.zero);
      _stateCtrl.add(false);
    });
  }

  @override
  Future<void> play(String url) async {
    _ensureAudio(url);
    try {
      await _audio?.play();
    } catch (_) {
      // Browser autoplay policies: user must interact first
    }
  }

  @override
  Future<void> pause() async {
    _audio?.pause();
  }

  @override
  Future<void> seek(double fraction) async {
    if (_audio != null) {
      final durSec = _audio!.duration.toDouble();
      if (durSec > 0 && durSec.isFinite) {
        _audio!.currentTime = fraction * durSec;
      }
    }
  }

  @override
  void dispose() {
    _audio?.pause();
    _audio = null;
    _posCtrl.close();
    _stateCtrl.close();
  }
}
