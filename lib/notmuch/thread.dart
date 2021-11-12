import 'dart:ffi';
import 'package:ava/notmuch/base.dart';
import 'package:ava/notmuch/database.dart';
import 'package:ava/notmuch/tags.dart';

import './bindings.dart';

import 'package:ffi/ffi.dart';

import 'message.dart';
import 'nm.dart';

class Thread extends Base {
  late MemoryPointer<notmuch_thread_t> _thread_p;

  var _parent;

  var _db;

  Thread(parent, Pointer<notmuch_thread_t> thread_p, db) {
    _parent = parent;
    _thread_p = MemoryPointer(thread_p);
    _db = db;
  }

  @override
  bool get alive {
    if (!_parent.alive) {
      return false;
    }

    try {
      _thread_p.ptr;
    } on ObjectDestroyedError {
      return false;
    }
    return true;
  }

  @override
  void destroy() {
    if (alive) {
      LibNotmuch.notmuch_thread_destroy(_thread_p.ptr);
      _thread_p.ptr = null;
    }
  }

  MessageIterator get messages {
    var msgs_p = LibNotmuch.notmuch_thread_get_messages(_thread_p.ptr);
    return MessageIterator(this, msgs_p, _db);
  }

  String get threadId {
    var ret = LibNotmuch.notmuch_thread_get_thread_id(_thread_p.ptr);
    return BinString.fromCffi(ret);
  }

  String get authors {
    var ret = LibNotmuch.notmuch_thread_get_authors(_thread_p.ptr);
    return BinString.fromCffi(ret);
  }

  String get subject {
    var ret = LibNotmuch.notmuch_thread_get_subject(_thread_p.ptr);
    return BinString.fromCffi(ret);
  }

  TagSet get tags {
    return TagSet(
        this, () => _thread_p.ptr, LibNotmuch.notmuch_thread_get_tags);
  }

  void markAsRead() {
    removeTag("unread");
  }

  void removeTag(String tag) {
    Database writable =
        Database(notmuch_database_mode_t.NOTMUCH_DATABASE_MODE_READ_WRITE);

    MessageIterator itr = writable.messages("thread:$threadId");

    while (itr.moveNext()) {
      print("removing tag");
      Message msg = itr.current;

      if (msg.tags.contains(tag)) {
        print("Starting...");
        msg.tags.remove(tag);
        print("Done!");
      } else {
        print("Skipped tag");
      }
    }

    print("Destroying writable database");
    writable.destroy();
    print("Flushing main database");

    DB.flush();
  }

  void archive() {
    removeTag("inbox");
  }
}

class ThreadIterator implements Iterator<Thread> {
  var _parent;
  late Thread _current;

  var _db;

  late MemoryPointer<notmuch_threads_t> _threads_p;

  ThreadIterator(parent, Pointer<notmuch_threads_t> threads_p, db) {
    _parent = parent;
    _threads_p = MemoryPointer(threads_p);
    _db = db;
  }

  @override
  Thread get current => _current;

  bool get alive {
    if (!_parent.alive) {
      return false;
    }

    try {
      _threads_p.ptr;
    } on ObjectDestroyedError {
      return false;
    }

    return true;
  }

  void destroy() {
    if (alive) {
      try {
        LibNotmuch.notmuch_threads_destroy(_threads_p.ptr);
      } on ObjectDestroyedError {
        // do nothing
      }

      _threads_p.ptr = null;
    }
  }

  // Iterator iterator(){
  //     """Return the iterator itself.

  //     Note that as this is an iterator and not a container this will
  //     not return a new iterator.  Thus any elements already consumed
  //     will not be yielded by the :meth:`__next__` method anymore.
  //     """
  //     return self

  @override
  bool moveNext() {
    var status = LibNotmuch.notmuch_threads_valid(_threads_p.ptr);
    if (status != TRUE) {
      print("not valid $status");

      destroy();
      return false;
    }

    var obj_p = LibNotmuch.notmuch_threads_get(_threads_p.ptr);
    LibNotmuch.notmuch_threads_move_to_next(_threads_p.ptr);

    _current = Thread(this, obj_p, _db);
    return true;
  }

  // def __repr__(self):
  //     try:
  //         self._iter_p
  //     except errors.ObjectDestroyedError:
  //         return '<NotmuchIter (exhausted)>'
  //     else:
  //         return '<NotmuchIter>'

}
