import 'dart:ffi';

import 'package:ava/notmuch/base.dart';
import 'package:ava/notmuch/message.dart';
import 'package:ava/notmuch/query.dart';
import 'package:ava/notmuch/thread.dart';
import 'package:ffi/ffi.dart';
import 'package:ffi/src/utf8.dart';
import './bindings.dart';
import 'nm.dart';
import 'dart:ffi' as ffi;

class Database extends Base {
  late MemoryPointer<notmuch_database_t> _database_p;
  var _closed = true;

  Database([mode = notmuch_database_mode_t.NOTMUCH_DATABASE_MODE_READ_ONLY]) {
    open(mode);
  }

  void open([mode = notmuch_database_mode_t.NOTMUCH_DATABASE_MODE_READ_ONLY]) {
    final dbPath = '/mnt/data/mail/.notmuch'.toNativeUtf8();
    final configPath =
        '/home/colinramsay/.config/notmuch/default/config'.toNativeUtf8();
    final profile = 'default'.toNativeUtf8();

    Pointer<Pointer<notmuch_database_t>> dbpp = calloc();
    Pointer<Pointer<Int8>> cmsg = calloc();

    final res = LibNotmuch.notmuch_database_open_with_config(
        dbPath.cast<Int8>(),
        mode,
        configPath.cast(),
        profile.cast(),
        dbpp,
        cmsg);

    String? error;

    if (cmsg.value != ffi.nullptr) {
      error = cmsg.value.cast<Utf8>().toDartString();
    }

    calloc.free(cmsg);

    if (res != notmuch_status_t.NOTMUCH_STATUS_SUCCESS) {
      throw NotmuchError.withError(res, error);
    }

    _database_p = MemoryPointer(dbpp.value);

    _closed = false;
  }

  void close() {
    var ret = LibNotmuch.notmuch_database_close(_database_p.ptr);
    if (ret != notmuch_status_t.NOTMUCH_STATUS_SUCCESS) {
      throw NotmuchError(ret);
    }
    _closed = true;
  }

  void flush() {
    close();
    open();
  }

  Query _create_query(String query) {
    var query_p = LibNotmuch.notmuch_query_create(
        _database_p.ptr, query.toNativeUtf8().cast());

    if (query_p == ffi.nullptr) {
      throw OutOfMemoryError();
    }

    return Query(this, query_p);
  }

  MessageIterator messages(String querystring) {
    var query = _create_query(querystring);
    return query.messages();
  }

  ThreadIterator threads(String querystring) {
    var query = _create_query(querystring);
    return query.threads();
  }

  @override
  bool get alive {
    try {
      _database_p;
      return true;
    } on ObjectDestroyedError {
      return false;
    }
  }

  @override
  void destroy() {
    var ret;
    try {
      ret = LibNotmuch.notmuch_database_destroy(_database_p.ptr);
      _database_p.ptr = null;
    } on ObjectDestroyedError {
      ret = notmuch_status_t.NOTMUCH_STATUS_SUCCESS;
    }
    if (ret != notmuch_status_t.NOTMUCH_STATUS_SUCCESS) {
      throw NotmuchError(ret);
    }
  }

  void openForWrite() {
    close();
    open(notmuch_database_mode_t.NOTMUCH_DATABASE_MODE_READ_WRITE);
  }
}

Database DB = Database();
