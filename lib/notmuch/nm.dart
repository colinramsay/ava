import 'dart:collection';
import 'dart:developer';
import 'dart:io';
import 'dart:convert';
import 'package:enough_mail/enough_mail.dart';
import 'package:ffi/ffi.dart';
import './bindings.dart';

import 'dart:ffi';

NativeLibrary libNotMuch() {
  final dl = DynamicLibrary.open("libnotmuch.so");

  return NativeLibrary(dl);
}

final LibNotmuch = libNotMuch();

class NotmuchDatabase {
  Pointer<notmuch_database_t> get db => _database;

  late Pointer<notmuch_database_t> _database;
  bool _open = false;
  final NativeLibrary _nativeNotmuch = libNotMuch();

  NotmuchDatabase() {
    final dbPath = '/mnt/data/mail/.notmuch'.toNativeUtf8();
    final configPath =
        '/home/colinramsay/.config/notmuch/default/config'.toNativeUtf8();
    final profile = 'default'.toNativeUtf8();
    Pointer<Pointer<notmuch_database_t>> dbOut = calloc();
    Pointer<Pointer<Int8>> error = calloc();

    _nativeNotmuch.notmuch_database_open_with_config(
        dbPath.cast<Int8>(),
        notmuch_database_mode_t.NOTMUCH_DATABASE_MODE_READ_WRITE,
        configPath.cast(),
        profile.cast(),
        dbOut,
        error);

    _open = true;
    _database = dbOut.value;
  }

  void close() {
    _nativeNotmuch.notmuch_database_close(db);
  }

  void reopen() {
    _nativeNotmuch.notmuch_database_reopen(
        db, notmuch_database_mode_t.NOTMUCH_DATABASE_MODE_READ_WRITE);
  }

  void destroy() {
    _nativeNotmuch.notmuch_database_destroy(db);
  }
}

class Message {
  late String threadId;
  late String messageId;
  late Pointer<Int8> nmessageId;
  final NativeLibrary _nativeNotmuch = libNotMuch();
  late Pointer<notmuch_message_t> _nmMessage;

  Message(Pointer<notmuch_message_t> nmMessage) {
    _nmMessage = nmMessage;
    Pointer<Int8> nthreadId =
        _nativeNotmuch.notmuch_message_get_thread_id(nmMessage);

    nmessageId = _nativeNotmuch.notmuch_message_get_message_id(nmMessage);

    threadId = nthreadId.cast<Utf8>().toDartString();
    messageId = nmessageId.cast<Utf8>().toDartString();
  }

  MimeMessage get parsedMessage {
    final filename = _nativeNotmuch
        .notmuch_message_get_filename(_nmMessage)
        .cast<Utf8>()
        .toDartString();

    final file = File(filename);
    final lines = file.readAsLinesSync();
    return MimeMessage.parseFromText(lines.join('\r\n'));
  }

  String get asHtml {
    return parsedMessage.decodeTextHtmlPart()!;
  }

  String get asText {
    return parsedMessage.decodeTextPlainPart()!;
  }

  List<String> get tags {
    final ntags = _nativeNotmuch.notmuch_message_get_tags(_nmMessage);

    List<String> list = List.generate(0, (index) => "");

    while (_nativeNotmuch.notmuch_tags_valid(ntags) == TRUE) {
      final tag = _nativeNotmuch.notmuch_tags_get(ntags);

      list.add(tag.cast<Utf8>().toDartString());
      _nativeNotmuch.notmuch_tags_move_to_next(ntags);
    }

    return list;
  }
}

class Thread {
  late Pointer<notmuch_thread_t> _nthread;
  final NativeLibrary _nativeNotmuch = libNotMuch();

  Pointer<notmuch_query_t>? _query;

  Thread(Pointer<notmuch_thread_t> nthread) {
    _nthread = nthread;
  }

  Thread.fromQuery(
      Pointer<notmuch_query_t> query, Pointer<notmuch_thread_t> nthread) {
    _nthread = nthread;
    _query = query;
  }

