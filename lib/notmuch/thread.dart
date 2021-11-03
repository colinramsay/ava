import 'dart:ffi';
import './bindings.dart';

import 'package:ffi/ffi.dart';

import 'message.dart';
import 'nm.dart';

class Thread {
  late Pointer<notmuch_thread_t> _nthread;
  Pointer<notmuch_query_t>? _query;

  Thread(Pointer<notmuch_thread_t> nthread) {
    _nthread = nthread;
  }

  void destroy() {
    if (_query != null) {
      LibNotmuch.notmuch_query_destroy(_query!);
    }
  }

  String folder() {
    NotmuchDatabase.ensureOpen(msg: "folder");
    final messages = LibNotmuch.notmuch_thread_get_messages(_nthread);
    Pointer<Int8>? ppath;

    while (LibNotmuch.notmuch_messages_valid(messages) == TRUE) {
      final msg = LibNotmuch.notmuch_messages_get(messages);

      ppath = LibNotmuch.notmuch_message_get_filename(msg);

      break;
    }

    final completePath = ppath!.cast<Utf8>().toDartString();

    var fileName = (completePath.split('/').last);
    NotmuchDatabase.close(msg: "thread folder");

    return completePath.replaceAll("/$fileName", '');
  }

  archive() {
    removeTag("inbox");
  }

  markAsRead() {
    removeTag("unread");
  }

  removeTag(String stag) {
    NotmuchDatabase.ensureOpen(msg: "removeTag");

    final messages = LibNotmuch.notmuch_thread_get_messages(_nthread);

    while (LibNotmuch.notmuch_messages_valid(messages) == TRUE) {
      final msg = LibNotmuch.notmuch_messages_get(messages);
      final tag = stag.toNativeUtf8().cast<Int8>();

      LibNotmuch.notmuch_message_freeze(msg);

      LibNotmuch.notmuch_message_remove_tag(msg, tag);
//      LibNotmuch.notmuch_message_tags_to_maildir_flags(msg);
      LibNotmuch.notmuch_message_thaw(msg);

      LibNotmuch.notmuch_messages_move_to_next(messages);
    }

    NotmuchDatabase.close(msg: "removeTag");
  }

  List<String> get tags {
    final tagsStr = List.generate(0, (index) => "");

    NotmuchDatabase.ensureOpen(msg: "thread: get tags");

    final tags = LibNotmuch.notmuch_thread_get_tags(_nthread);

    while (LibNotmuch.notmuch_tags_valid(tags) == TRUE) {
      final tag = LibNotmuch.notmuch_tags_get(tags);

      tagsStr.add(tag.cast<Utf8>().toDartString());

      LibNotmuch.notmuch_tags_move_to_next(tags);
    }
    NotmuchDatabase.close(msg: "thread get tags");

    return tagsStr;
  }

  String get subject {
    NotmuchDatabase.ensureOpen(msg: "thread: get subject");

    Pointer<Int8> nsub = LibNotmuch.notmuch_thread_get_subject(_nthread);
    NotmuchDatabase.close(msg: "thread: get subject");

    return nsub.cast<Utf8>().toDartString();
  }

  String get authors {
    NotmuchDatabase.ensureOpen(msg: "thread: get authors");
    Pointer<Int8>? authors = LibNotmuch.notmuch_thread_get_authors(_nthread);
    NotmuchDatabase.close(msg: "thread: get authors");

    return authors.cast<Utf8>().toDartString();
  }

  List<Message> get messages {
    final List<Message> list = [];
    NotmuchDatabase.ensureOpen(msg: "thjread: get msgs");

    Pointer<notmuch_messages_t>? nmessages =
        LibNotmuch.notmuch_thread_get_messages(_nthread);

    while (LibNotmuch.notmuch_messages_valid(nmessages) == TRUE) {
      list.add(Message(LibNotmuch.notmuch_messages_get(nmessages)));
      LibNotmuch.notmuch_messages_move_to_next(nmessages);
    }

    NotmuchDatabase.close(msg: "thread: get msgs");

    return list;
  }
}

class Threads {
  static List<Thread> query(String querystring) {
    List<Thread> list = [];

    NotmuchDatabase.ensureOpen(msg: "threads query");
    Pointer<Pointer<notmuch_threads_t>> threads = calloc();
    final qs = querystring.toNativeUtf8();

    final query =
        LibNotmuch.notmuch_query_create(NotmuchDatabase.db, qs.cast());

    LibNotmuch.notmuch_query_search_threads(query, threads);

    final threadsVal = threads.value;

    while (LibNotmuch.notmuch_threads_valid(threadsVal) == TRUE) {
      list.add(Thread(LibNotmuch.notmuch_threads_get(threadsVal)));
      LibNotmuch.notmuch_threads_move_to_next(threadsVal);
    }
    NotmuchDatabase.close();

    return list;
  }
}
