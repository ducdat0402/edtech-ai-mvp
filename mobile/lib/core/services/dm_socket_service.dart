import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';

/// Realtime DM socket. Connect when entering chat, disconnect when leaving.
class DmSocketService {
  io.Socket? _socket;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const String _tokenKey = 'auth_token';

  void Function(Map<String, dynamic> message)? onNewMessage;
  void Function(String userId)? onTyping;
  void Function(String message)? onError;
  void Function(String messageId)? onMessageDeleted;

  bool get isConnected => _socket?.connected ?? false;

  Future<void> connect() async {
    if (_socket?.connected == true) return;
    final token = await _storage.read(key: _tokenKey);
    if (token == null || token.isEmpty) return;

    final url = '${ApiConfig.serverUrl}/dm';
    _socket = io.io(
      url,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .setAuth({'token': token})
          .build(),
    );

    _socket!.onConnect((_) {});
    _socket!.onDisconnect((_) {});
    _socket!.on('new_message', (data) {
      if (data is Map<String, dynamic>) {
        onNewMessage?.call(data);
      }
    });
    _socket!.on('typing', (data) {
      if (data is Map<String, dynamic> && data['userId'] != null) {
        onTyping?.call(data['userId'] as String);
      }
    });
    _socket!.on('dm_error', (data) {
      if (data is Map<String, dynamic> && data['message'] != null) {
        onError?.call(data['message'] as String);
      }
    });
    _socket!.on('message_deleted', (data) {
      if (data is Map<String, dynamic> && data['messageId'] != null) {
        onMessageDeleted?.call(data['messageId'] as String);
      }
    });

    _socket!.connect();
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  void sendMessage(String peerId, String content, {String? replyToId}) {
    if (_socket?.connected != true) return;
    _socket!.emit('send_message', {
      'peerId': peerId,
      'content': content,
      if (replyToId != null) 'replyToId': replyToId,
    });
  }

  void emitTyping(String peerId) {
    if (_socket?.connected != true) return;
    _socket!.emit('typing', {'peerId': peerId});
  }
}
