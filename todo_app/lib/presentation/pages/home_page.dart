import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/todo.dart';
import '../../main.dart';
import '../providers/todo_provider.dart';
import '../providers/category_provider.dart';

// Constants for categories
const List<String> categories = ['General', 'Work', 'Personal', 'Shopping', 'Health'];

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncTodos = ref.watch(todoProvider);
    final asyncCategories = ref.watch(categoryProvider);
    final theme = Theme.of(context);
    final currentThemeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Enterprise Todo'),
        centerTitle: true,
        elevation: 0,
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
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search tasks...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) {
                ref.read(todoProvider.notifier).setSearchQuery(val);
              },
            ),
          ),

          // Sort Chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Text('Sort: ', style: theme.textTheme.labelMedium),
                const SizedBox(width: 8),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: SortOption.values.map((opt) {
                        final isSelected = ref.watch(todoProvider.notifier).sortOption == opt;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: FilterChip(
                            label: Text(_getSortLabel(opt)),
                            selected: isSelected,
                            onSelected: (_) => ref.read(todoProvider.notifier).setSortOption(opt),
                            side: BorderSide.none,
                            backgroundColor: theme.colorScheme.surfaceContainerHighest,
                            selectedColor: theme.colorScheme.primaryContainer,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content (List or Shimmer)
          Expanded(
            child: asyncTodos.when(
              data: (todos) {
                if (todos.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline, size: 80, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No Tasks Found',
                          style: theme.textTheme.titleLarge?.copyWith(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: todos.length,
                  itemBuilder: (context, index) {
                    final todo = todos[index];
                    // Pass the Edit callback here
                    return _TodoCard(
                        todo: todo,
                        onEdit: () => _showTodoDialog(context, ref, todo)
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTodoDialog(context, ref),
        label: const Text('Add Task'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  String _getSortLabel(SortOption opt) {
    switch (opt) {
      case SortOption.dateAsc: return 'Date (Old)';
      case SortOption.dateDesc: return 'Date (New)';
      case SortOption.nameAsc: return 'Name (A-Z)';
      case SortOption.status: return 'Status';
      case SortOption.category: return 'Category'; // ADDED THIS
    }
  }

  // --- Add / Edit Todo Dialog ---
  void _showTodoDialog(BuildContext context, WidgetRef ref, [Todo? todo]) {
    final titleController = TextEditingController(text: todo?.title ?? '');
    final descController = TextEditingController(text: todo?.description ?? '');
    // Default to 'General' if not set or if list doesn't contain it yet
    String category = todo?.category ?? 'General';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(todo == null ? 'New Task' : 'Edit Task'),
          content: Consumer(
            builder: (context, ref, child) {
              // Watch categories inside dialog so it updates if we add a new one
              final asyncCats = ref.watch(categoryProvider);
              final cats = asyncCats.maybeWhen(data: (d) => d, orElse: () => ['General']);

              // Ensure current category is in the list (in case it was deleted but exists in history)
              if (!cats.contains(category)) {
                cats.insert(0, category);
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
                    autofocus: true,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),

                  // Dynamic Category Input
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: category,
                          decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                          items: cats.map((cat) {
                            return DropdownMenuItem(value: cat, child: Text(cat));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setDialogState(() => category = val);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Add Category Button
                      SizedBox(
                        width: 50,
                        height: 60,
                        child: IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () {
                            _showAddCategoryDialog(context, ref);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (titleController.text.isNotEmpty) {
                  if (todo == null) {
                    // Add
                    await ref.read(todoProvider.notifier).addTodo(
                      Todo(
                        id: const Uuid().v4(),
                        title: titleController.text,
                        description: descController.text,
                        category: category,
                        isCompleted: false,
                        createdAt: DateTime.now(),
                      ),
                    );
                    if (context.mounted) _showToast(context, 'Task Added');
                  } else {
                    // Edit
                    await ref.read(todoProvider.notifier).updateTodo(
                      todo.copyWith(
                        title: titleController.text,
                        description: descController.text,
                        category: category,
                      ),
                    );
                    if (context.mounted) _showToast(context, 'Task Updated');
                  }
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  // --- Add Category Dialog ---
  void _showAddCategoryDialog(BuildContext context, WidgetRef ref) {
    final catController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Category'),
        content: TextField(
          controller: catController,
          decoration: const InputDecoration(hintText: "Enter category name"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (catController.text.trim().isNotEmpty) {
                await ref.read(categoryProvider.notifier).addCategory(catController.text.trim());
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Create'),
          )
        ],
      ),
    );
  }

  void _showToast(BuildContext context, String message) {
    final snackBar = SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    );
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}

// --- Shimmer Loader (Same as before) ---
class _ShimmerLoader extends StatelessWidget {
  const _ShimmerLoader();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}

// --- Todo Card Widget (Updated for Edit) ---
class _TodoCard extends ConsumerWidget {
  final Todo todo;
  final VoidCallback onEdit; // NEW: Callback for Edit

  const _TodoCard({required this.todo, required this.onEdit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    Color categoryColor = Colors.blue;
    if(todo.category == 'Work') categoryColor = Colors.orange;
    if(todo.category == 'Personal') categoryColor = Colors.green;
    if(todo.category == 'Shopping') categoryColor = Colors.purple;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Checkbox(
          value: todo.isCompleted,
          onChanged: (_) async {
            await ref.read(todoProvider.notifier).updateTodo(todo.copyWith(isCompleted: !todo.isCompleted));
            if(context.mounted) {
              final msg = todo.isCompleted ? 'Marked Incomplete' : 'Marked Completed';
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), duration: Duration(seconds: 1)));
            }
          },
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                todo.title,
                style: TextStyle(
                  fontSize: 18,
                  decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
                  color: todo.isCompleted ? Colors.grey : null,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Chip(
                label: Text(todo.category, style: const TextStyle(fontSize: 10)),
                backgroundColor: categoryColor.withOpacity(0.2),
                side: BorderSide.none,
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
            ),
            if (todo.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Text(todo.description, style: theme.textTheme.bodyMedium),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                DateFormat('MMM dd, yyyy • hh:mm a').format(todo.createdAt),
                style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey),
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // WORKING EDIT BUTTON
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: onEdit, // Calls the function passed from HomePage
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Delete Task?'),
                    content: const Text('This action cannot be undone.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () async {
                          await ref.read(todoProvider.notifier).deleteTodo(todo.id);
                          Navigator.pop(context);
                          if(context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Task Deleted')));
                          }
                        },
                        child: const Text('Delete', style: TextStyle(color: Colors.red)),
                      )
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}