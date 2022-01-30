import 'dart:io';

import 'package:enough_mail/enough_mail.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'config.dart';

class Composer extends StatefulWidget {
  const Composer({Key? key}) : super(key: key);

  @override
  ComposerState createState() => ComposerState();
}

class ComposerState extends State<Composer> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text("Composer"),
        TextField(
          controller: _controller,
          decoration: const InputDecoration(border: OutlineInputBorder()),
          maxLines: 10,
        ),
        TextButton(
            onPressed: () async {
              final builder =
                  MessageBuilder.prepareMultipartAlternativeMessage();
              builder.addText(_controller.text);
              builder.to = [MailAddress("colin", "colin@gotripod.com")];
              builder.subject = "Test 12";

              final file = File("/home/colinramsay/test.txt");
              await builder.addFile(file, MediaType.textPlain);
              final mimeMessage = builder.buildMimeMessage();
              var cmd = Config().getDeepValue<String>('send.cmd');
              var args = Config().getDeepValue<List<dynamic>>('send.args');

              var process = await Process.start(cmd!, args!.cast<String>());
              var rm = mimeMessage.renderMessage();
              process.stdin.write(rm);
              await process.stdin.flush();
              await process.stdin.close();
              await process.stdin.done;

              if (kDebugMode) {
                print(process.stdout);
                print(process.stderr);
              }
            },
            child: const Text("Send"))
      ],
    );
  }
}
