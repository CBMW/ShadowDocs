// lib/services/encryption_service.dart
import 'package:encrypt/encrypt.dart';

class EncryptionService {
  late final Key _key;
  // For simplicity, we use a fixed IV. In production, consider a random IV per message.
  late final IV _iv;
  late final Encrypter _encrypter;

  /// [keyString] should be a secret provided by the user (or generated)
  EncryptionService(String keyString) {
    // Ensure a 32-byte key (for AES-256) by padding or trimming.
    final keyStr = _generateKey(keyString);
    _key = Key.fromUtf8(keyStr);
    _iv = IV.fromLength(16); // 16 bytes for AES
    _encrypter = Encrypter(AES(_key, mode: AESMode.cbc));
  }

  // Utility: pads or trims key to exactly 32 characters.
  static String _generateKey(String keyString) {
    if (keyString.length >= 32) {
      return keyString.substring(0, 32);
    } else {
      return keyString.padRight(32, '0');
    }
  }

  /// Encrypts [plainText] and returns a base64 string.
  String encrypt(String plainText) {
    final encrypted = _encrypter.encrypt(plainText, iv: _iv);
    return encrypted.base64;
  }

  /// Decrypts [encryptedText] (base64) and returns the plain text.
  String decrypt(String encryptedText) {
    final encrypted = Encrypted.fromBase64(encryptedText);
    return _encrypter.decrypt(encrypted, iv: _iv);
  }
}
