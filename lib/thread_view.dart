import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'notmuch/message.dart';
import 'notmuch/nm.dart';
import 'notmuch/thread.dart';

class ThreadView extends StatelessWidget {
  final Thread thread;
  const ThreadView({Key? key, required this.thread}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<Message> messages = [];
    final itr = thread.messages;
    while (itr.moveNext()) {
      messages.add(itr.current);
    }

    return WillPopScope(
        onWillPop: () async {
          thread.destroy();
          return true;
        },
        child: Scaffold(
          appBar:
              AppBar(title: Text("Thread with ${thread.authors}"), actions: [
            IconButton(
                icon: const Icon(Icons.archive_sharp),
                onPressed: () {
                  thread.markAsRead();
                  Navigator.pop(context);
                })
          ]),
          body: Center(
            child: ListView.builder(
                itemCount: messages.length,
                itemBuilder: (context, i) {
                  final msg = messages[i];

                  return Container(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        msg.messageId,
                        style: const TextStyle(fontSize: 16),
                      ));
                }),
          ),
        ));
  }
}
