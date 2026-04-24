import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/repositories/category_repository.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final String _boxName = 'categoriesBox';

  Box _getBox() => Hive.box(_boxName);

  @override
  Future<List<String>> getCategories() async {
    final box = _getBox();
    // Return list of strings.
    // We handle the box not having data by returning default.
    if (box.isEmpty) {
      // Add default category if empty
      await addCategory('General');
      return ['General'];
    }
    return box.values.toList().cast<String>();
  }

  @override
  Future<void> addCategory(String name) async {
    final box = _getBox();
    // Avoid duplicates
    if (!box.values.contains(name)) {
      await box.add(name);
    }
  }

  @override
  Future<void> deleteCategory(String name) async {
    final box = _getBox();
    // Hive key might differ from value, so we search for the key that matches value
    final keyToDelete = box.keys.firstWhere((k) => box.get(k) == name, orElse: () => null);
    if (keyToDelete != null) {
      await box.delete(keyToDelete);
    }
  }
}