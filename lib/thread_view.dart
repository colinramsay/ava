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
        child: ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Back to inbox'),
        ),
      ),
    );
  }
}
