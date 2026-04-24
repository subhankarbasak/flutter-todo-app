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

// 2. Sort Options Enum
enum SortOption { dateAsc, dateDesc, nameAsc, status, category }

// 3. State Notifier (Controller)
class TodoNotifier extends StateNotifier<AsyncValue<List<Todo>>> {
  final TodoRepository _repository;

  // Search and Sort State
  String _searchQuery = '';
  SortOption _sortOption = SortOption.dateDesc;

  TodoNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadTodos();
  }

  // Getters for current filters
  String get searchQuery => _searchQuery;
  SortOption get sortOption => _sortOption;

  Future<void> loadTodos() async {
    state = const AsyncValue.loading();
    try {
      final todos = await _repository.getTodos();
      // Apply Filter and Sort Logic
      final filtered = _applyFilters(todos);
      state = AsyncValue.data(filtered);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // Logic to filter and sort
  List<Todo> _applyFilters(List<Todo> todos) {
    // 1. Filter by Search
    var result = todos.where((t) {
      return t.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          t.description.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    // 2. Sort
    switch (_sortOption) {
      case SortOption.dateAsc:
        result.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case SortOption.dateDesc:
        result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case SortOption.nameAsc:
        result.sort((a, b) => a.title.compareTo(b.title));
        break;
      case SortOption.status:
        result.sort((a, b) => a.isCompleted.toString().compareTo(b.isCompleted.toString()));
        break;
      // NEW: Sort by Category
      case SortOption.category:
        result.sort((a, b) => a.category.toLowerCase().compareTo(b.category.toLowerCase()));
        break;
    }
    return result;
  }

  // Actions
  Future<void> setSearchQuery(String query) async {
    _searchQuery = query;
    // Re-process current data without fetching from DB if possible
    state.whenData((todos) async {
      // Fetch raw data again to ensure we filter correctly from source
      final raw = await _repository.getTodos();
      state = AsyncValue.data(_applyFilters(raw));
    });
  }

  Future<void> setSortOption(SortOption option) async {
    _sortOption = option;
    state.whenData((todos) async {
      final raw = await _repository.getTodos();
      state = AsyncValue.data(_applyFilters(raw));
    });
  }


  Future<void> addTodo(Todo todo) async {
    await _repository.addTodo(todo);
    await loadTodos();
  }

  Future<void> updateTodo(Todo todo) async {
    await _repository.updateTodo(todo);
    await loadTodos();
  }

  Future<void> deleteTodo(String id) async {
    await _repository.deleteTodo(id);
    await loadTodos();
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

}

// 3. Provider for the UI to consume
final todoProvider = StateNotifierProvider<TodoNotifier, AsyncValue<List<Todo>>>((ref) {
  final repository = ref.watch(todoRepositoryProvider);
  return TodoNotifier(repository);
});