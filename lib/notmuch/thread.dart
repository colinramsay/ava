import 'dart:ffi';
import 'package:ava/notmuch/base.dart';
import 'package:ava/notmuch/database.dart';
import 'package:ava/notmuch/tags.dart';
import 'package:flutter/foundation.dart';

import './bindings.dart';

import 'message.dart';
import 'nm.dart';

class Thread extends Base {
  late MemoryPointer<notmuch_thread_t> threadPointer;

  // ignore: prefer_typing_uninitialized_variables
  var _parent;

  late Database _db;

  Thread(parent, Pointer<notmuch_thread_t> threadp, db) {
    _parent = parent;
    threadPointer = MemoryPointer(threadp);
    _db = db;
  }

  @override
  bool get alive {
    if (!_parent.alive) {
      return false;
    }

    try {
      threadPointer.ptr;
    } on ObjectDestroyedError {
      return false;
    }
    return true;
  }

  @override
  void destroy() {
    if (alive) {
      LibNotmuch.notmuch_thread_destroy(threadPointer.ptr);
      threadPointer.ptr = null;
    }
  }

  MessageIterator get messages {
    var msgsP = LibNotmuch.notmuch_thread_get_messages(threadPointer.ptr);
    return MessageIterator(this, msgsP, _db);
  }

  String get threadId {
    var ret = LibNotmuch.notmuch_thread_get_thread_id(threadPointer.ptr);
    return BinString.fromCffi(ret);
  }

  String get authors {
    var ret = LibNotmuch.notmuch_thread_get_authors(threadPointer.ptr);
    return BinString.fromCffi(ret);
  }

  DateTime get newestDate {
    var ret = LibNotmuch.notmuch_thread_get_newest_date(threadPointer.ptr);

    // https://en.cppreference.com/w/c/chrono/time_t
    // time_t should be seconds so convert to milliseconds
    return DateTime.fromMillisecondsSinceEpoch(ret * 1000);
  }

  String get subject {
    var ret = LibNotmuch.notmuch_thread_get_subject(threadPointer.ptr);
    return BinString.fromCffi(ret);
  }

  TagSet get tags {
    return TagSet(
        this, () => threadPointer.ptr, LibNotmuch.notmuch_thread_get_tags);
  }

  void markAsRead() {
    removeTag("unread");
  }

  void removeTag(String tag) {
    Database writable =
        Database(notmuch_database_mode_t.NOTMUCH_DATABASE_MODE_READ_WRITE);

    MessageIterator itr = writable.messages("thread:$threadId");

    while (itr.moveNext()) {
      if (kDebugMode) {
        print("removing tag");
      }
      Message msg = itr.current;

      if (msg.tags.contains(tag)) {
        if (kDebugMode) {
          print("Starting...");
        }
        msg.tags.remove(tag);
        if (kDebugMode) {
          print("Done!");
        }
      } else {
        if (kDebugMode) {
          print("Skipped tag");
        }
      }
    }

    if (kDebugMode) {
      print("Destroying writable database");
    }
    writable.destroy();
    if (kDebugMode) {
      print("Flushing main database");
    }

    DB.flush();
  }

  void archive() {
    removeTag("inbox");
  }
}

class ThreadIterator implements Iterator<Thread> {
  // ignore: prefer_typing_uninitialized_variables
  var _parent;
  late Thread _current;

  late Database _db;

  late MemoryPointer<notmuch_threads_t> threadsPointer;

  ThreadIterator(parent, Pointer<notmuch_threads_t> threadsP, db) {
    _parent = parent;
    threadsPointer = MemoryPointer(threadsP);
    _db = db;
  }

  @override
  Thread get current => _current;

  bool get alive {
    if (!_parent.alive) {
      return false;
    }

    try {
      threadsPointer.ptr;
    } on ObjectDestroyedError {
      return false;
    }

    return true;
  }

  void destroy() {
    if (alive) {
      try {
        LibNotmuch.notmuch_threads_destroy(threadsPointer.ptr);
      } on ObjectDestroyedError {
        // do nothing
      }

      threadsPointer.ptr = null;
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
    var status = LibNotmuch.notmuch_threads_valid(threadsPointer.ptr);
    if (status != TRUE) {
      if (kDebugMode) {
        print("not valid $status");
      }

      destroy();
      return false;
    }

    var objP = LibNotmuch.notmuch_threads_get(threadsPointer.ptr);
    LibNotmuch.notmuch_threads_move_to_next(threadsPointer.ptr);

    _current = Thread(this, objP, _db);
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
