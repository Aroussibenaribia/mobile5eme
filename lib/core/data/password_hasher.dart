import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'package:crypto/crypto.dart';

/// PBKDF2-HMAC-SHA256, one 32-byte block, with an independent random salt.
class PasswordHasher {
  static const iterations = 210000;
  static Future<String> hash(String password) => Isolate.run(() {
        final random = Random.secure();
        final salt = List<int>.generate(16, (_) => random.nextInt(256));
        final key = derive(password, salt, iterations);
        return [
          'pbkdf2_sha256',
          iterations.toString(),
          base64Encode(salt),
          base64Encode(key)
        ].join(':');
      });

  static Future<bool> verify(String password, String encoded) =>
      Isolate.run(() {
        try {
          final parts = encoded.split(':');
          if (parts.length != 4 || parts[0] != 'pbkdf2_sha256') return false;
          final rounds = int.parse(parts[1]);
          if (rounds < 1 || rounds > 1000000) return false;
          final expected = base64Decode(parts[3]);
          final actual = derive(password, base64Decode(parts[2]), rounds);
          var difference = expected.length ^ actual.length;
          for (var i = 0; i < actual.length; i++) {
            difference |= actual[i] ^ (i < expected.length ? expected[i] : 0);
          }
          return difference == 0;
        } catch (_) {
          return false;
        }
      });

  static List<int> derive(String password, List<int> salt, int rounds) {
    final hmac = Hmac(sha256, utf8.encode(password));
    var block = hmac.convert([...salt, 0, 0, 0, 1]).bytes;
    final result = List<int>.from(block);
    for (var round = 1; round < rounds; round++) {
      block = hmac.convert(block).bytes;
      for (var i = 0; i < result.length; i++) {
        result[i] ^= block[i];
      }
    }
    return result;
  }
}
