import 'package:flutter/material.dart';
import 'package:nano/nano.dart';
import 'logic.dart';

void main() {
  runApp(
    Scope(
      modules: [NanoLazy((_) => ExcuseLogic())],
      child: const ExcuseApp(),
    ),
  );
}

class ExcuseApp extends StatelessWidget {
  const ExcuseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nano Excuse Generator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple, brightness: Brightness.dark),
        useMaterial3: true,
      ),
      home: const ExcusePage(),
    );
  }
}

class ExcusePage extends StatelessWidget {
  const ExcusePage({super.key});

  @override
  Widget build(BuildContext context) {
    return NanoView<ExcuseLogic, void>(
      create: (reg) => reg.get<ExcuseLogic>(),
      builder: (context, logic) {
        return NanoPage(
          title: "Nano Excuse Generator",
          body: NanoStack(
            layout: const NanoLayout(
              spacing: 24,
              padding: EdgeInsets.all(32),
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
            ),
            children: [
              // Header
              "Professional IT Excuses".bold(fontSize: 28).center(),

              // Category Buttons
              _buildCategorySelector(logic),

              // Excuse Display
              Container(
                constraints: const BoxConstraints(minHeight: 120),
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: logic.currentExcuse.watch((context, excuse) => excuse
                    .text(
                        style: const TextStyle(
                            fontSize: 18, fontStyle: FontStyle.italic))
                    .center()),
              ),

              // Action Button
              logic.category
                  .button("INTERNALIZE EXCUSE",
                      onPressed: () => logic.generate())
                  .size(width: 250, height: 50),

              // Tip
              "Tip: Use these during Stand-up for maximum effect."
                  .text(
                      style: const TextStyle(color: Colors.grey, fontSize: 12))
                  .padding(const EdgeInsets.only(top: 100)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategorySelector(ExcuseLogic logic) {
    return logic.category.watch((context, current) => Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ExcuseCategory.values.map((cat) {
            final isSelected = current == cat;
            return FilterChip(
              label: Text(cat.name.toUpperCase()),
              selected: isSelected,
              onSelected: (_) => logic.setCategory(cat),
            );
          }).toList(),
        ));
  }
}
