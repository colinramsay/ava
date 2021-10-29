import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'notmuch/nm.dart';

class ThreadView extends StatelessWidget {
  final Thread thread;
  const ThreadView({Key? key, required this.thread}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Thread with ${thread.authors}"),
      ),
      body: Center(
        child: ListView.builder(
            itemCount: thread.messages.length,
            itemBuilder: (context, i) {
              final msg = thread.messages.elementAt(i);
//.decodeTextPlainPart()!;

              return Container(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    msg!.asText,
                    style: const TextStyle(fontSize: 16),
                  ));
            }),
      ),
    );
  }
}
