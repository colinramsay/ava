import 'dart:convert';
import 'dart:io';

// Taken from https://github.com/Ephenodrom/Flutter-Global-Config
class Config {
  static final Config _singleton = Config._internal();

  factory Config() {
    return _singleton;
  }

  Config._internal();

  Map<String, dynamic> appConfig = <String, dynamic>{};

  Future<Config> loadFromPath(String path) async {
    String content = await File(path).readAsString();
    Map<String, dynamic> configAsMap = json.decode(content);
    appConfig.addAll(configAsMap);
    return _singleton;
  }

  ///
  /// Reads a value of any type from persistent storage for the given [key].
  ///
  dynamic get(String key) => appConfig[key];

  ///
  /// Reads a value of T type from persistent storage for the given [key].
  ///
  T getValue<T>(String key) => appConfig[key] as T;

  T? getDeepValue<T>(String keyPath) {
    dynamic _value;

    keyPath.split(".").forEach((element) {
      if (_value == null) {
        _value = appConfig[element];
      } else {
        _value = _value[element];
      }
    });

    if (_value != null) {
      return _value as T;
    }

    return null;
  }
}
