import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:uuid/uuid.dart'; // Add 'uuid' package to pubspec
import '../../domain/entities/todo.dart';
import '../../domain/repositories/todo_repository.dart';
import '../../data/repositories/todo_repo_impl.dart';

// 1. Dependency Injection Provider
final todoRepositoryProvider = Provider<TodoRepository>((ref) {
  return TodoRepositoryImpl();
});

// 2. State Notifier (Controller)
class TodoNotifier extends StateNotifier<AsyncValue<List<Todo>>> {
  final TodoRepository _repository;

  TodoNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadTodos();
  }

  Future<void> loadTodos() async {
    state = const AsyncValue.loading();
    try {
      final todos = await _repository.getTodos();
      state = AsyncValue.data(todos);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addTodo(String title, String description) async {
    // Optimistic UI could go here, but we'll stick to simple loading
    final newTodo = Todo(
      id: const Uuid().v4(),
      title: title,
      description: description,
      isCompleted: false,
      createdAt: DateTime.now(),
    );

    await _repository.addTodo(newTodo);
    await loadTodos(); // Refresh list
  }

  Future<void> toggleTodo(Todo todo) async {
    final updatedTodo = todo.copyWith(isCompleted: !todo.isCompleted);
    await _repository.updateTodo(updatedTodo);

    // Update state locally immediately for responsiveness
    state.whenData((todos) {
      final index = todos.indexWhere((t) => t.id == updatedTodo.id);
      if (index != -1) {
        todos[index] = updatedTodo;
        state = AsyncValue.data(List.from(todos)); // Trigger update
      }
    });
  }

  Future<void> deleteTodo(String id) async {
    await _repository.deleteTodo(id);
    state.whenData((todos) {
      state = AsyncValue.data(todos.where((t) => t.id != id).toList());
    });
  }
}

// 3. Provider for the UI to consume
final todoProvider = StateNotifierProvider<TodoNotifier, AsyncValue<List<Todo>>>((ref) {
  final repository = ref.watch(todoRepositoryProvider);
  return TodoNotifier(repository);
});