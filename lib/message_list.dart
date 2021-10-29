import 'package:ava/notmuch/nm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class MessageList extends StatefulWidget {
  const MessageList({Key? key}) : super(key: key);
  @override
  _MessageListState createState() => _MessageListState();
}

class _MessageListState extends State<MessageList> {
  final _biggerFont = const TextStyle(fontSize: 16.0);

  Widget _buildSuggestions() {
    final nm = Database();
    final messages = nm.query("tag:inbox");
    final ml = messages.toList();
    return ListView.separated(
        separatorBuilder: (BuildContext context, int index) =>
            const Divider(height: 1),
        padding: const EdgeInsets.all(16.0),
        itemCount: ml.length - 1,
        itemBuilder: /*1*/ (context, i) {
          final msg = ml.elementAt(i);
          final tid = msg?.threadId;
          final thread = nm.queryThreads("thread:$tid").first;

          return Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              color: const Color(0xFFededed),
              child: Row(
                children: [
                  SizedBox(
                    width: 400,
                    child: Container(
                      padding: const EdgeInsets.only(right: 20.0),
                      child: Text('${thread?.authors}', style: _biggerFont),
                    ),
                  ),
                  Expanded(
                    //padding: const EdgeInsets.all(4.0),
                    child: Text('${thread?.subject}', style: _biggerFont),
                  )
                ],
              ));
        });
  }
  // #enddocregion _buildSuggestions

  // #docregion RWS-build
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildSuggestions(),
    );
  }
}