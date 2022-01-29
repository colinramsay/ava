import 'dart:io';

import 'package:ava/search/container.dart' as search;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

Future<ServerSocket> socklock() async {
  return await ServerSocket.bind(InternetAddress.loopbackIPv4, 5599);
}

void startServer() {
  Future<ServerSocket> serverFuture = ServerSocket.bind('0.0.0.0', 55555);
  serverFuture.then((ServerSocket server) {
    server.listen((Socket socket) {
      socket.listen(
        (List<int> data) {
          String result = String.fromCharCodes(data);
          if (kDebugMode) {
            print(result.substring(0, result.length - 1));
          }
          socket.close();
        },
        onError: (error) {
          if (kDebugMode) {
            print(error);
          }
          socket.close();
        },

        // handle the client closing the connection
        onDone: () {
          if (kDebugMode) {
            print('Client left');
          }
          socket.close();
        },
      );
    });
  });
}

void main() async {
  startServer();
  runApp(const Ava());
}

class Ava extends StatelessWidget {
  const Ava({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ava',
      theme: ThemeData(
          //primarySwatch: Colors.blueGrey,
          ),
      home: const search.Container(),
    );
  }
}
