import 'dart:ffi';

import 'package:ava/notmuch/base.dart';
import 'package:ava/notmuch/message.dart';
import 'package:ava/notmuch/query.dart';
import 'package:ava/notmuch/thread.dart';
import 'package:ffi/ffi.dart';
import '../config.dart';
import './bindings.dart';
import 'nm.dart';
import 'dart:ffi' as ffi;

class Database extends Base {
  late MemoryPointer<notmuch_database_t> databasePtr;
  var _closed = true;

  Database([mode = notmuch_database_mode_t.NOTMUCH_DATABASE_MODE_READ_ONLY]) {
    open(mode);
  }

  void open([mode = notmuch_database_mode_t.NOTMUCH_DATABASE_MODE_READ_ONLY]) {
    final dbPath =
        Config().getDeepValue<String>('notmuch.databasePath')!.toNativeUtf8();
    final configPath =
        Config().getDeepValue<String>('notmuch.configPath')!.toNativeUtf8();
    final profile =
        Config().getDeepValue<String>('notmuch.profile')!.toNativeUtf8();

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

    databasePtr = MemoryPointer(dbpp.value);

    _closed = false;
  }

  void close() {
    var ret = LibNotmuch.notmuch_database_close(databasePtr.ptr);
    if (ret != notmuch_status_t.NOTMUCH_STATUS_SUCCESS) {
      throw NotmuchError(ret);
    }
    _closed = true;
  }

  void flush() {
    close();
    open();
  }

  Query createQuery(String query) {
    var queryPtr = LibNotmuch.notmuch_query_create(
        databasePtr.ptr, query.toNativeUtf8().cast());

    if (queryPtr == ffi.nullptr) {
      throw const OutOfMemoryError();
    }

    return Query(this, queryPtr);
  }

  MessageIterator messages(String querystring) {
    var query = createQuery(querystring);
    return query.messages();
  }

  ThreadIterator threads(String querystring) {
    var query = createQuery(querystring);
    return query.threads();
  }

  bool get closed {
    return _closed;
  }

  @override
  bool get alive {
    try {
      databasePtr;
      return true;
    } on ObjectDestroyedError {
      return false;
    }
  }

  @override
  void destroy() {
    // ignore: prefer_typing_uninitialized_variables
    var ret;
    try {
      ret = LibNotmuch.notmuch_database_destroy(databasePtr.ptr);
      databasePtr.ptr = null;
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
