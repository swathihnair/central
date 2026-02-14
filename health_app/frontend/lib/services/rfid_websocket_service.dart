import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter/foundation.dart';

class RFIDWebSocketService {
  static const String wsUrl = 'ws://127.0.0.1:8765';
  
  WebSocketChannel? _channel;
  StreamController<Map<String, dynamic>>? _messageController;
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  bool _isConnecting = false;
  bool _shouldReconnect = true;
  
  Stream<Map<String, dynamic>> get messages => _messageController!.stream;
  bool get isConnected => _channel != null;
  
  RFIDWebSocketService() {
    _messageController = StreamController<Map<String, dynamic>>.broadcast();
  }
  
  Future<void> connect() async {
    if (_isConnecting || isConnected) {
      debugPrint('⚠️ Already connected or connecting');
      return;
    }
    
    _isConnecting = true;
    _shouldReconnect = true;
    
    try {
      debugPrint('🔌 Connecting to WebSocket: $wsUrl');
      
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      
      debugPrint('✅ WebSocket connected');
      _isConnecting = false;
      
      // Start ping timer to keep connection alive
      _startPingTimer();
      
      // Listen to messages
      _channel!.stream.listen(
        (message) {
          try {
            final data = jsonDecode(message);
            debugPrint('📨 WebSocket message: $data');
            
            // Handle different message types
            if (data['type'] == 'rfid_scan') {
              debugPrint('🎴 RFID Card Scanned: ${data['card_uid']}');
              _messageController!.add(data);
            } else if (data['type'] == 'patient_found') {
              debugPrint('✅ Patient Found: ${data['patient']['full_name']}');
              _messageController!.add(data);
            } else if (data['type'] == 'error') {
              debugPrint('❌ Error: ${data['message']}');
              _messageController!.add(data);
            } else if (data['type'] == 'connected') {
              debugPrint('✅ ${data['message']}');
              _messageController!.add(data);
            } else if (data['type'] == 'pong') {
              debugPrint('🏓 Pong received');
            }
          } catch (e) {
            debugPrint('❌ Error parsing message: $e');
          }
        },
        onError: (error) {
          debugPrint('❌ WebSocket error: $error');
          _handleDisconnect();
        },
        onDone: () {
          debugPrint('⚠️ WebSocket connection closed');
          _handleDisconnect();
        },
      );
    } catch (e) {
      debugPrint('❌ Failed to connect: $e');
      _isConnecting = false;
      _scheduleReconnect();
    }
  }
  
  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (isConnected) {
        sendMessage({'type': 'ping'});
      }
    });
  }
  
  void _handleDisconnect() {
    _channel = null;
    _pingTimer?.cancel();
    _isConnecting = false;
    
    if (_shouldReconnect) {
      _scheduleReconnect();
    }
  }
  
  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      if (_shouldReconnect && !isConnected && !_isConnecting) {
        debugPrint('🔄 Attempting to reconnect...');
        connect();
      }
    });
  }
  
  void sendMessage(Map<String, dynamic> message) {
    if (isConnected) {
      try {
        _channel!.sink.add(jsonEncode(message));
        debugPrint('📤 Sent: $message');
      } catch (e) {
        debugPrint('❌ Error sending message: $e');
      }
    } else {
      debugPrint('⚠️ Cannot send message: Not connected');
    }
  }
  
  void disconnect() {
    debugPrint('🔌 Disconnecting WebSocket');
    _shouldReconnect = false;
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
  }
  
  void dispose() {
    disconnect();
    _messageController?.close();
  }
}
