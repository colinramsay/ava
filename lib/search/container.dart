import 'dart:io';

import 'package:ava/notmuch/nm.dart';
import 'package:ava/notmuch/database.dart';
import 'package:ava/thread_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../notmuch/thread.dart';
import 'bar.dart' as searchbar;
import 'list.dart' as searchlist;

class Container extends StatefulWidget {
  const Container({Key? key}) : super(key: key);
  @override
  _ContainerState createState() => _ContainerState();
}

List<Thread> getThreads(searchTerm) {
  List<Thread> threads = [];
  DB.flush();
  var itr = DB.threads(searchTerm);

  while (itr.moveNext()) {
    threads.add(itr.current);
  }

  return threads;
}

class _ContainerState extends State<Container> {
  late String _searchTerm = "tag:inbox";
  late bool _listenList = false;
  late Future<List<Thread>> _threads;

  _ContainerState() {
    ProcessSignal.sigusr1.watch().listen((signal) {
      _refresh();
    });
  }

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    if (_searchTerm.isNotEmpty) {
      var threads = compute(getThreads, _searchTerm);
      setState(() {
        _threads = threads;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: searchbar.Bar(
          term: _searchTerm,
          onSearch: (val) {
            setState(() {
              _searchTerm = val;
            });

            _refresh();
          }),
      body: Focus(
          onFocusChange: (f) {
            setState(() {
              _listenList = f;
            });
          },
          child: searchlist.List(
            listen: _listenList,
            view: _view,
            refresh: _refresh,
            threads: _threads,
            onRowPressed: (Thread thread) => {_view(thread)},
          )),
    );
  }

  void _view(Thread thread) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ThreadView(thread: thread)),
    ).then((value) {
      _refresh();
    });
  }
}
