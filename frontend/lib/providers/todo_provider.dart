import 'package:flutter/foundation.dart';

import '../models/todo.dart';
import '../services/todo_service.dart';

class TodoProvider extends ChangeNotifier {
  TodoProvider({TodoService? service}) : _service = service ?? TodoService();

  final TodoService _service;

  List<Todo> todos = [];
  bool isLoading = false;
  String? error;
  Map<String, dynamic>? stats;

  Future<void> fetchTodos({
    bool? completed,
    String? priority,
    String? search,
  }) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      todos = await _service.getTodos(
        completed: completed,
        priority: priority,
        search: search,
      );
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<Todo?> createTodo({
    required String title,
    String description = '',
    String priority = 'medium',
    String? dueDate,
    List<String> tags = const [],
  }) async {
    error = null;
    try {
      final created = await _service.createTodo(
        title: title,
        description: description,
        priority: priority,
        dueDate: dueDate,
        tags: tags,
      );
      todos = [created, ...todos];
      notifyListeners();
      return created;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<void> updateTodo(String id, Map<String, dynamic> fields) async {
    final index = todos.indexWhere((t) => t.id == id);
    if (index == -1) return;

    final original = todos[index];
    final optimistic = _applyFields(original, fields);
    todos = List<Todo>.from(todos)..[index] = optimistic;
    error = null;
    notifyListeners();

    try {
      final fresh = await _service.updateTodo(id, fields);
      final current = todos.indexWhere((t) => t.id == id);
      if (current != -1) {
        todos = List<Todo>.from(todos)..[current] = fresh;
        notifyListeners();
      }
    } catch (e) {
      final current = todos.indexWhere((t) => t.id == id);
      if (current != -1) {
        todos = List<Todo>.from(todos)..[current] = original;
      }
      error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteTodo(String id) async {
    final index = todos.indexWhere((t) => t.id == id);
    if (index == -1) return;

    final original = todos[index];
    todos = todos.where((t) => t.id != id).toList(growable: false);
    error = null;
    notifyListeners();

    try {
      await _service.deleteTodo(id);
    } catch (e) {
      final restored = List<Todo>.from(todos);
      final insertAt = index <= restored.length ? index : restored.length;
      restored.insert(insertAt, original);
      todos = restored;
      error = e.toString();
      notifyListeners();
    }
  }

  Future<void> toggleComplete(String id) async {
    final index = todos.indexWhere((t) => t.id == id);
    if (index == -1) return;
    await updateTodo(id, {'completed': !todos[index].completed});
  }

  Future<void> fetchStats() async {
    error = null;
    try {
      stats = await _service.getStats();
    } catch (e) {
      error = e.toString();
    } finally {
      notifyListeners();
    }
  }

  Todo _applyFields(Todo original, Map<String, dynamic> fields) {
    return original.copyWith(
      title: fields['title'] as String?,
      description: fields['description'] as String?,
      completed: fields['completed'] as bool?,
      priority: fields['priority'] is String
          ? priorityFromString(fields['priority'] as String)
          : null,
      dueDate: fields.containsKey('due_date') && fields['due_date'] != null
          ? DateTime.tryParse(fields['due_date'].toString())
          : null,
      tags: (fields['tags'] as List?)
          ?.map((e) => e.toString())
          .toList(growable: false),
      updatedAt: DateTime.now(),
    );
  }
}
