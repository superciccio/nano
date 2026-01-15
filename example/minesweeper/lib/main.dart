import 'package:flutter/material.dart';
import 'package:nano/nano.dart';
import 'minesweeper_logic.dart';

void main() {
  runApp(
    Scope(
      modules: [
        NanoLazy((_) => MinesweeperLogic()),
      ],
      child: const MinesweeperApp(),
    ),
  );
}

class MinesweeperApp extends StatelessWidget {
  const MinesweeperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nano Minesweeper',
      theme: ThemeData(
        primarySwatch: Colors.grey,
        scaffoldBackgroundColor: const Color(0xFFC0C0C0), // Classic Grey
        useMaterial3: false, // Retro feel
      ),
      home: const MinesweeperPage(),
    );
  }
}

class MinesweeperPage extends StatelessWidget {
  const MinesweeperPage({super.key});

  @override
  Widget build(BuildContext context) {
    return NanoView<MinesweeperLogic, void>(
      create: (reg) => reg.get<MinesweeperLogic>(),
      builder: (context, logic) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Nano Minesweeper'),
            backgroundColor: const Color(0xFF000080),
            foregroundColor: Colors.white,
            actions: [
              PopupMenuButton<String>(
                onSelected: (val) {
                  if (val == 'easy') logic.newGame(r: 9, c: 9, m: 10);
                  if (val == 'medium') logic.newGame(r: 16, c: 16, m: 40);
                  if (val == 'hard') logic.newGame(r: 16, c: 30, m: 99);
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'easy', child: Text('Beginner (9x9)')),
                  const PopupMenuItem(value: 'medium', child: Text('Intermediate (16x16)')),
                  const PopupMenuItem(value: 'hard', child: Text('Expert (16x30)')),
                ],
              )
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // HUD
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: _bezelDecoration(),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _DigitalClock(valueAtom: logic.minesLeft),
                      Watch(logic.state, builder: (ctx, state) {
                        IconData icon = Icons.sentiment_satisfied;
                        if (state == GameState.won) icon = Icons.sentiment_very_satisfied;
                        if (state == GameState.lost) icon = Icons.sentiment_very_dissatisfied;
                        return IconButton(
                          iconSize: 32,
                          icon: Icon(icon),
                          onPressed: () => logic.newGame(),
                        );
                      }),
                      const _DigitalClock(value: 000), // Timer placeholder
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Grid
                Expanded(
                  child: Container(
                    decoration: _bezelDecoration(),
                    child: Watch(logic.cols, builder: (ctx, cols) {
                      return Watch(logic.board, builder: (ctx, board) {
                        if (board.isEmpty) return const SizedBox.shrink();
                        return GridView.builder(
                          padding: EdgeInsets.zero,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: cols,
                          ),
                          itemCount: board.length * board[0].length,
                          itemBuilder: (context, index) {
                            final r = index ~/ cols;
                            final c = index % cols;
                            final cell = board[r][c];
                            return _MineCell(logic: logic, cell: cell);
                          },
                        );
                      });
                    }),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  BoxDecoration _bezelDecoration() {
    return BoxDecoration(
      border: Border(
        left: const BorderSide(color: Colors.white, width: 3),
        top: const BorderSide(color: Colors.white, width: 3),
        right: BorderSide(color: Colors.grey[700]!, width: 3),
        bottom: BorderSide(color: Colors.grey[700]!, width: 3),
      ),
      color: const Color(0xFFC0C0C0),
    );
  }
}

class _DigitalClock extends StatelessWidget {
  final Atom<int>? valueAtom;
  final int value;

  const _DigitalClock({this.valueAtom, this.value = 0});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      color: Colors.black,
      child: valueAtom != null 
        ? Watch(valueAtom!, builder: (ctx, v) => _text(v))
        : _text(value),
    );
  }

  Widget _text(int v) {
    return Text(
      v.toString().padLeft(3, '0'),
      style: const TextStyle(
        fontFamily: 'monospace',
        fontSize: 24,
        color: Colors.red,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _MineCell extends StatelessWidget {
  final MinesweeperLogic logic;
  final Cell cell;

  const _MineCell({required this.logic, required this.cell});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => logic.openCell(cell.r, cell.c),
      onLongPress: () => logic.toggleFlag(cell.r, cell.c),
      onSecondaryTap: () => logic.toggleFlag(cell.r, cell.c),
      child: Container(
        decoration: BoxDecoration(
          color: cell.isOpen ? Colors.grey[300] : const Color(0xFFC0C0C0),
          border: cell.isOpen 
            ? Border.all(color: Colors.grey[400]!)
            : Border(
                left: const BorderSide(color: Colors.white, width: 2),
                top: const BorderSide(color: Colors.white, width: 2),
                right: BorderSide(color: Colors.grey[700]!, width: 2),
                bottom: BorderSide(color: Colors.grey[700]!, width: 2),
              ),
        ),
        child: Center(child: _content(cell)),
      ),
    );
  }

  Widget _content(Cell cell) {
    if (cell.isFlagged) {
      return const Icon(Icons.flag, color: Colors.red, size: 16);
    }
    if (!cell.isOpen) return const SizedBox.shrink();
    if (cell.hasMine) {
      return const Icon(Icons.emergency, color: Colors.black, size: 16);
    }
    if (cell.adjacentMines > 0) {
      return Text(
        '${cell.adjacentMines}',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: _numColor(cell.adjacentMines),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Color _numColor(int n) {
    switch(n) {
      case 1: return Colors.blue;
      case 2: return Colors.green;
      case 3: return Colors.red;
      case 4: return Colors.indigo;
      case 5: return Colors.brown;
      case 6: return Colors.teal;
      case 7: return Colors.black;
      case 8: return Colors.grey;
      default: return Colors.blue;
    }
  }
}
