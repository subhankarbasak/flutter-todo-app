import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../domain/repositories/category_repository.dart';
import '../../data/repositories/category_repo_impl.dart';

// 1. Dependency Injection
final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepositoryImpl();
});

// 2. State Notifier
class CategoryNotifier extends StateNotifier<AsyncValue<List<String>>> {
  final CategoryRepository _repository;

  CategoryNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadCategories();
  }

  Future<void> loadCategories() async {
    state = const AsyncValue.loading();
    try {
      final cats = await _repository.getCategories();
      state = AsyncValue.data(cats);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addCategory(String name) async {
    await _repository.addCategory(name);
    await loadCategories();
  }

  Future<void> deleteCategory(String name) async {
    await _repository.deleteCategory(name);
    await loadCategories();
  }
}

final categoryProvider = StateNotifierProvider<CategoryNotifier, AsyncValue<List<String>>>((ref) {
  final repository = ref.watch(categoryRepositoryProvider);
  return CategoryNotifier(repository);
});