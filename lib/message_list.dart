import 'dart:developer';

import 'package:ava/notmuch/nm.dart';
import 'package:ava/thread_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class MessageList extends StatefulWidget {
  const MessageList({Key? key}) : super(key: key);
  @override
  _MessageListState createState() => _MessageListState();
}

class _MessageListState extends State<MessageList> {
  final nm = NotmuchDatabase();
  late Threads messages;

  _MessageListState() {
    messages = Threads.query(nm.db, "tag:inbox");
  }

  _biggerFont({bool unread = false}) => TextStyle(
      fontSize: 16.0, fontWeight: unread ? FontWeight.bold : FontWeight.normal);

  Widget _buildList() {
    final ml = messages.toList();
    return ListView.separated(
        separatorBuilder: (BuildContext context, int index) =>
            const Divider(height: 1),
        padding: const EdgeInsets.all(16.0),
        itemCount: ml.length,
        itemBuilder: /*1*/ (context, i) {
          final msg = ml[i];
          // final tid = msg?.threadId;
          // final thread = Thread.queryById(nm.db, "thread:$tid");
          final unread = msg!.tags.contains("unread");

          return buildItem(context, msg, unread);
        });
  }

  TextButton buildItem(BuildContext context, Thread? thread, bool unread) {
    return TextButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => ThreadView(db: nm, thread: thread!)),
          ).then((value) {
            setState(() {
              log("popped threadview");
              messages.destroy();
              log("destroyed");
              nm.close();
              nm.reopen();
              log("closed and opened");
              messages = Threads.query(nm.db, "tag:inbox");
              log("refrreshed");
            });
            //messages = Threads.query(nm.db, "tag:inbox");
          });
        },
        child: Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            color: unread ? const Color(0xFFededed) : const Color(0xffFFFFFF),
            child: Row(
              children: [
                SizedBox(
                  width: 400,
                  child: Container(
                    padding: const EdgeInsets.only(right: 20.0),
                    child: Text('${thread?.authors}',
                        style: _biggerFont(unread: unread)),
                  ),
                ),
                Expanded(
                  //padding: const EdgeInsets.all(4.0),
                  child: Text('${thread?.subject}',
                      style: _biggerFont(unread: unread)),
                )
              ],
            )));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ava"), actions: [
        IconButton(
            icon: const Icon(Icons.refresh_sharp),
            onPressed: () {
              setState(() {
                messages.destroy();
                log("destroyed");
                nm.close();
                nm.reopen();
                log("closed");
                messages = Threads.query(nm.db, "tag:inbox");
                log("queried");
              });
            })
      ]),
      body: _buildList(),
    );
  }
}