  // static Thread queryById(
  //     Pointer<notmuch_database_t> database, String threadId) {
  //   Threads threads = Threads.query(database, threadId);

  //   return Thread.fromQuery(threads._query, threads.first!._nthread);
  // }

  void destroy() {
    if (_query != null) {
      LibNotmuch.notmuch_query_destroy(_query!);
    }
  }

  archive(NotmuchDatabase db) {
    removeTag(db, "inbox");
  }

  markAsRead(NotmuchDatabase db) {
    removeTag(db, "unread");
  }

  removeTag(NotmuchDatabase db, String stag) {
    final messages = _nativeNotmuch.notmuch_thread_get_messages(_nthread);

    while (_nativeNotmuch.notmuch_messages_valid(messages) == TRUE) {
      final msg = _nativeNotmuch.notmuch_messages_get(messages);

      final tag = stag.toNativeUtf8().cast<Int8>();
      // TODO remove only if exists
      final removeTagResult =
          _nativeNotmuch.notmuch_message_remove_tag(msg, tag);

      log("Remove tag result $removeTagResult");

      if (removeTagResult != notmuch_status_t.NOTMUCH_STATUS_SUCCESS) {
        throw Exception("Tag could not be removed");
      }

      // final notmuch_message_tags_to_maildir_flagsResult =
      //     _nativeNotmuch.notmuch_message_tags_to_maildir_flags(msg);

      // log("notmuch_message_tags_to_maildir_flags result $notmuch_message_tags_to_maildir_flagsResult");

      _nativeNotmuch.notmuch_messages_move_to_next(messages);
    }
  }

  List<String> get tags {
    final tags = _nativeNotmuch.notmuch_thread_get_tags(_nthread);

    final tagsStr = List.generate(0, (index) => "");

    while (_nativeNotmuch.notmuch_tags_valid(tags) == TRUE) {
      final tag = _nativeNotmuch.notmuch_tags_get(tags);

      tagsStr.add(tag.cast<Utf8>().toDartString());

      _nativeNotmuch.notmuch_tags_move_to_next(tags);
    }

    return tagsStr;
  }

  String get subject {
    final nsub = _nativeNotmuch.notmuch_thread_get_subject(_nthread);
    return nsub.cast<Utf8>().toDartString();
  }

  String get authors {
    final authors = _nativeNotmuch.notmuch_thread_get_authors(_nthread);
    return authors.cast<Utf8>().toDartString();
  }

  Messages get messages {
    final nmessages = _nativeNotmuch.notmuch_thread_get_messages(_nthread);

    return Messages.simple(nmessages);
  }
}

class Threads extends ListBase<Thread?> {
  late ThreadIterator _iterator;
  late Pointer<notmuch_query_t> _query;
  final NativeLibrary _nativeNotmuch = libNotMuch();
  final List<Thread?> _list = List.generate(0, (index) => null);

  Threads(
      Pointer<notmuch_query_t> query, Pointer<notmuch_threads_t> nmThreads) {
    _iterator = ThreadIterator(nmThreads);
    _query = query;

    while (_iterator.moveNext()) {
      _list.add(_iterator.current);
    }
  }

  void destroy() {
    _nativeNotmuch.notmuch_query_destroy(_query);
  }

  @override
  Iterator<Thread?> get iterator => _iterator;

  static Threads query(
      Pointer<notmuch_database_t> database, String querystring) {
    final NativeLibrary _nativeNotmuch = libNotMuch();

    final qs = querystring.toNativeUtf8();

    var query = _nativeNotmuch.notmuch_query_create(database, qs.cast());
    Pointer<Pointer<notmuch_threads_t>> threads = calloc();

    // _nativeNotmuch.notmuch_query_set_sort(
    //     query, notmuch_sort_t.NOTMUCH_SORT_MESSAGE_ID);
    final stat = _nativeNotmuch.notmuch_query_search_threads(query, threads);
// stat == notmuch_status_t.NOTMUCH_STATUS_SUCCESS &&
    // _nativeNotmuch.notmuch_query_destroy(query);

    return Threads(query, threads.value);
  }

  @override
  int get length {
    return _list.length;
  }

