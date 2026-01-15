import 'dart:math';
import 'package:nano/nano.dart';

enum Difficulty {
  easy(30),
  medium(40),
  hard(50);

  final int holes;
  const Difficulty(this.holes);
}

class SudokuLogic extends NanoLogic<void> {
  // 9x9 Grid. 0 means empty.
  late final board = Atom<List<List<int>>>(
    List.generate(9, (_) => List.filled(9, 0)),
    label: 'board',
  );

  // Tracks the immutable starting numbers
  late final initialBoard = Atom<List<List<int>>>(
    List.generate(9, (_) => List.filled(9, 0)),
    label: 'initialBoard',
  );

  final difficulty = Atom<Difficulty>(Difficulty.easy, label: 'difficulty');
  final selectedCell =
      Atom<({int r, int c})?>((r: -1, c: -1), label: 'selected');
  final mistakes = Atom<int>(0, label: 'mistakes');
  final history = Atom<List<List<List<int>>>>([], label: 'history');

  late final isComplete = computed(() {
    final b = board.value;
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        if (b[r][c] == 0) return false;
      }
    }
    return _isValidBoard(b);
  }, label: 'isComplete');

  void newGame([Difficulty? diff]) {
    final d = diff ?? difficulty.value;
    difficulty.value = d;
    mistakes.value = 0;

    final fullBoard = _generateSolvedBoard();
    final newBoard = _removeNumbers(fullBoard, d.holes);

    // Deep copy for initial state
    initialBoard.value = newBoard.map((r) => List<int>.from(r)).toList();
    board.value = newBoard.map((r) => List<int>.from(r)).toList();
    history.value = [];
    selectedCell.value = null;
  }

  void selectCell(int r, int c) {
    if (initialBoard.value[r][c] != 0) return; // Cannot select fixed cells
    selectedCell.value = (r: r, c: c);
  }

  void inputNumber(int number) {
    final sel = selectedCell.value;
    if (sel == null || sel.r == -1) return;

    final r = sel.r;
    final c = sel.c;

    if (initialBoard.value[r][c] != 0) return;

    // Save history
    final currentHistory = List<List<List<int>>>.from(history.value);
    currentHistory.add(board.value.map((row) => List<int>.from(row)).toList());
    history.value = currentHistory;

    final newBoard = board.value.map((row) => List<int>.from(row)).toList();
    newBoard[r][c] = number;
    board.value = newBoard;

    // Check if move is valid immediately (optional, but good for feedback)
    if (number != 0 && !_isValidMove(newBoard, r, c, number)) {
      mistakes.update((v) => v + 1);
    }
  }

  void undo() {
    if (history.value.isEmpty) return;
    final prev = history.value.last;
    board.value = prev;
    history.update((h) => h.sublist(0, h.length - 1));
  }

  // --- Generator Logic ---

  List<List<int>> _generateSolvedBoard() {
    final b = List.generate(9, (_) => List.filled(9, 0));
    _solve(b);
    return b;
  }

  bool _solve(List<List<int>> b) {
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        if (b[r][c] == 0) {
          final nums = [1, 2, 3, 4, 5, 6, 7, 8, 9]..shuffle();
          for (final num in nums) {
            if (_isValidMove(b, r, c, num)) {
              b[r][c] = num;
              if (_solve(b)) return true;
              b[r][c] = 0;
            }
          }
          return false;
        }
      }
    }
    return true;
  }

  List<List<int>> _removeNumbers(List<List<int>> full, int holes) {
    final b = full.map((r) => List<int>.from(r)).toList();
    var removed = 0;
    final rand = Random();

    while (removed < holes) {
      final r = rand.nextInt(9);
      final c = rand.nextInt(9);
      if (b[r][c] != 0) {
        b[r][c] = 0;
        removed++;
      }
    }
    return b;
  }

  bool _isValidMove(List<List<int>> b, int r, int c, int num) {
    // Row & Col
    for (var i = 0; i < 9; i++) {
      if (b[r][i] == num && i != c) return false;
      if (b[i][c] == num && i != r) return false;
    }
    // 3x3 Box
    final startR = (r ~/ 3) * 3;
    final startC = (c ~/ 3) * 3;
    for (var i = 0; i < 3; i++) {
      for (var j = 0; j < 3; j++) {
        if (b[startR + i][startC + j] == num &&
            (startR + i != r || startC + j != c)) {
          return false;
        }
      }
    }
    return true;
  }

  bool _isValidBoard(List<List<int>> b) {
    // Simplified validation: if full and valid moves, it's solved.
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        if (b[r][c] == 0 || !_isValidMove(b, r, c, b[r][c])) return false;
      }
    }
    return true;
  }

  @override
  void onReady() {
    newGame(Difficulty.easy);
  }
}
