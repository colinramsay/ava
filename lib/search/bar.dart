import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class Bar extends StatefulWidget implements PreferredSizeWidget {
  final String term;

  const Bar(
      {Key key = const ObjectKey("searchbar"),
      required this.onSearch,
      required this.term})
      : preferredSize = const Size.fromHeight(kToolbarHeight),
        super(key: key);

  @override
  final Size preferredSize;

  final void Function(String) onSearch;

  @override
  _BarState createState() => _BarState();
}

class _BarState extends State<Bar> {
  late TextEditingController controller;
  late bool focused = false;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.term);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
        onFocusChange: (bool focused) {
          setState(() {
            this.focused = focused;
          });
        },
        child: AppBar(
            backgroundColor: Theme.of(context).colorScheme.primaryVariant,
            title: TextField(
              textAlignVertical: TextAlignVertical.center,
              controller: controller,
              style: TextStyle(color: Colors.white),
              onSubmitted: (String _) => {widget.onSearch(controller.text)},
              decoration: InputDecoration(
                suffixIcon: IconButton(
                  onPressed: controller.clear,
                  icon: Icon(Icons.clear),
                ),
                isDense: true,
                fillColor: Colors.red,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 2, vertical: 10),
                border: OutlineInputBorder(),
                hintText: "Search",
              ),
            ),
            actions: [
              IconButton(
                  icon: const Icon(Icons.refresh_sharp),
                  onPressed: () => {widget.onSearch(controller.text)})
            ]));
  }
}
