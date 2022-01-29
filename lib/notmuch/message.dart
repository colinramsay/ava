import 'dart:ffi';
import 'dart:io';

import 'package:ava/notmuch/base.dart';
import 'package:ava/notmuch/bindings.dart';
import 'package:ava/notmuch/database.dart';
import 'package:ava/notmuch/tags.dart';
import 'package:enough_mail/mime_message.dart';
import 'package:html/parser.dart';

import 'nm.dart';

class Message extends Base {
  late MemoryPointer<notmuch_message_t> messagePointer;

  // ignore: prefer_typing_uninitialized_variables
  var _parent;

  late Database database;

  Message(parent, Pointer<notmuch_message_t> msgp, db) {
    _parent = parent;
    messagePointer = MemoryPointer(msgp);
    database = db;
  }

  String get messageId {
    final ret = LibNotmuch.notmuch_message_get_message_id(messagePointer.ptr);
    return BinString.fromCffi(ret);
  }

  String get threadId {
    final ret = LibNotmuch.notmuch_message_get_thread_id(messagePointer.ptr);

    return BinString.fromCffi(ret);
  }

  String get filename {
    final ret = LibNotmuch.notmuch_message_get_filename(messagePointer.ptr);

    return BinString.fromCffi(ret);
  }

  TagSet get tags {
    return TagSet(
        this, () => messagePointer.ptr, LibNotmuch.notmuch_message_get_tags);
  }

  MimeMessage get parsedMessage {
    final file = File(filename);
    final lines = file.readAsLinesSync();
    return MimeMessage.parseFromText(lines.join('\r\n'));
  }

  String get asHtml {
    return parsedMessage.decodeTextHtmlPart()!;
  }

  String get asText {
    final plainTextPart = parsedMessage.decodeTextPlainPart();

    if (plainTextPart != null) {
      return plainTextPart;
    }

    final bodyNode = parse(asHtml).body;

    if (bodyNode == null) {
      return "Can't get a text version of the message.";
    }

    final body = parse(bodyNode.text);

    final docEl = body.documentElement;

    if (docEl == null) {
      return "Can't get a text version of the message";
    }
    return docEl.text;
  }

  @override
  bool get alive {
    if (!_parent.alive) {
      return false;
    }

    try {
      messagePointer.ptr;
    } on ObjectDestroyedError {
      return false;
    }
    return true;
  }

  @override
  void destroy() {
    if (alive) {
      LibNotmuch.notmuch_message_destroy(messagePointer.ptr);
      messagePointer.ptr = null;
    }
  }
}

class MessageIterator implements Iterator<Message> {
  // ignore: prefer_typing_uninitialized_variables
  var parent;
  late Message _current;

  late Database database;

  late MemoryPointer<notmuch_messages_t> messagesPointer;

  MessageIterator(owner, Pointer<notmuch_messages_t> messagesp, db) {
    parent = owner;
    messagesPointer = MemoryPointer(messagesp);
    database = db;
  }

  @override
  Message get current => _current;

  bool get alive {
    if (!parent.alive) {
      return false;
    }

    try {
      messagesPointer.ptr;
    } on ObjectDestroyedError {
      return false;
    }

    return true;
  }

  void destroy() {
    if (alive) {
      try {
        LibNotmuch.notmuch_messages_destroy(messagesPointer.ptr);
      } on ObjectDestroyedError {
        // do nothing
      }

      messagesPointer.ptr = null;
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
    var status = LibNotmuch.notmuch_messages_valid(messagesPointer.ptr);

    if (status != TRUE) {
      destroy();
      return false;
    }

    Pointer<notmuch_message_t> objP =
        LibNotmuch.notmuch_messages_get(messagesPointer.ptr);

    LibNotmuch.notmuch_messages_move_to_next(messagesPointer.ptr);
    _current = Message(this, objP, database);

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
