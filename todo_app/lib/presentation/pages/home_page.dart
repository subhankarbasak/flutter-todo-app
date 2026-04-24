import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:confetti/confetti.dart'; // Import Confetti
import '../../domain/entities/todo.dart';
import '../../main.dart';
import '../providers/todo_provider.dart';
import '../providers/category_provider.dart';

// --- Main Page (Stateful for Confetti) ---
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    // Initialize Confetti Controller
    _confettiController = ConfettiController(duration: const Duration(seconds: 1));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  // List of Motivational Quotes
  final List<String> _quotes = [
    "Great job!", "You're on fire!", "Crushing it!",
    "Productivity master!", "One step closer to your goals!", "Excellent work!"
  ];

  void _fireConfetti() {
    _confettiController.play();
    // Pick random quote
    final randomQuote = _quotes[Random().nextInt(_quotes.length)];
    _showToast(context, randomQuote);
  }

  void _showToast(BuildContext context, String message) {
    final snackBar = SnackBar(
      content: Row(
        children: [
          const Icon(Icons.celebration, color: Colors.yellow),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.blueGrey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
    );
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    final asyncTodos = ref.watch(todoProvider);
    final asyncCategories = ref.watch(categoryProvider);
    final theme = Theme.of(context);
    final currentThemeMode = ref.watch(themeModeProvider);

    return Stack(
      children: [
        Scaffold(
          backgroundColor: theme.brightness == Brightness.dark
              ? const Color(0xFF121212)
              : const Color(0xFFF5F7FA), // Modern off-white background
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            title: Text(
              'My Tasks',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
            ),
            centerTitle: false, // Modern look
            actions: [
              IconButton(
                icon: Icon(currentThemeMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode),
                onPressed: () {
                  final newMode = currentThemeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
                  ref.read(themeModeProvider.notifier).state = newMode;
                },
              )
            ],
          ),
          body: Column(
            children: [
              // --- Modern Search Bar ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search tasks...',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    ),
                    onChanged: (val) {
                      ref.read(todoProvider.notifier).setSearchQuery(val);
                    },
                  ),
                ),
              ),

              // --- Horizontal Sort Chips ---
              SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: SortOption.values.length,
                  itemBuilder: (context, index) {
                    final opt = SortOption.values[index];
                    final isSelected = ref.watch(todoProvider.notifier).sortOption == opt;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: FilterChip(
                        label: Text(_getSortLabel(opt), style: TextStyle(fontSize: 13, color: isSelected ? Colors.white : Colors.grey[700])),
                        selected: isSelected,
                        onSelected: (_) => ref.read(todoProvider.notifier).setSortOption(opt),
                        side: BorderSide.none,
                        backgroundColor: theme.colorScheme.surface,
                        selectedColor: theme.colorScheme.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                    );
                  },
                ),
              ),

              // --- Task List ---
              Expanded(
                child: asyncTodos.when(
                  data: (todos) {
                    if (todos.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.task_alt, size: 100, color: Colors.grey[300]),
                            const SizedBox(height: 20),
                            Text(
                              'All caught up!',
                              style: theme.textTheme.titleLarge?.copyWith(color: Colors.grey),
                            ),
                          ],
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: todos.length,
                      itemBuilder: (context, index) {
                        final todo = todos[index];
                        return _ModernTodoCard(
                            todo: todo,
                            onEdit: () => _showBottomSheetModal(context, ref, todo),
                            onToggleComplete: () {
                              // Logic to trigger confetti if not already complete
                              if (!todo.isCompleted) {
                                _fireConfetti();
                              }
                            }
                        );
                      },
                    );
                  },
                  loading: () => const _ShimmerLoader(),
                  error: (err, stack) => Center(child: Text('Error: $err')),
                ),
              ),
            ],
          ),
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: FloatingActionButton.extended(
              onPressed: () => _showBottomSheetModal(context, ref),
              backgroundColor: theme.colorScheme.primary,
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              label: const Text('New Task', style: TextStyle(fontWeight: FontWeight.bold)),
              icon: const Icon(Icons.add),
            ),
          ),
        ),
        // --- Confetti Overlay ---
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: pi / 2, // downwards
            emissionFrequency: 0.05,
            numberOfParticles: 50,
            gravity: 0.1,
          ),
        ),
      ],
    );
  }

  String _getSortLabel(SortOption opt) {
    switch (opt) {
      case SortOption.dateAsc: return 'Date: Old';
      case SortOption.dateDesc: return 'Date: New';
      case SortOption.nameAsc: return 'Name: A-Z';
      case SortOption.status: return 'Status';
      case SortOption.category: return 'Category';
    }
  }

  // --- MODERN BOTTOM SHEET MODAL ---
  void _showBottomSheetModal(BuildContext context, WidgetRef ref, [Todo? todo]) {
    final titleController = TextEditingController(text: todo?.title ?? '');
    final descController = TextEditingController(text: todo?.description ?? '');
    String category = todo?.category ?? 'General';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.1), spreadRadius: 5, blurRadius: 15)
            ],
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom, // Move up with keyboard
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(5)),
                  ),
                ),
                const SizedBox(height: 20),
                Text(todo == null ? 'Create New Task' : 'Edit Task', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),

                // Inputs
                TextField(
                  controller: titleController,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                ),
                const SizedBox(height: 16),

                // Dynamic Category Dropdown
                Consumer(
                  builder: (context, ref, child) {
                    final asyncCats = ref.watch(categoryProvider);
                    final cats = asyncCats.maybeWhen(data: (d) => d, orElse: () => ['General']);
                    if (!cats.contains(category)) cats.insert(0, category);

                    return Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: category,
                            decoration: InputDecoration(
                              labelText: 'Category',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: Colors.grey[100],
                            ),
                            items: cats.map((cat) {
                              return DropdownMenuItem(value: cat, child: Text(cat));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setModalState(() => category = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, size: 30),
                          onPressed: () => _showAddCategoryDialog(context, ref),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 30),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (titleController.text.isNotEmpty) {
                        final newTodo = todo == null
                            ? Todo(
                          id: const Uuid().v4(),
                          title: titleController.text,
                          description: descController.text,
                          category: category,
                          isCompleted: false,
                          createdAt: DateTime.now(),
                        )
                            : todo.copyWith(
                          title: titleController.text,
                          description: descController.text,
                          category: category,
                        );

                        if (todo == null) {
                          await ref.read(todoProvider.notifier).addTodo(newTodo);
                        } else {
                          await ref.read(todoProvider.notifier).updateTodo(newTodo);
                        }

                        if (mounted) Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 4,
                    ),
                    child: const Text('Save Task', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context, WidgetRef ref) {
    final catController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Category'),
        content: TextField(
          controller: catController,
          decoration: const InputDecoration(hintText: "e.g. Urgent"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              if (catController.text.trim().isNotEmpty) {
                await ref.read(categoryProvider.notifier).addCategory(catController.text.trim());
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Create', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }
}

// --- Modern Shimmer Loader ---
class _ShimmerLoader extends StatelessWidget {
  const _ShimmerLoader();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }
}

// --- Modern Todo Card Widget ---
class _ModernTodoCard extends ConsumerWidget {
  final Todo todo;
  final VoidCallback onEdit;
  final VoidCallback onToggleComplete;

  const _ModernTodoCard({
    required this.todo,
    required this.onEdit,
    required this.onToggleComplete
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // Dynamic Colors
    Color categoryColor = Colors.blue;
    if(todo.category == 'Work') categoryColor = Colors.orange;
    if(todo.category == 'Personal') categoryColor = Colors.green;
    if(todo.category == 'Shopping') categoryColor = Colors.purple;

    return Dismissible(
      key: UniqueKey(),
      direction: DismissDirection.endToStart,
      onDismissed: (_) async {
        await ref.read(todoProvider.notifier).deleteTodo(todo.id);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Task Deleted')));
      },
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: GestureDetector(
        onTap: onEdit, // Tap card to edit
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Checkbox
              Transform.scale(
                scale: 1.2,
                child: Checkbox(
                  value: todo.isCompleted,
                  onChanged: (_) async {
                    await ref.read(todoProvider.notifier).updateTodo(todo.copyWith(isCompleted: !todo.isCompleted));
                    onToggleComplete(); // Trigger Confetti
                  },
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  activeColor: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            todo.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
                              color: todo.isCompleted ? Colors.grey : theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        // Edit Icon (Subtle)
                        if (!todo.isCompleted)
                          Icon(Icons.edit_outlined, size: 18, color: Colors.grey[400]),
                      ],
                    ),

                    const SizedBox(height: 6),

                    if (todo.description.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          todo.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                        ),
                      ),

                    // Footer: Category & Date
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: categoryColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            todo.category,
                            style: TextStyle(fontSize: 11, color: categoryColor, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Icon(Icons.access_time, size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('MMM dd').format(todo.createdAt),
                          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}