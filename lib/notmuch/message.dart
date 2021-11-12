import 'dart:ffi';
import 'dart:io';

import 'package:ava/notmuch/base.dart';
import 'package:ava/notmuch/bindings.dart';
import 'package:ava/notmuch/tags.dart';
import 'package:enough_mail/mime_message.dart';
import 'package:html/parser.dart';

import 'nm.dart';

class Message extends Base {
  late MemoryPointer<notmuch_message_t> _msg_p;

  var _parent;

  var _db;

  Message(parent, Pointer<notmuch_message_t> msg_p, db) {
    _parent = parent;
    _msg_p = MemoryPointer(msg_p);
    _db = db;
  }

  String get messageId {
    final ret = LibNotmuch.notmuch_message_get_message_id(_msg_p.ptr);
    return BinString.fromCffi(ret);
  }

  String get threadId {
    final ret = LibNotmuch.notmuch_message_get_thread_id(_msg_p.ptr);

    return BinString.fromCffi(ret);
  }

  String get filename {
    final ret = LibNotmuch.notmuch_message_get_filename(_msg_p.ptr);

    return BinString.fromCffi(ret);
  }

  TagSet get tags {
    return TagSet(this, () => _msg_p.ptr, LibNotmuch.notmuch_message_get_tags);
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
      _msg_p.ptr;
    } on ObjectDestroyedError {
      return false;
    }
    return true;
  }

  @override
  void destroy() {
    if (alive) {
      LibNotmuch.notmuch_message_destroy(_msg_p.ptr);
      _msg_p.ptr = null;
    }
  }
}

class MessageIterator implements Iterator<Message> {
  var _parent;
  late Message _current;

  var _db;

  late MemoryPointer<notmuch_messages_t> _messages_p;

  MessageIterator(parent, Pointer<notmuch_messages_t> messages_p, db) {
    _parent = parent;
    _messages_p = MemoryPointer(messages_p);
    _db = db;
  }

  @override
  Message get current => _current;

  bool get alive {
    if (!_parent.alive) {
      return false;
    }

    try {
      _messages_p.ptr;
    } on ObjectDestroyedError {
      return false;
    }

    return true;
  }

  void destroy() {
    if (alive) {
      try {
        LibNotmuch.notmuch_messages_destroy(_messages_p.ptr);
      } on ObjectDestroyedError {
        // do nothing
      }

      _messages_p.ptr = null;
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
    var status = LibNotmuch.notmuch_messages_valid(_messages_p.ptr);

    print("Message iterator status: $status");

    if (status != TRUE) {
      destroy();
      return false;
    }

    Pointer<notmuch_message_t> obj_p =
        LibNotmuch.notmuch_messages_get(_messages_p.ptr);

    print("Is message null? ${obj_p == nullptr}");

    LibNotmuch.notmuch_messages_move_to_next(_messages_p.ptr);
    _current = Message(this, obj_p, _db);

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
