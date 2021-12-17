import 'package:ava/notmuch/thread.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/widgets.dart';

class Row extends StatelessWidget {
  final bool selected;
  final Thread thread;
  final Function() onPressed;

  const Row(
      {Key? key,
      required this.selected,
      required this.thread,
      required this.onPressed})
      : super(key: key);

  _biggerFont({bool unread = false}) => TextStyle(
      fontSize: 16.0, fontWeight: unread ? FontWeight.bold : FontWeight.normal);

  @override
  Widget build(BuildContext context) {
    final unread = thread.tags.contains("unread");

    return material.TextButton(
        onPressed: onPressed,
        child: Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            decoration: BoxDecoration(
                border: Border.all(),
                color: selected
                    ? const Color(0xFFededed)
                    : const Color(0xffFFFFFF)),
            //color: selected ? const Color(0xFFededed) : const Color(0xffFFFFFF),
            child: material.Row(
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
                  child:
                      Text(thread.subject, style: _biggerFont(unread: unread)),
                )
              ],
            )));
  }
}
