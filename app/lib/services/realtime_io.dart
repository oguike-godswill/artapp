import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'realtime_service.dart';

RealtimeSocket createRealtimeSocket(String url) => RealtimeSocketIO(url);

class RealtimeSocketIO implements RealtimeSocket {
  io.WebSocket? _ws;
  VoidCallback? _onOpen;
  void Function(String msg)? _onMessage;
  VoidCallback? _onClose;

  RealtimeSocketIO(String url) {
    _connect(url);
  }

  Future<void> _connect(String url) async {
    try {
      _ws = await io.WebSocket.connect(url);
      _onOpen?.call();
      _ws!.listen(
        (data) {
          if (data is String) {
            _onMessage?.call(data);
          }
        },
        onDone: () => _onClose?.call(),
        onError: (_) => _onClose?.call(),
      );
    } catch (_) {
      _onClose?.call();
    }
  }

  @override
  void send(String data) {
    _ws?.add(data);
  }

  @override
  void close() {
    _ws?.close();
  }

  @override
  void onOpen(VoidCallback callback) {
    _onOpen = callback;
  }

  @override
  void onMessage(void Function(String msg) callback) {
    _onMessage = callback;
  }

  @override
  void onClose(VoidCallback callback) {
    _onClose = callback;
  }
}
