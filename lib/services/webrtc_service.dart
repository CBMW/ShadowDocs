// lib/services/webrtc_service.dart
import 'dart:convert';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'encryption_service.dart';
import 'signaling_service.dart';

class WebRTCService {
  RTCPeerConnection? _peerConnection;
  RTCDataChannel? _dataChannel;
  SignalingService? _signalingService;
  EncryptionService? _encryptionService;
  bool encryptionEnabled = false;

  /// Callback for incoming (and optionally decrypted) messages.
  Function(String)? onDataReceived;

  final Map<String, dynamic> _config = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      // In production, add TURN servers if needed.
    ]
  };

  final Map<String, dynamic> _constraints = {
    'mandatory': {},
    'optional': [
      {'DtlsSrtpKeyAgreement': true},
    ]
  };

  /// Initializes the connection.
  /// - [isOfferer]: true if this peer is initiating the connection.
  /// - [enableEncryption]: toggles extra encryption.
  /// - [encryptionService]: instance for encryption (if encryption is enabled).
  /// - [signalingServerUrl]: URL for the signaling server.
  Future<void> initialize({
    bool isOfferer = false,
    bool enableEncryption = false,
    EncryptionService? encryptionService,
    String? signalingServerUrl,
  }) async {
    encryptionEnabled = enableEncryption;
    if (encryptionEnabled && encryptionService != null) {
      _encryptionService = encryptionService;
    }

    // Set up signaling (if a URL is provided).
    if (signalingServerUrl != null) {
      _signalingService = SignalingService(serverUrl: signalingServerUrl);
      _signalingService!.onMessageReceived = _handleSignalingMessage;
      _signalingService!.connect();
    }

    _peerConnection = await createPeerConnection(_config, _constraints);

    // When new ICE candidates are generated, send them over signaling.
    _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      print("New ICE candidate: ${candidate.candidate}");
      _signalingService?.send({
        'type': 'candidate',
        'candidate': candidate.toMap(),
      });
    };

    if (isOfferer) {
      // Create the data channel for syncing document changes.
      _dataChannel =
          await _peerConnection!.createDataChannel("docSync", RTCDataChannelInit());
      _setupDataChannel();

      // Create and set the local offer.
      RTCSessionDescription offer = await _peerConnection!.createOffer();
      await _peerConnection!.setLocalDescription(offer);
      _signalingService?.send({
        'type': 'offer',
        'sdp': offer.sdp,
      });
    } else {
      // If not the offerer, listen for an incoming data channel.
      _peerConnection!.onDataChannel = (RTCDataChannel channel) {
        _dataChannel = channel;
        _setupDataChannel();
      };
    }
  }

  void _setupDataChannel() {
    if (_dataChannel != null) {
      _dataChannel!.onMessage = (RTCDataChannelMessage message) {
        String data = message.text;
        if (encryptionEnabled && _encryptionService != null) {
          try {
            data = _encryptionService!.decrypt(data);
          } catch (e) {
            print("Decryption error: $e");
            return;
          }
        }
        if (onDataReceived != null) {
          onDataReceived!(data);
        }
      };
    }
  }

  /// Sends [message] over the data channel (encrypting if enabled).
  Future<void> send(String message) async {
    if (encryptionEnabled && _encryptionService != null) {
      message = _encryptionService!.encrypt(message);
    }
    if (_dataChannel != null) {
      _dataChannel!.send(RTCDataChannelMessage(message));
    }
  }

  /// Handles incoming signaling messages.
  void _handleSignalingMessage(Map<String, dynamic> message) async {
    String type = message['type'];
    switch (type) {
      case 'offer':
        {
          RTCSessionDescription offer =
              RTCSessionDescription(message['sdp'], 'offer');
          await _peerConnection!.setRemoteDescription(offer);
          // Create an answer and send it back.
          RTCSessionDescription answer = await _peerConnection!.createAnswer();
          await _peerConnection!.setLocalDescription(answer);
          _signalingService?.send({
            'type': 'answer',
            'sdp': answer.sdp,
          });
          break;
        }
      case 'answer':
        {
          RTCSessionDescription answer =
              RTCSessionDescription(message['sdp'], 'answer');
          await _peerConnection!.setRemoteDescription(answer);
          break;
        }
      case 'candidate':
        {
          RTCIceCandidate candidate = RTCIceCandidate(
            message['candidate']['candidate'],
            message['candidate']['sdpMid'],
            message['candidate']['sdpMLineIndex'],
          );
          await _peerConnection!.addCandidate(candidate);
          break;
        }
      default:
        print("Unknown signaling message type: $type");
    }
  }

  /// Closes the data channel, peer connection, and disconnects signaling.
  Future<void> close() async {
    await _dataChannel?.close();
    await _peerConnection?.close();
    _signalingService?.disconnect();
  }
}
