import 'dart:ffi';

import 'package:ava/notmuch/base.dart';
import 'package:ava/notmuch/database.dart';
import 'package:ava/notmuch/message.dart';
import 'package:ava/notmuch/nm.dart';
import 'package:ava/notmuch/thread.dart';
import 'package:ffi/ffi.dart';
import './bindings.dart';

class Query extends Base {
  late MemoryPointer<notmuch_query_t> queryPointer;
  late Database database;

  Query(db, queryp) {
    database = db;
    queryPointer = MemoryPointer(queryp);
  }

  @override
  bool get alive {
    if (!database.alive) {
      return false;
    }
    try {
      queryPointer.ptr;
    } on ObjectDestroyedError {
      return false;
    }
    return true;
  }

  @override
  void destroy() {
    if (alive == true) {
      LibNotmuch.notmuch_query_destroy(queryPointer.ptr);
    }
    queryPointer.ptr = null;
  }

  get query {
    final q = LibNotmuch.notmuch_query_get_query_string(queryPointer.ptr);
    return BinString.fromCffi(q);
  }

  MessageIterator messages() {
    Pointer<Pointer<notmuch_messages_t>> msgsPp = calloc();

    //   msgs_pp = capi.ffi.new('notmuch_messages_t**')
    var ret =
        LibNotmuch.notmuch_query_search_messages(queryPointer.ptr, msgsPp);

    if (ret != notmuch_status_t.NOTMUCH_STATUS_SUCCESS) {
      throw NotmuchError(ret);
    }

    return MessageIterator(this, msgsPp.value, database);
  }

  ThreadIterator threads() {
    Pointer<Pointer<notmuch_threads_t>> threadsPp = calloc();

    var ret =
        LibNotmuch.notmuch_query_search_threads(queryPointer.ptr, threadsPp);
    if (ret != notmuch_status_t.NOTMUCH_STATUS_SUCCESS) {
      throw NotmuchError(ret);
    }
    return ThreadIterator(this, threadsPp.value, database);
  }
}
