import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'notmuch/message.dart';
import 'notmuch/thread.dart';

class BackIntent extends Intent {
  const BackIntent();
}

class ThreadView extends StatelessWidget {
  final Thread thread;
  const ThreadView({Key? key, required this.thread}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<Message> messages = [];
    final itr = thread.messages;
    while (itr.moveNext()) {
      messages.add(itr.current);
    }

    messages = messages.reversed.toList();

    return Shortcuts(
        shortcuts: <ShortcutActivator, Intent>{
          LogicalKeySet(LogicalKeyboardKey.escape): const BackIntent(),
        },
        child: Actions(
            actions: <Type, Action<Intent>>{
              BackIntent: CallbackAction<BackIntent>(
                onInvoke: (BackIntent intent) => Navigator.pop(context),
              )
            },
            child: WillPopScope(
                onWillPop: () async {
                  thread.destroy();
                  return true;
                },
                child: Scaffold(
                  appBar: AppBar(
                    title: Text("Thread with ${thread.authors}"),
                    actions: [
                      IconButton(
                          icon: const Icon(Icons.archive_sharp),
                          onPressed: () {
                            thread.archive();
                            Navigator.pop(context);
                          }),
                      IconButton(
                          icon: const Icon(Icons.mark_email_read_sharp),
                          onPressed: () {
                            thread.markAsRead();
                            Navigator.pop(context);
                          })
                    ],
                  ),
                  body: Center(
                    child: ListView.separated(
                        separatorBuilder: (BuildContext context, int index) =>
                            const Divider(height: 2),
                        itemCount: messages.length,
                        itemBuilder: (context, i) {
                          final msg = messages[i];

                          return Container(
                              padding: const EdgeInsets.all(20),
                              child: Text(
                                msg.asText,
                                style: const TextStyle(
                                    fontFamily: 'JetBrainsMono Nerd Font',
                                    fontSize: 16),
                              ));
                        }),
                  ),
                ))));
  }
}
