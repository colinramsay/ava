import 'dart:ffi';
import 'dart:io';

import 'package:ava/notmuch/bindings.dart';
import 'package:enough_mail/mime_message.dart';
import 'package:ffi/ffi.dart';
import 'package:ffi/src/utf8.dart';

import 'nm.dart';

class Message {
  late String threadId;
  late String messageId;
  late Pointer<Int8> nmessageId;
  late Pointer<notmuch_message_t> _nmMessage;

  Message(Pointer<notmuch_message_t> nmMessage) {
    _nmMessage = nmMessage;
    Pointer<Int8> nthreadId =
        LibNotmuch.notmuch_message_get_thread_id(nmMessage);

    nmessageId = LibNotmuch.notmuch_message_get_message_id(nmMessage);

    threadId = nthreadId.cast<Utf8>().toDartString();
    messageId = nmessageId.cast<Utf8>().toDartString();
  }

  MimeMessage get parsedMessage {
    final filename = LibNotmuch.notmuch_message_get_filename(_nmMessage)
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
    NotmuchDatabase.ensureOpen(msg: "message tags");
    final ntags = LibNotmuch.notmuch_message_get_tags(_nmMessage);

    List<String> list = List.generate(0, (index) => "");

    while (LibNotmuch.notmuch_tags_valid(ntags) == TRUE) {
      final tag = LibNotmuch.notmuch_tags_get(ntags);

      list.add(tag.cast<Utf8>().toDartString());
      LibNotmuch.notmuch_tags_move_to_next(ntags);
    }

    return list;
  }
}

class Messages {
  late Pointer<notmuch_query_t> _query;

  Messages(
      Pointer<notmuch_query_t> query, Pointer<notmuch_messages_t> nmMessages) {
    _query = query;
  }

  static List<Message> query(String querystring) {
    List<Message> list = [];

    NotmuchDatabase.ensureOpen(msg: "Messages query");

    final NativeLibrary _nativeNotmuch = libNotMuch();

    final qs = querystring.toNativeUtf8();

    Pointer<Pointer<notmuch_messages_t>> messages = calloc();

    var query =
        _nativeNotmuch.notmuch_query_create(NotmuchDatabase.db, qs.cast());
    _nativeNotmuch.notmuch_query_search_messages(query, messages);
    final messagesValue = messages.value;

    while (LibNotmuch.notmuch_messages_valid(messagesValue) == TRUE) {
      list.add(Message(LibNotmuch.notmuch_messages_get(messagesValue)));
      LibNotmuch.notmuch_messages_move_to_next(messagesValue);
    }

    NotmuchDatabase.close(msg: "Messages query");

    return list;
  }

  void destroy() {
    NotmuchDatabase.ensureOpen(msg: "destroy messages query");

    LibNotmuch.notmuch_query_destroy(_query);

    NotmuchDatabase.close();
  }
}
