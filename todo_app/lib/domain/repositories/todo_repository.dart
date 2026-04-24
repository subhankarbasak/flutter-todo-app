import '../entities/todo.dart';

// Abstract contract. The UI depends on this, not the implementation.
abstract class TodoRepository {
  Future<List<Todo>> getTodos();
  Future<void> addTodo(Todo todo);
  Future<void> updateTodo(Todo todo);
  Future<void> deleteTodo(String id);
}