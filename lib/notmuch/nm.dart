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

class Database {
  late Pointer<notmuch_database_t> _database;
  bool _open = false;
  final NativeLibrary _nativeNotmuch = libNotMuch();

  Database() {
    final dbPath = '/mnt/data/mail/.notmuch'.toNativeUtf8();
    final configPath =
        '/home/colinramsay/.config/notmuch/default/config'.toNativeUtf8();
    final profile = 'default'.toNativeUtf8();
    Pointer<Pointer<notmuch_database_t>> dbOut = calloc();
    Pointer<Pointer<Int8>> error = calloc();

    _nativeNotmuch.notmuch_database_open_with_config(
        dbPath.cast<Int8>(),
        notmuch_database_mode_t.NOTMUCH_DATABASE_MODE_READ_ONLY,
        configPath.cast(),
        profile.cast(),
        dbOut,
        error);

    _open = true;
    _database = dbOut.value;
  }

  Threads queryThreads(String querystring) {
    final qs = querystring.toNativeUtf8();

    var query = _nativeNotmuch.notmuch_query_create(_database, qs.cast());
    Pointer<Pointer<notmuch_threads_t>> threads = calloc();

    // _nativeNotmuch.notmuch_query_set_sort(
    //     query, notmuch_sort_t.NOTMUCH_SORT_MESSAGE_ID);
    final stat = _nativeNotmuch.notmuch_query_search_threads(query, threads);
// stat == notmuch_status_t.NOTMUCH_STATUS_SUCCESS &&
    // _nativeNotmuch.notmuch_query_destroy(query);

    return Threads(threads.value);
  }

  Messages query(String querystring) {
    final qs = querystring.toNativeUtf8();

    Pointer<Pointer<notmuch_messages_t>> threads = calloc();

    var query = _nativeNotmuch.notmuch_query_create(_database, qs.cast());
    // _nativeNotmuch.notmuch_query_set_sort(
    //     query, notmuch_sort_t.NOTMUCH_SORT_MESSAGE_ID);
    final stat = _nativeNotmuch.notmuch_query_search_messages(query, threads);
// stat == notmuch_status_t.NOTMUCH_STATUS_SUCCESS &&
    final threadsValue = threads.value;
    // _nativeNotmuch.notmuch_query_destroy(query);

    return Messages(threadsValue);
  }
}

class Message {
  late String threadId;
  final NativeLibrary _nativeNotmuch = libNotMuch();
  late Pointer<notmuch_message_t> _nmMessage;

  Message(Pointer<notmuch_message_t> nmMessage) {
    _nmMessage = nmMessage;
    Pointer<Int8> nthreadId =
        _nativeNotmuch.notmuch_message_get_thread_id(nmMessage);
    threadId = nthreadId.cast<Utf8>().toDartString();
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

  Thread(Pointer<notmuch_thread_t> nthread) {
    _nthread = nthread;
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

    return Messages(nmessages);
  }
}

class Threads extends Iterable<Thread?> {
  late ThreadIterator _iterator;

  Threads(Pointer<notmuch_threads_t> nmThreads) {
    _iterator = ThreadIterator(nmThreads);
  }

  @override
  Iterator<Thread?> get iterator => _iterator;
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
  late MessageIterator _iterator;

  Messages(Pointer<notmuch_messages_t> nmMessages) {
    _iterator = MessageIterator(nmMessages);
  }

  @override
  Iterator<Message?> get iterator => _iterator;
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
