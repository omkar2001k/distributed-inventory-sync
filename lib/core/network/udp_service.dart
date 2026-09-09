import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';
import '../../modules/inventory/data/models/sync_message_model.dart';

/// Service managing peer-to-peer UDP broadcasts on the local Wi-Fi router.
/// Used as Phase 3 Local Fallback when cloud MQTT is unreachable.
class UdpService {
  RawDatagramSocket? _socket;
  final _messageController = StreamController<SyncMessageModel>.broadcast();
  bool _isListening = false;

  Stream<SyncMessageModel> get messageStream => _messageController.stream;
  bool get isListening => _isListening;

  /// Starts listening for UDP packets on the designated local port.
  Future<bool> startListening() async {
    if (kIsWeb) {
      debugPrint('[UDP] Web does not support raw UDP sockets. UDP fallback disabled.');
      return false;
    }

    if (_isListening && _socket != null) return true;

    try {
      _socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        AppConstants.udpPort,
        reuseAddress: true,
        reusePort: true,
      );

      _socket?.broadcastEnabled = true;
      _isListening = true;

      _socket?.listen(
        (RawSocketEvent event) {
          if (event == RawSocketEvent.read) {
            final datagram = _socket?.receive();
            if (datagram != null) {
              _handleIncomingDatagram(datagram);
            }
          }
        },
        onError: (error) {
          debugPrint('[UDP] Socket error: $error');
        },
      );

      debugPrint('[UDP] Listening on port ${AppConstants.udpPort}');
      return true;
    } catch (e) {
      debugPrint('[UDP] Failed to bind UDP socket: $e');
      _isListening = false;
      return false;
    }
  }

  void _handleIncomingDatagram(Datagram datagram) {
    try {
      final payload = utf8.decode(datagram.data);
      final dynamic decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) {
        final syncMessage = SyncMessageModel.fromJson(decoded);
        _messageController.add(syncMessage);
      }
    } catch (e) {
      debugPrint('[UDP] Failed to parse datagram: $e');
    }
  }

  /// Broadcasts an inventory mutation payload across the local subnet.
  Future<bool> broadcast(SyncMessageModel message) async {
    if (kIsWeb) return false;

    try {
      if (_socket == null) {
        final started = await startListening();
        if (!started || _socket == null) return false;
      }

      final jsonString = jsonEncode(message.toJson());
      final data = utf8.encode(jsonString);

      final bytesSent = _socket!.send(
        data,
        InternetAddress(AppConstants.udpBroadcastAddress),
        AppConstants.udpPort,
      );

      return bytesSent > 0;
    } catch (e) {
      debugPrint('[UDP] Broadcast error: $e');
      return false;
    }
  }

  void stop() {
    _isListening = false;
    _socket?.close();
    _socket = null;
  }

  void dispose() {
    stop();
    _messageController.close();
  }
}
