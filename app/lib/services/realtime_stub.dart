import 'package:flutter/foundation.dart';
import 'realtime_service.dart';

RealtimeSocket createRealtimeSocket(String url) => _StubSocket();

class _StubSocket implements RealtimeSocket {
  @override
  void send(String data) {}
  @override
  void close() {}
  @override
  void onOpen(VoidCallback callback) {}
  @override
  void onMessage(void Function(String msg) callback) {}
  @override
  void onClose(VoidCallback callback) {}
}
