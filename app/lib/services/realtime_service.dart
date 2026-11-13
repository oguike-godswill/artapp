import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../theme.dart';

// Adaptive WebSocket for Web and IO
import 'realtime_stub.dart'
    if (dart.library.html) 'realtime_web.dart'
    if (dart.library.io) 'realtime_io.dart';

class RealtimeBidEvent {
  final String auctionId;
  final int currentBid;
  final int bidCount;
  final String bidder;
  final String highestBidderId;
  final int minNextBid;
  final String artworkTitle;

  RealtimeBidEvent({
    required this.auctionId,
    required this.currentBid,
    required this.bidCount,
    required this.bidder,
    required this.highestBidderId,
    required this.minNextBid,
    required this.artworkTitle,
  });

  factory RealtimeBidEvent.fromJson(Map<String, dynamic> j) => RealtimeBidEvent(
        auctionId: j['auctionId'] as String,
        currentBid: (j['currentBid'] as num).toInt(),
        bidCount: (j['bidCount'] as num).toInt(),
        bidder: j['bidder'] as String? ?? 'Collector',
        highestBidderId: j['highestBidderId'] as String? ?? '',
        minNextBid: (j['minNextBid'] as num).toInt(),
        artworkTitle: j['artworkTitle'] as String? ?? 'Artwork',
      );
}

class RealtimeService extends ChangeNotifier {
  static final RealtimeService _instance = RealtimeService._internal();
  factory RealtimeService() => _instance;
  RealtimeService._internal();

  final _bidEvents = StreamController<RealtimeBidEvent>.broadcast();
  final _viewerCounts = StreamController<Map<String, int>>.broadcast();
  final Map<String, int> _viewers = {};

  Stream<RealtimeBidEvent> get onBid => _bidEvents.stream;
  Stream<Map<String, int>> get onViewers => _viewerCounts.stream;

  RealtimeSocket? _socket;
  Timer? _reconnectTimer;
  bool _connected = false;

  bool get isConnected => _connected;
  int viewersFor(String auctionId) => _viewers[auctionId] ?? 4;

  void connect() {
    if (_socket != null) return;
    final wsUrl = _getWsUrl();
    try {
      _socket = createRealtimeSocket(wsUrl);
      _socket?.onOpen(() {
        _connected = true;
        notifyListeners();
      });
      _socket?.onMessage((msg) {
        try {
          final data = jsonDecode(msg) as Map<String, dynamic>;
          final type = data['type'] as String?;
          if (type == 'bid') {
            final ev = RealtimeBidEvent.fromJson(data);
            _bidEvents.add(ev);
            HapticFeedback.mediumImpact();
            notifyListeners();
          } else if (type == 'viewers') {
            final aId = data['auctionId'] as String;
            final count = (data['count'] as num).toInt();
            _viewers[aId] = count;
            _viewerCounts.add(_viewers);
            notifyListeners();
          }
        } catch (_) {}
      });
      _socket?.onClose(() {
        _connected = false;
        _socket = null;
        notifyListeners();
        _scheduleReconnect();
      });
    } catch (_) {
      _scheduleReconnect();
    }
  }

  void subscribeAuction(String auctionId) {
    if (_socket != null) {
      _socket?.send(jsonEncode({
        'type': 'subscribe_auction',
        'auctionId': auctionId,
      }));
    }
  }

  String _getWsUrl() {
    final base = AppConfig.apiUrl;
    if (base.startsWith('https://')) {
      return base.replaceFirst('https://', 'wss://');
    }
    return base.replaceFirst('http://', 'ws://');
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 4), () {
      connect();
    });
  }

  @override
  void dispose() {
    _reconnectTimer?.cancel();
    _socket?.close();
    _bidEvents.close();
    _viewerCounts.close();
    super.dispose();
  }
}

abstract class RealtimeSocket {
  void send(String data);
  void close();
  void onOpen(VoidCallback callback);
  void onMessage(void Function(String msg) callback);
  void onClose(VoidCallback callback);
}
