abstract class CategoryRepository {
  Future<List<String>> getCategories();
  Future<void> addCategory(String name);
  Future<void> deleteCategory(String name);
}