import 'dart:async';

import 'package:flutter/material.dart';
import 'src/core/puzzle_animator.dart';
import 'src/puzzle_home_state.dart';


void main() => runApp(PuzzleApp());

class PuzzleApp extends StatelessWidget {
  final int rows, columns;

  PuzzleApp({int columns = 4, int rows = 4})
      : columns = columns ?? 4,
        rows = rows ?? 4;

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Slide Puzzle',
        home: Scaffold(
          body: _PuzzleHome(rows, columns),
        ),
      );
}

class _PuzzleHome extends StatefulWidget {
  final int _rows, _columns;

  const _PuzzleHome(this._rows, this._columns, {Key key}) : super(key: key);

  @override
  PuzzleHomeState createState() =>
      PuzzleHomeState(PuzzleAnimator(_columns, _rows));
}
