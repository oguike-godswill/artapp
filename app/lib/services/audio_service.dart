import 'dart:async';

import 'audio_service_stub.dart'
    if (dart.library.html) 'audio_service_web.dart'
    if (dart.library.io) 'audio_service_io.dart';

abstract class SolisAudioService {
  factory SolisAudioService() => createAudioService();

  bool get isPlaying;
  Duration get position;
  Duration get duration;

  Stream<Duration> get onPositionChanged;
  Stream<bool> get onPlayerStateChanged;

  Future<void> play(String url);
  Future<void> pause();
  Future<void> seek(double fraction);
  void dispose();
}
