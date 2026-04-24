import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/entities/todo.dart';
import '../../domain/repositories/todo_repository.dart';
import '../models/todo_model.dart';

class TodoRepositoryImpl implements TodoRepository {
  final String _boxName = 'todosBox';

  // Helper to get the box
  Box _getBox() => Hive.box(_boxName);

  @override
  Future<List<Todo>> getTodos() async {
    final box = _getBox();
    // Convert Hive Maps to Domain Entities
    final todos = box.values.map((map) {
      // Handling both stored Map and Object scenarios
      if (map is Map) return TodoModel.fromMap(Map<String, dynamic>.from(map));
      return map as Todo; // Simplification
    }).toList();

    // Sort by creation date (newest first)
    todos.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return todos.cast<Todo>();
  }

  @override
  Future<void> addTodo(Todo todo) async {
    final box = _getBox();
    await box.put(todo.id, TodoModel(
      id: todo.id,
      title: todo.title,
      description: todo.description,
      category: todo.category, // Ensure this line exists
      isCompleted: todo.isCompleted,
      createdAt: todo.createdAt,
    ).toMap());
  }

  @override
  Future<void> updateTodo(Todo todo) async {
    final box = _getBox();
    await box.put(todo.id, TodoModel(
      id: todo.id,
      title: todo.title,
      description: todo.description,
      category: todo.category, // Ensure this line exists
      isCompleted: todo.isCompleted,
      createdAt: todo.createdAt,
    ).toMap());
  }

  @override
  Future<void> deleteTodo(String id) async {
    final box = _getBox();
    await box.delete(id);
  }
}