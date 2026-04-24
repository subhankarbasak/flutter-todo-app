import 'package:hive/hive.dart';
import '../../domain/entities/todo.dart';

// Adapter to teach Hive how to store our Todo object
// In a real app, you would run 'build_runner' to generate this.
// For this manual example, we will handle conversion in the repository.
class TodoModel extends Todo {
  TodoModel({
    required String id,
    required String title,
    required String description,
    required bool isCompleted,
    required DateTime createdAt,
  }) : super(
    id: id,
    title: title,
    description: description,
    isCompleted: isCompleted,
    createdAt: createdAt,
  );

  // Helper to convert Hive Map back to Object
  factory TodoModel.fromMap(Map<String, dynamic> map) {
    return TodoModel(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      isCompleted: map['isCompleted'] as bool,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  // Helper to convert Object to Hive Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}