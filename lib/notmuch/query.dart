import 'dart:ffi';

import 'package:ava/notmuch/base.dart';
import 'package:ava/notmuch/database.dart';
import 'package:ava/notmuch/message.dart';
import 'package:ava/notmuch/nm.dart';
import 'package:ava/notmuch/thread.dart';
import 'package:ffi/ffi.dart';
import './bindings.dart';
// __all__ = []

class Query extends Base {
  late MemoryPointer<notmuch_query_t> _query_p;
  late Database _db;

  Query(db, query_p) {
    this._db = db;
    this._query_p = MemoryPointer(query_p);
  }

  @override
  bool get alive {
    if (!_db.alive) {
      return false;
    }
    try {
      _query_p.ptr;
    } on ObjectDestroyedError {
      return false;
    }
    return true;
  }

  @override
  void destroy() {
    if (alive == true) {
      LibNotmuch.notmuch_query_destroy(_query_p.ptr);
    }
    _query_p.ptr = null;
  }

  get query {
    final q = LibNotmuch.notmuch_query_get_query_string(_query_p.ptr);
    return BinString.fromCffi(q);
  }

  MessageIterator messages() {
    Pointer<Pointer<notmuch_messages_t>> msgs_pp = calloc();

    //   msgs_pp = capi.ffi.new('notmuch_messages_t**')
    var ret = LibNotmuch.notmuch_query_search_messages(_query_p.ptr, msgs_pp);

    if (ret != notmuch_status_t.NOTMUCH_STATUS_SUCCESS) {
      throw NotmuchError(ret);
    }

    return MessageIterator(this, msgs_pp.value, _db);
  }

  ThreadIterator threads() {
    Pointer<Pointer<notmuch_threads_t>> threads_pp = calloc();

    var ret = LibNotmuch.notmuch_query_search_threads(_query_p.ptr, threads_pp);
    if (ret != notmuch_status_t.NOTMUCH_STATUS_SUCCESS) {
      throw NotmuchError(ret);
    }
    return ThreadIterator(this, threads_pp.value, _db);
  }
}
