// lib/services/webrtc_service.dart
import 'package:flutter_webrtc/flutter_webrtc.dart';

class WebRTCService {
  RTCPeerConnection? _peerConnection;
  RTCDataChannel? _dataChannel;

  /// Called when a message is received on the data channel.
  Function(String)? onDataReceived;

  final Map<String, dynamic> _config = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      // Add TURN servers here if needed.
    ]
  };

  final Map<String, dynamic> _constraints = {
    'mandatory': {},
    'optional': [
      {'DtlsSrtpKeyAgreement': true},
    ]
  };

  /// Initializes the peer connection.
  /// [isOfferer] should be true if this peer is initiating the connection.
  Future<void> initialize({bool isOfferer = false}) async {
    _peerConnection = await createPeerConnection(_config, _constraints);

    // Handle ICE candidates – you must forward these via your signaling server.
    _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      // TODO: send candidate via your signaling channel.
      print("New ICE candidate: ${candidate.candidate}");
    };

    if (isOfferer) {
      // Create a data channel for document syncing.
      _dataChannel = await _peerConnection!.createDataChannel("docSync", RTCDataChannelInit());
      _setupDataChannel();

      // Create and set a local offer.
      RTCSessionDescription offer = await _peerConnection!.createOffer();
      await _peerConnection!.setLocalDescription(offer);
      // TODO: send the offer via your signaling channel.
    } else {
      // When receiving a connection, listen for the incoming data channel.
      _peerConnection!.onDataChannel = (RTCDataChannel channel) {
        _dataChannel = channel;
        _setupDataChannel();
      };
    }
  }

  void _setupDataChannel() {
    if (_dataChannel != null) {
      _dataChannel!.onMessage = (RTCDataChannelMessage message) {
        if (onDataReceived != null) {
          onDataReceived!(message.text);
        }
      };
    }
  }

  /// Sends a text message (document content) over the data channel.
  Future<void> send(String message) async {
    if (_dataChannel != null) {
      _dataChannel!.send(RTCDataChannelMessage(message));
    }
  }

  /// Sets the remote description (offer/answer) received via signaling.
  Future<void> setRemoteDescription(RTCSessionDescription description) async {
    await _peerConnection!.setRemoteDescription(description);
  }

  /// Adds a received ICE candidate.
  Future<void> addIceCandidate(RTCIceCandidate candidate) async {
    await _peerConnection!.addCandidate(candidate);
  }

  /// Closes the connection.
  Future<void> close() async {
    await _dataChannel?.close();
    await _peerConnection?.close();
  }
}
