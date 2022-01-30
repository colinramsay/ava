import 'dart:io';

import 'package:ava/notmuch/thread.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Row extends StatelessWidget {
  final bool selected;
  final Thread thread;
  final Function() onPressed;
  final DateFormat formatter = DateFormat('MMM dd');

  Row(
      {Key? key,
      required this.selected,
      required this.thread,
      required this.onPressed})
      : super(key: key);

  _biggerFont({bool unread = false, bool selected = false}) => TextStyle(
      color: selected ? Colors.black : Colors.black,
      fontSize: 16.0,
      fontWeight: unread ? FontWeight.bold : FontWeight.normal);

  @override
  Widget build(BuildContext context) {
    final unread = thread.tags.contains("unread");

    return material.TextButton(
        onPressed: onPressed,
        child: Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            decoration: BoxDecoration(
                color: selected
                    ? Theme.of(context).focusColor
                    : Colors.grey.shade100,
                border: Border.symmetric(
                    horizontal: BorderSide(
                        width: 1, color: Theme.of(context).dividerColor))),
            child: material.Row(
              children: [
                SizedBox(
                  width: 400,
                  child: Container(
                    padding: const EdgeInsets.only(right: 20.0),
                    child: Text(thread.authors,
                        style: _biggerFont(selected: selected, unread: unread)),
                  ),
                ),
                Expanded(
                  //padding: const EdgeInsets.all(4.0),
                  child: Text(thread.subject,
                      style: _biggerFont(selected: selected, unread: unread)),
                ),
                SizedBox(
                  width: 100,
                  child: Container(
                    padding: const EdgeInsets.only(right: 20.0),
                    child: TextButton(
                        onPressed: () {
                          thread.openNewestAttachment();
                        },
                        child: Text(
                            formatter.format(thread.newestDate) +
                                " ${thread.newestAttachmentFilename}",
                            textAlign: material.TextAlign.right,
                            style: _biggerFont(
                                selected: selected, unread: unread))),
                  ),
                )
              ],
            )));
  }
}
