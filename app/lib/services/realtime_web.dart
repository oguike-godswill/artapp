// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import 'realtime_service.dart';

RealtimeSocket createRealtimeSocket(String url) => RealtimeSocketWeb(url);

class RealtimeSocketWeb implements RealtimeSocket {
  final html.WebSocket _ws;

  RealtimeSocketWeb(String url) : _ws = html.WebSocket(url);

  @override
  void send(String data) {
    if (_ws.readyState == html.WebSocket.OPEN) {
      _ws.send(data);
    }
  }

  @override
  void close() {
    _ws.close();
  }

  @override
  void onOpen(VoidCallback callback) {
    _ws.onOpen.listen((_) => callback());
  }

  @override
  void onMessage(void Function(String msg) callback) {
    _ws.onMessage.listen((event) {
      if (event.data is String) {
        callback(event.data as String);
      }
    });
  }

  @override
  void onClose(VoidCallback callback) {
    _ws.onClose.listen((_) => callback());
    _ws.onError.listen((_) => callback());
  }
}
