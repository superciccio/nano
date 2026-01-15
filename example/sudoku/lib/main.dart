import 'package:flutter/material.dart';
import 'package:nano/nano.dart';
import 'sudoku_logic.dart';

void main() {
  runApp(
    Scope(
      modules: [
        // Register Logic as a factory so we get a fresh one if we rebuild scope,
        // or just singleton if we want persistence.
        // For a game, keeping state while app is alive is good.
        NanoLazy((_) => SudokuLogic()),
      ],
      child: const SudokuApp(),
    ),
  );
}

class SudokuApp extends StatelessWidget {
  const SudokuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nano Sudoku',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
      ),
      home: const SudokuPage(),
    );
  }
}

class SudokuPage extends StatelessWidget {
  const SudokuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return NanoView<SudokuLogic, void>(
      create: (reg) => reg.get<SudokuLogic>(),
      builder: (context, logic) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Nano Sudoku'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => logic.newGame(),
              ),
            ],
          ),
          body: Column(
            children: [
              const SizedBox(height: 16),
              // Stats & Difficulty
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Watch(logic.mistakes, builder: (ctx, mistakes) {
                    return Text('Mistakes: $mistakes/3', 
                      style: TextStyle(color: mistakes >= 3 ? Colors.red : Colors.black));
                  }),
                  Watch(logic.difficulty, builder: (ctx, diff) {
                    return DropdownButton<Difficulty>(
                      value: diff,
                      items: Difficulty.values.map((d) => DropdownMenuItem(
                        value: d,
                        child: Text(d.name.toUpperCase()),
                      )).toList(),
                      onChanged: (d) {
                        if (d != null) logic.newGame(d);
                      },
                    );
                  }),
                ],
              ),
              const SizedBox(height: 16),
              
              // Grid
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: _SudokuGrid(logic: logic),
                    ),
                  ),
                ),
              ),
              
              // Numpad
              _NumPad(logic: logic),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}

class _SudokuGrid extends StatelessWidget {
  final SudokuLogic logic;
  const _SudokuGrid({required this.logic});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(width: 2),
      ),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 9,
        ),
        itemCount: 81,
        itemBuilder: (context, index) {
          final r = index ~/ 9;
          final c = index % 9;
          
          return Watch(logic.selectedCell, builder: (ctx, selected) {
            final isSelected = selected != null && selected.r == r && selected.c == c;
            
            return Watch(logic.board, builder: (ctx, board) {
              return Watch(logic.initialBoard, builder: (ctx, initial) {
                final val = board[r][c];
                final isFixed = initial[r][c] != 0;
                
                // Borders for 3x3
                final borderRight = (c + 1) % 3 == 0 && c != 8;
                final borderBottom = (r + 1) % 3 == 0 && r != 8;

                return GestureDetector(
                  onTap: () => logic.selectCell(r, c),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.indigo.withValues(alpha: 0.2) : (isFixed ? Colors.grey[200] : Colors.white),
                      border: Border(
                        right: BorderSide(width: borderRight ? 2 : 0.5),
                        bottom: BorderSide(width: borderBottom ? 2 : 0.5),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        val == 0 ? '' : val.toString(),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: isFixed ? FontWeight.bold : FontWeight.normal,
                          color: isFixed ? Colors.black : Colors.indigo,
                        ),
                      ),
                    ),
                  ),
                );
              });
            });
          });
        },
      ),
    );
  }
}

class _NumPad extends StatelessWidget {
  final SudokuLogic logic;
  const _NumPad({required this.logic});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      height: 60,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (var i = 1; i <= 9; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(2.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => logic.inputNumber(i),
                  child: Text('$i', style: const TextStyle(fontSize: 18)),
                ),
              ),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(2.0),
              child: IconButton(
                icon: const Icon(Icons.backspace),
                onPressed: () => logic.inputNumber(0), // Clear
              ),
            ),
          ),
        ],
      ),
    );
  }
}
