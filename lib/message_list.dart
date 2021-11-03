import 'package:ava/notmuch/nm.dart';
import 'package:ava/notmuch/database.dart';
import 'package:ava/thread_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'notmuch/thread.dart';

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
  late List<Thread> _threads;
  late int _selectedIndex;

  _MessageListState() {
    _selectedIndex = 0;
    _threads = getThreads();
  }

  _biggerFont({bool unread = false}) => TextStyle(
      fontSize: 16.0, fontWeight: unread ? FontWeight.bold : FontWeight.normal);

  void _refresh() {
    setState(() {
      _threads = getThreads();
    });
  }

  List<Thread> getThreads() {
    List<Thread> threads = [];
    var itr = DB.threads("tag:inbox");

    while (itr.moveNext()) {
      threads.add(itr.current);
    }

    return threads;
  }

  Widget _buildList() {
    return _threads.isNotEmpty
        ? ListView.separated(
            separatorBuilder: (BuildContext context, int index) =>
                const Divider(height: 1),
            padding: const EdgeInsets.all(16.0),
            itemCount: _threads.length,
            itemBuilder: /*1*/ _buildItem)
        : const Center(child: Text("No mail!"));
  }

  TextButton _buildItem(BuildContext context, int i) {
    final thread = _threads[i];

    print("builditem $thread");

    final unread = thread.tags.contains("unread");

    return TextButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ThreadView(thread: thread)),
          ).then((value) {
            _refresh();
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
                  // final thread = _threads[_selectedIndex];
                  // thread.archive();
                  // final scafMsg = ScaffoldMessenger.of(context);
                  // scafMsg.showSnackBar(
                  //     SnackBar(content: Text('Archived ${thread.subject}')));
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
                      _refresh();
                    })
              ]),
              body: _buildList(),
            )));
  }
}
