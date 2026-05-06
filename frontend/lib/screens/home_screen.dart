import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/todo_provider.dart';
import '../widgets/todo_tile.dart';

enum _Filter { all, pending, completed, high, medium, low }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  _Filter _filter = _Filter.all;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() {
    bool? completed;
    String? priority;
    switch (_filter) {
      case _Filter.all:
        break;
      case _Filter.pending:
        completed = false;
        break;
      case _Filter.completed:
        completed = true;
        break;
      case _Filter.high:
        priority = 'high';
        break;
      case _Filter.medium:
        priority = 'medium';
        break;
      case _Filter.low:
        priority = 'low';
        break;
    }
    return context
        .read<TodoProvider>()
        .fetchTodos(completed: completed, priority: priority);
  }

  void _setFilter(_Filter next) {
    if (_filter == next) return;
    setState(() => _filter = next);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        titleSpacing: 20,
        toolbarHeight: 72,
        title: const Text(
          'Today',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.black,
            height: 1.1,
          ),
        ),
      ),
      body: Column(
        children: [
          _FilterRow(filter: _filter, onChanged: _setFilter),
          const SizedBox(height: 8),
          Expanded(
            child: Consumer<TodoProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading && provider.todos.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.black),
                  );
                }
                if (provider.error != null && provider.todos.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        provider.error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                }
                if (provider.todos.isEmpty) {
                  return const Center(
                    child: Text(
                      'No todos yet',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 16,
                      ),
                    ),
                  );
                }
                return RefreshIndicator(
                  color: Colors.black,
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 96),
                    itemCount: provider.todos.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => TodoTile(todo: provider.todos[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.filter, required this.onChanged});

  final _Filter filter;
  final ValueChanged<_Filter> onChanged;

  static const _entries = <(_Filter, String)>[
    (_Filter.all, 'All'),
    (_Filter.pending, 'Pending'),
    (_Filter.completed, 'Completed'),
    (_Filter.high, 'High'),
    (_Filter.medium, 'Medium'),
    (_Filter.low, 'Low'),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _entries.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final (value, label) = _entries[i];
          final selected = value == filter;
          return ChoiceChip(
            label: Text(label),
            selected: selected,
            onSelected: (_) => onChanged(value),
            backgroundColor: Colors.white,
            selectedColor: Colors.black,
            side: BorderSide(
              color: selected ? Colors.black : Colors.black12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            labelStyle: TextStyle(
              color: selected ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w500,
            ),
            showCheckmark: false,
          );
        },
      ),
    );
  }
}
