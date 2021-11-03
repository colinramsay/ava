import 'dart:ffi';

import 'package:ffi/ffi.dart';

abstract class Base {
  Base();

  bool get alive;

  void destroy();
}

class BinString {
  static fromCffi(Pointer<Int8> str) {
    return str.cast<Utf8>().toDartString();
  }
}

class NotmuchError implements Exception {
  NotmuchError.withError(res, String? error);
  NotmuchError(res);
}

class MemoryPointer<T extends NativeType> {
  late Pointer<T>? _ptr;

  MemoryPointer(this._ptr);

  Pointer<T> get ptr {
    if (_ptr == null) {
      throw ObjectDestroyedError();
    }
    return _ptr!;
  }

  set ptr(val) {
    _ptr = val;
  }
}

class ObjectDestroyedError implements Exception {}

class NullPointerError implements Exception {}
