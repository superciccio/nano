import 'package:nano/nano.dart';

enum TaskStatus { backlog, todo, doing, done }

enum TaskPriority { low, medium, high }

/// A modern, reactive task model.
/// Notice how each task is a "mini-logic" container.
class TaskModel {
  final String id;
  final FieldAtom<String> title;
  final Atom<TaskStatus> status;
  final Atom<TaskPriority> priority;

  TaskModel({
    required this.id,
    required String initialTitle,
    TaskStatus initialStatus = TaskStatus.todo,
    TaskPriority initialPriority = TaskPriority.medium,
  })  : title = FieldAtom(initialTitle),
        status = Atom(initialStatus),
        priority = Atom(initialPriority);
}

class KanbanLogic extends NanoLogic<void> {
  // Master list of tasks
  final tasks = Atom<List<TaskModel>>([]);

  // Stats derived from tasks
  late final completionRate = ComputedAtom(() {
    if (tasks.value.isEmpty) return 0.0;
    final done =
        tasks.value.where((t) => t.status.value == TaskStatus.done).length;
    return (done / tasks.value.length) * 100;
  });

  // Active filter
  final searchQuery = FieldAtom("");
  final isSearchOpen = Atom(false);

  // Filtered view of tasks
  late final filteredTasks = ComputedAtom(() {
    if (!isSearchOpen.value) return tasks.value;
    final query = searchQuery.value.toLowerCase();
    if (query.isEmpty) return tasks.value;
    return tasks.value
        .where((t) => t.title.value.toLowerCase().contains(query))
        .toList();
  });

  // Derived: Is the board currently filtered?
  late final isFiltered =
      ComputedAtom(() => isSearchOpen.value && searchQuery.value.isNotEmpty);

  @override
  void onReady() {
    super.onReady();
    // Pre-populate with some sample data
    tasks.value = [
      TaskModel(
          id: '1',
          initialTitle: "Modularize Nano Framework",
          initialStatus: TaskStatus.done,
          initialPriority: TaskPriority.high),
      TaskModel(
          id: '2',
          initialTitle: "Implement Compose DSL",
          initialStatus: TaskStatus.doing,
          initialPriority: TaskPriority.medium),
      TaskModel(
          id: '3',
          initialTitle: "Write Complex Examples",
          initialStatus: TaskStatus.doing,
          initialPriority: TaskPriority.high),
      TaskModel(
          id: '4',
          initialTitle: "Unit Test Core Logic",
          initialStatus: TaskStatus.todo,
          initialPriority: TaskPriority.low),
      TaskModel(
          id: '5',
          initialTitle: "Review PR #42",
          initialStatus: TaskStatus.backlog,
          initialPriority: TaskPriority.medium),
    ];

    status.value = NanoStatus.success;
  }

  void addTask(String title, TaskStatus status) {
    final newTask = TaskModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      initialTitle: title,
      initialStatus: status,
    );
    tasks.value = [...tasks.value, newTask];
  }

  void moveTask(TaskModel task, TaskStatus newStatus) {
    task.status.value = newStatus;
    // Notify board of change (since status is deep, we force a list update or just rely on deep watch)
    // Actually, because TaskModel has its own atoms, individual card observers will update.
    // However, columns need to rebuild if a task MOVES between them.
    // So we update the list too.
    tasks.value = [...tasks.value];
  }

  void deleteTask(TaskModel task) {
    tasks.value = tasks.value.where((t) => t.id != task.id).toList();
  }

  void resetBoard() {
    tasks.value = [];
    searchQuery.value = "";
    isSearchOpen.value = false;
    onReady(); // Reuse pre-population
  }

  void toggleSearch() {
    isSearchOpen.value = !isSearchOpen.value;
    if (!isSearchOpen.value) searchQuery.value = "";
  }
}
