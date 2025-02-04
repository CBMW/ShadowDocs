// lib/services/signaling_service.dart
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';

typedef SignalingMessageCallback = void Function(Map<String, dynamic> message);

class SignalingService {
  final String serverUrl;
  WebSocketChannel? _channel;
  SignalingMessageCallback? onMessageReceived;

  SignalingService({required this.serverUrl});

  /// Connects to the signaling server.
  void connect() {
    _channel = IOWebSocketChannel.connect(Uri.parse(serverUrl));
    _channel!.stream.listen(
      (message) {
        try {
          final Map<String, dynamic> data = jsonDecode(message);
          if (onMessageReceived != null) {
            onMessageReceived!(data);
          }
        } catch (e) {
          print("Error decoding signaling message: $e");
        }
      },
      onError: (error) => print("Signaling error: $error"),
      onDone: () => print("Signaling connection closed"),
    );
  }

  /// Sends a JSON-encoded [message] to the signaling server.
  void send(Map<String, dynamic> message) {
    if (_channel != null) {
      _channel!.sink.add(jsonEncode(message));
    }
  }

  /// Closes the signaling connection.
  void disconnect() {
    _channel?.sink.close();
  }
}
