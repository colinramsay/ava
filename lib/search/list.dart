import 'package:ava/notmuch/thread.dart';
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

  final Function(Thread thread) onRowPressed;

  const List(
      {Key? key,
      required this.threads,
      required this.onRowPressed,
      required this.view,
      required this.refresh})
      : super(key: key);

  @core.override
  _ListState createState() => _ListState();
}

class _ListState extends State<List> {
  late core.int _selectedIndex = 0;

  core.bool focused = false;
  FocusNode focusNode = FocusNode();

  Widget _buildShortcuts(core.List<Thread> threads) {
    var content = GestureDetector(
      onTap: () {
        focusNode.requestFocus();
      },
      child: Focus(
          focusNode: focusNode,
          debugLabel: "SearchList",
          autofocus: true,
          canRequestFocus: true,
          descendantsAreFocusable: false,
          onFocusChange: (core.bool focused) {
            setState(() {
              this.focused = focused;
            });
          },
          child: ListView.builder(
              shrinkWrap: true, // and set this
              padding: const EdgeInsets.all(16.0),
              itemCount: threads.length,
              itemBuilder: /*1*/ (context, i) => searchrow.Row(
                    selected: _selectedIndex == i,
                    onPressed: () => widget.onRowPressed(threads[i]),
                    thread: threads[i],
                  ))),
    );

    var innerChild =
        threads.isNotEmpty ? content : const Center(child: Text("No mail!"));

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
              if (_selectedIndex < threads.length - 1) {
                _selectedIndex = _selectedIndex + 1;
              }
            }),
          ),
          DecrementIntent: CallbackAction<DecrementIntent>(
            onInvoke: (DecrementIntent intent) => setState(() {
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
