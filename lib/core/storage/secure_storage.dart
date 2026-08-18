import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _instance = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: true,
    ),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  Future<void> write(String key, String value) {
    return _instance.write(key: key, value: value);
  }

  Future<String?> read(String key) {
    return _instance.read(key: key);
  }

  Future<void> delete(String key) {
    return _instance.delete(key: key);
  }

  Future<void> deleteAll() {
    return _instance.deleteAll();
  }
}
