import 'dart:ffi';

import 'package:ava/notmuch/nm.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';

import 'message_list.dart';
import 'notmuch/bindings.dart';
import 'notmuch/nm.dart';

void main() {
  // var db = Database();
  // var msgs = Messages.query(db.db, "thread:0000000000036024");
  // final NativeLibrary _nativeNotmuch = libNotMuch();
  // final tag = "unread".toNativeUtf8().cast<Int8>();

  // Pointer<Pointer<notmuch_message_t>> message = calloc();

  // _nativeNotmuch.notmuch_database_find_message(
  //     db.db, msgs.first!.nmessageId, message);
  // _nativeNotmuch.notmuch_message_remove_tag(message.value, tag);
  // //db.close();
  runApp(const Ava());
}

class Ava extends StatelessWidget {
  const Ava({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ava',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
      ),
      home: const MessageList(),
    );
  }
}
