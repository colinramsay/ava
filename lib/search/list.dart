import 'package:ava/notmuch/thread.dart';
import 'package:flutter/cupertino.dart';
import 'dart:core' as core;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'row.dart' as searchrow;

class IncrementIntent extends Intent {
  const IncrementIntent();
}

class DecrementIntent extends Intent {
  const DecrementIntent();
}

class ArchiveIntent extends Intent {
  const ArchiveIntent();
}

class ViewIntent extends Intent {
  const ViewIntent();
}

class List extends StatefulWidget {
  final core.Future<core.List<Thread>> threads;

  final Function(Thread thread) view;
  final Function() refresh;
  final core.bool listen;

  final Function(Thread thread) onRowPressed;

  const List(
      {Key? key,
      required this.threads,
      required this.onRowPressed,
      required this.view,
      required this.refresh,
      required this.listen})
      : super(key: key);

  @core.override
  _ListState createState() => _ListState();
}

class _ListState extends State<List> {
  late core.int _selectedIndex = 0;

  Widget _buildShortcuts(core.List<Thread> threads) {
    var innerChild = threads.isNotEmpty
        ? Container(
            decoration: BoxDecoration(
                border: widget.listen
                    ? Border.all(width: 10, color: const Color(0xffff0000))
                    : null),
            child: ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: threads.length,
                itemBuilder: /*1*/ (context, i) => searchrow.Row(
                      onPressed: () => widget.onRowPressed(threads[i]),
                      selected: i == _selectedIndex,
                      thread: threads[i],
                    )),
          )
        : const Center(child: Text("No mail!"));
    return Shortcuts(
        shortcuts: <ShortcutActivator, Intent>{
          LogicalKeySet(LogicalKeyboardKey.arrowDown): const IncrementIntent(),
          LogicalKeySet(LogicalKeyboardKey.arrowUp): const DecrementIntent(),
          LogicalKeySet(LogicalKeyboardKey.keyA): const ArchiveIntent(),
          LogicalKeySet(LogicalKeyboardKey.enter): const ViewIntent(),
        },
        child: Actions(actions: <core.Type, Action<Intent>>{
          ViewIntent: CallbackAction<ViewIntent>(
            onInvoke: (ViewIntent intent) => setState(() {
              final thread = threads[_selectedIndex];

              widget.view(thread);
            }),
          ),
          ArchiveIntent: CallbackAction<ArchiveIntent>(
            onInvoke: (ArchiveIntent intent) => setState(() {
              final thread = threads[_selectedIndex];
              thread.archive();
              widget.refresh();
              final scafMsg = ScaffoldMessenger.of(context);
              scafMsg.showSnackBar(
                  SnackBar(content: Text('Archived ${thread.subject}')));
            }),
          ),
          IncrementIntent: CallbackAction<IncrementIntent>(
            onInvoke: (IncrementIntent intent) => setState(() {
              core.print("incre");
              if (_selectedIndex < threads.length - 1) {
                _selectedIndex = _selectedIndex + 1;
              }
            }),
          ),
          DecrementIntent: CallbackAction<DecrementIntent>(
            onInvoke: (DecrementIntent intent) => setState(() {
              core.print("decre");

              if (_selectedIndex > 0) {
                _selectedIndex = _selectedIndex - 1;
              }
            }),
          ),
        }, child: innerChild));
  }

  @core.override
  Widget build(context) {
    return FutureBuilder<core.List<Thread>>(
        future: widget.threads,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text(snapshot.error.toString());
          }

          if (snapshot.data != null) {
            return _buildShortcuts(snapshot.data!);
          }

          return const LinearProgressIndicator(
            minHeight: 10,
          );
        });
  }
}
