import 'package:flutter/material.dart';

// expect_lint: refactor_to_nano
class MyCounter extends StatefulWidget {
  @override
  _MyCounterState createState() => _MyCounterState();
}

class _MyCounterState extends State<MyCounter> {
  int _counter = 0;

  void _increment() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('$_counter'),
        TextButton(onPressed: _increment, child: Text('Increment')),
      ],
    );
  }
}
