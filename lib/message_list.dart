import 'dart:developer';

import 'package:ava/notmuch/nm.dart';
import 'package:ava/thread_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class IncrementIntent extends Intent {
  const IncrementIntent();
}

class DecrementIntent extends Intent {
  const DecrementIntent();
}

class ArchiveIntent extends Intent {
  const ArchiveIntent();
}

class MessageList extends StatefulWidget {
  const MessageList({Key? key}) : super(key: key);
  @override
  _MessageListState createState() => _MessageListState();
}

class _MessageListState extends State<MessageList> {
  final nm = NotmuchDatabase();
  late Threads _threads;
  late int _selectedIndex;

  _MessageListState() {
    _selectedIndex = 0;
    _threads = Threads.query(nm.db, "tag:inbox");
  }

  _biggerFont({bool unread = false}) => TextStyle(
      fontSize: 16.0, fontWeight: unread ? FontWeight.bold : FontWeight.normal);

  void _refresh() {
    _threads.destroy();
    log("destroyed");
    nm.close();
    nm.reopen();
    log("closed");
    _threads = Threads.query(nm.db, "tag:inbox");
    log("queried");
  }

  Widget _buildList() {
    return ListView.separated(
        separatorBuilder: (BuildContext context, int index) =>
            const Divider(height: 1),
        padding: const EdgeInsets.all(16.0),
        itemCount: _threads.length,
        itemBuilder: /*1*/ _buildItem);
  }

  TextButton _buildItem(BuildContext context, int i) {
    final thread = _threads[i];
    final unread = thread!.tags.contains("unread");

    return TextButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => ThreadView(db: nm, thread: thread)),
          ).then((value) {
            setState(() {
              _refresh();
            });
            //messages = Threads.query(nm.db, "tag:inbox");
          });
        },
        child: Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            color: i == _selectedIndex
                ? const Color(0xFFededed)
                : const Color(0xffFFFFFF),
            child: Row(
              children: [
                SizedBox(
                  width: 400,
                  child: Container(
                    padding: const EdgeInsets.only(right: 20.0),
                    child: Text(thread.authors,
                        style: _biggerFont(unread: unread)),
                  ),
                ),
                Expanded(
                  //padding: const EdgeInsets.all(4.0),
                  child: Text('$_selectedIndex ${thread.subject}',
                      style: _biggerFont(unread: unread)),
                )
              ],
            )));
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
        shortcuts: <ShortcutActivator, Intent>{
          LogicalKeySet(LogicalKeyboardKey.arrowUp): const IncrementIntent(),
          LogicalKeySet(LogicalKeyboardKey.arrowDown): const DecrementIntent(),
          LogicalKeySet(LogicalKeyboardKey.keyA): const ArchiveIntent(),
        },
        child: Actions(
            actions: <Type, Action<Intent>>{
              ArchiveIntent: CallbackAction<ArchiveIntent>(
                onInvoke: (ArchiveIntent intent) => setState(() {
                  final thread = _threads[_selectedIndex];
                  thread!.archive(nm);
                  final scafMsg = ScaffoldMessenger.of(context);
                  scafMsg.showSnackBar(
                      SnackBar(content: Text('Archived ${thread.subject}')));
                }),
              ),
              IncrementIntent: CallbackAction<IncrementIntent>(
                onInvoke: (IncrementIntent intent) => setState(() {
                  _selectedIndex = _selectedIndex + 1;
                }),
              ),
              DecrementIntent: CallbackAction<DecrementIntent>(
                onInvoke: (DecrementIntent intent) => setState(() {
                  _selectedIndex = _selectedIndex - 1;
                }),
              ),
            },
            child: Scaffold(
              appBar: AppBar(title: const Text("Ava"), actions: [
                IconButton(
                    icon: const Icon(Icons.refresh_sharp),
                    onPressed: () {
                      setState(() {
                        _refresh();
                      });
                    })
              ]),
              body: _buildList(),
            )));
  }
}
