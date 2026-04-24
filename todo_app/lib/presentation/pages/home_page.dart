import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/todo.dart';
import '../../main.dart';
import '../providers/todo_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncTodos = ref.watch(todoProvider);
    final theme = Theme.of(context);

    // Watch the theme mode provider
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
              // FIX: Manually switch between Light and Dark
              final newMode = currentThemeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
              ref.read(themeModeProvider.notifier).state = newMode;
            },
          )
        ],
      ),
      body: asyncTodos.when(
        data: (todos) {
          if (todos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No Tasks Yet',
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
              return _TodoCard(todo: todo);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTodoDialog(context, ref),
        label: const Text('Add Task'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  void _showAddTodoDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Task'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
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
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (titleController.text.isNotEmpty) {
                ref.read(todoProvider.notifier).addTodo(
                  titleController.text,
                  descController.text,
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

// --- Sub-widgets for cleaner code ---
// Changed to ConsumerWidget to allow Delete functionality
class _TodoCard extends ConsumerWidget {
  final Todo todo;
  const _TodoCard({required this.todo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Row(
          children: [
            Checkbox(
              value: todo.isCompleted,
              onChanged: (_) => ref.read(todoProvider.notifier).toggleTodo(todo),
            ),
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
            if (todo.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 48.0, bottom: 4.0),
                child: Text(todo.description, style: theme.textTheme.bodyMedium),
              ),
            Padding(
              padding: const EdgeInsets.only(left: 48.0),
              child: Text(
                DateFormat('MMM dd, yyyy • hh:mm a').format(todo.createdAt),
                style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey),
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () {
            // Show confirmation dialog
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
                    onPressed: () {
                      // Access ref directly since we are in a ConsumerWidget
                      ref.read(todoProvider.notifier).deleteTodo(todo.id);
                      Navigator.pop(context);
                    },
                    child: const Text('Delete', style: TextStyle(color: Colors.red)),
                  )
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}