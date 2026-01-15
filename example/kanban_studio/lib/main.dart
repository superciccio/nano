import 'package:flutter/material.dart';
import 'package:nano/nano.dart';
import 'logic.dart';

void main() {
  runApp(
    Scope(
      modules: [NanoLazy((_) => KanbanLogic())],
      child: const KanbanApp(),
    ),
  );
}

class KanbanApp extends StatelessWidget {
  const KanbanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nano Kanban Studio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blueGrey, brightness: Brightness.dark),
        useMaterial3: true,
      ),
      home: const KanbanBoardPage(),
    );
  }
}

class KanbanBoardPage extends StatelessWidget {
  const KanbanBoardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return NanoView<KanbanLogic, void>(
      create: (reg) => reg.get<KanbanLogic>(),
      rebuildOnUpdate: false,
      builder: (context, logic) => NanoPage(
        title: logic.isSearchOpen.watch((context, isOpen) => isOpen
            ? const SizedBox.shrink()
            : const Text("Nano Kanban Studio")),
        actions: [
          IconButton(
            onPressed: logic.toggleSearch,
            icon: logic.isSearchOpen.watch(
                (context, isOpen) => Icon(isOpen ? Icons.close : Icons.search)),
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'reset', child: Text("Reset Board")),
            ],
            onSelected: (val) {
              if (val == 'reset') logic.resetBoard();
            },
          ),
        ],
        body: Column(
          children: [
            logic.isSearchOpen.watch(
              (context, isOpen) => isOpen
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      color: Colors.white.withValues(alpha: 0.05),
                      child: logic.searchQuery.textField(
                        hint: "Search tasks...",
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search, size: 20),
                          border: InputBorder.none,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            _buildPowerBar(logic),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: TaskStatus.values
                      .map((status) => _buildColumn(context, logic, status))
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPowerBar(KanbanLogic logic) {
    return logic.completionRate.watch((context, rate) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            border: Border(
                bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
          ),
          child: Row(
            children: [
              "Project Velocity".text(
                  style: const TextStyle(fontSize: 14, color: Colors.grey)),
              const SizedBox(width: 20),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: rate / 100,
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    color: Colors.greenAccent,
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: 15),
              "${rate.toInt()}%".bold(),
            ],
          ),
        ));
  }

  Widget _buildColumn(
      BuildContext context, KanbanLogic logic, TaskStatus status) {
    return Container(
      width: 320,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Column Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              status.name
                  .toUpperCase()
                  .bold(fontSize: 14, color: Colors.blueGrey[200])
                  .padding(const EdgeInsets.only(left: 8)),
              IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () => logic.addTask("New Task", status),
                  icon: const Icon(Icons.add, size: 20)),
            ],
          ).padding(const EdgeInsets.only(bottom: 15)),

          // Tasks List
          Expanded(
            child: logic.filteredTasks.watch((context, allTasks) {
              final columnTasks =
                  allTasks.where((t) => t.status.value == status).toList();

              return ListView.builder(
                itemCount: columnTasks.length,
                itemBuilder: (context, index) => _TaskCard(
                  key: ValueKey(columnTasks[index].id),
                  task: columnTasks[index],
                  logic: logic,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final TaskModel task;
  final KanbanLogic logic;
  const _TaskCard({super.key, required this.task, required this.logic});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Priority Indicator
          task.priority
              .watch((context, priority) => Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _getPriorityColor(priority),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ))
              .padding(const EdgeInsets.only(bottom: 12)),

          // Title
          task.title.textField(
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),

          const SizedBox(height: 16),

          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatusPicker(context),
              IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () => logic.deleteTask(task),
                  icon: const Icon(Icons.delete_outline,
                      size: 18, color: Colors.redAccent)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPicker(BuildContext context) {
    return task.status.watch((context, current) => PopupMenuButton<TaskStatus>(
          initialValue: current,
          onSelected: (s) => logic.moveTask(task, s),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                current.name.bold(fontSize: 10, color: Colors.grey),
                const Icon(Icons.arrow_drop_down, size: 14, color: Colors.grey),
              ],
            ),
          ),
          itemBuilder: (context) => TaskStatus.values
              .map((s) => PopupMenuItem(
                    value: s,
                    child: s.name.text(),
                  ))
              .toList(),
        ));
  }

  Color _getPriorityColor(TaskPriority p) {
    switch (p) {
      case TaskPriority.low:
        return Colors.greenAccent;
      case TaskPriority.medium:
        return Colors.orangeAccent;
      case TaskPriority.high:
        return Colors.redAccent;
    }
  }
}
