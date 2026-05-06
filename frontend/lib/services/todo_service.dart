import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/todo.dart';
import '../utils/constants.dart';

class TodoService {
  TodoService({http.Client? client}) : _client = client ?? http.Client();

  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  final http.Client _client;
  final String _root = '$baseUrl/api/todos';

  Future<List<Todo>> getTodos({
    bool? completed,
    String? priority,
    String? search,
  }) async {
    final qp = <String, String>{};
    if (completed != null) qp['completed'] = completed.toString();
    if (priority != null && priority.isNotEmpty) qp['priority'] = priority;
    if (search != null && search.isNotEmpty) qp['search'] = search;

    final uri =
        Uri.parse(_root).replace(queryParameters: qp.isEmpty ? null : qp);

    final res = await _send(() => _client.get(uri, headers: _headers));
    final body = _decode(res, 'getTodos');

    final outer = body['data'];
    final list = (outer is Map) ? outer['data'] : outer;
    if (list is! List) {
      throw Exception('getTodos failed: malformed response');
    }
    return list
        .map((e) => Todo.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(growable: false);
  }

  Future<Todo> createTodo({
    required String title,
    String description = '',
    String priority = 'medium',
    String? dueDate,
    List<String> tags = const [],
  }) async {
    final payload = <String, dynamic>{
      'title': title,
      'description': description,
      'priority': priority,
      'tags': tags,
    };
    if (dueDate != null && dueDate.isNotEmpty) {
      payload['due_date'] = dueDate;
    }

    final res = await _send(() => _client.post(
          Uri.parse(_root),
          headers: _headers,
          body: jsonEncode(payload),
        ));
    final body = _decode(res, 'createTodo');
    return Todo.fromJson(Map<String, dynamic>.from(body['data'] as Map));
  }

  Future<Todo> updateTodo(String id, Map<String, dynamic> fields) async {
    final res = await _send(() => _client.patch(
          Uri.parse('$_root/$id'),
          headers: _headers,
          body: jsonEncode(fields),
        ));
    final body = _decode(res, 'updateTodo');
    return Todo.fromJson(Map<String, dynamic>.from(body['data'] as Map));
  }

  Future<bool> deleteTodo(String id) async {
    final res = await _send(() => _client.delete(
          Uri.parse('$_root/$id'),
          headers: _headers,
        ));
    _decode(res, 'deleteTodo');
    return true;
  }

  Future<Map<String, dynamic>> getStats() async {
    final res = await _send(
        () => _client.get(Uri.parse('$_root/stats'), headers: _headers));
    final body = _decode(res, 'getStats');
    return Map<String, dynamic>.from(body['data'] as Map);
  }

  Future<http.Response> _send(Future<http.Response> Function() request) async {
    try {
      return await request();
    } on http.ClientException catch (e) {
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Map<String, dynamic> _decode(http.Response res, String op) {
    Map<String, dynamic> parsed;
    try {
      parsed = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      throw Exception(
          '$op failed: HTTP ${res.statusCode} (invalid JSON response)');
    }

    final ok = res.statusCode >= 200 &&
        res.statusCode < 300 &&
        parsed['success'] == true;
    if (!ok) {
      final msg = parsed['message'] ?? 'Unknown error';
      throw Exception('$op failed (HTTP ${res.statusCode}): $msg');
    }
    return parsed;
  }
}
