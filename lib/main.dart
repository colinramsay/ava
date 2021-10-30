import 'package:flutter/material.dart';
import 'message_list.dart';

void main() {
  runApp(const Ava());
}

class Ava extends StatelessWidget {
  const Ava({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ava',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
      ),
      home: const MessageList(),
    );
  }
}
