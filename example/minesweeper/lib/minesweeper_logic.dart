import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:nano/nano.dart';

enum GameState { playing, won, lost }

class Cell {
  final int r, c;
  final bool hasMine;
  final bool isOpen;
  final bool isFlagged;
  final int adjacentMines;

  const Cell({
    required this.r,
    required this.c,
    this.hasMine = false,
    this.isOpen = false,
    this.isFlagged = false,
    this.adjacentMines = 0,
  });

  Cell copyWith({
    bool? isOpen,
    bool? isFlagged,
    int? adjacentMines,
  }) {
    return Cell(
      r: r,
      c: c,
      hasMine: hasMine,
      isOpen: isOpen ?? this.isOpen,
      isFlagged: isFlagged ?? this.isFlagged,
      adjacentMines: adjacentMines ?? this.adjacentMines,
    );
  }
}

class MinesweeperLogic extends NanoLogic<void> {
  // Config
  final rows = Atom<int>(10, label: 'rows');
  final cols = Atom<int>(10, label: 'cols');
  final totalMines = Atom<int>(10, label: 'totalMines');

  final board = Atom<List<List<Cell>>>([], label: 'board');
  final state = Atom<GameState>(GameState.playing, label: 'state');
  
  late final minesLeft = computed(() {
    int flags = 0;
    for (var row in board.value) {
      for (var cell in row) {
        if (cell.isFlagged) flags++;
      }
    }
    return totalMines.value - flags;
  }, label: 'minesLeft');

  void newGame({int? r, int? c, int? m}) {
    if (r != null) rows.value = r;
    if (c != null) cols.value = c;
    if (m != null) totalMines.value = m;

    final h = rows.value;
    final w = cols.value;
    final mines = totalMines.value;

    // Init empty board
    var b = List.generate(
      h,
      (r) => List.generate(w, (c) => Cell(r: r, c: c)),
    );

    // Place mines
    int placed = 0;
    final rand = Random();
    while (placed < mines) {
      final rr = rand.nextInt(h);
      final cc = rand.nextInt(w);
      if (!b[rr][cc].hasMine) {
        b[rr][cc] = Cell(r: rr, c: cc, hasMine: true);
        placed++;
      }
    }

    // Calc adjacent
    for (var rr = 0; rr < h; rr++) {
      for (var cc = 0; cc < w; cc++) {
        if (!b[rr][cc].hasMine) {
          int count = 0;
          for (var dr = -1; dr <= 1; dr++) {
            for (var dc = -1; dc <= 1; dc++) {
              if (dr == 0 && dc == 0) continue;
              final nr = rr + dr;
              final nc = cc + dc;
              if (nr >= 0 && nr < h && nc >= 0 && nc < w && b[nr][nc].hasMine) {
                count++;
              }
            }
          }
          b[rr][cc] = b[rr][cc].copyWith(adjacentMines: count);
        }
      }
    }

    board.value = b;
    state.value = GameState.playing;
  }

  void openCell(int r, int c) {
    if (state.value != GameState.playing) return;
    final b = List<List<Cell>>.from(board.value.map((l) => List<Cell>.from(l)));
    final cell = b[r][c];

    if (cell.isOpen || cell.isFlagged) return;

    if (cell.hasMine) {
      // Game Over
      _revealAllMines(b);
      board.value = b;
      state.value = GameState.lost;
      return;
    }

    _floodFill(b, r, c);
    board.value = b;
    _checkWin(b);
  }

  void toggleFlag(int r, int c) {
    if (state.value != GameState.playing) return;
    final b = List<List<Cell>>.from(board.value.map((l) => List<Cell>.from(l)));
    final cell = b[r][c];

    if (cell.isOpen) return;

    b[r][c] = cell.copyWith(isFlagged: !cell.isFlagged);
    board.value = b;
  }

  void _floodFill(List<List<Cell>> b, int r, int c) {
    if (r < 0 || r >= rows.value || c < 0 || c >= cols.value) return;
    if (b[r][c].isOpen || b[r][c].isFlagged) return;

    b[r][c] = b[r][c].copyWith(isOpen: true);

    if (b[r][c].adjacentMines == 0) {
      for (var dr = -1; dr <= 1; dr++) {
        for (var dc = -1; dc <= 1; dc++) {
          if (dr != 0 || dc != 0) _floodFill(b, r + dr, c + dc);
        }
      }
    }
  }

  void _revealAllMines(List<List<Cell>> b) {
    for (var r = 0; r < rows.value; r++) {
      for (var c = 0; c < cols.value; c++) {
        if (b[r][c].hasMine) {
          b[r][c] = b[r][c].copyWith(isOpen: true);
        }
      }
    }
  }

  void _checkWin(List<List<Cell>> b) {
    bool allClean = true;
    for (var r = 0; r < rows.value; r++) {
      for (var c = 0; c < cols.value; c++) {
        if (!b[r][c].hasMine && !b[r][c].isOpen) {
          allClean = false;
          break;
        }
      }
    }
    if (allClean) state.value = GameState.won;
  }

  @override
  void onReady() {
    newGame();
  }
}