  @override
  Thread? operator [](int index) {
    return _list[index];
  }

  @override
  void operator []=(int index, Thread? value) {
    _list[index] = value;
  }

  @override
  set length(int newLength) {
    // TODO: implement length
  }
}

class ThreadIterator extends Iterator<Thread?> {
  late Pointer<notmuch_threads_t> Threads;
  final NativeLibrary _nativeNotmuch = libNotMuch();

  late Thread? _current;
  int index = 0;

  ThreadIterator(Pointer<notmuch_threads_t> nmThreads) {
    Threads = nmThreads;
  }

  @override
  bool moveNext() {
    final valid = _nativeNotmuch.notmuch_threads_valid(Threads);

    if (valid == FALSE) {
      _current = null;
      return false;
    } else {
      _current = Thread(_nativeNotmuch.notmuch_threads_get(Threads));
      _nativeNotmuch.notmuch_threads_move_to_next(Threads);

      return true;
    }
  }

  @override
  Thread? get current => _current;
}

class Messages extends Iterable<Message?> {
  final NativeLibrary _nativeNotmuch = libNotMuch();

  late MessageIterator _iterator;
  late Pointer<notmuch_query_t> _query;

  Messages(
      Pointer<notmuch_query_t> query, Pointer<notmuch_messages_t> nmMessages) {
    _iterator = MessageIterator(nmMessages);
    _query = query;
  }

  Messages.simple(Pointer<notmuch_messages_t> nmMessages) {
    _iterator = MessageIterator(nmMessages);
  }

  @override
  Iterator<Message?> get iterator => _iterator;

  static Messages query(
      Pointer<notmuch_database_t> database, String querystring) {
    final NativeLibrary _nativeNotmuch = libNotMuch();

    final qs = querystring.toNativeUtf8();

    Pointer<Pointer<notmuch_messages_t>> messages = calloc();

    var query = _nativeNotmuch.notmuch_query_create(database, qs.cast());
    // _nativeNotmuch.notmuch_query_set_sort(
    //     query, notmuch_sort_t.NOTMUCH_SORT_MESSAGE_ID);
    final stat = _nativeNotmuch.notmuch_query_search_messages(query, messages);
// stat == notmuch_status_t.NOTMUCH_STATUS_SUCCESS &&
    final messagesValue = messages.value;
    // _nativeNotmuch.notmuch_query_destroy(query);

    log("MUST DESTROY");

    return Messages(query, messagesValue);
  }

  void destroy() {
    _nativeNotmuch.notmuch_query_destroy(_query);
  }
}

class MessageIterator extends Iterator<Message?> {
  late Pointer<notmuch_messages_t> messages;
  final NativeLibrary _nativeNotmuch = libNotMuch();

  late Message? _current;
  int index = 0;

  MessageIterator(Pointer<notmuch_messages_t> nmMessages) {
    messages = nmMessages;
  }

  @override
  bool moveNext() {
    final valid = _nativeNotmuch.notmuch_messages_valid(messages);

    if (valid == FALSE) {
      _current = null;
      return false;
    } else {
      _current = Message(_nativeNotmuch.notmuch_messages_get(messages));
      _nativeNotmuch.notmuch_messages_move_to_next(messages);

      return true;
    }
  }

  @override
  Message? get current => _current;
}


// typedef DatabaseOpenFunc = Void Function(String a, String b, Pointer<Int32> c);

// typedef DatabaseOpen = void Function(String a, String b, int c);

// class Notmuch {
//   Notmuch() {
//     DynamicLibrary nativeNotmuch = DynamicLibrary.open("libnotmuch.so");
//     final openPointer = nativeNotmuch
//         .lookup<NativeFunction<DatabaseOpenFunc>>('notmuch_database_open');
//     final apiFunction = openPointer.asFunction<DatabaseOpen>();

//     apiFunction("", "", null);
//   }
// }
// // }

// // typedef notmuch_database_open_native_t = ffi.Void Function(native.CString path,
// //                       notmuch_database_mode_t mode,
// //                         notmuch_database_t **database);1
