import 'dart:io';
import 'package:enough_mail/enough_mail.dart';
import 'package:ffi/ffi.dart';
import './bindings.dart';
import 'dart:ffi';

NativeLibrary libNotMuch() {
  final dl = DynamicLibrary.open("libnotmuch.so");

  return NativeLibrary(dl);
}

final LibNotmuch = libNotMuch();

final NotmuchDatabase = NmDb();

class NmDb {
  Pointer<notmuch_database_t> get db => _database;

  late Pointer<notmuch_database_t> _database;
  bool _open = false;
  final NativeLibrary _nativeNotmuch = libNotMuch();

  NmDb() {
    ensureOpen();
  }

  void ensureOpen() {
    if (_open) {
      return;
    }
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

  void flushChanges() {
    _nativeNotmuch.notmuch_database_close(db);
    reopen();
  }

  void reopen() {
    _nativeNotmuch.notmuch_database_reopen(
        db, notmuch_database_mode_t.NOTMUCH_DATABASE_MODE_READ_WRITE);
  }

  void destroy() {
    _nativeNotmuch.notmuch_database_destroy(db);
    _open = false;
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
  Pointer<notmuch_query_t>? _query;

  Thread(Pointer<notmuch_thread_t> nthread) {
    _nthread = nthread;
  }

  void destroy() {
    if (_query != null) {
      LibNotmuch.notmuch_query_destroy(_query!);
    }
  }

  archive() {
    removeTag("inbox");
  }

  markAsRead() {
    removeTag("unread");
  }

  removeTag(String stag) {
    NotmuchDatabase.ensureOpen();

    final messages = LibNotmuch.notmuch_thread_get_messages(_nthread);

    while (LibNotmuch.notmuch_messages_valid(messages) == TRUE) {
      final msg = LibNotmuch.notmuch_messages_get(messages);
      final tag = stag.toNativeUtf8().cast<Int8>();

      LibNotmuch.notmuch_message_remove_tag(msg, tag);
      LibNotmuch.notmuch_messages_move_to_next(messages);
    }

    NotmuchDatabase.flushChanges();
  }

  List<String> get tags {
    final tagsStr = List.generate(0, (index) => "");

    NotmuchDatabase.ensureOpen();

    final tags = LibNotmuch.notmuch_thread_get_tags(_nthread);

    while (LibNotmuch.notmuch_tags_valid(tags) == TRUE) {
      final tag = LibNotmuch.notmuch_tags_get(tags);

      tagsStr.add(tag.cast<Utf8>().toDartString());

      LibNotmuch.notmuch_tags_move_to_next(tags);
    }

    return tagsStr;
  }

  String get subject {
    NotmuchDatabase.ensureOpen();

    Pointer<Int8> nsub = LibNotmuch.notmuch_thread_get_subject(_nthread);

    return nsub.cast<Utf8>().toDartString();
  }

  String get authors {
    NotmuchDatabase.ensureOpen();
    Pointer<Int8>? authors = LibNotmuch.notmuch_thread_get_authors(_nthread);
    return authors.cast<Utf8>().toDartString();
  }

  Messages get messages {
    NotmuchDatabase.ensureOpen();

    Pointer<notmuch_messages_t>? nmessages =
        LibNotmuch.notmuch_thread_get_messages(_nthread);
    return Messages.simple(nmessages);
  }
}

class Threads {
  static List<Thread> query(String querystring) {
    List<Thread> list = [];

    NotmuchDatabase.ensureOpen();
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
    return list;
  }
}

class Messages extends Iterable<Message?> {
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

  static Messages query(String querystring) {
    NotmuchDatabase.ensureOpen();

    final NativeLibrary _nativeNotmuch = libNotMuch();

    final qs = querystring.toNativeUtf8();

    Pointer<Pointer<notmuch_messages_t>> messages = calloc();

    var query =
        _nativeNotmuch.notmuch_query_create(NotmuchDatabase.db, qs.cast());
    _nativeNotmuch.notmuch_query_search_messages(query, messages);
    final messagesValue = messages.value;

    return Messages(query, messagesValue);
  }

  void destroy() {
    NotmuchDatabase.ensureOpen();

    LibNotmuch.notmuch_query_destroy(_query);
  }
}

class MessageIterator extends Iterator<Message?> {
  late Pointer<notmuch_messages_t> messages;

  late Message? _current;
  int index = 0;

  MessageIterator(Pointer<notmuch_messages_t> nmMessages) {
    messages = nmMessages;
  }

  @override
  bool moveNext() {
    NotmuchDatabase.ensureOpen();

    final valid = LibNotmuch.notmuch_messages_valid(messages);

    if (valid == FALSE) {
      _current = null;
      return false;
    } else {
      _current = Message(LibNotmuch.notmuch_messages_get(messages));
      LibNotmuch.notmuch_messages_move_to_next(messages);

      return true;
    }
  }

  @override
  Message? get current => _current;
}
