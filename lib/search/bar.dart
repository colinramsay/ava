import 'package:flutter/material.dart';

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
  FocusNode focusNode = FocusNode();
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
    return GestureDetector(
        onTap: () {
          focusNode.requestFocus();
        },
        child: AppBar(
            backgroundColor: Theme.of(context).colorScheme.primaryVariant,
            title: TextField(
              focusNode: focusNode,
              textAlignVertical: TextAlignVertical.center,
              controller: controller,
              style: const TextStyle(color: Colors.white),
              onSubmitted: (String _) => {widget.onSearch(controller.text)},
              decoration: InputDecoration(
                suffixIcon: IconButton(
                  onPressed: controller.clear,
                  icon: const Icon(Icons.clear),
                  color: Colors.white,
                ),
                isDense: true,
                fillColor: Colors.red,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white, width: 1)),
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
